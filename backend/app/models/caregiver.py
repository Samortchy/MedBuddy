from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class CaregiverInviteResponse(BaseModel):
    invite_id: UUID
    code: str
    expires_at: datetime
    patient_id: UUID


class CaregiverAcceptRequest(BaseModel):
    code: str = Field(..., min_length=6, max_length=6)


class CaregiverAcceptResponse(BaseModel):
    caregiver_patient_id: UUID
    caregiver_id: UUID
    patient_id: UUID
    created_at: datetime


class PatientSummary(BaseModel):
    patient_profile_id: UUID
    full_name: Optional[str] = None
    phone: Optional[str] = None
    date_of_birth: Optional[str] = None
    linked_at: datetime


class CaregiverPatientsResponse(BaseModel):
    patients: List[PatientSummary]
    total: int
