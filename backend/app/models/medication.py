from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date
from enum import Enum


class DoseUnit(str, Enum):
    mg = "mg"
    ml = "ml"
    mcg = "mcg"
    tablet = "tablet"
    capsule = "capsule"
    unit = "unit"
    iu = "iu"


class MedicationForm(str, Enum):
    tablet = "tablet"
    capsule = "capsule"
    liquid = "liquid"
    injection = "injection"
    inhaler = "inhaler"
    patch = "patch"
    drops = "drops"
    other = "other"


class MedicationScheduleCreate(BaseModel):
    time_of_day: str = Field(..., pattern=r"^\d{2}:\d{2}$", description="HH:MM format")


class MedicationCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    dose_amount: float = Field(..., gt=0)
    dose_unit: DoseUnit
    form: Optional[MedicationForm] = None
    instructions: Optional[str] = None
    start_date: date
    end_date: Optional[date] = None
    schedules: List[MedicationScheduleCreate] = Field(..., min_length=1)


class MedicationUpdate(BaseModel):
    name: Optional[str] = None
    dose_amount: Optional[float] = None
    dose_unit: Optional[DoseUnit] = None
    form: Optional[MedicationForm] = None
    instructions: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    schedules: Optional[List[MedicationScheduleCreate]] = None
