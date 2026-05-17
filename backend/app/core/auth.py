from fastapi import HTTPException, status
from supabase import Client
from jose import jwt, JWTError, ExpiredSignatureError

from app.core.config import settings


async def verify_jwt(token: str, db: Client) -> dict:
    """
    Decodes and verifies a Supabase JWT.
    Returns {"profile_id": str, "patient_profile_id": str, "role": str}
    """
    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    profile_id: str | None = payload.get("sub")
    if not profile_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject claim.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Role is stored in user_metadata or app_metadata set at sign-up
    user_metadata = payload.get("user_metadata") or {}
    app_metadata = payload.get("app_metadata") or {}
    role: str = (
        user_metadata.get("role")
        or app_metadata.get("role")
        or "patient"
    )

    result = (
        db.table("patient_profiles")
        .select("id")
        .eq("profile_id", profile_id)
        .maybe_single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No profile found for this user.",
        )

    return {
        "profile_id": profile_id,
        "patient_profile_id": result.data["id"],
        "role": role,
    }
