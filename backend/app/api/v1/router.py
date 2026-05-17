# """
# v1 aggregate router.

# Include each sub-router from this file, then mount this single router
# in main.py with prefix="/api/v1".
# """

# from fastapi import APIRouter

# from app.api.v1 import notifications

# api_router = APIRouter()

# # Task #27 — notification preferences
# api_router.include_router(notifications.router)

# # Other sub-routers will be added here as Ahmed/others ship them:
# # api_router.include_router(medications.router)
# # api_router.include_router(appointments.router)
# # ...
from fastapi import APIRouter
from app.api.v1 import (
    dose_logs,
    appointments,
    emergency_contacts,
    health_conditions,
)

router = APIRouter()

router.include_router(dose_logs.router)
router.include_router(appointments.router)
router.include_router(emergency_contacts.router)
router.include_router(health_conditions.router)