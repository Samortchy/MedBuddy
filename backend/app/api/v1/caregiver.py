import secrets
import string
from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client
from datetime import datetime, timezone, timedelta

from app.core.database import get_db
from app.core.dependencies import get_current_patient, get_current_user, get_current_caregiver
from app.models.caregiver import CaregiverAcceptRequest

router = APIRouter(prefix="/caregiver", tags=["Caregiver"])

_INVITE_EXPIRY_HOURS = 24
_CODE_LENGTH = 6
_CODE_CHARS = string.ascii_uppercase + string.digits


def _generate_invite_code() -> str:
    return "".join(secrets.choice(_CODE_CHARS) for _ in range(_CODE_LENGTH))


# ─── POST /caregiver/invite ───────────────────────────────────────────────────

@router.post(
    "/invite",
    status_code=status.HTTP_201_CREATED,
    summary="Generate a caregiver invite code (patient only)",
)
async def create_caregiver_invite(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Generates a 6-character alphanumeric invite code for a caregiver to accept.
    The code expires after 24 hours. Only patients can create invites.
    """
    patient_id = current_user["patient_profile_id"]
    expires_at = datetime.now(timezone.utc) + timedelta(hours=_INVITE_EXPIRY_HOURS)
    code = _generate_invite_code()

    result = db.table("caregiver_invites").insert({
        "patient_id": patient_id,
        "code": code,
        "expires_at": expires_at.isoformat(),
        "used": False,
    }).execute()

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create invite.",
        )

    invite = result.data[0]
    return {
        "invite_id": invite["id"],
        "code": invite["code"],
        "expires_at": invite["expires_at"],
        "patient_id": invite["patient_id"],
    }


# ─── POST /caregiver/accept ───────────────────────────────────────────────────

@router.post(
    "/accept",
    summary="Accept a caregiver invite using a 6-char code",
)
async def accept_caregiver_invite(
    payload: CaregiverAcceptRequest,
    current_user: dict = Depends(get_current_user),
    db: Client = Depends(get_db),
):
    """
    Links the authenticated user to a patient as their caregiver.
    The invite code must exist, not be expired, and not already be used.
    """
    now = datetime.now(timezone.utc)

    invite_result = (
        db.table("caregiver_invites")
        .select("*")
        .eq("code", payload.code.upper())
        .eq("used", False)
        .single()
        .execute()
    )

    if not invite_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invite code not found or already used.",
        )

    invite = invite_result.data
    expires_at_str = invite["expires_at"]
    # Normalise the ISO string from Supabase (may end with 'Z' or '+00:00')
    if expires_at_str.endswith("Z"):
        expires_at_str = expires_at_str[:-1] + "+00:00"
    expires_at = datetime.fromisoformat(expires_at_str)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if expires_at < now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invite code has expired.",
        )

    caregiver_id = current_user["profile_id"]

    existing = (
        db.table("caregiver_patients")
        .select("id")
        .eq("caregiver_id", caregiver_id)
        .eq("patient_id", invite["patient_id"])
        .execute()
    )

    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You are already linked to this patient.",
        )

    link_result = db.table("caregiver_patients").insert({
        "caregiver_id": caregiver_id,
        "patient_id": invite["patient_id"],
    }).execute()

    if not link_result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to link caregiver to patient.",
        )

    db.table("caregiver_invites").update({
        "used": True,
        "used_by": caregiver_id,
    }).eq("id", invite["id"]).execute()

    link = link_result.data[0]
    return {
        "caregiver_patient_id": link["id"],
        "caregiver_id": link["caregiver_id"],
        "patient_id": link["patient_id"],
        "created_at": link["created_at"],
    }


# ─── GET /caregiver/patients ──────────────────────────────────────────────────

@router.get(
    "/patients",
    summary="Get all patients linked to the authenticated caregiver",
)
async def get_caregiver_patients(
    current_user: dict = Depends(get_current_caregiver),
    db: Client = Depends(get_db),
):
    """
    Returns the list of patients assigned to the authenticated caregiver,
    including each patient's profile information.
    """
    caregiver_id = current_user["profile_id"]

    result = (
        db.table("caregiver_patients")
        .select("id, created_at, patient_id, patient_profiles(id, profiles(full_name, phone, date_of_birth))")
        .eq("caregiver_id", caregiver_id)
        .order("created_at", desc=True)
        .execute()
    )

    patients = []
    for row in (result.data or []):
        patient_profile = row.get("patient_profiles") or {}
        profile = patient_profile.get("profiles") or {}
        patients.append({
            "patient_profile_id": row["patient_id"],
            "full_name": profile.get("full_name"),
            "phone": profile.get("phone"),
            "date_of_birth": profile.get("date_of_birth"),
            "linked_at": row["created_at"],
        })

    return {
        "patients": patients,
        "total": len(patients),
    }
