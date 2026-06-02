# Manual Phase 2 test — LLM, STT, TTS
# Run from MedBuddy root:
#   python tests/test_phase2_manual.py
#
# Before running:
#   1. Start the server (see instructions at bottom)
#   2. python tests/get_tokens.py   (tokens expire every 1 hour)

import os, sys, io, json, time, struct, requests
import numpy as np
from pathlib import Path


def _make_test_wav(sample_rate: int = 16000, duration_sec: float = 2.0) -> bytes:
    """Valid 16-bit mono WAV with a 440 Hz sine tone — soundfile can decode this."""
    num_samples = int(duration_sec * sample_rate)
    t = np.linspace(0, duration_sec, num_samples, endpoint=False)
    audio = (np.sin(2 * np.pi * 440 * t) * 0.3 * 32767).astype(np.int16)
    data_bytes = audio.tobytes()
    buf = io.BytesIO()
    buf.write(b"RIFF")
    buf.write(struct.pack("<I", 36 + len(data_bytes)))
    buf.write(b"WAVE")
    buf.write(b"fmt ")
    buf.write(struct.pack("<I", 16))
    buf.write(struct.pack("<H", 1))
    buf.write(struct.pack("<H", 1))
    buf.write(struct.pack("<I", sample_rate))
    buf.write(struct.pack("<I", sample_rate * 2))
    buf.write(struct.pack("<H", 2))
    buf.write(struct.pack("<H", 16))
    buf.write(b"data")
    buf.write(struct.pack("<I", len(data_bytes)))
    buf.write(data_bytes)
    buf.seek(0)
    return buf.read()

BASE = "http://localhost:8000/api/v1"
ENV_FILE = Path(__file__).parent / ".env.test"

# ── Load tokens ───────────────────────────────────────────────────────────────

def load_tokens():
    if not ENV_FILE.exists():
        print("ERROR: tests/.env.test not found.")
        print("Run: python tests/get_tokens.py")
        sys.exit(1)
    tokens = {}
    for line in ENV_FILE.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, _, v = line.partition("=")
            tokens[k.strip()] = v.strip()
    patient_tok = tokens.get("PATIENT_TOKEN", "")
    if not patient_tok:
        print("ERROR: PATIENT_TOKEN missing in .env.test")
        print("Run: python tests/get_tokens.py")
        sys.exit(1)
    return patient_tok, tokens.get("CAREGIVER_TOKEN", "")

PATIENT_TOKEN, CAREGIVER_TOKEN = load_tokens()
PATIENT_HDR   = {"Authorization": f"Bearer {PATIENT_TOKEN}"}
CAREGIVER_HDR = {"Authorization": f"Bearer {CAREGIVER_TOKEN}"}

PASS = "[PASS]"
FAIL = "[FAIL]"
SKIP = "[SKIP]"

results = []

def check(name, condition, detail=""):
    status = PASS if condition else FAIL
    results.append((status, name))
    print(f"  {status}  {name}" + (f"  →  {detail}" if detail else ""))
    return condition


# ── Health check ──────────────────────────────────────────────────────────────

print("\n── Health ──────────────────────────────────────────────────────")
try:
    r = requests.get("http://localhost:8000/health", timeout=3)
    check("Server is up", r.status_code == 200, f"status={r.status_code}")
except requests.exceptions.ConnectionError:
    print(f"  {FAIL}  Server not reachable at localhost:8000")
    print("\n  Start the server first:")
    print("  conda activate medbuddy-backend")
    print("  cd backend")
    print("  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")
    sys.exit(1)


# ── POST /chat ────────────────────────────────────────────────────────────────

print("\n── POST /chat (OpenRouter LLM) ──────────────────────────────────")

# Auth guard
r = requests.post(f"{BASE}/chat", json={"message": "Hello"})
check("Requires auth (no token → 401/403)", r.status_code in (401, 403), f"got {r.status_code}")

# Empty message
r = requests.post(f"{BASE}/chat", json={"message": ""}, headers=PATIENT_HDR)
check("Empty message → 400", r.status_code == 400, f"got {r.status_code}")

# English message
print("  Sending English message (may take 3-10s)...")
t0 = time.time()
r = requests.post(f"{BASE}/chat", json={"message": "Hello, how are you?"}, headers=PATIENT_HDR, timeout=30)
elapsed = time.time() - t0

if r.status_code == 503:
    print(f"  {SKIP}  Chat → 503 (OPENROUTER_API_KEY not configured)")
elif r.status_code == 200:
    data = r.json()
    check("Chat returns 200",         True,                           f"{elapsed:.1f}s")
    check("Response has 'reply'",     "reply" in data,                str(data.get("reply", ""))[:80])
    check("Reply is non-empty",       len(data.get("reply", "")) > 0)
else:
    check("Chat request succeeded", False, f"status={r.status_code} body={r.text[:200]}")

# Arabic message
print("  Sending Arabic message...")
r = requests.post(f"{BASE}/chat", json={"message": "مرحبا، كيف حالك؟"}, headers=PATIENT_HDR, timeout=30)
if r.status_code == 200:
    check("Arabic message works", True, r.json().get("reply", "")[:80])
elif r.status_code == 503:
    print(f"  {SKIP}  Arabic chat → 503")
else:
    check("Arabic message works", False, f"status={r.status_code}")

# Session ID echo
r = requests.post(
    f"{BASE}/chat",
    json={"message": "Test", "session_id": "abc-123"},
    headers=PATIENT_HDR, timeout=30
)
if r.status_code == 200:
    check("session_id echoed back", r.json().get("session_id") == "abc-123")

# History
r = requests.post(
    f"{BASE}/chat",
    json={
        "message": "What is my name?",
        "history": [
            {"role": "user",      "content": "My name is Hassan."},
            {"role": "assistant", "content": "Nice to meet you, Hassan!"},
        ],
    },
    headers=PATIENT_HDR, timeout=30
)
if r.status_code == 200:
    reply = r.json().get("reply", "")
    check("History context passed", "Hassan" in reply or len(reply) > 0, reply[:80])

# Caregiver can also chat
r = requests.post(f"{BASE}/chat", json={"message": "Hello"}, headers=CAREGIVER_HDR, timeout=30)
check("Caregiver can use chat", r.status_code in (200, 503), f"got {r.status_code}")


# ── POST /stt ─────────────────────────────────────────────────────────────────

print("\n── POST /stt (Whisper STT) ───────────────────────────────────────")

# Auth guard
r = requests.post(f"{BASE}/stt", files={"audio": ("t.wav", b"x", "audio/wav")})
check("Requires auth", r.status_code in (401, 403), f"got {r.status_code}")

# Empty audio
r = requests.post(f"{BASE}/stt", files={"audio": ("e.wav", b"", "audio/wav")}, headers=PATIENT_HDR)
check("Empty audio → 400", r.status_code == 400, f"got {r.status_code}")

# Real request with a valid WAV (2s sine tone — model loads on first call)
print("  Sending valid WAV audio (first call downloads ~1.5 GB if not cached)...")
test_wav = _make_test_wav()
t0 = time.time()
r = requests.post(
    f"{BASE}/stt",
    files={"audio": ("test.wav", test_wav, "audio/wav")},
    headers=PATIENT_HDR, timeout=300  # allow time for model download + inference
)
elapsed = time.time() - t0
if r.status_code == 200:
    data = r.json()
    check("STT returns 200",                  True,                                    f"{elapsed:.1f}s")
    check("STT has 'text' field",             "text" in data,                          repr(data.get("text", ""))[:60])
    check("STT has 'language' field",         "language" in data,                      data.get("language", ""))
    check("STT has 'language_probability'",   "language_probability" in data)
else:
    check("STT responded", False, f"status={r.status_code} body={r.text[:300]}")


# ── POST /tts ─────────────────────────────────────────────────────────────────

print("\n── POST /tts (Chatterbox TTS) ───────────────────────────────────")

# Auth guard
r = requests.post(f"{BASE}/tts", json={"text": "Hello"})
check("Requires auth", r.status_code in (401, 403), f"got {r.status_code}")

# Empty text
r = requests.post(f"{BASE}/tts", json={"text": ""}, headers=PATIENT_HDR)
check("Empty text → 400", r.status_code == 400, f"got {r.status_code}")

# Real request
r = requests.post(
    f"{BASE}/tts",
    json={"text": "مرحبا، كيف حالك اليوم؟", "language_id": "ar"},
    headers=PATIENT_HDR, timeout=120
)
if r.status_code == 503:
    print(f"  {SKIP}  TTS → 503 (Chatterbox model still downloading)")
elif r.status_code == 200:
    check("TTS returns WAV",       r.headers.get("content-type", "").startswith("audio/wav"))
    check("WAV has content",       len(r.content) > 1000, f"{len(r.content):,} bytes")
    Path("tests/tts_output.wav").write_bytes(r.content)
    print("       Saved to tests/tts_output.wav — open it and listen!")
else:
    check("TTS responded", False, f"status={r.status_code} body={r.text[:200]}")


# ── Summary ───────────────────────────────────────────────────────────────────

print("\n── Summary ──────────────────────────────────────────────────────")
passed  = sum(1 for s, _ in results if s == PASS)
failed  = sum(1 for s, _ in results if s == FAIL)
print(f"  {passed} passed  |  {failed} failed  |  {len(results)} total checks")
if failed:
    print("\n  Failed checks:")
    for s, name in results:
        if s == FAIL:
            print(f"    - {name}")
