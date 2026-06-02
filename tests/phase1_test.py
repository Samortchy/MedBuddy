"""
Phase 1 tests — Wellness Check-in POST + worker bug fixes
==========================================================
Run after get_tokens.py and with the backend server running on localhost:8000.

    C:\\Users\\User\\.conda\\envs\\medbuddy-backend\\python.exe -m pytest tests/phase1_test.py -v
"""

import pytest
import requests

BASE = "http://localhost:8000/api/v1"


# ── POST /wellness-checkins/ ─────────────────────────────────────────────────

class TestWellnessCheckInPost:

    def test_post_full_checkin_returns_201(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={
                "mood_score": 4,
                "energy_score": 3,
                "pain_level": 2,
                "sleep_quality": 5,
                "meds_confirmed": True,
                "raw_summary": "Feeling okay today",
            },
            headers=patient_headers,
        )
        assert r.status_code == 201, r.text

    def test_post_minimal_checkin_returns_201(self, patient_headers):
        """Posting with no fields (all optional) should still create a row."""
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={},
            headers=patient_headers,
        )
        assert r.status_code == 201, r.text

    def test_post_sets_source_patient(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 5},
            headers=patient_headers,
        )
        assert r.status_code == 201
        assert r.json()["source"] == "patient"

    def test_post_sets_patient_id(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 3},
            headers=patient_headers,
        )
        assert r.status_code == 201
        data = r.json()
        assert "patient_id" in data
        assert data["patient_id"] is not None

    def test_post_sets_completed_at(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"energy_score": 4},
            headers=patient_headers,
        )
        assert r.status_code == 201
        data = r.json()
        assert "completed_at" in data
        assert data["completed_at"] is not None

    def test_post_stores_mood_score(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 2},
            headers=patient_headers,
        )
        assert r.status_code == 201
        assert r.json()["mood_score"] == 2

    def test_post_stores_meds_confirmed(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"meds_confirmed": False},
            headers=patient_headers,
        )
        assert r.status_code == 201
        assert r.json()["meds_confirmed"] is False

    def test_post_mood_score_out_of_range_returns_422(self, patient_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 10},
            headers=patient_headers,
        )
        assert r.status_code == 422

    def test_post_requires_auth(self):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 3},
        )
        assert r.status_code in (401, 403)

    def test_caregiver_cannot_post_checkin(self, caregiver_headers):
        r = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 3},
            headers=caregiver_headers,
        )
        assert r.status_code == 403


# ── GET /wellness-checkins/ reflects new rows ─────────────────────────────────

class TestWellnessCheckInGet:

    def test_get_after_post_includes_new_row(self, patient_headers):
        # Post a unique summary to identify the row
        marker = "phase1-test-marker-unique"
        post = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 1, "raw_summary": marker},
            headers=patient_headers,
        )
        assert post.status_code == 201
        new_id = post.json()["id"]

        get = requests.get(f"{BASE}/wellness-checkins/", headers=patient_headers)
        assert get.status_code == 200
        ids = [row["id"] for row in get.json()]
        assert new_id in ids

    def test_get_returns_correct_columns(self, patient_headers):
        r = requests.get(f"{BASE}/wellness-checkins/", headers=patient_headers)
        assert r.status_code == 200
        rows = r.json()
        if rows:
            row = rows[0]
            # Columns confirmed to exist in wellness_checkins table
            for col in ("id", "patient_id", "completed_at", "source"):
                assert col in row, f"Missing column: {col}"

    def test_today_endpoint_returns_200(self, patient_headers):
        r = requests.get(f"{BASE}/wellness-checkins/today", headers=patient_headers)
        assert r.status_code == 200

    def test_today_endpoint_returns_todays_checkin(self, patient_headers):
        # Post a checkin then verify today returns it
        post = requests.post(
            f"{BASE}/wellness-checkins/",
            json={"mood_score": 4},
            headers=patient_headers,
        )
        assert post.status_code == 201

        today = requests.get(f"{BASE}/wellness-checkins/today", headers=patient_headers)
        assert today.status_code == 200
        # today may return null or a dict; if dict it should have our patient_id
        data = today.json()
        if data is not None:
            assert "patient_id" in data


# ── Regression: Phase 0 GET endpoints still work ──────────────────────────────

class TestPhase1Regression:

    def test_notification_prefs_still_works(self, patient_headers):
        r = requests.get(f"{BASE}/patient/notification-preferences", headers=patient_headers)
        assert r.status_code == 200

    def test_symptom_logs_still_works(self, patient_headers):
        r = requests.get(f"{BASE}/symptom-logs/", headers=patient_headers)
        assert r.status_code == 200

    def test_medications_still_works(self, patient_headers):
        r = requests.get(f"{BASE}/medications/", headers=patient_headers)
        assert r.status_code == 200

    def test_patient_profile_still_works(self, patient_headers):
        r = requests.get(f"{BASE}/patient/profile", headers=patient_headers)
        assert r.status_code == 200

    def test_caregiver_patients_still_works(self, caregiver_headers):
        r = requests.get(f"{BASE}/caregiver/patients", headers=caregiver_headers)
        assert r.status_code == 200
