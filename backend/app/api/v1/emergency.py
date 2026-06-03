"""
Emergency endpoints — trigger (fall / SOS) and liveness verification.
Phase 3.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from supabase import Client
from pydantic import BaseModel

from app.core.database import get_db
from app.core.dependencies import get_current_patient
from app.core.limiter import limiter
from app.services import agora_service

router = APIRouter(prefix="/emergency", tags=["Emergency"])
logger = logging.getLogger(__name__)


class TriggerType(str, Enum):
    fall_detected = "fall_detected"
    manual_sos = "manual_sos"


class EmergencyTriggerRequest(BaseModel):
    event_type: TriggerType
    gps_lat: Optional[float] = None
    gps_lng: Optional[float] = None
    gps_accuracy: Optional[float] = None


class EmergencyVerifyRequest(BaseModel):
    event_id: str
    verified: bool
    factor: str = "factor1"  # "factor1" | "factor2"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _channel_for(event_id: str) -> str:
    # Agora channel names must be ASCII and < 64 bytes. Strip hyphens from UUID.
    return f"emg{event_id.replace('-', '')}"[:64]


# ─── POST /emergency/trigger ──────────────────────────────────────────────────

@router.post(
    "/trigger",
    status_code=status.HTTP_201_CREATED,
    summary="Trigger an emergency (fall detection or manual SOS)",
)
@limiter.limit("3/minute")
async def trigger_emergency(
    request: Request,
    payload: EmergencyTriggerRequest,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Creates an emergency_events row and returns an Agora channel + token so the
    patient can open a real-time audio channel for the caregiver to join.
    """
    patient_id = current_user["patient_profile_id"]

    insert_data: dict = {
        "patient_id": patient_id,
        "trigger_type": payload.event_type.value,
        "triggered_at": _now(),
    }
    if payload.gps_lat is not None:
        insert_data["gps_lat"] = payload.gps_lat
    if payload.gps_lng is not None:
        insert_data["gps_lng"] = payload.gps_lng
    if payload.gps_accuracy is not None:
        insert_data["gps_accuracy"] = payload.gps_accuracy

    result = db.table("emergency_events").insert(insert_data).execute()
    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create emergency event.",
        )

    event = result.data[0]
    event_id = event["id"]
    channel = _channel_for(event_id)

    # Generate an Agora token for the patient (uid 0). Don't fail the whole
    # emergency if Agora isn't configured — still return the event.
    agora_token: Optional[str] = None
    agora_app_id: Optional[str] = None
    try:
        agora = agora_service.generate_rtc_token(channel, uid=0)
        agora_token = agora["token"]
        agora_app_id = agora["app_id"]
    except ValueError as e:
        logger.warning("Agora token not generated: %s", e)

    # Notify linked caregivers via FCM so they can join the emergency channel.
    try:
        from app.services import notification_service

        label = event["trigger_type"].replace("_", " ").title()
        await notification_service.notify_caregivers(
            patient_id,
            "Emergency Alert",
            f"{label} — your patient may need help. Tap to respond.",
            data={
                "type": "emergency",
                "event_id": str(event_id),
                "agora_channel": channel,
            },
        )
    except Exception as e:  # noqa: BLE001
        logger.warning("Failed to notify caregivers: %s", e)

    return {
        "event_id": event_id,
        "agora_channel": channel,
        "agora_token": agora_token,
        "agora_app_id": agora_app_id,
        "trigger_type": event["trigger_type"],
        "triggered_at": event["triggered_at"],
    }


# ─── POST /emergency/verify ───────────────────────────────────────────────────

@router.post(
    "/verify",
    summary="Record a liveness verification step for an emergency",
)
async def verify_emergency(
    payload: EmergencyVerifyRequest,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Logs an escalation step. If verified, the event is resolved as a false
    alarm (patient responded). If not verified on factor2, escalation begins
    (the caregiver audio call is needed).
    """
    existing = (
        db.table("emergency_events")
        .select("id, patient_id, resolved_at")
        .eq("id", payload.event_id)
        .single()
        .execute()
    )
    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency event not found.",
        )
    if str(existing.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )

    # Log the verification attempt as an escalation step.
    db.table("emergency_escalation_steps").insert({
        "event_id": payload.event_id,
        "step_type": f"liveness_{payload.factor}",
        "status": "completed" if payload.verified else "failed",
        "attempted_at": _now(),
    }).execute()

    if payload.verified:
        # Patient responded — resolve as a false alarm.
        db.table("emergency_events").update({
            "resolved_at": _now(),
            "outcome": "false_alarm",
        }).eq("id", payload.event_id).execute()
        return {"status": "resolved", "outcome": "false_alarm"}

    # Not verified. On the second factor, escalate to the caregiver call.
    if payload.factor == "factor2":
        return {"status": "escalate", "needs_call": True}
    return {"status": "retry"}
