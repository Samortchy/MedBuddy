from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.dependencies import get_current_patient
from app.models.health_condition import (
    HealthConditionCreate,
    HealthConditionUpdate,
    HealthConditionResponse,
)

router = APIRouter(prefix="/health-conditions", tags=["Health Conditions"])


# ─── Helper: verify condition belongs to patient ──────────────────────────────

def verify_condition_ownership(
    condition: dict,
    patient_profile_id: str,
) -> None:
    if str(condition["patient_id"]) != str(patient_profile_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this health condition.",
        )


# ─── GET /health-conditions ───────────────────────────────────────────────────

@router.get(
    "/",
    summary="Get all health conditions for the authenticated patient",
)
async def get_health_conditions(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns all health conditions for the authenticated patient,
    sorted by creation date descending (most recent first).
    """
    result = (
        db.table("health_conditions")
        .select("*")
        .eq("patient_id", current_user["patient_profile_id"])
        .order("created_at", desc=True)
        .execute()
    )

    return result.data or []


# ─── POST /health-conditions ──────────────────────────────────────────────────

@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Add a new health condition",
)
async def create_health_condition(
    payload: HealthConditionCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Creates a new health condition for the authenticated patient.
    """
    insert_data = {
        "patient_id": current_user["patient_profile_id"],
        "name": payload.name,
    }

    if payload.diagnosed_at:
        insert_data["diagnosed_at"] = payload.diagnosed_at.isoformat()
    if payload.notes:
        insert_data["notes"] = payload.notes

    result = db.table("health_conditions").insert(insert_data).execute()

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create health condition.",
        )

    return result.data[0]


# ─── PATCH /health-conditions/{id} ───────────────────────────────────────────

@router.patch(
    "/{condition_id}",
    summary="Update a health condition",
)
async def update_health_condition(
    condition_id: str,
    payload: HealthConditionUpdate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Updates fields on an existing health condition.
    Only the owning patient can update their conditions.
    """
    existing = (
        db.table("health_conditions")
        .select("*")
        .eq("id", condition_id)
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Health condition not found.",
        )

    verify_condition_ownership(existing.data, current_user["patient_profile_id"])

    update_data = {}
    if payload.name is not None:
        update_data["name"] = payload.name
    if payload.diagnosed_at is not None:
        update_data["diagnosed_at"] = payload.diagnosed_at.isoformat()
    if payload.notes is not None:
        update_data["notes"] = payload.notes

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )

    result = (
        db.table("health_conditions")
        .update(update_data)
        .eq("id", condition_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update health condition.",
        )

    return result.data[0]


# ─── DELETE /health-conditions/{id} ──────────────────────────────────────────

@router.delete(
    "/{condition_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a health condition",
)
async def delete_health_condition(
    condition_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Hard deletes a health condition.
    Note: deleting a condition will also delete its RAG embedding (Phase 5).
    """
    existing = (
        db.table("health_conditions")
        .select("*")
        .eq("id", condition_id)
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Health condition not found.",
        )

    verify_condition_ownership(existing.data, current_user["patient_profile_id"])

    db.table("health_conditions").delete().eq("id", condition_id).execute()

    # TODO Phase 5: delete corresponding ai_embeddings row
    # db.table("ai_embeddings")
    #     .delete()
    #     .eq("source_type", "condition")
    #     .eq("source_id", condition_id)
    #     .execute()