from fastapi import APIRouter, Depends, HTTPException, status, Query
from supabase import Client
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone, date

from app.core.database import get_db
from app.core.dependencies import get_current_patient

router = APIRouter(prefix="/visit-summaries", tags=["Visit Summaries"])


# ─── Models ───────────────────────────────────────────────────────────────────

class VisitSummaryCreate(BaseModel):
    appointment_id: Optional[str] = None
    raw_transcript: Optional[str] = None
    diagnosis: Optional[str] = None
    medications_changed: Optional[str] = None
    instructions: Optional[str] = None
    next_appointment: Optional[date] = None
    audio_url: Optional[str] = None


class VisitSummaryUpdate(BaseModel):
    raw_transcript: Optional[str] = None
    diagnosis: Optional[str] = None
    medications_changed: Optional[str] = None
    instructions: Optional[str] = None
    next_appointment: Optional[date] = None
    audio_url: Optional[str] = None


# ─── GET /visit-summaries ─────────────────────────────────────────────────────

@router.get("/", summary="Get all visit summaries for the authenticated patient")
async def get_visit_summaries(
    limit: int = Query(default=20, ge=1, le=100),
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    result = (
        db.table("visit_summaries")
        .select("*, appointments(title, doctor_name, scheduled_at)")
        .eq("patient_id", current_user["patient_profile_id"])
        .order("recorded_at", desc=True)
        .limit(limit)
        .execute()
    )
    return result.data or []


# ─── GET /visit-summaries/{id} ────────────────────────────────────────────────

@router.get("/{summary_id}", summary="Get a specific visit summary")
async def get_visit_summary(
    summary_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    result = (
        db.table("visit_summaries")
        .select("*, appointments(title, doctor_name, scheduled_at)")
        .eq("id", summary_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Visit summary not found.")
    if str(result.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    return result.data


# ─── POST /visit-summaries ────────────────────────────────────────────────────

@router.post("/", status_code=status.HTTP_201_CREATED, summary="Create a new visit summary")
async def create_visit_summary(
    payload: VisitSummaryCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    insert_data = {
        "patient_id": current_user["patient_profile_id"],
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }
    if payload.appointment_id:
        insert_data["appointment_id"] = payload.appointment_id
    if payload.raw_transcript:
        insert_data["raw_transcript"] = payload.raw_transcript
    if payload.diagnosis:
        insert_data["diagnosis"] = payload.diagnosis
    if payload.medications_changed:
        insert_data["medications_changed"] = payload.medications_changed
    if payload.instructions:
        insert_data["instructions"] = payload.instructions
    if payload.next_appointment:
        insert_data["next_appointment"] = payload.next_appointment.isoformat()
    if payload.audio_url:
        insert_data["audio_url"] = payload.audio_url

    result = db.table("visit_summaries").insert(insert_data).execute()
    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create visit summary.",
        )
    return result.data[0]


# ─── PATCH /visit-summaries/{id} ─────────────────────────────────────────────

@router.patch("/{summary_id}", summary="Update a visit summary")
async def update_visit_summary(
    summary_id: str,
    payload: VisitSummaryUpdate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    existing = (
        db.table("visit_summaries")
        .select("*")
        .eq("id", summary_id)
        .single()
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Visit summary not found.")
    if str(existing.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    update_data = {}
    if payload.raw_transcript is not None:
        update_data["raw_transcript"] = payload.raw_transcript
    if payload.diagnosis is not None:
        update_data["diagnosis"] = payload.diagnosis
    if payload.medications_changed is not None:
        update_data["medications_changed"] = payload.medications_changed
    if payload.instructions is not None:
        update_data["instructions"] = payload.instructions
    if payload.next_appointment is not None:
        update_data["next_appointment"] = payload.next_appointment.isoformat()
    if payload.audio_url is not None:
        update_data["audio_url"] = payload.audio_url

    if not update_data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update.")

    result = db.table("visit_summaries").update(update_data).eq("id", summary_id).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update.")
    return result.data[0]