"""
TTS Service — Chatterbox Multilingual (Arabic fine-tune)
---------------------------------------------------------
Strategy:
  1. Load the base ChatterboxMultilingualTTS from HuggingFace (downloads ~500 MB
     of companion files: ve.safetensors, t3_cfg.pkl, s3gen.safetensors, tokenizer).
  2. Overlay the fine-tuned Arabic T3 weights from CHATTERBOX_MODEL_PATH.

This means only model.safetensors needs to be local — everything else auto-downloads
from resemble-ai/chatterbox-multilingual on first call.
"""

from __future__ import annotations

import asyncio
import io
import logging
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="chatterbox")
_model = None
_sample_rate: int = 24000


def _pick_device() -> str:
    try:
        import torch
        if torch.cuda.is_available():
            logger.info("TTS: CUDA available — using GPU")
            return "cuda"
    except ImportError:
        pass
    logger.info("TTS: no CUDA — using CPU")
    return "cpu"


def _resolve_weights_file() -> Optional[Path]:
    """Return Path to fine-tuned model.safetensors, or None if not configured."""
    from app.core.config import settings
    raw = settings.chatterbox_model_path.strip().strip('"')
    if not raw:
        return None
    p = Path(raw)
    if p.is_file() and p.suffix == ".safetensors":
        return p
    candidate = p / "model.safetensors"
    if candidate.exists():
        return candidate
    return None


def _load_model():
    global _model, _sample_rate
    if _model is not None:
        return _model

    from chatterbox.mtl_tts import ChatterboxMultilingualTTS

    device = _pick_device()

    # Step 1: download/load base multilingual model from HuggingFace
    logger.info("Loading Chatterbox Multilingual base model (HuggingFace)...")
    _model = ChatterboxMultilingualTTS.from_pretrained(device=device)
    _sample_rate = _model.sr
    logger.info("Base model loaded (sr=%d Hz)", _sample_rate)

    # Step 2: overlay fine-tuned weights if available
    weights_file = _resolve_weights_file()
    if weights_file:
        logger.info("Overlaying fine-tuned weights from %s", weights_file)
        try:
            import safetensors.torch
            state = safetensors.torch.load_file(str(weights_file), device=device)
            # Fine-tuned file contains T3 transformer weights
            missing, unexpected = _model.t3.load_state_dict(state, strict=False)
            if unexpected:
                logger.debug("Fine-tune overlay — unexpected keys (ignored): %d", len(unexpected))
            if missing:
                logger.warning("Fine-tune overlay — missing keys in checkpoint: %d", len(missing))
            else:
                logger.info("Fine-tuned Arabic weights loaded successfully (all keys matched).")
            _model.t3.eval()
        except Exception as e:
            logger.warning("Could not load fine-tuned weights (%s) — using base model.", e)
    else:
        logger.info("No CHATTERBOX_MODEL_PATH set — using base multilingual model as-is.")

    return _model


def _synthesize_sync(text: str, language_id: str) -> bytes:
    import torch
    import torchaudio

    model = _load_model()

    with torch.inference_mode():
        wav = model.generate(text, language_id=language_id)

    buf = io.BytesIO()
    torchaudio.save(buf, wav, _sample_rate, format="wav")
    buf.seek(0)
    return buf.read()


async def synthesize(text: str, language_id: str = "ar") -> bytes:
    """
    Synthesize text to speech using Chatterbox Multilingual.

    Args:
        text:        Text to speak.
        language_id: ISO-639-1 code, e.g. 'ar', 'en'. Defaults to 'ar' (fine-tuned language).

    Returns:
        Raw WAV bytes.
    """
    if not text.strip():
        raise ValueError("Text must not be empty.")

    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_executor, _synthesize_sync, text, language_id)
