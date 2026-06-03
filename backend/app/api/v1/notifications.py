from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client
from pydantic import BaseModel

from app.core.database import get_db
from app.core.dependencies import get_current_patient, get_current_user
from app.models.notification import (
    NotificationPreferencesOut,
    NotificationPreferencesPatch,
)

router = APIRouter(prefix="/patient", tags=["Notification Preferences"])


class FcmTokenIn(BaseModel):
    token: str
    platform: Optional[str] = None


@router.post(
    "/fcm-token",
    summary="Register/refresh this device's FCM token (patient or caregiver)",
)
async def register_fcm_token(
    payload: FcmTokenIn,
    current_user: dict = Depends(get_current_user),
    db: Client = Depends(get_db),
):
    if not payload.token.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="token is required.",
        )
    db.table("fcm_tokens").upsert(
        {
            "user_id": current_user["profile_id"],
            "token": payload.token,
            "platform": payload.platform,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
        on_conflict="token",
    ).execute()
    return {"status": "ok"}


@router.get(
    "/notification-preferences",
    response_model=NotificationPreferencesOut,
    summary="Get notification preferences",
)
async def get_notification_preferences(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    patient_id: str = current_user["patient_profile_id"]

    result = (
        db.table("notification_preferences")
        .select("*")
        .eq("patient_id", patient_id)
        .limit(1)
        .execute()
    )

    if result.data:
        return result.data[0]

    # No row yet — return defaults without inserting.
    # The PATCH endpoint will create the row on first save via upsert.
    now = datetime.now(timezone.utc).isoformat()
    return {
        "id": patient_id,  # placeholder; real id assigned on first PATCH
        "patient_id": patient_id,
        "channel": "both",
        "quiet_from": None,
        "quiet_until": None,
        "language": "en",
        "created_at": now,
        "updated_at": now,
    }


@router.patch(
    "/notification-preferences",
    response_model=NotificationPreferencesOut,
    summary="Update notification preferences",
)
async def patch_notification_preferences(
    payload: NotificationPreferencesPatch,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    patient_id: str = current_user["patient_profile_id"]

    updates: dict = {}
    for field in ("channel", "quiet_from", "quiet_until", "language"):
        if field in payload.model_fields_set:
            updates[field] = getattr(payload, field, None)

    if not updates:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No fields provided to update.",
        )

    updates["updated_at"] = datetime.now(timezone.utc).isoformat()

    result = (
        db.table("notification_preferences")
        .upsert({"patient_id": patient_id, **updates}, on_conflict="patient_id")
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update notification preferences.",
        )

    return result.data[0]
