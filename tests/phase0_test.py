"""
Phase 0 — Critical Bug Fix Tests
=================================
Tests every fix made in Phase 0. Run after the backend is up.

Setup:
    pip install pytest requests

Usage:
    # Set your Supabase JWT token (patient role):
    set PATIENT_TOKEN=eyJ...
    # Set your Supabase JWT token (caregiver role):
    set CAREGIVER_TOKEN=eyJ...

    cd D:/projects-last-semester/MedBuddy
    pytest tests/phase0_test.py -v

All tests hit the real running backend at http://localhost:8000.
Start the backend first:
    cd backend && uvicorn app.main:app --reload
"""

import os
import pytest
import requests

BASE = "http://localhost:8000"
API  = f"{BASE}/api/v1"

PATIENT_TOKEN   = os.getenv("PATIENT_TOKEN", "")
CAREGIVER_TOKEN = os.getenv("CAREGIVER_TOKEN", "")


def patient_headers():
    if not PATIENT_TOKEN:
        pytest.skip("PATIENT_TOKEN env var not set")
    return {"Authorization": f"Bearer {PATIENT_TOKEN}"}


def caregiver_headers():
    if not CAREGIVER_TOKEN:
        pytest.skip("CAREGIVER_TOKEN env var not set")
    return {"Authorization": f"Bearer {CAREGIVER_TOKEN}"}


# ─────────────────────────────────────────────────────────────────────────────
# Sanity check
# ─────────────────────────────────────────────────────────────────────────────

class TestHealth:
    def test_health_endpoint(self):
        """Backend must be reachable and return ok."""
        r = requests.get(f"{BASE}/health")
        assert r.status_code == 200
        assert r.json()["status"] == "ok"


# ─────────────────────────────────────────────────────────────────────────────
# FIX 1 — notifications.py: sync Supabase + correct patient_id key
# ─────────────────────────────────────────────────────────────────────────────

class TestFix1_NotificationPreferences:
    """
    Before fix: used `await` on sync supabase calls + wrong `current_user["id"]` key.
    After fix : standard sync pattern, uses current_user["patient_profile_id"].
    """

    def test_get_notification_preferences_returns_200(self):
        """GET /patient/notification-preferences must not 500-crash."""
        r = requests.get(
            f"{API}/patient/notification-preferences",
            headers=patient_headers(),
        )
        assert r.status_code == 200, f"Expected 200, got {r.status_code}: {r.text}"

    def test_get_notification_preferences_shape(self):
        """Response must include all required fields."""
        r = requests.get(
            f"{API}/patient/notification-preferences",
            headers=patient_headers(),
        )
        assert r.status_code == 200
        data = r.json()
        for field in ("id", "patient_id", "channel", "language", "created_at", "updated_at"):
            assert field in data, f"Missing field: {field}"
        assert data["channel"] in ("push", "sms", "both")

    def test_patch_notification_preferences_channel(self):
        """PATCH must update channel and return updated row."""
        r = requests.patch(
            f"{API}/patient/notification-preferences",
            headers=patient_headers(),
            json={"channel": "push"},
        )
        assert r.status_code == 200, f"Expected 200, got {r.status_code}: {r.text}"
        assert r.json()["channel"] == "push"

    def test_patch_notification_preferences_no_fields_returns_422(self):
        """PATCH with no fields must return 422, not 500."""
        r = requests.patch(
            f"{API}/patient/notification-preferences",
            headers=patient_headers(),
            json={},
        )
        assert r.status_code == 422

    def test_patch_notification_preferences_language(self):
        """PATCH with valid language must succeed."""
        r = requests.patch(
            f"{API}/patient/notification-preferences",
            headers=patient_headers(),
            json={"language": "en", "channel": "both"},
        )
        assert r.status_code == 200
        assert r.json()["language"] == "en"

    def test_get_without_token_returns_401_or_403(self):
        """No auth must be rejected."""
        r = requests.get(f"{API}/patient/notification-preferences")
        assert r.status_code in (401, 403)


# ─────────────────────────────────────────────────────────────────────────────
# FIX 2 — caregiver_provider.dart: backend response shape verification
# ─────────────────────────────────────────────────────────────────────────────

class TestFix2_CaregiverPatientsShape:
    """
    Before fix (frontend): parsed response.data as List → TypeError crash.
    After fix (frontend): reads response.data['patients'] as List.
    These tests verify the BACKEND returns the correct shape so the fix is valid.
    """

    def test_caregiver_patients_returns_dict_not_list(self):
        """Backend must return {patients: [...], total: N}, NOT a bare list."""
        r = requests.get(
            f"{API}/caregiver/patients",
            headers=caregiver_headers(),
        )
        assert r.status_code == 200, f"Expected 200, got {r.status_code}: {r.text}"
        data = r.json()
        assert isinstance(data, dict), (
            f"Backend returned {type(data).__name__}, expected dict. "
            "Frontend fix assumes response.data is a dict with 'patients' key."
        )
        assert "patients" in data, "Response dict must have 'patients' key"
        assert "total" in data, "Response dict must have 'total' key"
        assert isinstance(data["patients"], list)
        assert isinstance(data["total"], int)

    def test_caregiver_patients_items_have_flat_fields(self):
        """Each patient item must have flat full_name and patient_profile_id fields."""
        r = requests.get(
            f"{API}/caregiver/patients",
            headers=caregiver_headers(),
        )
        assert r.status_code == 200
        patients = r.json()["patients"]
        for p in patients:
            # These are the fields LinkedPatient.fromJson now reads
            assert "patient_profile_id" in p, f"Missing patient_profile_id in {p}"
            assert "full_name" in p, f"Missing full_name in {p}"
            assert "linked_at" in p, f"Missing linked_at in {p}"

    def test_patient_cannot_access_caregiver_patients(self):
        """Patient token must be rejected from caregiver-only endpoint."""
        r = requests.get(
            f"{API}/caregiver/patients",
            headers=patient_headers(),
        )
        assert r.status_code == 403


# ─────────────────────────────────────────────────────────────────────────────
# FIX 3 — history_providers.dart: symptom log field name mismatch
# ─────────────────────────────────────────────────────────────────────────────

class TestFix3_SymptomLogs:
    """
    Before fix (frontend): POST sent {'description': ...} → backend returned 422.
    After fix (frontend): POST sends {'body': ..., 'input_type': 'text'}.
    Before fix (frontend): GET read m['description'], m['created_at'] → always null/crash.
    After fix (frontend): GET reads m['body'], m['logged_at'].
    """

    created_id = None  # shared across test methods

    def test_post_with_wrong_field_returns_422(self):
        """POST with 'description' field must fail — proves the bug was real."""
        r = requests.post(
            f"{API}/symptom-logs/",
            headers=patient_headers(),
            json={"description": "This is the broken payload the old frontend sent"},
        )
        assert r.status_code == 422, (
            f"Expected 422 for wrong field name, got {r.status_code}. "
            "If this is 201, the backend now accepts 'description' — update this test."
        )

    def test_post_with_correct_body_field_returns_201(self):
        """POST with 'body' field must succeed — proves the fix is correct."""
        r = requests.post(
            f"{API}/symptom-logs/",
            headers=patient_headers(),
            json={"body": "Phase 0 test: mild headache after lunch", "input_type": "text"},
        )
        assert r.status_code == 201, f"Expected 201, got {r.status_code}: {r.text}"
        data = r.json()
        assert data["body"] == "Phase 0 test: mild headache after lunch"
        assert data["input_type"] == "text"
        TestFix3_SymptomLogs.created_id = data["id"]

    def test_get_returns_body_not_description(self):
        """GET response items must have 'body' field, not 'description'."""
        r = requests.get(f"{API}/symptom-logs/", headers=patient_headers())
        assert r.status_code == 200
        items = r.json()
        if items:
            first = items[0]
            assert "body" in first, f"'body' not in response item: {first.keys()}"
            assert "description" not in first, "'description' should not be in response"

    def test_get_returns_logged_at_not_created_at(self):
        """GET response items must have 'logged_at' timestamp field."""
        r = requests.get(f"{API}/symptom-logs/", headers=patient_headers())
        assert r.status_code == 200
        items = r.json()
        if items:
            first = items[0]
            assert "logged_at" in first, f"'logged_at' not in response: {first.keys()}"

    def test_delete_created_log(self):
        """Cleanup: delete the symptom log created in this test."""
        if not TestFix3_SymptomLogs.created_id:
            pytest.skip("No symptom log was created to delete")
        r = requests.delete(
            f"{API}/symptom-logs/{TestFix3_SymptomLogs.created_id}",
            headers=patient_headers(),
        )
        assert r.status_code == 204


# ─────────────────────────────────────────────────────────────────────────────
# FIX 4 — history_providers.dart: wellness check-in timestamp field
# ─────────────────────────────────────────────────────────────────────────────

class TestFix4_WellnessCheckIns:
    """
    Before fix (frontend): read m['created_at'] → null → DateTime.parse crash.
    After fix (frontend): reads m['completed_at'].
    These tests verify the BACKEND returns completed_at so the fix is valid.
    """

    def test_get_wellness_checkins_returns_200(self):
        r = requests.get(f"{API}/wellness-checkins/", headers=patient_headers())
        assert r.status_code == 200

    def test_wellness_checkins_have_completed_at_not_created_at(self):
        """Each check-in item must have 'completed_at' (the field the fixed frontend reads)."""
        r = requests.get(f"{API}/wellness-checkins/", headers=patient_headers())
        assert r.status_code == 200
        items = r.json()
        if items:
            first = items[0]
            assert "completed_at" in first, (
                f"'completed_at' not in response: {list(first.keys())}. "
                "Frontend fix is reading the wrong field."
            )

    def test_wellness_today_returns_200_or_null(self):
        """GET /wellness-checkins/today must return 200 (data or null, never crash)."""
        r = requests.get(f"{API}/wellness-checkins/today", headers=patient_headers())
        assert r.status_code == 200


# ─────────────────────────────────────────────────────────────────────────────
# FIX 5 — history_providers.dart: emergency events field names
# ─────────────────────────────────────────────────────────────────────────────

class TestFix5_EmergencyEvents:
    """
    Before fix (frontend): read m['created_at'], m['steps'] → wrong/null values.
    After fix (frontend): reads m['triggered_at'], m['emergency_escalation_steps'].
    These tests verify the BACKEND returns those field names.
    """

    def test_get_emergency_events_returns_200(self):
        r = requests.get(f"{API}/emergency-events/", headers=patient_headers())
        assert r.status_code == 200

    def test_emergency_events_have_triggered_at(self):
        """Each event must have 'triggered_at' (the field the fixed frontend reads)."""
        r = requests.get(f"{API}/emergency-events/", headers=patient_headers())
        assert r.status_code == 200
        items = r.json()
        if items:
            first = items[0]
            assert "triggered_at" in first, (
                f"'triggered_at' not in event: {list(first.keys())}"
            )
            assert "created_at" not in first or "triggered_at" in first, (
                "Frontend now reads triggered_at — make sure this field is present"
            )

    def test_emergency_events_have_escalation_steps_key(self):
        """Each event must have 'emergency_escalation_steps' (not 'steps')."""
        r = requests.get(f"{API}/emergency-events/", headers=patient_headers())
        assert r.status_code == 200
        items = r.json()
        if items:
            first = items[0]
            assert "emergency_escalation_steps" in first, (
                f"'emergency_escalation_steps' not in event: {list(first.keys())}"
            )

    def test_emergency_events_steps_is_list(self):
        """emergency_escalation_steps must be a list (may be empty)."""
        r = requests.get(f"{API}/emergency-events/", headers=patient_headers())
        assert r.status_code == 200
        items = r.json()
        if items:
            steps = items[0].get("emergency_escalation_steps")
            assert isinstance(steps, list), f"Steps must be a list, got: {type(steps)}"


# ─────────────────────────────────────────────────────────────────────────────
# Regression guard — endpoints that were already working must still work
# ─────────────────────────────────────────────────────────────────────────────

class TestRegression:
    """Verify Phase 0 fixes didn't break existing working endpoints."""

    def test_medications_still_works(self):
        r = requests.get(f"{API}/medications/", headers=patient_headers())
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_appointments_still_works(self):
        r = requests.get(f"{API}/appointments/", headers=patient_headers())
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_patient_profile_still_works(self):
        r = requests.get(f"{API}/patient/profile", headers=patient_headers())
        assert r.status_code == 200
        data = r.json()
        assert "full_name" in data or "id" in data

    def test_emergency_contacts_still_works(self):
        r = requests.get(f"{API}/emergency-contacts/", headers=patient_headers())
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_health_conditions_still_works(self):
        r = requests.get(f"{API}/health-conditions/", headers=patient_headers())
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_dose_logs_still_works(self):
        from datetime import date
        today = date.today().isoformat()
        r = requests.get(
            f"{API}/dose-logs/",
            headers=patient_headers(),
            params={"date": today},
        )
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_visit_summaries_still_works(self):
        r = requests.get(f"{API}/visit-summaries/", headers=patient_headers())
        assert r.status_code == 200
        assert isinstance(r.json(), list)
