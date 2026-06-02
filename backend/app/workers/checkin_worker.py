"""
checkin_worker.py
------------------
Cron job that runs every minute.

For each patient whose checkin_time matches the current UTC minute AND who
has not yet had a wellness_checkin recorded today, send an FCM push / SMS
to open the check-in flow in the Flutter app.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from app.core.database import get_db
from app.services.notification_service import notify_patient

logger = logging.getLogger(__name__)

CHECKIN_TITLE = "Daily Wellness Check-In"
CHECKIN_BODY = "Time for your daily check-in. How are you feeling today?"


async def trigger_daily_checkins() -> None:
    """Entry point registered with APScheduler — runs every minute."""
    now_utc: datetime = datetime.now(timezone.utc)
    today_str: str = now_utc.strftime("%Y-%m-%d")

    logger.debug("checkin_worker: running at %s", now_utc.isoformat())

    db = get_db()

    # patient_profiles.id is what wellness_checkins.patient_id references
    patients_result = (
        db.table("patient_profiles")
        .select("id, profile_id, checkin_time, checkin_frequency")
        .not_.is_("checkin_time", "null")
        .execute()
    )

    patients = (patients_result.data or []) if patients_result else []
    if not patients:
        return

    checkins_today_result = (
        db.table("wellness_checkins")
        .select("patient_id")
        .gte("completed_at", f"{today_str}T00:00:00Z")
        .lte("completed_at", f"{today_str}T23:59:59Z")
        .execute()
    )
    already_checked_in: set[str] = {
        row["patient_id"]
        for row in ((checkins_today_result.data or []) if checkins_today_result else [])
    }

    triggered: list[str] = []

    for patient in patients:
        patient_id: str = patient["id"]  # patient_profiles.id
        if patient_id in already_checked_in:
            continue

        checkin_time_str: str | None = patient.get("checkin_time")
        if not checkin_time_str:
            continue

        try:
            parts = str(checkin_time_str).split(":")
            scheduled_hour = int(parts[0])
            scheduled_minute = int(parts[1])
        except (IndexError, ValueError):
            logger.warning(
                "Invalid checkin_time '%s' for patient=%s",
                checkin_time_str,
                patient_id,
            )
            continue

        scheduled_dt = datetime(
            now_utc.year, now_utc.month, now_utc.day,
            scheduled_hour, scheduled_minute,
            tzinfo=timezone.utc,
        )

        delta_seconds = abs((now_utc - scheduled_dt).total_seconds())
        if delta_seconds > 60:
            continue

        logger.info(
            "Triggering check-in for patient=%s (checkin_time=%s, delta=%.1fs)",
            patient_id, checkin_time_str, delta_seconds,
        )

        try:
            await notify_patient(
                patient_id=patient_id,
                title=CHECKIN_TITLE,
                body=CHECKIN_BODY,
                data={"action": "open_checkin", "patient_id": patient_id},
            )
            triggered.append(patient_id)
        except Exception as exc:  # noqa: BLE001
            logger.error("Failed to notify patient=%s: %s", patient_id, exc)

    if triggered:
        logger.info(
            "checkin_worker: triggered check-ins for %d patients", len(triggered)
        )
