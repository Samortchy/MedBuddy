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


# --- MENNA: add NotificationPreference schemas below this line ---
