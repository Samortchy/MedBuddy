from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime
from uuid import UUID
from enum import Enum


class MobilityLevel(str, Enum):
    independent = "independent"
    assisted     = "assisted"
    wheelchair   = "wheelchair"
    bedridden    = "bedridden"


class CognitiveState(str, Enum):
    normal               = "normal"
    mild_impairment      = "mild_impairment"
    moderate_impairment  = "moderate_impairment"
    severe_impairment    = "severe_impairment"


class PatientProfileUpdate(BaseModel):
    # ── profiles table fields ─────────────────────────────────────
    full_name:          Optional[str]   = Field(None, min_length=1, max_length=255)
    phone:              Optional[str]   = Field(None, max_length=20)
    date_of_birth:      Optional[date]  = None
    avatar_url:         Optional[str]   = None
    preferred_language: Optional[str]   = Field(None, max_length=10)

    # ── patient_profiles table fields ────────────────────────────
    mobility_level:             Optional[MobilityLevel]   = None
    cognitive_state:            Optional[CognitiveState]  = None
    fall_detection_enabled:     Optional[bool]            = None
    checkin_time:               Optional[str]             = None  # "HH:MM" format
    checkin_frequency:          Optional[int]             = Field(None, ge=1, le=10)
    medication_grace_mins:      Optional[int]             = Field(None, ge=1, le=120)


class PatientProfileResponse(BaseModel):
    # profiles fields
    id:                 UUID
    full_name:          Optional[str]   = None
    phone:              Optional[str]   = None
    date_of_birth:      Optional[date]  = None
    avatar_url:         Optional[str]   = None
    preferred_language: Optional[str]   = None

    # patient_profiles fields
    profile_id:                 UUID
    mobility_level:             Optional[str]   = None
    cognitive_state:            Optional[str]   = None
    fall_detection_enabled:     Optional[bool]  = None
    checkin_time:               Optional[str]   = None
    checkin_frequency:          Optional[int]   = None
    medication_grace_mins:      Optional[int]   = None
    created_at:                 datetime
    updated_at:                 datetime