from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime
from uuid import UUID


class PatientProfileUpdate(BaseModel):
    # profiles table fields
    full_name: Optional[str] = Field(None, min_length=1, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[date] = None
    avatar_url: Optional[str] = None
    # patient_profiles table fields
    weight_kg: Optional[float] = Field(None, gt=0, le=500)
    height_cm: Optional[float] = Field(None, gt=0, le=300)
    blood_type: Optional[str] = Field(None, max_length=10)
    allergies: Optional[str] = None


class PatientProfileResponse(BaseModel):
    id: UUID
    profile_id: UUID
    full_name: Optional[str] = None
    phone: Optional[str] = None
    date_of_birth: Optional[date] = None
    avatar_url: Optional[str] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    blood_type: Optional[str] = None
    allergies: Optional[str] = None
    created_at: datetime
    updated_at: datetime
