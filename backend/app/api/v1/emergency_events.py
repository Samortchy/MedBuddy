from fastapi import APIRouter, Depends, HTTPException, status, Query
from supabase import Client
from typing import Optional

from app.core.database import get_db
from app.core.dependencies import get_current_patient

router = APIRouter(prefix="/emergency-events", tags=["Emergency Events"])


# ─── GET /emergency-events ────────────────────────────────────────────────────

@router.get("/", summary="Get emergency events for the authenticated patient")
async def get_emergency_events(
    limit: int = Query(default=20, ge=1, le=100),
    include_resolved: bool = Query(default=True),
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns emergency events for the authenticated patient.
    Includes escalation steps for each event.
    """
    query = (
        db.table("emergency_events")
        .select("*, emergency_escalation_steps(*)")
        .eq("patient_id", current_user["patient_profile_id"])
        .order("triggered_at", desc=True)
        .limit(limit)
    )

    if not include_resolved:
        query = query.is_("resolved_at", "null")

    result = query.execute()
    return result.data or []


# ─── GET /emergency-events/{id} ───────────────────────────────────────────────

@router.get("/{event_id}", summary="Get a specific emergency event with all steps")
async def get_emergency_event(
    event_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    result = (
        db.table("emergency_events")
        .select("*, emergency_escalation_steps(*)")
        .eq("id", event_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency event not found.",
        )
    if str(result.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )
    return result.data


# ─── GET /emergency-events/{id}/steps ────────────────────────────────────────

@router.get("/{event_id}/steps", summary="Get escalation steps for an emergency event")
async def get_emergency_event_steps(
    event_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    # Verify ownership first
    event = (
        db.table("emergency_events")
        .select("patient_id")
        .eq("id", event_id)
        .single()
        .execute()
    )
    if not event.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found.")
    if str(event.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    result = (
        db.table("emergency_escalation_steps")
        .select("*")
        .eq("event_id", event_id)
        .order("attempted_at", desc=False)
        .execute()
    )
    return result.data or []