from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.dependencies import get_current_patient
from app.models.medication import MedicationCreate, MedicationUpdate
from app.services.medication_service import generate_doses_for_patient

router = APIRouter(prefix="/medications", tags=["Medications"])


def _verify_ownership(medication: dict, patient_profile_id: str) -> None:
    if str(medication["patient_id"]) != str(patient_profile_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this medication.",
        )


# ─── GET /medications ─────────────────────────────────────────────────────────

@router.get("/", summary="List all active medications for the authenticated patient")
async def get_medications(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    patient_id = current_user["patient_profile_id"]

    result = (
        db.table("medications")
        .select("*, medication_schedules(*)")
        .eq("patient_id", patient_id)
        .is_("deleted_at", "null")
        .order("created_at", desc=False)
        .execute()
    )

    return result.data or []


# ─── POST /medications ────────────────────────────────────────────────────────

@router.post("/", status_code=status.HTTP_201_CREATED, summary="Add a new medication")
async def create_medication(
    payload: MedicationCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    patient_id = current_user["patient_profile_id"]

    insert_data: dict = {
        "patient_id": patient_id,
        "name": payload.name,
        "dose_amount": payload.dose_amount,
        "dose_unit": payload.dose_unit.value,
        "start_date": payload.start_date.isoformat(),
    }
    if payload.form:
        insert_data["form"] = payload.form.value
    if payload.instructions:
        insert_data["instructions"] = payload.instructions
    if payload.end_date:
        insert_data["end_date"] = payload.end_date.isoformat()

    med_result = db.table("medications").insert(insert_data).execute()
    if not med_result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create medication.",
        )

    medication_id = med_result.data[0]["id"]

    schedule_rows = [
        {"medication_id": medication_id, "time_of_day": s.time_of_day}
        for s in payload.schedules
    ]
    db.table("medication_schedules").insert(schedule_rows).execute()

    await generate_doses_for_patient(patient_id, db, days_ahead=7)

    full = (
        db.table("medications")
        .select("*, medication_schedules(*)")
        .eq("id", medication_id)
        .single()
        .execute()
    )
    return full.data


# ─── PATCH /medications/{id} ──────────────────────────────────────────────────

@router.patch("/{medication_id}", summary="Update a medication")
async def update_medication(
    medication_id: str,
    payload: MedicationUpdate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    existing = (
        db.table("medications")
        .select("*")
        .eq("id", medication_id)
        .is_("deleted_at", "null")
        .single()
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found.")

    _verify_ownership(existing.data, current_user["patient_profile_id"])

    update_data: dict = {}
    if payload.name is not None:
        update_data["name"] = payload.name
    if payload.dose_amount is not None:
        update_data["dose_amount"] = payload.dose_amount
    if payload.dose_unit is not None:
        update_data["dose_unit"] = payload.dose_unit.value
    if payload.form is not None:
        update_data["form"] = payload.form.value
    if payload.instructions is not None:
        update_data["instructions"] = payload.instructions
    if payload.start_date is not None:
        update_data["start_date"] = payload.start_date.isoformat()
    if payload.end_date is not None:
        update_data["end_date"] = payload.end_date.isoformat()

    if not update_data and payload.schedules is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )

    if update_data:
        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()
        db.table("medications").update(update_data).eq("id", medication_id).execute()

    if payload.schedules is not None:
        # Replace schedule and delete future pending doses so they regenerate cleanly
        db.table("medication_schedules").delete().eq("medication_id", medication_id).execute()
        db.table("medication_doses").delete().eq("medication_id", medication_id).eq("status", "pending").execute()

        if payload.schedules:
            new_schedules = [
                {"medication_id": medication_id, "time_of_day": s.time_of_day}
                for s in payload.schedules
            ]
            db.table("medication_schedules").insert(new_schedules).execute()

        await generate_doses_for_patient(current_user["patient_profile_id"], db, days_ahead=7)

    full = (
        db.table("medications")
        .select("*, medication_schedules(*)")
        .eq("id", medication_id)
        .single()
        .execute()
    )
    return full.data


# ─── DELETE /medications/{id} ─────────────────────────────────────────────────

@router.delete(
    "/{medication_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft delete a medication",
)
async def delete_medication(
    medication_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    existing = (
        db.table("medications")
        .select("*")
        .eq("id", medication_id)
        .is_("deleted_at", "null")
        .single()
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found.")

    _verify_ownership(existing.data, current_user["patient_profile_id"])

    db.table("medications").update({
        "deleted_at": datetime.now(timezone.utc).isoformat()
    }).eq("id", medication_id).execute()
