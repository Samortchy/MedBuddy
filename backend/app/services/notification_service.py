import asyncio
import json
import logging
import os
from threading import Lock

import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError

from app.core.config import settings
from app.models.notification import PushResult

logger = logging.getLogger(__name__)

_init_lock = Lock()


def _load_credentials() -> credentials.Certificate:
    raw = settings.FIREBASE_CREDENTIALS_JSON
    if raw and os.path.isfile(raw):
        return credentials.Certificate(raw)
    cred_dict = json.loads(raw)
    return credentials.Certificate(cred_dict)


def _ensure_initialized() -> None:
    try:
        firebase_admin.get_app()
        return
    except ValueError:
        pass
    with _init_lock:
        try:
            firebase_admin.get_app()
        except ValueError:
            cred = _load_credentials()
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized")


def _send_sync(message: messaging.Message) -> str:
    return messaging.send(message)


async def send_push(
    device_token: str,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> PushResult:
    """Send a single FCM push notification. Returns PushResult — never raises."""
    try:
        _ensure_initialized()
        message = messaging.Message(
            token=device_token,
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
        )
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(None, _send_sync, message)
        logger.info("FCM push sent: message_id=%s", response)
        return PushResult(success=True, message_id=response)
    except FirebaseError as e:
        logger.warning("FCM push failed (FirebaseError): %s", e)
        return PushResult(success=False, error=str(e))
    except Exception as e:  # noqa: BLE001
        logger.exception("FCM push failed (unexpected): %s", e)
        return PushResult(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Preference-aware dispatchers (Menna — Tasks 24/25/26)
# ---------------------------------------------------------------------------

from datetime import datetime, time as dtime
from typing import Any, Literal

from app.core.database import get_db

Channel = Literal["push", "sms", "both"]


async def _acquire_db() -> Any:
    """Match reminder_worker._acquire_db — handles get_db being an async-gen."""
    candidate = get_db()
    if hasattr(candidate, "__anext__"):
        return await candidate.__anext__()
    return candidate


async def get_notification_preferences(patient_id: str) -> dict:
    """Return the notification_preferences row for a patient (defaults if none)."""
    db = await _acquire_db()
    result = await (
        db.table("notification_preferences")
        .select("*")
        .eq("patient_id", patient_id)
        .maybe_single()
        .execute()
    )
    if getattr(result, "data", None):
        return result.data
    return {
        "channel": "both",
        "quiet_from": None,
        "quiet_until": None,
        "language": "en",
    }


def _is_quiet_hours(prefs: dict) -> bool:
    """Return True if current UTC time is within the patient's quiet window."""
    quiet_from = prefs.get("quiet_from")
    quiet_until = prefs.get("quiet_until")
    if not quiet_from or not quiet_until:
        return False

    now = datetime.utcnow().time()

    def _parse(t: str) -> dtime:
        parts = t.split(":")
        return dtime(int(parts[0]), int(parts[1]))

    qf = _parse(quiet_from)
    qu = _parse(quiet_until)

    if qf <= qu:
        return qf <= now <= qu
    return now >= qf or now <= qu


async def _send_sms(phone: str, message: str) -> bool:
    """Send SMS via Twilio. Returns True on success."""
    try:
        from twilio.rest import Client  # noqa: PLC0415

        client = Client(
            os.environ["TWILIO_ACCOUNT_SID"],
            os.environ["TWILIO_AUTH_TOKEN"],
        )
        client.messages.create(
            body=message,
            from_=os.environ["TWILIO_FROM_NUMBER"],
            to=phone,
        )
        logger.info("SMS sent to phone=***%s", phone[-4:])
        return True
    except Exception as exc:  # noqa: BLE001
        logger.warning("SMS delivery failed: %s", exc)
        return False


async def notify_patient(
    patient_id: str,
    title: str,
    body: str,
    data: dict | None = None,
    *,
    force_sms: bool = False,
) -> None:
    """Send a notification to a patient honouring channel preference + quiet hours.

    force_sms=True bypasses quiet hours and channel preference (emergency).
    """
    prefs = await get_notification_preferences(patient_id)

    if not force_sms and _is_quiet_hours(prefs):
        logger.info("Skipping notification for patient=%s (quiet hours)", patient_id)
        return

    channel: Channel = prefs.get("channel", "both")
    db = await _acquire_db()

    profile = await (
        db.table("patient_profiles")
        .select("device_token, profiles(phone)")
        .eq("patient_id", patient_id)
        .single()
        .execute()
    )
    patient_data = getattr(profile, "data", None) or {}
    device_token: str | None = patient_data.get("device_token")
    phone: str | None = (patient_data.get("profiles") or {}).get("phone")

    push_ok = False
    if channel in ("push", "both") and device_token and not force_sms:
        result = await send_push(device_token, title, body, {str(k): str(v) for k, v in (data or {}).items()})
        push_ok = result.success

    if force_sms or channel in ("sms", "both") or not push_ok:
        if phone:
            await _send_sms(phone, f"{title}: {body}")


async def notify_caregivers(
    patient_id: str,
    title: str,
    body: str,
    data: dict | None = None,
    *,
    force_sms: bool = False,
) -> None:
    """Notify all active caregivers linked to a patient via FCM + SMS."""
    db = await _acquire_db()
    links = await (
        db.table("caregiver_patient_links")
        .select("caregiver_id, profiles(phone), patient_profiles!caregiver_id(device_token)")
        .eq("patient_id", patient_id)
        .eq("status", "active")
        .execute()
    )

    for link in getattr(links, "data", None) or []:
        caregiver_id: str = link["caregiver_id"]
        device_token: str | None = (link.get("patient_profiles") or {}).get("device_token")
        phone: str | None = (link.get("profiles") or {}).get("phone")

        push_ok = False
        if device_token:
            result = await send_push(device_token, title, body, {str(k): str(v) for k, v in (data or {}).items()})
            push_ok = result.success

        if force_sms or not push_ok:
            if phone:
                await _send_sms(phone, f"{title}: {body}")

        logger.info(
            "Notified caregiver=%s for patient=%s push_ok=%s",
            caregiver_id,
            patient_id,
            push_ok,
        )
