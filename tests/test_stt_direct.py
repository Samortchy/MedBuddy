# Direct STT test — loads faster-whisper and transcribes real audio.
# Run: python tests/test_stt_direct.py
# First run downloads large-v3-turbo (~1.5 GB) — let it complete.

import io
import struct
import time
import numpy as np

OUTPUT_WAV = r"D:\projects-last-semester\MedBuddy\tests\stt_test_input.wav"


def _make_wav(text_hint: str = "", sample_rate: int = 16000,
              duration_sec: float = 3.0) -> bytes:
    """
    Generate a proper 16-bit mono WAV at 16 kHz.
    Uses a 440 Hz sine wave (audible tone) so Whisper gets real signal,
    not silence (which VAD filters out and returns empty string).
    """
    num_samples = int(duration_sec * sample_rate)
    t = np.linspace(0, duration_sec, num_samples, endpoint=False)
    # 440 Hz tone at 30% amplitude
    audio = (np.sin(2 * np.pi * 440 * t) * 0.3 * 32767).astype(np.int16)

    buf = io.BytesIO()
    data_bytes = audio.tobytes()
    data_size = len(data_bytes)

    buf.write(b"RIFF")
    buf.write(struct.pack("<I", 36 + data_size))
    buf.write(b"WAVE")
    buf.write(b"fmt ")
    buf.write(struct.pack("<I", 16))          # chunk size
    buf.write(struct.pack("<H", 1))           # PCM
    buf.write(struct.pack("<H", 1))           # mono
    buf.write(struct.pack("<I", sample_rate)) # sample rate
    buf.write(struct.pack("<I", sample_rate * 2))  # byte rate
    buf.write(struct.pack("<H", 2))           # block align
    buf.write(struct.pack("<H", 16))          # bits per sample
    buf.write(b"data")
    buf.write(struct.pack("<I", data_size))
    buf.write(data_bytes)
    buf.seek(0)
    return buf.read()


print("Step 1: generating valid 3-second test WAV (440 Hz tone)...")
wav_bytes = _make_wav()
print(f"  WAV size: {len(wav_bytes):,} bytes")

# Save so you can listen to it
from pathlib import Path
Path(OUTPUT_WAV).write_bytes(wav_bytes)
print(f"  Saved to: {OUTPUT_WAV}")

print("\nStep 2: loading faster-whisper large-v3-turbo...")
print("  (First run downloads ~1.5 GB — let it complete)")
t0 = time.time()

import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

from faster_whisper import WhisperModel
model = WhisperModel("large-v3-turbo", device="cpu", compute_type="int8")
print(f"  Model loaded in {time.time() - t0:.1f}s")

print("\nStep 3: transcribing tone audio (expect empty — VAD filters pure tones)...")
import soundfile as sf
audio_buf = io.BytesIO(wav_bytes)
audio, sr = sf.read(audio_buf, dtype="float32", always_2d=False)
print(f"  Audio shape: {audio.shape}, SR: {sr} Hz")

t0 = time.time()
segments, info = model.transcribe(
    audio,
    beam_size=5,
    vad_filter=True,
    vad_parameters=dict(min_silence_duration_ms=500, speech_pad_ms=200),
    language="ar",
)
text = " ".join(seg.text.strip() for seg in segments).strip()
print(f"  Transcription: '{text}' (empty is OK for tone)")
print(f"  Language: {info.language} ({info.language_probability:.1%})  |  Time: {time.time()-t0:.2f}s")

# ── Step 4: transcribe real Arabic speech from TTS output ─────────────────────
REAL_AUDIO = r"D:\epoch_1\test_output.wav"
print(f"\nStep 4: transcribing real Arabic speech from {REAL_AUDIO} ...")

if not Path(REAL_AUDIO).exists():
    print(f"  SKIP — file not found: {REAL_AUDIO}")
    print("  Run tests/test_tts_direct.py first to generate it.")
else:
    real_audio, real_sr = sf.read(REAL_AUDIO, dtype="float32", always_2d=False)
    print(f"  Audio: {len(real_audio)/real_sr:.1f}s, SR={real_sr} Hz")

    t0 = time.time()
    segs, info2 = model.transcribe(
        real_audio,
        beam_size=5,
        vad_filter=True,
        vad_parameters=dict(min_silence_duration_ms=500, speech_pad_ms=200),
        language="ar",
    )
    result = " ".join(s.text.strip() for s in segs).strip()
    print(f"  Language: {info2.language} ({info2.language_probability:.1%})  |  Time: {time.time()-t0:.2f}s")
    print(f"  Transcription : {result}")
    print(f"  Expected      : مرحبا، كيف حالك اليوم؟")

print()
print("STT pipeline complete.")
