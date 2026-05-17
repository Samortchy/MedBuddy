from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime
from uuid import UUID
import re


class EmergencyContactCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    relationship: Optional[str] = None
    phone: str = Field(..., min_length=7, max_length=20)
    priority: int = Field(default=1, ge=1, le=5)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        # Strip spaces and dashes for validation
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        if not re.match(r"^\+?[0-9]{7,15}$", cleaned):
            raise ValueError("Invalid phone number format.")
        return v


class EmergencyContactUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    relationship: Optional[str] = None
    phone: Optional[str] = Field(None, min_length=7, max_length=20)
    priority: Optional[int] = Field(None, ge=1, le=5)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        if not re.match(r"^\+?[0-9]{7,15}$", cleaned):
            raise ValueError("Invalid phone number format.")
        return v


class EmergencyContactResponse(BaseModel):
    id: UUID
    patient_id: UUID
    name: str
    relationship: Optional[str]
    phone: str
    priority: int
    created_at: datetime