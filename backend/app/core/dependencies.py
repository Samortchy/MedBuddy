from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import Client
from app.core.database import get_db
from app.core.auth import verify_jwt

_security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_security),
    db: Client = Depends(get_db),
) -> dict:
    """
    Returns the authenticated user's IDs and role.

    Returns:
        {
            "profile_id": str,          # profiles.id (Supabase Auth UUID)
            "patient_profile_id": str,  # patient_profiles.id
            "role": str                 # "patient" or "caregiver"
        }
    """
    return await verify_jwt(credentials.credentials, db)


async def get_current_patient(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Extends get_current_user — raises 403 if the user is not a patient.
    Use this on all patient-only endpoints.
    """
    if current_user["role"] != "patient":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is only accessible to patients.",
        )
    return current_user


async def get_current_caregiver(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Extends get_current_user — raises 403 if the user is not a caregiver.
    Use this on all caregiver-only endpoints.
    """
    if current_user["role"] != "caregiver":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is only accessible to caregivers.",
        )
    return current_user