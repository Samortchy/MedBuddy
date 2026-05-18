from fastapi import APIRouter
from app.api.v1 import (
    dose_logs,
    appointments,
    emergency_contacts,
    health_conditions,
    medications,
    patient_profile,
    caregiver,
    notifications,
    symptom_logs,
    visit_summaries,
    emergency_events,
    wellness_checkins,
)

router = APIRouter()

router.include_router(dose_logs.router)
router.include_router(appointments.router)
router.include_router(emergency_contacts.router)
router.include_router(health_conditions.router)
router.include_router(medications.router)
router.include_router(patient_profile.router)
router.include_router(caregiver.router)
router.include_router(notifications.router)
router.include_router(symptom_logs.router)
router.include_router(visit_summaries.router)
router.include_router(emergency_events.router)
router.include_router(wellness_checkins.router)