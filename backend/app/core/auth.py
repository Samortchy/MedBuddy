from fastapi import HTTPException, status
from supabase import Client
from jose import jwt, JWTError, ExpiredSignatureError
import httpx
import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


async def _fetch_jwks() -> dict:
    url = f"{settings.supabase_url}/auth/v1/.well-known/jwks.json"
    async with httpx.AsyncClient() as client:
        r = await client.get(url)
        r.raise_for_status()
        return r.json()


async def verify_jwt(token: str, db: Client) -> dict:
    try:
        jwks = await _fetch_jwks()

        unverified_header = jwt.get_unverified_header(token)

        key = None
        for k in jwks.get("keys", []):
            if k.get("kid") == unverified_header.get("kid"):
                key = k
                break

        if key is None:
            key = settings.supabase_jwt_secret
            algorithms = ["HS256"]
        else:
            algorithms = ["ES256"]

        payload = jwt.decode(
            token,
            key,
            algorithms=algorithms,
            options={"verify_aud": False},
        )

    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except JWTError as e:
        logger.error(f"JWTError: {e}")
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

    user_metadata = payload.get("user_metadata") or {}
    app_metadata = payload.get("app_metadata") or {}
    role: str = (
        user_metadata.get("role")
        or app_metadata.get("role")
        or "patient"
    )

    logger.info(f"JWT verified | sub={profile_id} role={role}")

    # Caregivers have no patient_profile row — return early
    if role == "caregiver":
        return {
            "profile_id": profile_id,
            "patient_profile_id": None,
            "role": "caregiver",
        }

    result = (
        db.table("patient_profiles")
        .select("id")
        .eq("profile_id", profile_id)
        .maybe_single()
        .execute()
    )

    if not result.data:
        logger.warning(f"No patient_profile for sub={profile_id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No profile found for this user.",
        )

    logger.info(f"Patient profile found | patient_profile_id={result.data['id']}")
    return {
        "profile_id": profile_id,
        "patient_profile_id": result.data["id"],
        "role": role,
    }