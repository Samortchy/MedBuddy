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
