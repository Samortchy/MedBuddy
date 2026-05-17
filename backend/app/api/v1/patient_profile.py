from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.dependencies import get_current_patient
from app.models.patient import PatientProfileUpdate

router = APIRouter(prefix="/patient", tags=["Patient Profile"])


# ─── GET /patient/profile ─────────────────────────────────────────────────────

@router.get(
    "/profile",
    summary="Get the authenticated patient's profile",
)
async def get_patient_profile(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns the patient's full profile by joining patient_profiles and profiles tables.
    """
    patient_profile_id = current_user["patient_profile_id"]

    result = (
        db.table("patient_profiles")
        .select("*, profiles(*)")
        .eq("id", patient_profile_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient profile not found.",
        )

    data = result.data.copy()
    profile = data.pop("profiles", {}) or {}
    return {**profile, **data}


# ─── PATCH /patient/profile ───────────────────────────────────────────────────

@router.patch(
    "/profile",
    summary="Update the authenticated patient's profile",
)
async def update_patient_profile(
    payload: PatientProfileUpdate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Updates fields in patient_profiles and/or profiles tables.
    Only non-null fields are updated. At least one field must be provided.
    """
    patient_profile_id = current_user["patient_profile_id"]
    profile_id = current_user["profile_id"]
    now = datetime.now(timezone.utc).isoformat()

    # Fields that live in the profiles table
    profile_fields = {}
    if payload.full_name is not None:
        profile_fields["full_name"] = payload.full_name
    if payload.phone is not None:
        profile_fields["phone"] = payload.phone
    if payload.date_of_birth is not None:
        profile_fields["date_of_birth"] = payload.date_of_birth.isoformat()
    if payload.avatar_url is not None:
        profile_fields["avatar_url"] = payload.avatar_url

    # Fields that live in the patient_profiles table
    patient_fields = {}
    if payload.weight_kg is not None:
        patient_fields["weight_kg"] = payload.weight_kg
    if payload.height_cm is not None:
        patient_fields["height_cm"] = payload.height_cm
    if payload.blood_type is not None:
        patient_fields["blood_type"] = payload.blood_type
    if payload.allergies is not None:
        patient_fields["allergies"] = payload.allergies

    if not profile_fields and not patient_fields:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )

    if profile_fields:
        profile_fields["updated_at"] = now
        db.table("profiles").update(profile_fields).eq("id", profile_id).execute()

    if patient_fields:
        patient_fields["updated_at"] = now
        db.table("patient_profiles").update(patient_fields).eq("id", patient_profile_id).execute()

    result = (
        db.table("patient_profiles")
        .select("*, profiles(*)")
        .eq("id", patient_profile_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve updated profile.",
        )

    data = result.data.copy()
    profile = data.pop("profiles", {}) or {}
    return {**profile, **data}
