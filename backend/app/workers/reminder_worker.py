import logging
from datetime import datetime, timedelta, timezone
from typing import Any

from app.core.database import get_db
from app.services.notification_service import send_push

logger = logging.getLogger(__name__)


def _extract_medication_name(row: dict) -> str | None:
    meds = row.get("medications")
    if not meds:
        return None
    if isinstance(meds, list):
        meds = meds[0] if meds else None
    if isinstance(meds, dict):
        return meds.get("name")
    return None


def _parse_dt(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
    return None


async def medication_reminder_job() -> None:
    """Send FCM reminders for medication doses due in the next 15 minutes."""
    try:
        now = datetime.now(timezone.utc)
        window_end = now + timedelta(minutes=15)

        db = get_db()

        try:
            result = (
                db.table("medication_doses")
                .select("id, scheduled_at, status, medication_id, patient_id, medications(name)")
                .gte("scheduled_at", now.isoformat())
                .lt("scheduled_at", window_end.isoformat())
                .eq("status", "pending")
                .execute()
            )
        except Exception as e:  # noqa: BLE001
            logger.exception("medication_reminder_job: query failed: %s", e)
            return

        rows = (result.data or []) if result else []
        logger.info("medication_reminder_job: %d candidate doses", len(rows))

        for row in rows:
            try:
                dose_id = row.get("id")
                patient_id = row.get("patient_id")
                medication_name = _extract_medication_name(row) or "your medication"
                scheduled_at = _parse_dt(row.get("scheduled_at"))
                scheduled_str = scheduled_at.strftime("%H:%M") if scheduled_at else "soon"

                # No device_token column yet — log only
                logger.info(
                    "medication_reminder_job: dose=%s patient=%s med=%s at=%s (push skipped — no FCM token)",
                    dose_id, patient_id, medication_name, scheduled_str,
                )
            except Exception as e:  # noqa: BLE001
                logger.exception(
                    "medication_reminder_job: error processing row %s: %s",
                    row.get("id"), e,
                )
    except Exception as e:  # noqa: BLE001
        logger.exception("medication_reminder_job: unexpected failure: %s", e)


async def appointment_reminder_job() -> None:
    """Log upcoming appointments (24h-ahead and 30-min-ahead). Push deferred to Phase 4."""
    try:
        now = datetime.now(timezone.utc)
        daily_start = now + timedelta(hours=23)
        daily_end = now + timedelta(hours=25)
        soon_start = now + timedelta(minutes=25)
        soon_end = now + timedelta(minutes=35)

        db = get_db()

        rows: list[dict] = []
        for window_start, window_end, label in (
            (daily_start, daily_end, "daily"),
            (soon_start, soon_end, "soon"),
        ):
            try:
                result = (
                    db.table("appointments")
                    .select("id, title, appointment_at, status, patient_id")
                    .gte("appointment_at", window_start.isoformat())
                    .lt("appointment_at", window_end.isoformat())
                    .neq("status", "cancelled")
                    .execute()
                )
                batch = (result.data or []) if result else []
                logger.info(
                    "appointment_reminder_job: %d candidates in %s window",
                    len(batch), label,
                )
                rows.extend(batch)
            except Exception as e:  # noqa: BLE001
                logger.exception(
                    "appointment_reminder_job: query failed for %s window: %s",
                    label, e,
                )

        seen: set[Any] = set()
        for row in rows:
            appointment_id = row.get("id")
            if appointment_id in seen:
                continue
            seen.add(appointment_id)
            appointment_at = _parse_dt(row.get("appointment_at"))
            appt_str = appointment_at.strftime("%H:%M") if appointment_at else "soon"
            logger.info(
                "appointment_reminder_job: appt=%s title='%s' at=%s (push skipped — no FCM token)",
                appointment_id, row.get("title"), appt_str,
            )
    except Exception as e:  # noqa: BLE001
        logger.exception("appointment_reminder_job: unexpected failure: %s", e)
