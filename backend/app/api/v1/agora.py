"""
Agora RTC token endpoint.
Phase 3 — real-time audio for the emergency flow.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.core.dependencies import get_current_user
from app.services import agora_service

router = APIRouter(prefix="/agora", tags=["Agora"])


class AgoraTokenRequest(BaseModel):
    channel_name: str
    uid: int = 0


@router.post("/token", summary="Generate an Agora RTC token (1 hour)")
async def create_agora_token(
    payload: AgoraTokenRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Returns an Agora RTC token for the given channel. Usable by patients and
    caregivers so both sides can join the same emergency audio channel.
    """
    if not payload.channel_name.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="channel_name is required.",
        )

    try:
        result = agora_service.generate_rtc_token(payload.channel_name, payload.uid)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(e),
        )

    return {
        "token": result["token"],
        "channel_name": result["channel_name"],
        "uid": result["uid"],
        "app_id": result["app_id"],
        "expires_at": datetime.fromtimestamp(
            result["expires_at"], tz=timezone.utc
        ).isoformat(),
    }
