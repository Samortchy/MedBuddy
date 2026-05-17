import logging
from datetime import datetime, timedelta, timezone
from typing import Any

from app.core.database import get_db
from app.services.notification_service import send_push

logger = logging.getLogger(__name__)


async def _acquire_db() -> Any:
    gen = get_db()
    return await gen.__anext__()


def _extract_fcm_token(row: dict) -> str | None:
    profiles = row.get("profiles")
    if not profiles:
        return None
    if isinstance(profiles, list):
        if not profiles:
            return None
        profiles = profiles[0]
    if isinstance(profiles, dict):
        return profiles.get("fcm_token")
    return None


def _extract_medication_name(row: dict) -> str | None:
    meds = row.get("medications")
    if not meds:
        return None
    if isinstance(meds, list):
        if not meds:
            return None
        meds = meds[0]
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
        window_start = now
        window_end = now + timedelta(minutes=15)

        try:
            db = await _acquire_db()
        except Exception as e:  # noqa: BLE001
            logger.exception("medication_reminder_job: failed to acquire db: %s", e)
            return

        try:
            result = await (
                db.table("doses")
                .select(
                    "id, scheduled_at, status, medication_id, patient_id, "
                    "medications(name), profiles(fcm_token)"
                )
                .gte("scheduled_at", window_start.isoformat())
                .lt("scheduled_at", window_end.isoformat())
                .eq("status", "pending")
                .execute()
            )
        except Exception as e:  # noqa: BLE001
            logger.exception("medication_reminder_job: query failed: %s", e)
            return

        rows = getattr(result, "data", None) or []
        logger.info("medication_reminder_job: %d candidate doses", len(rows))

        for row in rows:
            try:
                fcm_token = _extract_fcm_token(row)
                if not fcm_token:
                    logger.debug(
                        "medication_reminder_job: skip dose %s (no fcm_token)",
                        row.get("id"),
                    )
                    continue

                dose_id = row.get("id")
                patient_id = row.get("patient_id")
                medication_name = _extract_medication_name(row) or "your medication"
                scheduled_at = _parse_dt(row.get("scheduled_at"))
                scheduled_str = (
                    scheduled_at.strftime("%H:%M") if scheduled_at else "soon"
                )

                title = "Time to take your medication"
                body = (
                    f"It's time to take {medication_name}. "
                    f"Scheduled at {scheduled_str} UTC"
                )
                data = {
                    "type": "medication_reminder",
                    "dose_id": str(dose_id),
                    "patient_id": str(patient_id),
                }

                push_result = await send_push(fcm_token, title, body, data)
                if push_result.success:
                    logger.info(
                        "medication_reminder_job: pushed dose %s message_id=%s",
                        dose_id,
                        push_result.message_id,
                    )
                else:
                    logger.warning(
                        "medication_reminder_job: push failed dose %s error=%s",
                        dose_id,
                        push_result.error,
                    )
            except Exception as e:  # noqa: BLE001
                logger.exception(
                    "medication_reminder_job: error processing row %s: %s",
                    row.get("id"),
                    e,
                )
    except Exception as e:  # noqa: BLE001
        logger.exception("medication_reminder_job: unexpected failure: %s", e)


async def appointment_reminder_job() -> None:
    """Send FCM reminders for upcoming appointments (24h-ahead and 30-min-ahead)."""
    try:
        now = datetime.now(timezone.utc)
        daily_start = now + timedelta(hours=23)
        daily_end = now + timedelta(hours=25)
        soon_start = now + timedelta(minutes=25)
        soon_end = now + timedelta(minutes=35)

        try:
            db = await _acquire_db()
        except Exception as e:  # noqa: BLE001
            logger.exception("appointment_reminder_job: failed to acquire db: %s", e)
            return

        select_cols = (
            "id, title, appointment_at, status, patient_id, profiles(fcm_token)"
        )

        rows: list[dict] = []
        for window_start, window_end, label in (
            (daily_start, daily_end, "daily"),
            (soon_start, soon_end, "soon"),
        ):
            try:
                result = await (
                    db.table("appointments")
                    .select(select_cols)
                    .gte("appointment_at", window_start.isoformat())
                    .lt("appointment_at", window_end.isoformat())
                    .neq("status", "cancelled")
                    .execute()
                )
                batch = getattr(result, "data", None) or []
                logger.info(
                    "appointment_reminder_job: %d candidates in %s window",
                    len(batch),
                    label,
                )
                rows.extend(batch)
            except Exception as e:  # noqa: BLE001
                logger.exception(
                    "appointment_reminder_job: query failed for %s window: %s",
                    label,
                    e,
                )

        seen: set[Any] = set()
        for row in rows:
            try:
                appointment_id = row.get("id")
                if appointment_id in seen:
                    continue
                seen.add(appointment_id)

                fcm_token = _extract_fcm_token(row)
                if not fcm_token:
                    logger.debug(
                        "appointment_reminder_job: skip appt %s (no fcm_token)",
                        appointment_id,
                    )
                    continue

                patient_id = row.get("patient_id")
                appointment_title = row.get("title") or "your appointment"
                appointment_at = _parse_dt(row.get("appointment_at"))
                appt_str = (
                    appointment_at.strftime("%H:%M") if appointment_at else "soon"
                )

                title = "Upcoming appointment reminder"
                body = f"You have '{appointment_title}' at {appt_str} UTC"
                data = {
                    "type": "appointment_reminder",
                    "appointment_id": str(appointment_id),
                    "patient_id": str(patient_id),
                }

                push_result = await send_push(fcm_token, title, body, data)
                if push_result.success:
                    logger.info(
                        "appointment_reminder_job: pushed appt %s message_id=%s",
                        appointment_id,
                        push_result.message_id,
                    )
                else:
                    logger.warning(
                        "appointment_reminder_job: push failed appt %s error=%s",
                        appointment_id,
                        push_result.error,
                    )
            except Exception as e:  # noqa: BLE001
                logger.exception(
                    "appointment_reminder_job: error processing row %s: %s",
                    row.get("id"),
                    e,
                )
    except Exception as e:  # noqa: BLE001
        logger.exception("appointment_reminder_job: unexpected failure: %s", e)
