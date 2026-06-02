"""
STT Service — faster-whisper large-v3-turbo
-------------------------------------------
Adapted from realtime_stt.py (Ali's 2nd project).
Lazy-loads on first call. CUDA → CPU fallback.
Accepts raw audio bytes from the API, converts to numpy internally.
"""

import asyncio
import io
import logging
import os
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Optional

import numpy as np

os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

logger = logging.getLogger(__name__)

_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="whisper")
_whisper_model = None
_model_loaded = False


def _get_device_and_compute_type() -> tuple[str, str]:
    try:
        import torch
        if torch.cuda.is_available():
            logger.info("[STT] CUDA available — using GPU (float16)")
            return "cuda", "float16"
        else:
            logger.info("[STT] CUDA not available — using CPU (int8)")
            return "cpu", "int8"
    except ImportError:
        logger.info("[STT] PyTorch not found — using CPU (int8)")
        return "cpu", "int8"


def load_model(force_cpu: bool = False):
    global _whisper_model, _model_loaded

    if _model_loaded:
        return _whisper_model

    from faster_whisper import WhisperModel
    from app.core.config import settings

    logger.info("[STT] Loading Faster-Whisper model...")
    start = time.time()

    if force_cpu:
        device, compute_type = "cpu", "int8"
    else:
        device, compute_type = _get_device_and_compute_type()

    model_size = settings.whisper_model_size or "large-v3-turbo"
    _whisper_model = WhisperModel(model_size, device=device, compute_type=compute_type)
    _model_loaded = True

    elapsed = time.time() - start
    logger.info("[STT] Model loaded in %.1fs (device=%s)", elapsed, device)
    return _whisper_model


def get_model():
    if not _model_loaded:
        load_model()
    return _whisper_model


def _bytes_to_numpy(audio_bytes: bytes) -> np.ndarray:
    """Decode audio bytes (WAV/WebM/MP3/M4A) to float32 numpy array at 16 kHz."""
    import soundfile as sf

    buf = io.BytesIO(audio_bytes)
    try:
        audio, sr = sf.read(buf, dtype="float32", always_2d=False)
    except Exception:
        # soundfile can't handle compressed formats — fall back to torchaudio
        import torchaudio
        buf.seek(0)
        waveform, sr = torchaudio.load(buf)
        audio = waveform.mean(0).numpy()  # mono

    # Resample to 16 kHz if needed
    if sr != 16000:
        import torchaudio.functional as F
        import torch
        audio = F.resample(torch.from_numpy(audio), sr, 16000).numpy()

    return audio.astype(np.float32)


def _transcribe_sync(audio_bytes: bytes, language: Optional[str]) -> dict:
    audio = _bytes_to_numpy(audio_bytes)

    duration = len(audio) / 16000
    logger.info("[STT] Transcribing %.2fs of audio", duration)

    model = get_model()
    start = time.time()

    kwargs = dict(
        beam_size=5,
        vad_filter=True,
        vad_parameters=dict(
            min_silence_duration_ms=500,
            speech_pad_ms=200,
        ),
    )
    if language:
        kwargs["language"] = language
    else:
        kwargs["language"] = "ar"  # default to Arabic

    segments, info = model.transcribe(audio, **kwargs)
    full_text = " ".join(seg.text for seg in segments).strip()

    elapsed = time.time() - start
    logger.info("[STT] Transcribed in %.3fs: '%s...'", elapsed, full_text[:50])

    return {
        "text": full_text,
        "language": info.language,
        "language_probability": round(info.language_probability, 3),
    }


async def transcribe(audio_bytes: bytes, language: Optional[str] = None) -> dict:
    """
    Transcribe audio bytes to text.

    Args:
        audio_bytes: Raw audio (WAV, WebM, M4A, MP3).
        language:    ISO-639-1 hint (None → defaults to 'ar').

    Returns:
        {"text": str, "language": str, "language_probability": float}
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_executor, _transcribe_sync, audio_bytes, language)
