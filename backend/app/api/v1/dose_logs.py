from fastapi import APIRouter, Depends, HTTPException, status, Query
from supabase import Client
from pydantic import BaseModel
from typing import Optional
from datetime import date
from enum import Enum

from app.core.database import get_db
from app.core.dependencies import get_current_patient

router = APIRouter(prefix="/dose-logs", tags=["Dose Logs"])


# ─── Enums (match Supabase exactly) ──────────────────────────────────────────

class DoseStatus(str, Enum):
    taken   = "taken"
    missed  = "missed"
    skipped = "skipped"
    snoozed = "snoozed"


# ─── Request / Response schemas ───────────────────────────────────────────────

class DoseLogCreate(BaseModel):
    dose_id: str
    status: DoseStatus
    notes: Optional[str] = None


class DoseLogResponse(BaseModel):
    id: str
    dose_id: str
    status: str
    actioned_at: str
    noted_by: Optional[str]
    notes: Optional[str]


# ─── Helper: verify dose belongs to patient ───────────────────────────────────

async def verify_dose_ownership(
    dose_id: str,
    patient_profile_id: str,
    db: Client,
) -> dict:
    """
    Fetches the dose and confirms it belongs to the authenticated patient.
    Raises 404 if not found, 403 if it belongs to someone else.
    """
    result = (
        db.table("medication_doses")
        .select("id, medication_id, medications(patient_id)")
        .eq("id", dose_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dose not found.",
        )

    dose_patient_id = result.data["medications"]["patient_id"]

    if str(dose_patient_id) != str(patient_profile_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this dose.",
        )

    return result.data


# ─── POST /dose-logs ──────────────────────────────────────────────────────────

@router.post(
    "/",
    response_model=DoseLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log a dose action (taken / missed / skipped / snoozed)",
)
async def create_dose_log(
    payload: DoseLogCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Logs a dose action for the authenticated patient.
    Validates that the dose belongs to the patient before inserting.
    """
    # Verify ownership before logging
    await verify_dose_ownership(
        dose_id=payload.dose_id,
        patient_profile_id=current_user["patient_profile_id"],
        db=db,
    )

    insert_data = {
        "dose_id": payload.dose_id,
        "status": payload.status.value,
        "noted_by": current_user["profile_id"],
    }
    if payload.notes:
        insert_data["notes"] = payload.notes

    result = db.table("dose_logs").insert(insert_data).execute()

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create dose log.",
        )

    return result.data[0]


# ─── GET /dose-logs ───────────────────────────────────────────────────────────

@router.get(
    "/",
    summary="Get dose logs for a specific date (defaults to today)",
)
async def get_dose_logs(
    date: Optional[date] = Query(
        default=None,
        description="Date in YYYY-MM-DD format. Defaults to today.",
    ),
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns all dose logs for the authenticated patient on a given date.
    Used by the Flutter medication screen to show today's dose status.

    Query params:
        date: YYYY-MM-DD (optional, defaults to today)
    """
    from datetime import datetime, timezone

    target_date = date or datetime.now(timezone.utc).date()

    # Build date range for the full day
    day_start = f"{target_date}T00:00:00+00:00"
    day_end   = f"{target_date}T23:59:59+00:00"

    # Get dose logs for the patient's doses on this date
    # Join: dose_logs → medication_doses → medications (scoped by patient_id)
    result = (
        db.table("dose_logs")
        .select(
            "id, dose_id, status, actioned_at, noted_by, notes, "
            "medication_doses(scheduled_at, medication_id, "
            "medications(name, dose_amount, dose_unit, patient_id))"
        )
        .gte("actioned_at", day_start)
        .lte("actioned_at", day_end)
        .execute()
    )

    # Filter client-side to only this patient's logs
    # (service role bypasses RLS so we must manually scope)
    patient_id = current_user["patient_profile_id"]
    filtered = [
        log for log in (result.data or [])
        if log.get("medication_doses", {})
           .get("medications", {})
           .get("patient_id") == patient_id
    ]

    return {"date": str(target_date), "dose_logs": filtered}