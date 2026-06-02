"""
escalation_worker.py
---------------------
Cron job that runs every 30 minutes.

For every scheduled dose that:
  - has passed its scheduled_at timestamp by more than the patient's
    medication_grace_mins
  - has NO corresponding dose_log row

→ Insert a 'missed' dose_log
→ Notify all active caregivers (FCM + SMS) with patient name and medication

Idempotency: a UNIQUE constraint on dose_logs.dose_id prevents double-inserts.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any

from app.core.database import get_db
from app.services.notification_service import notify_caregivers

logger = logging.getLogger(__name__)


async def escalate_missed_doses() -> None:
    """Entry point registered with APScheduler — runs every 30 minutes."""
    now_utc: datetime = datetime.now(timezone.utc)

    logger.debug("escalation_worker: running at %s", now_utc.isoformat())

    db = get_db()

    lookback_cutoff = (now_utc - timedelta(hours=24)).isoformat()

    overdue_result = (
        db.table("medication_doses")
        .select(
            "id, scheduled_at, medication_id, patient_id, "
            "medications(name, dosage_amount, dosage_unit)"
        )
        .lt("scheduled_at", now_utc.isoformat())
        .gte("scheduled_at", lookback_cutoff)
        .execute()
    )

    all_overdue = (overdue_result.data or []) if overdue_result else []
    if not all_overdue:
        logger.debug("escalation_worker: no overdue doses found")
        return

    overdue_ids = [row["id"] for row in all_overdue]
    logged_result = (
        db.table("dose_logs")
        .select("dose_id")
        .in_("dose_id", overdue_ids)
        .execute()
    )
    already_logged: set[str] = {
        row["dose_id"]
        for row in ((logged_result.data or []) if logged_result else [])
    }

    missed_count = 0

    for dose in all_overdue:
        dose_id: str = dose["id"]
        if dose_id in already_logged:
            continue

        patient_id: str = dose["patient_id"]
        scheduled_at_str: str = dose["scheduled_at"]
        medication: dict = dose.get("medications") or {}
        med_name: str = medication.get("name", "Unknown medication")
        dosage_amount = medication.get("dosage_amount", "")
        dosage_unit: str = medication.get("dosage_unit", "")

        # Fetch grace_mins separately (no patient_id column on patient_profiles)
        grace_mins = _get_grace_mins(db, patient_id)

        try:
            scheduled_at = datetime.fromisoformat(
                scheduled_at_str.replace("Z", "+00:00")
            )
        except ValueError:
            logger.warning(
                "Cannot parse scheduled_at='%s' for dose=%s",
                scheduled_at_str, dose_id,
            )
            continue

        elapsed_mins = (now_utc - scheduled_at).total_seconds() / 60
        if elapsed_mins <= grace_mins:
            continue

        logger.info(
            "Marking dose=%s as missed (patient=%s, med=%s, elapsed=%.1f min, grace=%d min)",
            dose_id, patient_id, med_name, elapsed_mins, grace_mins,
        )

        try:
            db.table("dose_logs").insert(
                {
                    "dose_id": dose_id,
                    "patient_id": patient_id,
                    "status": "missed",
                    "logged_at": now_utc.isoformat(),
                },
            ).execute()
        except Exception as exc:  # noqa: BLE001
            if "duplicate" in str(exc).lower() or "unique" in str(exc).lower():
                logger.debug("dose_log for dose=%s already exists", dose_id)
                continue
            logger.error(
                "Failed to insert missed dose_log for dose=%s: %s", dose_id, exc
            )
            continue

        missed_count += 1

        patient_name = _get_patient_name(db, patient_id)
        dose_label = f"{dosage_amount} {dosage_unit}".strip() if dosage_amount else ""
        title = f"Missed Dose Alert — {patient_name}"
        body = (
            f"{patient_name} missed their {med_name}"
            + (f" ({dose_label})" if dose_label else "")
            + f" scheduled at {scheduled_at.strftime('%H:%M')} UTC."
        )

        try:
            await notify_caregivers(
                patient_id=patient_id,
                title=title,
                body=body,
                data={
                    "action": "missed_dose",
                    "dose_id": dose_id,
                    "patient_id": patient_id,
                    "medication": med_name,
                },
                force_sms=True,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error(
                "Failed to notify caregivers for patient=%s dose=%s: %s",
                patient_id, dose_id, exc,
            )

    logger.info("escalation_worker: processed %d missed dose(s)", missed_count)


def _get_grace_mins(db: Any, patient_id: str) -> int:
    """Fetch medication_grace_mins for the patient_profiles row with id=patient_id."""
    try:
        result = (
            db.table("patient_profiles")
            .select("medication_grace_mins")
            .eq("id", patient_id)
            .maybe_single()
            .execute()
        )
        data = (result.data or {}) if result else {}
        return data.get("medication_grace_mins", 30) or 30
    except Exception:  # noqa: BLE001
        return 30


def _get_patient_name(db: Any, patient_id: str) -> str:
    """Fetch the patient's display name. patient_id is patient_profiles.id."""
    try:
        result = (
            db.table("patient_profiles")
            .select("profile_id, profiles(full_name)")
            .eq("id", patient_id)
            .maybe_single()
            .execute()
        )
        data = (result.data or {}) if result else {}
        return (data.get("profiles") or {}).get("full_name", "Patient") or "Patient"
    except Exception:  # noqa: BLE001
        return "Patient"
