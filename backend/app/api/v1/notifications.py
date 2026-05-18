"""
notifications.py  (Task #27)
-----------------------------
FastAPI router for GET and PATCH /patient/notification-preferences.

DB dependency: notification_preferences table (sql/05_notification_prefs.sql):
  id, patient_id (FK), channel ('push'/'sms'/'both'),
  quiet_from (time), quiet_until (time), language (text), created_at, updated_at

Auth: patient_id is always taken from the JWT (get_current_user), never from
the request body — consistent with the rest of the API.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_current_user
from app.core.database import get_db
from app.models.notification import (
    NotificationPreferencesOut,
    NotificationPreferencesPatch,
)

router = APIRouter(prefix="/patient", tags=["Notification Preferences"])


async def _acquire_db() -> Any:
    candidate = get_db()
    if hasattr(candidate, "__anext__"):
        return await candidate.__anext__()
    return candidate


@router.get(
    "/notification-preferences",
    response_model=NotificationPreferencesOut,
    summary="Get notification preferences",
    description=(
        "Returns the current patient's notification preferences. "
        "If no preferences row exists yet, one is created with defaults."
    ),
)
async def get_notification_preferences(
    current_user: dict = Depends(get_current_user),
):
    patient_id: str = current_user["id"]
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

    now = datetime.now(timezone.utc).isoformat()
    defaults = {
        "patient_id": patient_id,
        "channel": "both",
        "quiet_from": None,
        "quiet_until": None,
        "language": "en",
        "created_at": now,
        "updated_at": now,
    }
    created = await db.table("notification_preferences").insert(defaults).execute()

    if not getattr(created, "data", None):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to initialise notification preferences",
        )

    return created.data[0]


@router.patch(
    "/notification-preferences",
    response_model=NotificationPreferencesOut,
    summary="Update notification preferences",
    description=(
        "Update one or more notification preference fields. "
        "Only provided fields are changed (partial update). "
        "Set quiet_from / quiet_until to null to disable quiet hours. "
        "The workers (check-in and reminder crons) read these settings "
        "before every notification."
    ),
)
async def patch_notification_preferences(
    payload: NotificationPreferencesPatch,
    current_user: dict = Depends(get_current_user),
):
    patient_id: str = current_user["id"]
    db = await _acquire_db()

    updates: dict = {}
    for field in ("channel", "quiet_from", "quiet_until", "language"):
        if field in payload.model_fields_set:
            updates[field] = getattr(payload, field, None)

    if not updates:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No fields provided to update",
        )

    updates["updated_at"] = datetime.now(timezone.utc).isoformat()

    result = await (
        db.table("notification_preferences")
        .upsert(
            {"patient_id": patient_id, **updates},
            on_conflict="patient_id",
        )
        .execute()
    )

    if not getattr(result, "data", None):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update notification preferences",
        )

    return result.data[0]
