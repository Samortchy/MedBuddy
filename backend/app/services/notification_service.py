import asyncio
import json
import logging
import os
from datetime import datetime, time as dtime
from threading import Lock
from typing import Any, Literal

import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError

from app.core.config import settings
from app.core.database import get_db
from app.models.notification import PushResult

logger = logging.getLogger(__name__)

_init_lock = Lock()

Channel = Literal["push", "sms", "both"]


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
# Preference-aware dispatchers
# ---------------------------------------------------------------------------

def get_notification_preferences(patient_id: str) -> dict:
    """Return the notification_preferences row for a patient (defaults if none)."""
    db = get_db()
    result = (
        db.table("notification_preferences")
        .select("*")
        .eq("patient_id", patient_id)
        .maybe_single()
        .execute()
    )
    if result and result.data:
        return result.data
    return {
        "channel": "both",
        "quiet_from": None,
        "quiet_until": None,
        "language": "en",
    }


def _is_quiet_hours(prefs: dict) -> bool:
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

    patient_id is patient_profiles.id.
    No device_token column exists yet — push is skipped; falls back to SMS if available.
    """
    prefs = get_notification_preferences(patient_id)

    if not force_sms and _is_quiet_hours(prefs):
        logger.info("Skipping notification for patient=%s (quiet hours)", patient_id)
        return

    channel: Channel = prefs.get("channel", "both")
    db = get_db()

    profile_result = (
        db.table("patient_profiles")
        .select("profile_id, profiles(phone)")
        .eq("id", patient_id)
        .maybe_single()
        .execute()
    )
    patient_data = (profile_result.data or {}) if profile_result else {}
    phone: str | None = (patient_data.get("profiles") or {}).get("phone")

    # No device_token column on patient_profiles yet — push skipped until Phase 4
    if channel in ("sms", "both") or force_sms:
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
    """Notify all active caregivers linked to a patient.

    Looks up caregiver profiles via caregiver_patient_links.
    Push skipped until Phase 4 (no device_token column yet); SMS attempted if phone on file.
    """
    db = get_db()
    links_result = (
        db.table("caregiver_patient_links")
        .select("caregiver_id, profiles!caregiver_id(phone)")
        .eq("patient_id", patient_id)
        .eq("status", "active")
        .execute()
    )

    for link in (links_result.data or []) if links_result else []:
        caregiver_id: str = link["caregiver_id"]
        phone: str | None = (link.get("profiles") or {}).get("phone")

        if force_sms and phone:
            await _send_sms(phone, f"{title}: {body}")

        logger.info(
            "notify_caregivers: caregiver=%s patient=%s sms_attempted=%s",
            caregiver_id, patient_id, bool(phone and force_sms),
        )
