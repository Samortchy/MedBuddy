from fastapi import APIRouter, Depends, HTTPException, status, Query
from supabase import Client
from typing import Optional
from datetime import datetime, timezone, timedelta

from app.core.database import get_db
from app.core.dependencies import get_current_patient
from app.models.appointment import (
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentResponse,
)

router = APIRouter(prefix="/appointments", tags=["Appointments"])


# ─── Helper: verify appointment belongs to patient ────────────────────────────

def verify_appointment_ownership(
    appointment: dict,
    patient_profile_id: str,
) -> None:
    if str(appointment["patient_id"]) != str(patient_profile_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this appointment.",
        )


# ─── GET /appointments ────────────────────────────────────────────────────────

@router.get(
    "/",
    summary="Get upcoming appointments (next 30 days by default)",
)
async def get_appointments(
    days_ahead: int = Query(default=30, ge=1, le=365, description="Number of days ahead to fetch"),
    include_past: bool = Query(default=False, description="Include past appointments"),
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns appointments for the authenticated patient.
    By default returns upcoming appointments for the next 30 days.
    Set include_past=true to also see past appointments.
    """
    patient_id = current_user["patient_profile_id"]
    now = datetime.now(timezone.utc)

    query = (
        db.table("appointments")
        .select("*")
        .eq("patient_id", patient_id)
        .is_("deleted_at", "null")
        .order("scheduled_at", desc=False)
    )

    if not include_past:
        future_limit = now + timedelta(days=days_ahead)
        query = query.gte("scheduled_at", now.isoformat())
        query = query.lte("scheduled_at", future_limit.isoformat())

    result = query.execute()
    return result.data or []


# ─── POST /appointments ───────────────────────────────────────────────────────

@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Create a new appointment",
)
async def create_appointment(
    payload: AppointmentCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Creates a new appointment for the authenticated patient.
    """
    patient_id = current_user["patient_profile_id"]

    insert_data = {
        "patient_id": patient_id,
        "title": payload.title,
        "scheduled_at": payload.scheduled_at.isoformat(),
    }

    if payload.doctor_name:
        insert_data["doctor_name"] = payload.doctor_name
    if payload.location:
        insert_data["location"] = payload.location
    if payload.notes:
        insert_data["notes"] = payload.notes

    result = db.table("appointments").insert(insert_data).execute()

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create appointment.",
        )

    return result.data[0]


# ─── PATCH /appointments/{id} ─────────────────────────────────────────────────

@router.patch(
    "/{appointment_id}",
    summary="Update an appointment",
)
async def update_appointment(
    appointment_id: str,
    payload: AppointmentUpdate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Updates fields on an existing appointment.
    Only the owning patient can update their appointments.
    """
    # Fetch and verify ownership
    existing = (
        db.table("appointments")
        .select("*")
        .eq("id", appointment_id)
        .is_("deleted_at", "null")
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found.",
        )

    verify_appointment_ownership(existing.data, current_user["patient_profile_id"])

    # Build update payload — only include fields that were provided
    update_data = {}
    if payload.title is not None:
        update_data["title"] = payload.title
    if payload.doctor_name is not None:
        update_data["doctor_name"] = payload.doctor_name
    if payload.location is not None:
        update_data["location"] = payload.location
    if payload.scheduled_at is not None:
        update_data["scheduled_at"] = payload.scheduled_at.isoformat()
        # Reset reminder flags if time changed
        update_data["reminder_24h_sent"] = False
        update_data["reminder_1h_sent"] = False
    if payload.notes is not None:
        update_data["notes"] = payload.notes

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )

    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    result = (
        db.table("appointments")
        .update(update_data)
        .eq("id", appointment_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update appointment.",
        )

    return result.data[0]


# ─── DELETE /appointments/{id} ────────────────────────────────────────────────

@router.delete(
    "/{appointment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft delete an appointment",
)
async def delete_appointment(
    appointment_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Soft deletes an appointment by setting deleted_at to now.
    The record remains in the database but is excluded from all queries.
    """
    existing = (
        db.table("appointments")
        .select("*")
        .eq("id", appointment_id)
        .is_("deleted_at", "null")
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found.",
        )

    verify_appointment_ownership(existing.data, current_user["patient_profile_id"])

    db.table("appointments").update({
        "deleted_at": datetime.now(timezone.utc).isoformat()
    }).eq("id", appointment_id).execute()