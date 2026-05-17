import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient


# ─────────────────────────────────────────────────────────────────────────────
# These tests use mocking so you don't need a real Supabase connection to run.
# Run with: pytest tests/test_dose_logs.py -v
# ─────────────────────────────────────────────────────────────────────────────


PATIENT_PROFILE_ID = "00000000-0000-0000-0000-000000000002"
PROFILE_ID = "00000000-0000-0000-0000-000000000001"
DOSE_ID = "aaaaaaaa-0000-0000-0000-000000000001"
OTHER_PATIENT_ID = "99999999-0000-0000-0000-000000000099"


def get_mock_app():
    """Create a test app with mocked dependencies."""
    from fastapi import FastAPI
    from app.api.v1.dose_logs import router
    from app.core.dependencies import get_current_patient
    from app.core.database import get_db

    app = FastAPI()
    app.include_router(router)

    mock_db = MagicMock()
    mock_user = {
        "profile_id": PROFILE_ID,
        "patient_profile_id": PATIENT_PROFILE_ID,
        "role": "patient",
    }

    app.dependency_overrides[get_db] = lambda: mock_db
    app.dependency_overrides[get_current_patient] = lambda: mock_user

    return app, mock_db


# ─── POST /dose-logs ──────────────────────────────────────────────────────────

class TestCreateDoseLog:

    def test_create_dose_log_taken_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        # Mock dose ownership check
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": DOSE_ID,
            "medication_id": "med-001",
            "medications": {"patient_id": PATIENT_PROFILE_ID},
        }

        # Mock insert
        mock_db.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": "log-001",
            "dose_id": DOSE_ID,
            "status": "taken",
            "actioned_at": "2026-05-16T09:00:00+00:00",
            "noted_by": PROFILE_ID,
            "notes": None,
        }]

        response = client.post("/dose-logs/", json={
            "dose_id": DOSE_ID,
            "status": "taken",
        })

        assert response.status_code == 201
        assert response.json()["status"] == "taken"
        assert response.json()["dose_id"] == DOSE_ID

    def test_create_dose_log_invalid_status(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        response = client.post("/dose-logs/", json={
            "dose_id": DOSE_ID,
            "status": "invalid_status",
        })

        assert response.status_code == 422  # Pydantic validation error

    def test_create_dose_log_dose_not_found(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        # Mock dose not found
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.post("/dose-logs/", json={
            "dose_id": "nonexistent-dose-id",
            "status": "taken",
        })

        assert response.status_code == 404

    def test_create_dose_log_wrong_patient(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        # Mock dose belonging to a different patient
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": DOSE_ID,
            "medication_id": "med-001",
            "medications": {"patient_id": OTHER_PATIENT_ID},  # different patient!
        }

        response = client.post("/dose-logs/", json={
            "dose_id": DOSE_ID,
            "status": "taken",
        })

        assert response.status_code == 403

    def test_create_dose_log_with_notes(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": DOSE_ID,
            "medications": {"patient_id": PATIENT_PROFILE_ID},
        }
        mock_db.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": "log-002",
            "dose_id": DOSE_ID,
            "status": "skipped",
            "actioned_at": "2026-05-16T09:00:00+00:00",
            "noted_by": PROFILE_ID,
            "notes": "Felt nauseous",
        }]

        response = client.post("/dose-logs/", json={
            "dose_id": DOSE_ID,
            "status": "skipped",
            "notes": "Felt nauseous",
        })

        assert response.status_code == 201
        assert response.json()["notes"] == "Felt nauseous"


# ─── GET /dose-logs ───────────────────────────────────────────────────────────

class TestGetDoseLogs:

    def test_get_dose_logs_today(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.gte.return_value.lte.return_value.execute.return_value.data = [
            {
                "id": "log-001",
                "dose_id": DOSE_ID,
                "status": "taken",
                "actioned_at": "2026-05-16T08:02:00+00:00",
                "noted_by": PROFILE_ID,
                "notes": None,
                "medication_doses": {
                    "scheduled_at": "2026-05-16T08:00:00+00:00",
                    "medication_id": "med-001",
                    "medications": {
                        "name": "Metformin 500mg",
                        "dose_amount": 500,
                        "dose_unit": "mg",
                        "patient_id": PATIENT_PROFILE_ID,
                    }
                }
            }
        ]

        response = client.get("/dose-logs/")
        assert response.status_code == 200
        assert "dose_logs" in response.json()
        assert "date" in response.json()

    def test_get_dose_logs_specific_date(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.gte.return_value.lte.return_value.execute.return_value.data = []

        response = client.get("/dose-logs/?date=2026-05-10")
        assert response.status_code == 200
        assert response.json()["date"] == "2026-05-10"

    def test_get_dose_logs_invalid_date_format(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        response = client.get("/dose-logs/?date=not-a-date")
        assert response.status_code == 422