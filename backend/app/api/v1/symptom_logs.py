from fastapi import APIRouter, Depends, HTTPException, status, Query
from supabase import Client
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.dependencies import get_current_patient

router = APIRouter(prefix="/symptom-logs", tags=["Symptom Logs"])


# ─── Models ───────────────────────────────────────────────────────────────────

class SymptomLogCreate(BaseModel):
    body: str
    input_type: Optional[str] = "text"
    session_id: Optional[str] = None


# ─── GET /symptom-logs ────────────────────────────────────────────────────────

@router.get("/", summary="Get all symptom logs for the authenticated patient")
async def get_symptom_logs(
    limit: int = Query(default=50, ge=1, le=100),
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    result = (
        db.table("symptom_logs")
        .select("*")
        .eq("patient_id", current_user["patient_profile_id"])
        .order("logged_at", desc=True)
        .limit(limit)
        .execute()
    )
    return result.data or []


# ─── POST /symptom-logs ───────────────────────────────────────────────────────

@router.post("/", status_code=status.HTTP_201_CREATED, summary="Log a new symptom")
async def create_symptom_log(
    payload: SymptomLogCreate,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    insert_data = {
        "patient_id": current_user["patient_profile_id"],
        "body": payload.body,
        "input_type": payload.input_type,
        "logged_at": datetime.now(timezone.utc).isoformat(),
    }
    if payload.session_id:
        insert_data["session_id"] = payload.session_id

    result = db.table("symptom_logs").insert(insert_data).execute()

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create symptom log.",
        )
    return result.data[0]


# ─── DELETE /symptom-logs/{id} ────────────────────────────────────────────────

@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a symptom log")
async def delete_symptom_log(
    log_id: str,
    current_user: dict = Depends(get_current_patient),
    db: Client = Depends(get_db),
):
    existing = (
        db.table("symptom_logs")
        .select("*")
        .eq("id", log_id)
        .single()
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Symptom log not found.")
    if str(existing.data["patient_id"]) != str(current_user["patient_profile_id"]):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    db.table("symptom_logs").delete().eq("id", log_id).execute()