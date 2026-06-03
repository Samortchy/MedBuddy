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
# Digits only — the caregiver "Enter Invite Code" screen uses a numeric keypad,
# and all UI copy says "6-digit code".
_CODE_CHARS = string.digits


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

    # Table: invite_codes (not caregiver_invites)
    result = db.table("invite_codes").insert({
        "patient_id": patient_id,
        "code": code,
        "expires_at": expires_at.isoformat(),
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

    # Table: invite_codes — check used_at is null (not used=False)
    invite_result = (
        db.table("invite_codes")
        .select("*")
        .eq("code", payload.code.upper())
        .is_("used_at", "null")
        .single()
        .execute()
    )

    if not invite_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invite code not found or already used.",
        )

    invite = invite_result.data

    # Normalise the ISO string from Supabase (may end with 'Z' or '+00:00')
    expires_at_str = invite["expires_at"]
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

    # Ensure the caregiver has a profiles row (FK target for the link).
    # Caregiver accounts don't get a profiles row at signup, so create one here.
    existing_profile = (
        db.table("profiles").select("id").eq("id", caregiver_id).execute()
    )
    if not existing_profile.data:
        db.table("profiles").insert({
            "id": caregiver_id,
            "role": "caregiver",
            "full_name": current_user.get("full_name") or "Caregiver",
        }).execute()

    # Table: caregiver_patient_links (not caregiver_patients)
    existing = (
        db.table("caregiver_patient_links")
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

    # Table: caregiver_patient_links (not caregiver_patients)
    link_result = db.table("caregiver_patient_links").insert({
        "caregiver_id": caregiver_id,
        "patient_id": invite["patient_id"],
        "status": "active",
        "linked_at": now.isoformat(),
    }).execute()

    if not link_result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to link caregiver to patient.",
        )

    # Mark invite as used — set used_at and used_by (not used=True)
    db.table("invite_codes").update({
        "used_at": now.isoformat(),
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

    # Table: caregiver_patient_links (not caregiver_patients)
    result = (
        db.table("caregiver_patient_links")
        .select("id, linked_at, patient_id, patient_profiles(id, profiles(full_name, phone, date_of_birth))")
        .eq("caregiver_id", caregiver_id)
        .eq("status", "active")
        .order("linked_at", desc=True)
        .execute()
    )

    patients = []
    for row in (result.data or []):
        patient_profile = row.get("patient_profiles") or {}
        profile = patient_profile.get("profiles") or {}
        patient_id = row["patient_id"]

        # Most recent completed wellness check-in (for the status line).
        last = (
            db.table("wellness_checkins")
            .select("completed_at")
            .eq("patient_id", patient_id)
            .not_.is_("completed_at", "null")
            .order("completed_at", desc=True)
            .limit(1)
            .execute()
        )
        last_checkin_at = last.data[0]["completed_at"] if last.data else None

        patients.append({
            "patient_profile_id": patient_id,
            "full_name": profile.get("full_name"),
            "phone": profile.get("phone"),
            "date_of_birth": profile.get("date_of_birth"),
            "linked_at": row["linked_at"],
            "last_checkin_at": last_checkin_at,
        })

    return {
        "patients": patients,
        "total": len(patients),
    }


# ─── Caregiver → linked-patient detail views ──────────────────────────────────

def _verify_linked(db: Client, caregiver_id: str, patient_id: str) -> None:
    """Raise 403 unless an active link exists between this caregiver and patient."""
    link = (
        db.table("caregiver_patient_links")
        .select("id")
        .eq("caregiver_id", caregiver_id)
        .eq("patient_id", patient_id)
        .eq("status", "active")
        .execute()
    )
    if not link.data:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not linked to this patient.",
        )


@router.get(
    "/patients/{patient_id}/profile",
    summary="Get a linked patient's full profile (caregiver only)",
)
async def get_patient_profile_for_caregiver(
    patient_id: str,
    current_user: dict = Depends(get_current_caregiver),
    db: Client = Depends(get_db),
):
    _verify_linked(db, current_user["profile_id"], patient_id)
    result = (
        db.table("patient_profiles")
        .select("*, profiles(*)")
        .eq("id", patient_id)
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


@router.get(
    "/patients/{patient_id}/medications",
    summary="Get a linked patient's active medications (caregiver only)",
)
async def get_patient_medications_for_caregiver(
    patient_id: str,
    current_user: dict = Depends(get_current_caregiver),
    db: Client = Depends(get_db),
):
    _verify_linked(db, current_user["profile_id"], patient_id)
    result = (
        db.table("medications")
        .select("*, medication_schedules(*)")
        .eq("patient_id", patient_id)
        .is_("deleted_at", "null")
        .order("created_at", desc=False)
        .execute()
    )
    return result.data or []


@router.get(
    "/patients/{patient_id}/wellness-checkins",
    summary="Get a linked patient's recent wellness check-ins (caregiver only)",
)
async def get_patient_wellness_for_caregiver(
    patient_id: str,
    current_user: dict = Depends(get_current_caregiver),
    db: Client = Depends(get_db),
):
    _verify_linked(db, current_user["profile_id"], patient_id)
    result = (
        db.table("wellness_checkins")
        .select("*")
        .eq("patient_id", patient_id)
        .order("completed_at", desc=True)
        .limit(30)
        .execute()
    )
    return result.data or []


@router.get(
    "/patients/{patient_id}/emergency-events",
    summary="Get a linked patient's emergency events (caregiver only)",
)
async def get_patient_emergencies_for_caregiver(
    patient_id: str,
    current_user: dict = Depends(get_current_caregiver),
    db: Client = Depends(get_db),
):
    _verify_linked(db, current_user["profile_id"], patient_id)
    result = (
        db.table("emergency_events")
        .select("*, emergency_escalation_steps(*)")
        .eq("patient_id", patient_id)
        .order("triggered_at", desc=True)
        .limit(50)
        .execute()
    )
    return result.data or []


# ─── GET /caregiver/my-caregivers ─────────────────────────────────────────────

@router.get(
    "/my-caregivers",
    summary="Get all caregivers linked to the authenticated patient",
)
async def get_my_caregivers(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns the list of caregivers linked to the authenticated patient,
    including each caregiver's name and phone. Patient only.
    """
    patient_id = current_user["patient_profile_id"]

    result = (
        db.table("caregiver_patient_links")
        .select(
            "id, status, linked_at, caregiver_id, "
            "profiles!caregiver_patient_links_caregiver_id_fkey(full_name, phone)"
        )
        .eq("patient_id", patient_id)
        .eq("status", "active")
        .order("linked_at", desc=True)
        .execute()
    )

    caregivers = []
    for row in (result.data or []):
        profile = row.get("profiles") or {}
        caregivers.append({
            "link_id": row["id"],
            "caregiver_id": row["caregiver_id"],
            "full_name": profile.get("full_name"),
            "phone": profile.get("phone"),
            "status": row.get("status"),
            "linked_at": row.get("linked_at"),
        })

    return {
        "caregivers": caregivers,
        "total": len(caregivers),
    }


# ─── DELETE /caregiver/links/{link_id} ────────────────────────────────────────

@router.delete(
    "/links/{link_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revoke a caregiver link (patient only)",
)
async def revoke_caregiver_link(
    link_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Removes a caregiver's access to the authenticated patient.
    Only the owning patient may revoke their own caregiver links.
    """
    existing = (
        db.table("caregiver_patient_links")
        .select("id, patient_id")
        .eq("id", link_id)
        .single()
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caregiver link not found.",
        )

    if str(existing.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this caregiver link.",
        )

    db.table("caregiver_patient_links").delete().eq("id", link_id).execute()