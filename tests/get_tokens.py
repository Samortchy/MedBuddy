"""
MedBuddy — Test Token Generator
================================
Creates (or reuses) two test accounts in Supabase, seeds the required DB rows,
and writes fresh JWTs to tests/.env.test.

Run this ONCE before any phase test, and again whenever tokens expire (1 hour).

Usage:
    cd D:/projects-last-semester/MedBuddy
    C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe tests/get_tokens.py

What it does:
    1. Creates test.patient@medbuddy.com  (role=patient)  if not already exists
    2. Creates test.caregiver@medbuddy.com (role=caregiver) if not already exists
    3. Signs in to both accounts, gets fresh JWTs
    4. For the patient account: ensures profiles + patient_profiles rows exist
    5. Writes tokens to tests/.env.test  (auto-loaded by conftest.py)
    6. Prints tokens + a ready-to-paste export block for manual use

No manual steps needed — run it and then run your tests.
"""

import os
import sys
import json
import requests

# -- Secret loading (NO secrets hardcoded — read from env / .env files) --------
#
# Supabase keys are read from backend/.env (already present for the backend).
# Test-account passwords are read from tests/.env.local (gitignored).
# You can also export any of these as environment variables.

_HERE = os.path.dirname(__file__)


def _load_env_file(path: str) -> None:
    """Parse a KEY=VAL .env file into os.environ without overwriting existing vars."""
    if not os.path.exists(path):
        return
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            key, val = key.strip(), val.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = val


# Backend .env holds the Supabase keys; tests/.env.local holds test passwords.
_load_env_file(os.path.join(_HERE, "..", "backend", ".env"))
_load_env_file(os.path.join(_HERE, ".env.local"))


def _require(*names: str) -> str:
    """Return the first matching env var (case-insensitive), or exit with guidance."""
    for n in names:
        for candidate in (n, n.upper(), n.lower()):
            if os.environ.get(candidate):
                return os.environ[candidate]
    sys.exit(
        f"\nMissing required secret: {names[0]}\n"
        "Provide it via backend/.env (Supabase keys) or tests/.env.local "
        "(test passwords), or export it as an environment variable.\n"
        "tests/.env.local example:\n"
        "  TEST_PATIENT_PASSWORD=...\n"
        "  TEST_CAREGIVER_PASSWORD=...\n"
    )


# -- Config (loaded from environment, never hardcoded) -------------------------

SUPABASE_URL = _require("SUPABASE_URL")
ANON_KEY     = _require("SUPABASE_ANON_KEY")
SERVICE_KEY  = _require("SUPABASE_SERVICE_ROLE_KEY")

PATIENT_EMAIL    = os.environ.get("TEST_PATIENT_EMAIL", "test.patient@medbuddy.com")
PATIENT_PASSWORD = _require("TEST_PATIENT_PASSWORD")
PATIENT_NAME     = "Test Patient"

CAREGIVER_EMAIL    = os.environ.get("TEST_CAREGIVER_EMAIL", "test.caregiver@medbuddy.com")
CAREGIVER_PASSWORD = _require("TEST_CAREGIVER_PASSWORD")
CAREGIVER_NAME     = "Test Caregiver"

ENV_FILE = os.path.join(_HERE, ".env.test")

# -- Helpers -------------------------------------------------------------------

def _anon_headers():
    return {"apikey": ANON_KEY, "Content-Type": "application/json"}

def _service_headers():
    return {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }

def _ok(label, r):
    if r.status_code in (200, 201):
        print(f"  [OK {r.status_code}] {label}")
        return True
    print(f"  [FAIL {r.status_code}] {label} — {r.text[:200]}")
    return False


# -- Step 1: sign in (returns token + user_id, or None) -----------------------

def sign_in(email, password):
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers=_anon_headers(),
        json={"email": email, "password": password},
    )
    if r.status_code == 200:
        data = r.json()
        return data["access_token"], data["user"]["id"]
    return None, None


# -- Step 2: admin-create user (email confirmed, no verification email) --------

def admin_create_user(email, password, role, full_name):
    """
    Uses the Supabase Admin API to create a user with email pre-confirmed.
    This bypasses email verification entirely — safe for test accounts.
    """
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=_service_headers(),
        json={
            "email": email,
            "password": password,
            "email_confirm": True,
            "user_metadata": {"role": role, "full_name": full_name},
        },
    )
    if r.status_code in (200, 201):
        user_id = r.json()["id"]
        print(f"  [CREATED] {email} (id={user_id})")
        return user_id
    print(f"  [FAIL] admin create {email}: {r.text[:300]}")
    return None


# -- Step 3: seed patient DB rows ----------------------------------------------

def _rest_get(table, params):
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/{table}",
        headers=_service_headers(),
        params=params,
    )
    return r.json() if r.status_code == 200 else []

def _rest_post(table, payload, label):
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/{table}",
        headers=_service_headers(),
        json=payload,
    )
    _ok(label, r)
    return r

def _rest_upsert(table, payload, on_conflict, label):
    headers = {**_service_headers(), "Prefer": f"return=representation,resolution=merge-duplicates"}
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/{table}",
        headers={**headers, "Prefer": f"return=representation,resolution=merge-duplicates"},
        params={"on_conflict": on_conflict},
        json=payload,
    )
    _ok(label, r)
    return r


def ensure_patient_rows(user_id, full_name):
    """
    Ensures the patient test account has:
      - profiles row  (id = user_id)
      - patient_profiles row  (profile_id = user_id)
    Returns the patient_profile_id (patient_profiles.id).
    """
    # -- profiles row ----------------------------------------------------------
    existing_profiles = _rest_get("profiles", {"id": f"eq.{user_id}", "select": "id"})
    if not existing_profiles:
        _rest_post(
            "profiles",
            {"id": user_id, "full_name": full_name, "role": "patient"},
            f"Insert profiles row for {user_id}",
        )
    else:
        print(f"  [EXISTS] profiles row for {user_id}")

    # -- patient_profiles row --------------------------------------------------
    existing_pp = _rest_get("patient_profiles", {"profile_id": f"eq.{user_id}", "select": "id"})
    if not existing_pp:
        r = _rest_post(
            "patient_profiles",
            {
                "profile_id": user_id,
                "mobility_level": "independent",
                "cognitive_state": "normal",
                "fall_detection_enabled": True,
                "checkin_time": "08:00",
                "checkin_frequency": 1,
                "medication_grace_mins": 30,
            },
            f"Insert patient_profiles row for {user_id}",
        )
        if r.status_code in (200, 201) and r.json():
            return r.json()[0]["id"]
        # Fetch after insert in case Prefer header didn't return body
        rows = _rest_get("patient_profiles", {"profile_id": f"eq.{user_id}", "select": "id"})
        return rows[0]["id"] if rows else None
    else:
        patient_profile_id = existing_pp[0]["id"]
        print(f"  [EXISTS] patient_profiles row — id={patient_profile_id}")
        return patient_profile_id


# -- Step 4: get or create an account -----------------------------------------

def get_or_create(email, password, role, full_name):
    print(f"\n{'-'*60}")
    print(f"  Account : {email}  (role={role})")

    # Try sign-in first
    token, user_id = sign_in(email, password)
    if token:
        print(f"  [SIGN IN OK] user_id={user_id}")
        return token, user_id

    # Account doesn't exist — create it
    print(f"  Sign-in failed — creating account via admin API...")
    user_id = admin_create_user(email, password, role, full_name)
    if not user_id:
        print(f"  FATAL: could not create {email}")
        sys.exit(1)

    # Sign in to get token
    token, uid = sign_in(email, password)
    if not token:
        print(f"  FATAL: created {email} but sign-in failed")
        sys.exit(1)

    print(f"  [SIGN IN OK] user_id={uid}")
    return token, uid


# -- Main ----------------------------------------------------------------------

def main():
    print("=" * 60)
    print("  MedBuddy Test Token Generator")
    print("=" * 60)

    # -- Patient ---------------------------------------------------------------
    patient_token, patient_uid = get_or_create(
        PATIENT_EMAIL, PATIENT_PASSWORD, "patient", PATIENT_NAME
    )
    print(f"  Seeding patient DB rows...")
    patient_profile_id = ensure_patient_rows(patient_uid, PATIENT_NAME)
    if not patient_profile_id:
        print("  WARNING: could not confirm patient_profiles row — "
              "check Supabase schema. Profile endpoints may fail.")

    # -- Caregiver -------------------------------------------------------------
    caregiver_token, caregiver_uid = get_or_create(
        CAREGIVER_EMAIL, CAREGIVER_PASSWORD, "caregiver", CAREGIVER_NAME
    )
    # Caregivers need no patient_profiles row — verify_jwt returns early for role=caregiver

    # -- Write .env.test -------------------------------------------------------
    env_content = (
        f"PATIENT_TOKEN={patient_token}\n"
        f"CAREGIVER_TOKEN={caregiver_token}\n"
        f"PATIENT_USER_ID={patient_uid}\n"
        f"CAREGIVER_USER_ID={caregiver_uid}\n"
    )
    if patient_profile_id:
        env_content += f"PATIENT_PROFILE_ID={patient_profile_id}\n"

    with open(ENV_FILE, "w") as f:
        f.write(env_content)

    print(f"\n{'=' * 60}")
    print(f"  Tokens written to: {ENV_FILE}")
    print(f"{'=' * 60}")
    print()
    print("  PATIENT_TOKEN (first 60 chars):")
    print(f"    {patient_token[:60]}...")
    print()
    print("  CAREGIVER_TOKEN (first 60 chars):")
    print(f"    {caregiver_token[:60]}...")
    print()
    print("  Ready. Run tests with:")
    print(f"    cd D:/projects-last-semester/MedBuddy")
    print(f"    C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe -m pytest tests/ -v")
    print()
    print("  Tokens expire in ~1 hour. Re-run this script to refresh.")
    print("=" * 60)


if __name__ == "__main__":
    main()
