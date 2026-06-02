"""
Patient-context system prompt builder.

Combines the base MedBuddy persona with the authenticated patient's profile,
health conditions, and medications so the LLM can answer questions like
"what is my name?" or "what are my medications?".
"""

from __future__ import annotations

from datetime import date
from typing import Optional

from app.services.llm_service import MEDBUDDY_SYSTEM_PROMPT


def _age_from_dob(dob: Optional[str]) -> Optional[int]:
    if not dob:
        return None
    try:
        d = date.fromisoformat(str(dob)[:10])
        today = date.today()
        return today.year - d.year - ((today.month, today.day) < (d.month, d.day))
    except (ValueError, TypeError):
        return None


def build_patient_system_prompt(
    profile: dict,
    conditions: list[dict],
    medications: list[dict],
) -> str:
    """
    Returns the base system prompt extended with a PATIENT PROFILE block.

    Args:
        profile:     merged profiles + patient_profiles row (full_name, date_of_birth, ...)
        conditions:  rows from health_conditions ([{"name": ...}, ...])
        medications: active rows from medications (name, dose_amount, dose_unit, frequency)
    """
    profile = profile or {}
    name = profile.get("full_name") or "the patient"
    age = _age_from_dob(profile.get("date_of_birth"))
    gender = profile.get("gender")
    language = profile.get("preferred_language")

    lines = [f"- Name: {name}"]
    if age is not None:
        lines.append(f"- Age: {age}")
    if gender:
        lines.append(f"- Gender: {gender}")
    if language:
        lines.append(f"- Preferred language: {language}")

    cond_names = [c.get("name") for c in (conditions or []) if c.get("name")]
    lines.append(
        f"- Health conditions: {', '.join(cond_names)}"
        if cond_names
        else "- Health conditions: none recorded"
    )

    med_lines = []
    for m in medications or []:
        mn = m.get("name")
        if not mn:
            continue
        amount = m.get("dose_amount")
        unit = m.get("dose_unit") or ""
        freq = (m.get("frequency") or "").replace("_", " ")
        dose = f"{amount} {unit}".strip() if amount is not None else ""
        parts = [mn]
        if dose:
            parts.append(dose)
        if freq:
            parts.append(freq)
        med_lines.append("  - " + " - ".join(parts))
    meds_block = "\n".join(med_lines) if med_lines else "  - none recorded"

    context = (
        "\n\n--- PATIENT PROFILE (use this to answer questions about the patient) ---\n"
        + "\n".join(lines)
        + "\nCurrent medications:\n"
        + meds_block
        + "\n\nWhen the patient asks about their name, age, conditions, or "
        "medications, answer using the profile above. Never say you don't know "
        "these personal details — you have them here."
    )
    return MEDBUDDY_SYSTEM_PROMPT + context
