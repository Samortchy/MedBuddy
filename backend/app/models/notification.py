from datetime import datetime

from pydantic import BaseModel, Field


class PushPayload(BaseModel):
    device_token: str
    title: str
    body: str
    data: dict[str, str] = Field(default_factory=dict)


class PushResult(BaseModel):
    success: bool
    message_id: str | None = None
    error: str | None = None


class MedicationReminderContext(BaseModel):
    patient_id: str
    medication_name: str
    dose_scheduled_at: datetime
    device_token: str


class AppointmentReminderContext(BaseModel):
    patient_id: str
    appointment_title: str
    appointment_at: datetime
    device_token: str


# --- MENNA: NotificationPreference schemas (Task #27) ---

from typing import Literal, Optional

from pydantic import field_validator

Channel = Literal["push", "sms", "both"]

VALID_LANGUAGES = {"en", "ar", "fr", "de", "es"}


class NotificationPreferencesOut(BaseModel):
    id: str
    patient_id: str
    channel: Channel
    quiet_from: Optional[str]
    quiet_until: Optional[str]
    language: str
    created_at: str
    updated_at: str


class NotificationPreferencesPatch(BaseModel):
    channel: Optional[Channel] = None
    quiet_from: Optional[str] = None
    quiet_until: Optional[str] = None
    language: Optional[str] = None

    @field_validator("quiet_from", "quiet_until", mode="before")
    @classmethod
    def validate_time_format(cls, v: str | None) -> str | None:
        if v is None:
            return None
        parts = v.split(":")
        if len(parts) not in (2, 3):
            raise ValueError("Time must be in HH:MM or HH:MM:SS format")
        try:
            hour = int(parts[0])
            minute = int(parts[1])
            second = int(parts[2]) if len(parts) == 3 else 0
        except ValueError:
            raise ValueError("Invalid time value")
        if not (0 <= hour <= 23 and 0 <= minute <= 59 and 0 <= second <= 59):
            raise ValueError("Time out of range")
        return f"{hour:02d}:{minute:02d}:{second:02d}"

    @field_validator("language", mode="before")
    @classmethod
    def validate_language(cls, v: str | None) -> str | None:
        if v is None:
            return None
        if v not in VALID_LANGUAGES:
            raise ValueError(f"language must be one of {sorted(VALID_LANGUAGES)}")
        return v
