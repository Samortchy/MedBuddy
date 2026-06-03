"""
Agora RTC token service.

Generates short-lived RTC tokens so the patient and caregiver can join a
real-time audio channel during an emergency. Credentials come from
settings.agora_app_id / settings.agora_app_certificate (backend .env only).
"""

from __future__ import annotations

import time

from agora_token_builder import RtcTokenBuilder

from app.core.config import settings

# Agora privilege roles: 1 = publisher (can send + receive audio).
_ROLE_PUBLISHER = 1

DEFAULT_EXPIRE_SECONDS = 3600  # 1 hour


def generate_rtc_token(
    channel_name: str,
    uid: int = 0,
    expire_seconds: int = DEFAULT_EXPIRE_SECONDS,
) -> dict:
    """
    Build an Agora RTC token for a channel.

    Raises:
        ValueError: if Agora credentials are not configured.

    Returns:
        dict with token, channel_name, uid, app_id, expires_at (unix ts).
    """
    app_id = settings.agora_app_id
    app_cert = settings.agora_app_certificate
    if not app_id or not app_cert:
        raise ValueError(
            "Agora is not configured. Set AGORA_APP_ID and "
            "AGORA_APP_CERTIFICATE in backend/.env."
        )

    privilege_expired_ts = int(time.time()) + expire_seconds
    token = RtcTokenBuilder.buildTokenWithUid(
        app_id,
        app_cert,
        channel_name,
        uid,
        _ROLE_PUBLISHER,
        privilege_expired_ts,
    )
    return {
        "token": token,
        "channel_name": channel_name,
        "uid": uid,
        "app_id": app_id,
        "expires_at": privilege_expired_ts,
    }
