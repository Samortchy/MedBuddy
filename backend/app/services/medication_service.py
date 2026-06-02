from supabase import Client
from datetime import datetime, timezone, timedelta, date
from typing import Optional


async def generate_doses_for_patient(
    patient_id: str,
    db: Client,
    days_ahead: int = 7,
) -> int:
    """
    Generates medication_doses rows for all active medications belonging to a patient.

    Idempotent: uses upsert with ignore_duplicates=True (ON CONFLICT DO NOTHING).
    The medication_doses table must have a UNIQUE constraint on (medication_id, scheduled_at).

    Returns the count of newly inserted rows.
    """
    now = datetime.now(timezone.utc)
    window_end = now + timedelta(days=days_ahead)

    meds_result = (
        db.table("medications")
        .select("id, start_date, end_date, medication_schedules(time_of_day)")
        .eq("patient_id", patient_id)
        .is_("deleted_at", "null")
        .execute()
    )

    medications = meds_result.data or []
    if not medications:
        return 0

    doses_to_insert = []

    for med in medications:
        medication_id = med["id"]
        schedules = med.get("medication_schedules") or []
        if not schedules:
            continue

        start_date = _parse_date(med.get("start_date")) or now.date()
        end_date = _parse_date(med.get("end_date"))

        for schedule in schedules:
            # DB returns time as "HH:MM:SS" — only take first two parts
            parts = str(schedule["time_of_day"]).split(":")
            hour, minute = int(parts[0]), int(parts[1])

            current_day = max(now.date(), start_date)
            while current_day <= window_end.date():
                if end_date and current_day > end_date:
                    break

                scheduled_at = datetime(
                    current_day.year,
                    current_day.month,
                    current_day.day,
                    hour,
                    minute,
                    0,
                    tzinfo=timezone.utc,
                )

                # Always include all doses for the start date so newly added
                # medications appear immediately regardless of current time.
                # For subsequent days only include future doses.
                is_start_date = (current_day == max(now.date(), start_date))
                if is_start_date or scheduled_at >= now - timedelta(hours=1):
                    doses_to_insert.append({
                        "medication_id": medication_id,
                        "scheduled_at": scheduled_at.isoformat(),
                    })

                current_day += timedelta(days=1)

    if not doses_to_insert:
        return 0

    result = (
        db.table("medication_doses")
        .upsert(
            doses_to_insert,
            ignore_duplicates=True,
            on_conflict="medication_id,scheduled_at",
        )
        .execute()
    )

    return len(result.data or [])


def _parse_date(value) -> Optional[date]:
    if not value:
        return None
    if isinstance(value, date):
        return value
    try:
        return date.fromisoformat(str(value)[:10])
    except (ValueError, TypeError):
        return None
