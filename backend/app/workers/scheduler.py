import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from fastapi import FastAPI

from app.workers.checkin_worker import trigger_daily_checkins
from app.workers.escalation_worker import escalate_missed_doses
from app.workers.reminder_worker import (
    appointment_reminder_job,
    medication_reminder_job,
)

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler(timezone="UTC")


def _register_jobs() -> None:
    scheduler.add_job(
        medication_reminder_job,
        trigger=IntervalTrigger(minutes=15),
        id="medication_reminder",
        misfire_grace_time=60,
        replace_existing=True,
    )
    scheduler.add_job(
        appointment_reminder_job,
        trigger=CronTrigger(hour=8, minute=0),
        id="appointment_reminder_daily",
        misfire_grace_time=60,
        replace_existing=True,
    )
    scheduler.add_job(
        appointment_reminder_job,
        trigger=IntervalTrigger(minutes=30),
        id="appointment_reminder_interval",
        misfire_grace_time=60,
        replace_existing=True,
    )
    # Task #24 — Daily wellness check-in trigger (every 60 seconds)
    scheduler.add_job(
        trigger_daily_checkins,
        trigger=IntervalTrigger(seconds=60),
        id="daily_checkin_trigger",
        misfire_grace_time=30,
        replace_existing=True,
    )
    # Task #26 — Missed-dose escalation (every 30 minutes)
    scheduler.add_job(
        escalate_missed_doses,
        trigger=IntervalTrigger(minutes=30),
        id="missed_dose_escalation",
        misfire_grace_time=120,
        replace_existing=True,
    )
    logger.info("Scheduler jobs registered: %s", [j.id for j in scheduler.get_jobs()])


@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.start()
    _register_jobs()
    logger.info("APScheduler started")
    try:
        yield
    finally:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler stopped")
