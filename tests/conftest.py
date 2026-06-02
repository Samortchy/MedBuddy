"""
Shared pytest fixtures for all MedBuddy phase tests.

Auto-loads tokens from tests/.env.test (written by get_tokens.py).
If .env.test is missing, falls back to PATIENT_TOKEN / CAREGIVER_TOKEN env vars.

Run get_tokens.py first if you haven't yet:
    C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe tests/get_tokens.py
"""

import os
import pytest

_ENV_FILE = os.path.join(os.path.dirname(__file__), ".env.test")


def _load_env_file():
    """Parse tests/.env.test into os.environ (does not overwrite existing vars)."""
    if not os.path.exists(_ENV_FILE):
        return
    with open(_ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            key = key.strip()
            val = val.strip()
            if key and key not in os.environ:
                os.environ[key] = val


# Load once when conftest is imported (before any test runs)
_load_env_file()


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(scope="session")
def patient_token():
    """Valid Supabase JWT for the patient test account."""
    tok = os.environ.get("PATIENT_TOKEN", "")
    if not tok:
        pytest.skip(
            "No PATIENT_TOKEN found. Run: "
            "C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe tests/get_tokens.py"
        )
    return tok


@pytest.fixture(scope="session")
def caregiver_token():
    """Valid Supabase JWT for the caregiver test account."""
    tok = os.environ.get("CAREGIVER_TOKEN", "")
    if not tok:
        pytest.skip(
            "No CAREGIVER_TOKEN found. Run: "
            "C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe tests/get_tokens.py"
        )
    return tok


@pytest.fixture(scope="session")
def patient_headers(patient_token):
    return {"Authorization": f"Bearer {patient_token}"}


@pytest.fixture(scope="session")
def caregiver_headers(caregiver_token):
    return {"Authorization": f"Bearer {caregiver_token}"}


@pytest.fixture(scope="session")
def patient_profile_id():
    return os.environ.get("PATIENT_PROFILE_ID", "")


@pytest.fixture(scope="session")
def api_base():
    return "http://localhost:8000/api/v1"


@pytest.fixture(scope="session")
def base_url():
    return "http://localhost:8000"
