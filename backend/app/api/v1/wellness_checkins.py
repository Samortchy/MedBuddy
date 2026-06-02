from fastapi import APIRouter, Depends, HTTPException, status, Query
from supabase import Client
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timezone, date

from app.core.database import get_db
from app.core.dependencies import get_current_patient

router = APIRouter(prefix="/wellness-checkins", tags=["Wellness Check-ins"])


class WellnessCheckInCreate(BaseModel):
    mood_score: Optional[int] = Field(None, ge=1, le=5)
    energy_score: Optional[int] = Field(None, ge=1, le=5)
    pain_level: Optional[int] = Field(None, ge=1, le=5)
    sleep_quality: Optional[int] = Field(None, ge=1, le=5)
    meds_confirmed: Optional[bool] = None
    raw_summary: Optional[str] = None


# ─── GET /wellness-checkins ───────────────────────────────────────────────────

@router.get("/", summary="Get wellness check-ins for the authenticated patient")
async def get_wellness_checkins(
    limit: int = Query(default=30, ge=1, le=100),
    from_date: Optional[date] = Query(default=None, description="Filter from date (YYYY-MM-DD)"),
    to_date: Optional[date] = Query(default=None, description="Filter to date (YYYY-MM-DD)"),
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    """
    Returns wellness check-ins for the authenticated patient.
    Optionally filter by date range.
    """
    query = (
        db.table("wellness_checkins")
        .select("*")
        .eq("patient_id", current_user["patient_profile_id"])
        .order("completed_at", desc=True)
        .limit(limit)
    )

    if from_date:
        query = query.gte("completed_at", f"{from_date}T00:00:00+00:00")
    if to_date:
        query = query.lte("completed_at", f"{to_date}T23:59:59+00:00")

    result = query.execute()
    return result.data or []


# ─── GET /wellness-checkins/today ─────────────────────────────────────────────

@router.get("/today", summary="Get today's wellness check-in if it exists")
async def get_todays_checkin(
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    today = datetime.now(timezone.utc).date()
    result = (
        db.table("wellness_checkins")
        .select("*")
        .eq("patient_id", current_user["patient_profile_id"])
        .gte("completed_at", f"{today}T00:00:00+00:00")
        .lte("completed_at", f"{today}T23:59:59+00:00")
        .order("completed_at", desc=True)
        .limit(1)
        .execute()
    )
    data = result.data or []
    return data[0] if data else None


# ─── GET /wellness-checkins/{id} ──────────────────────────────────────────────

@router.get("/{checkin_id}", summary="Get a specific wellness check-in")
async def get_wellness_checkin(
    checkin_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    result = (
        db.table("wellness_checkins")
        .select("*")
        .eq("id", checkin_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wellness check-in not found.",
        )
    if str(result.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )
    return result.data


# ─── POST /wellness-checkins ──────────────────────────────────────────────────

@router.post("/", status_code=status.HTTP_201_CREATED, summary="Submit a wellness check-in")
async def create_wellness_checkin(
    payload: WellnessCheckInCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    insert_data: dict = {
        "patient_id": current_user["patient_profile_id"],
        "source": "patient",
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }
    for field in ("mood_score", "energy_score", "pain_level", "sleep_quality",
                  "meds_confirmed", "raw_summary"):
        val = getattr(payload, field)
        if val is not None:
            insert_data[field] = val

    result = db.table("wellness_checkins").insert(insert_data).execute()
    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create wellness check-in.",
        )
    return result.data[0]