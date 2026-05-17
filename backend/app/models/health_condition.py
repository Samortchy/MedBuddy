from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date
from uuid import UUID


class HealthConditionCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    diagnosed_at: Optional[date] = None
    notes: Optional[str] = None


class HealthConditionUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    diagnosed_at: Optional[date] = None
    notes: Optional[str] = None


class HealthConditionResponse(BaseModel):
    id: UUID
    patient_id: UUID
    name: str
    diagnosed_at: Optional[date]
    notes: Optional[str]
    created_at: datetime