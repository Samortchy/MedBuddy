from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from app.core.database import get_db
from app.core.dependencies import get_current_patient
from app.models.emergency_contact import (
    EmergencyContactCreate,
    EmergencyContactUpdate,
    EmergencyContactResponse,
)

router = APIRouter(prefix="/emergency-contacts", tags=["Emergency Contacts"])

# Maximum contacts allowed per patient per spec
MAX_CONTACTS = 5


# ─── Helper: verify contact belongs to patient ───────────────────────────────

def verify_contact_ownership(
    contact: dict,
    patient_profile_id: str,
) -> None:
    if str(contact["patient_id"]) != str(patient_profile_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this contact.",
        )


# ─── GET /emergency-contacts ──────────────────────────────────────────────────

@router.get(
    "/",
    summary="Get all emergency contacts sorted by priority",
)
async def get_emergency_contacts(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns all emergency contacts for the authenticated patient,
    sorted by priority ascending (1 = highest priority).
    """
    result = (
        db.table("emergency_contacts")
        .select("*")
        .eq("patient_id", current_user["patient_profile_id"])
        .order("priority", desc=False)
        .execute()
    )

    return result.data or []


# ─── POST /emergency-contacts ─────────────────────────────────────────────────

@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Add a new emergency contact (max 5 per patient)",
)
async def create_emergency_contact(
    payload: EmergencyContactCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Creates a new emergency contact for the authenticated patient.
    Enforces a maximum of 5 contacts per patient.
    """
    patient_id = current_user["patient_profile_id"]

    # Check if a contact with this priority already exists (will be updated, not inserted)
    priority_check = (
        db.table("emergency_contacts")
        .select("id")
        .eq("patient_id", patient_id)
        .eq("priority", payload.priority)
        .maybe_single()
        .execute()
    )
    is_update = priority_check.data is not None

    # Only enforce the count limit when creating a genuinely new contact
    if not is_update:
        count_result = (
            db.table("emergency_contacts")
            .select("id", count="exact")
            .eq("patient_id", patient_id)
            .execute()
        )
        if (count_result.count or 0) >= MAX_CONTACTS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Maximum of {MAX_CONTACTS} emergency contacts allowed per patient.",
            )

    upsert_data: dict = {
        "patient_id": patient_id,
        "name": payload.name,
        "phone": payload.phone,
        "priority": payload.priority,
    }
    if payload.relationship:
        upsert_data["relationship"] = payload.relationship

    result = (
        db.table("emergency_contacts")
        .upsert(upsert_data, on_conflict="patient_id,priority")
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save emergency contact.",
        )

    return result.data[0]


# ─── PATCH /emergency-contacts/{id} ──────────────────────────────────────────

@router.patch(
    "/{contact_id}",
    summary="Update an emergency contact",
)
async def update_emergency_contact(
    contact_id: str,
    payload: EmergencyContactUpdate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Updates fields on an existing emergency contact.
    Only the owning patient can update their contacts.
    """
    existing = (
        db.table("emergency_contacts")
        .select("*")
        .eq("id", contact_id)
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found.",
        )

    verify_contact_ownership(existing.data, current_user["patient_profile_id"])

    update_data = {}
    if payload.name is not None:
        update_data["name"] = payload.name
    if payload.relationship is not None:
        update_data["relationship"] = payload.relationship
    if payload.phone is not None:
        update_data["phone"] = payload.phone
    if payload.priority is not None:
        update_data["priority"] = payload.priority

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )

    result = (
        db.table("emergency_contacts")
        .update(update_data)
        .eq("id", contact_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update emergency contact.",
        )

    return result.data[0]


# ─── DELETE /emergency-contacts/{id} ─────────────────────────────────────────

@router.delete(
    "/{contact_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an emergency contact",
)
async def delete_emergency_contact(
    contact_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Hard deletes an emergency contact.
    Emergency contacts have no soft delete — they are fully removed.
    """
    existing = (
        db.table("emergency_contacts")
        .select("*")
        .eq("id", contact_id)
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found.",
        )

    verify_contact_ownership(existing.data, current_user["patient_profile_id"])

    db.table("emergency_contacts").delete().eq("id", contact_id).execute()