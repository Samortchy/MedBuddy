"""
LLM Service — OpenRouter (meta-llama/llama-3.3-70b-instruct)
-------------------------------------------------------------
Uses httpx (already a project dependency) to call the OpenRouter API.
No extra packages needed.
"""

from __future__ import annotations

import logging
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
