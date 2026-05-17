from fastapi import Depends, HTTPException, status
from supabase import Client
from app.core.database import get_db

# ─────────────────────────────────────────────────────────────────────────────
# TEMPORARY PLACEHOLDER
# When Ahmed finishes app/core/auth.py, replace the body of get_current_user()
# with a call to his real JWT verification function.
# Nothing in the route files needs to change — only this file.
# ─────────────────────────────────────────────────────────────────────────────


async def get_current_user(db: Client = Depends(get_db)) -> dict:
    """
    Returns the authenticated user's IDs and role.

    Returns:
        {
            "profile_id": str,          # profiles.id (Supabase Auth UUID)
            "patient_profile_id": str,  # patient_profiles.id (used as patient_id in all tables)
            "role": str                 # "patient" or "caregiver"
        }

    ── SWAP INSTRUCTION ────────────────────────────────────────────────────────
    When Ahmed's auth.py is ready, replace the placeholder below with:

        from app.core.auth import verify_jwt
        from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

        security = HTTPBearer()

        async def get_current_user(
            credentials: HTTPAuthorizationCredentials = Depends(security),
            db: Client = Depends(get_db)
        ) -> dict:
            return await verify_jwt(credentials.credentials, db)
    ────────────────────────────────────────────────────────────────────────────
    """

    # ── PLACEHOLDER — hardcoded for local development only ──────────────────
    # Replace these UUIDs with real ones from your Supabase database for testing
    PLACEHOLDER_PROFILE_ID = "77eb9011-45e4-4b4c-b064-6d49956c86e5"
    PLACEHOLDER_PATIENT_PROFILE_ID = "7edb44fd-cc05-4880-a7a8-965fa8dc8435"

    return {
        "profile_id": PLACEHOLDER_PROFILE_ID,
        "patient_profile_id": PLACEHOLDER_PATIENT_PROFILE_ID,
        "role": "patient",
    }


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