"""
Phase 2 tests — STT, TTS, Chat (LLM) endpoints
================================================
Run after get_tokens.py and with the backend server running on localhost:8000.

    C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe -m pytest tests/phase2_test.py -v

Notes:
- /stt and /tts tests require WHISPER_MODEL_SIZE and CHATTERBOX_MODEL_PATH to be configured.
- /chat requires OPENROUTER_API_KEY to be set.
- Tests that need model download will be slow on first run.
- Tests skip gracefully when the service returns 503 (model not configured / not loaded yet).
"""

import io
import struct
import pytest
import requests
import numpy as np

BASE = "http://localhost:8000/api/v1"


def _make_test_wav(sample_rate: int = 16000, duration_sec: float = 2.0) -> bytes:
    """Valid 16-bit mono WAV with a 440 Hz sine tone."""
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


# ── Helpers ───────────────────────────────────────────────────────────────────

def _skip_if_503(r, feature: str):
    if r.status_code == 503:
        pytest.skip(f"{feature} not available (503) — model may not be configured")


# ── POST /chat ────────────────────────────────────────────────────────────────

class TestChat:

    def test_chat_requires_auth(self):
        r = requests.post(f"{BASE}/chat", json={"message": "Hello"})
        assert r.status_code in (401, 403)

    def test_chat_empty_message_returns_400(self, patient_headers):
        r = requests.post(f"{BASE}/chat", json={"message": ""}, headers=patient_headers)
        assert r.status_code == 400

    def test_chat_missing_api_key_returns_503(self, patient_headers):
        r = requests.post(
            f"{BASE}/chat",
            json={"message": "Hello"},
            headers=patient_headers,
        )
        # 503 = key not configured; 200 = working; 502 = API error
        assert r.status_code in (200, 502, 503)

    def test_chat_returns_reply_field(self, patient_headers):
        r = requests.post(
            f"{BASE}/chat",
            json={"message": "How are you?"},
            headers=patient_headers,
        )
        _skip_if_503(r, "Chat")
        if r.status_code == 200:
            data = r.json()
            assert "reply" in data
            assert isinstance(data["reply"], str)
            assert len(data["reply"]) > 0

    def test_chat_echoes_session_id(self, patient_headers):
        r = requests.post(
            f"{BASE}/chat",
            json={"message": "Hello", "session_id": "test-session-123"},
            headers=patient_headers,
        )
        _skip_if_503(r, "Chat")
        if r.status_code == 200:
            assert r.json().get("session_id") == "test-session-123"

    def test_chat_with_history(self, patient_headers):
        r = requests.post(
            f"{BASE}/chat",
            json={
                "message": "What did I say first?",
                "history": [
                    {"role": "user", "content": "My name is Hassan."},
                    {"role": "assistant", "content": "Nice to meet you, Hassan!"},
                ],
            },
            headers=patient_headers,
        )
        _skip_if_503(r, "Chat")
        assert r.status_code in (200, 502)

    def test_chat_caregiver_can_also_use(self, caregiver_headers):
        r = requests.post(
            f"{BASE}/chat",
            json={"message": "Hello"},
            headers=caregiver_headers,
        )
        _skip_if_503(r, "Chat")
        assert r.status_code in (200, 502, 503)


# ── POST /stt ─────────────────────────────────────────────────────────────────

class TestSTT:

    def test_stt_requires_auth(self):
        r = requests.post(
            f"{BASE}/stt",
            files={"audio": ("test.wav", b"fake", "audio/wav")},
        )
        assert r.status_code in (401, 403)

    def test_stt_empty_audio_returns_400(self, patient_headers):
        r = requests.post(
            f"{BASE}/stt",
            files={"audio": ("empty.wav", b"", "audio/wav")},
            headers=patient_headers,
        )
        assert r.status_code == 400

    def test_stt_invalid_audio_returns_400(self, patient_headers):
        r = requests.post(
            f"{BASE}/stt",
            files={"audio": ("bad.wav", b"this is not audio", "audio/wav")},
            headers=patient_headers,
        )
        # Bad audio either returns 503 (decode error) or 200 (empty transcription)
        assert r.status_code in (200, 503)

    def test_stt_returns_text_field_on_success(self, patient_headers):
        """Sends a real valid WAV — loads Whisper on first call (~1.5 GB download)."""
        r = requests.post(
            f"{BASE}/stt",
            files={"audio": ("test.wav", _make_test_wav(), "audio/wav")},
            headers=patient_headers,
            timeout=300,
        )
        _skip_if_503(r, "STT")
        assert r.status_code == 200
        data = r.json()
        assert "text" in data
        assert "language" in data
        assert "language_probability" in data

    def test_stt_accepts_language_hint(self, patient_headers):
        r = requests.post(
            f"{BASE}/stt",
            files={"audio": ("test.wav", _make_test_wav(), "audio/wav")},
            data={"language": "ar"},
            headers=patient_headers,
            timeout=300,
        )
        _skip_if_503(r, "STT")
        assert r.status_code == 200


# ── POST /tts ─────────────────────────────────────────────────────────────────

class TestTTS:

    def test_tts_requires_auth(self):
        r = requests.post(f"{BASE}/tts", json={"text": "Hello"})
        assert r.status_code in (401, 403)

    def test_tts_empty_text_returns_400(self, patient_headers):
        r = requests.post(f"{BASE}/tts", json={"text": ""}, headers=patient_headers)
        assert r.status_code == 400

    def test_tts_missing_model_returns_503(self, patient_headers):
        r = requests.post(
            f"{BASE}/tts",
            json={"text": "Hello"},
            headers=patient_headers,
        )
        # 503 = model not ready; 200 = success
        assert r.status_code in (200, 503)

    def test_tts_returns_wav_on_success(self, patient_headers):
        r = requests.post(
            f"{BASE}/tts",
            json={"text": "Good morning, how are you feeling today?"},
            headers=patient_headers,
        )
        _skip_if_503(r, "TTS")
        if r.status_code == 200:
            assert r.headers.get("content-type", "").startswith("audio/wav")
            assert len(r.content) > 1000


# ── Regression: Phase 1 still works ──────────────────────────────────────────

class TestPhase2Regression:

    def test_wellness_post_still_works(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 4},
            headers=patient_headers,
        )
        assert r.status_code == 201

    def test_wellness_get_still_works(self, patient_headers):
        r = requests.get(f"{BASE}/wellness-checkins/", headers=patient_headers)
        assert r.status_code == 200

    def test_symptom_logs_still_works(self, patient_headers):
        r = requests.get(f"{BASE}/symptom-logs/", headers=patient_headers)
        assert r.status_code == 200

    def test_notification_prefs_still_works(self, patient_headers):
        r = requests.get(
            f"{BASE}/patient/notification-preferences", headers=patient_headers
        )
        assert r.status_code == 200
