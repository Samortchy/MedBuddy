"""
LLM Service — OpenRouter (meta-llama/llama-3.3-70b-instruct)
-------------------------------------------------------------
Uses httpx (already a project dependency) to call the OpenRouter API.
No extra packages needed.
"""

from __future__ import annotations

import json
import logging
import re
from typing import Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

MEDBUDDY_SYSTEM_PROMPT = """You are MedBuddy, a warm and compassionate AI health companion for elderly patients.

Your role:
- Conduct daily wellness check-ins in a friendly, simple manner
- Answer questions about medications, appointments, and general health routines
- Offer emotional support and gentle encouragement
- Flag concerning symptoms and remind the patient to contact their caregiver or doctor

Communication rules:
- Keep responses SHORT — 2 to 4 sentences maximum
- Use SIMPLE words — no medical jargon
- Be WARM and PATIENT — the user may have cognitive challenges
- Match the patient's language (Arabic or English)
- NEVER diagnose or prescribe — always say "please ask your doctor"
- If the patient sounds distressed, remind them their caregiver is available"""


async def chat(
    message: str,
    history: Optional[list[dict]] = None,
    system_prompt: Optional[str] = None,
) -> str:
    """
    Send a message to the LLM and return the reply text.

    Args:
        message:       The user's new message.
        history:       Prior turns as [{"role": "user"|"assistant", "content": "..."}]
        system_prompt: Override the default MedBuddy system prompt.

    Returns:
        The assistant's reply as a plain string.
    """
    api_key = settings.openrouter_api_key
    if not api_key or api_key == "your-openrouter-api-key":
        raise ValueError("OPENROUTER_API_KEY is not configured in .env")

    messages: list[dict] = [
        {"role": "system", "content": system_prompt or MEDBUDDY_SYSTEM_PROMPT}
    ]
    if history:
        messages.extend(history)
    messages.append({"role": "user", "content": message})

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            OPENROUTER_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://medbuddy.app",
                "X-Title": "MedBuddy",
            },
            json={
                "model": settings.openrouter_model,
                "messages": messages,
                "max_tokens": 256,
                "temperature": 0.7,
            },
        )

    if response.status_code != 200:
        logger.error("OpenRouter error %s: %s", response.status_code, response.text[:300])
        raise RuntimeError(f"LLM API error {response.status_code}: {response.text[:200]}")

    data = response.json()
    reply = data["choices"][0]["message"]["content"]
    logger.info("LLM reply (%d chars)", len(reply))
    return reply.strip()


# ── Structured helpers (Phase 5) ──────────────────────────────────────────────

def _parse_json(text: str) -> dict:
    """Best-effort parse of a JSON object from an LLM reply (tolerates fences/prose)."""
    try:
        return json.loads(text)
    except Exception:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except Exception:
                pass
    return {}


async def extract_visit_summary(transcript: str) -> dict:
    """
    Turn a raw doctor-visit transcript into structured fields.

    Returns {diagnosis, medications_changed, instructions, next_appointment}.
    Values may be None/empty if not present in the transcript.
    """
    system_prompt = (
        "You are a careful medical scribe. From the doctor-visit transcript, "
        "extract a structured summary. Respond with ONLY a JSON object with "
        'these exact keys: "diagnosis" (string), "medications_changed" (string), '
        '"instructions" (string), "next_appointment" (date as YYYY-MM-DD or null). '
        "Use an empty string or null when something is not mentioned. "
        "Do not invent information. Output JSON only, no prose, no code fences."
    )
    reply = await chat(message=transcript, system_prompt=system_prompt)
    data = _parse_json(reply)
    return {
        "diagnosis": data.get("diagnosis") or None,
        "medications_changed": data.get("medications_changed") or None,
        "instructions": data.get("instructions") or None,
        "next_appointment": data.get("next_appointment") or None,
    }


async def assess_symptom(text: str) -> dict:
    """
    Triage a free-text symptom. Returns {severity, summary}.
    severity ∈ {normal, watch, flagged}.
    """
    system_prompt = (
        "You are a triage assistant for an elderly-care app. Classify the "
        "patient's symptom description by severity. Respond with ONLY a JSON "
        'object: {"severity": "normal" | "watch" | "flagged", '
        '"summary": "<one short sentence>"}. '
        "Use 'flagged' for anything urgent or dangerous (chest pain, trouble "
        "breathing, stroke signs, severe bleeding, fainting, suicidal thoughts). "
        "Use 'watch' for moderate concerns worth monitoring, and 'normal' for "
        "mild/routine complaints. Output JSON only."
    )
    reply = await chat(message=text, system_prompt=system_prompt)
    data = _parse_json(reply)
    severity = str(data.get("severity") or "normal").lower().strip()
    if severity not in ("normal", "watch", "flagged"):
        severity = "watch"
    return {"severity": severity, "summary": data.get("summary") or ""}
