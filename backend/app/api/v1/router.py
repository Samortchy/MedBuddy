from fastapi import APIRouter
from app.api.v1 import (
    dose_logs,
    appointments,
    emergency_contacts,
    health_conditions,
    patient_profile,
    caregiver,
)

router = APIRouter()

router.include_router(dose_logs.router)
router.include_router(appointments.router)
router.include_router(emergency_contacts.router)
router.include_router(health_conditions.router)
router.include_router(patient_profile.router)
router.include_router(caregiver.router)
