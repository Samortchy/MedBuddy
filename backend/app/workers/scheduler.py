import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from fastapi import FastAPI

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
