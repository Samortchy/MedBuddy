from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


class AppointmentCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    doctor_name: Optional[str] = None
    location: Optional[str] = None
    scheduled_at: datetime
    notes: Optional[str] = None


class AppointmentUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    doctor_name: Optional[str] = None
    location: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    notes: Optional[str] = None


class AppointmentResponse(BaseModel):
    id: UUID
    patient_id: UUID
    title: str
    doctor_name: Optional[str]
    location: Optional[str]
    scheduled_at: datetime
    notes: Optional[str]
    reminder_24h_sent: bool
    reminder_1h_sent: bool
    created_at: datetime
    updated_at: datetime