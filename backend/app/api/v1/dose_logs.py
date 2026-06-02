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
    summary="Get today's scheduled doses with their current status",
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
    Returns ALL scheduled doses for the given date (from medication_doses),
    each with its current status overlaid from dose_logs.
    Doses with no log entry are returned with status="pending".
    This is what the Flutter medication schedule screen needs.
    """
    from datetime import datetime, timezone

    target_date = date or datetime.now(timezone.utc).date()
    day_start = f"{target_date}T00:00:00+00:00"
    day_end   = f"{target_date}T23:59:59+00:00"
    patient_id = current_user["patient_profile_id"]

    # 1. Get all scheduled doses for this patient on the target date
    doses_result = (
        db.table("medication_doses")
        .select(
            "id, scheduled_at, medication_id, "
            "medications(id, name, dose_amount, dose_unit, patient_id, deleted_at)"
        )
        .gte("scheduled_at", day_start)
        .lte("scheduled_at", day_end)
        .execute()
    )

    # Exclude doses whose medication has been soft-deleted so removed
    # medications stop appearing on the schedule.
    doses = [
        d for d in (doses_result.data or [])
        if str((d.get("medications") or {}).get("patient_id", "")) == str(patient_id)
        and (d.get("medications") or {}).get("deleted_at") is None
    ]

    if not doses:
        return []

    # 2. Get any logged actions for these doses
    dose_ids = [d["id"] for d in doses]
    logs_result = (
        db.table("dose_logs")
        .select("id, dose_id, status, actioned_at, noted_by, notes")
        .in_("dose_id", dose_ids)
        .execute()
    )

    # Map dose_id → most recent log entry
    log_map: dict = {}
    for log in (logs_result.data or []):
        log_map[log["dose_id"]] = log

    # 3. Return each scheduled dose with its status (pending if no log yet)
    return [
        {
            "id":          log_map[d["id"]]["id"] if d["id"] in log_map else d["id"],
            "dose_id":     d["id"],
            "status":      log_map[d["id"]]["status"] if d["id"] in log_map else "pending",
            "actioned_at": log_map[d["id"]].get("actioned_at") if d["id"] in log_map else None,
            "noted_by":    log_map[d["id"]].get("noted_by") if d["id"] in log_map else None,
            "notes":       log_map[d["id"]].get("notes") if d["id"] in log_map else None,
            "medication_doses": {
                "scheduled_at":  d["scheduled_at"],
                "medication_id": d["medication_id"],
                "medications":   d.get("medications") or {},
            },
        }
        for d in doses
    ]