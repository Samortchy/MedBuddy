"""
AI endpoints — STT, TTS, Chat
Phase 2
"""

from __future__ import annotations

import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile, status
from fastapi.responses import Response
from pydantic import BaseModel
from supabase import Client

from app.core.database import get_db
from app.core.dependencies import get_current_patient, get_current_user
from app.core.limiter import limiter

logger = logging.getLogger(__name__)

router = APIRouter(tags=["AI"])


# ── Models ────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    history: Optional[list[dict]] = None
    system_prompt: Optional[str] = None
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    reply: str
    session_id: Optional[str] = None


class TTSRequest(BaseModel):
    text: str
    language_id: str = "ar"  # ISO-639-1; 'ar' = Arabic (fine-tuned), 'en' = English


# ── POST /stt ─────────────────────────────────────────────────────────────────

@router.post(
    "/stt",
    summary="Transcribe audio to text (faster-whisper large-v3-turbo)",
)
@limiter.limit("10/minute")
async def speech_to_text(
    request: Request,
    audio: UploadFile = File(..., description="Audio file (WAV, WebM, M4A, MP3)"),
    language: Optional[str] = Form(None, description="ISO-639-1 language hint, e.g. 'ar' or 'en'"),
    current_user: dict = Depends(get_current_user),
):
    """
    Accepts an audio file and returns the transcription.
    Model is lazy-loaded on first call (downloads ~1.5 GB for large-v3-turbo).
    """
    from app.services import stt_service

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Audio file is empty.",
        )

    try:
        result = await stt_service.transcribe(audio_bytes, language=language)
    except Exception as e:
        logger.exception("STT transcription failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Transcription failed: {e}",
        )

    return result


# ── POST /tts ─────────────────────────────────────────────────────────────────

@router.post(
    "/tts",
    summary="Synthesize text to speech (Chatterbox multilingual)",
    response_class=Response,
    responses={
        200: {
            "content": {"audio/wav": {}},
            "description": "WAV audio bytes",
        }
    },
)
async def text_to_speech(
    payload: TTSRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Accepts text and returns a WAV audio file.
    Model is lazy-loaded on first call.

    Requires the model directory (CHATTERBOX_MODEL_PATH) to contain all
    Chatterbox model files (model.safetensors + supporting files).
    """
    from app.services import tts_service

    if not payload.text.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Text must not be empty.",
        )

    try:
        wav_bytes = await tts_service.synthesize(payload.text, language_id=payload.language_id)
    except RuntimeError as e:
        logger.error("TTS error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(e),
        )
    except Exception as e:
        logger.exception("TTS unexpected error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"TTS failed: {e}",
        )

    return Response(
        content=wav_bytes,
        media_type="audio/wav",
        headers={"Content-Disposition": 'attachment; filename="speech.wav"'},
    )


def _build_patient_context(patient_profile_id: str, db: Client) -> Optional[str]:
    """
    Loads the patient's profile, conditions, and medications and returns a
    patient-aware system prompt. Returns None if the data can't be loaded
    (the caller then falls back to the default prompt).
    """
    from app.ai.prompts.system_prompt import build_patient_system_prompt

    try:
        prof = (
            db.table("patient_profiles")
            .select("*, profiles(*)")
            .eq("id", patient_profile_id)
            .single()
            .execute()
        )
        pdata = prof.data or {}
        merged = {**(pdata.get("profiles") or {}), **pdata}

        conditions = (
            db.table("health_conditions")
            .select("name")
            .eq("patient_id", patient_profile_id)
            .execute()
            .data
            or []
        )
        medications = (
            db.table("medications")
            .select("name, dose_amount, dose_unit, frequency, instructions")
            .eq("patient_id", patient_profile_id)
            .is_("deleted_at", "null")
            .execute()
            .data
            or []
        )
        return build_patient_system_prompt(merged, conditions, medications)
    except Exception as e:
        logger.warning("Could not load patient context for chat: %s", e)
        return None


# ── POST /chat ────────────────────────────────────────────────────────────────

@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="Send a message to the MedBuddy AI (Llama 3.3 70B via OpenRouter)",
)
@limiter.limit("10/minute")
async def chat(
    request: Request,
    payload: ChatRequest,
    current_user: dict = Depends(get_current_user),
    db: Client = Depends(get_db),
):
    """
    Sends a message to the LLM and returns the AI reply.
    Maintains conversation history via the `history` field.

    For authenticated patients, the patient's profile, health conditions, and
    medications are injected into the system prompt so the assistant can answer
    questions like "what is my name?" or "what are my medications?".

    The LLM is stateless — clients must send full conversation history each turn.
    """
    from app.services import llm_service

    if not payload.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message must not be empty.",
        )

    # Build a patient-aware system prompt unless the client supplied its own.
    system_prompt = payload.system_prompt
    if system_prompt is None and current_user.get("patient_profile_id"):
        system_prompt = _build_patient_context(current_user["patient_profile_id"], db)

    try:
        reply = await llm_service.chat(
            message=payload.message,
            history=payload.history,
            system_prompt=system_prompt,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(e),
        )
    except RuntimeError as e:
        logger.error("LLM error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(e),
        )
    except Exception as e:
        logger.exception("Chat unexpected error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Chat failed: {e}",
        )

    return ChatResponse(reply=reply, session_id=payload.session_id)
