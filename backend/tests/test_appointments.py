import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient


# ─────────────────────────────────────────────────────────────────────────────
# Run with: pytest tests/test_appointments.py -v
# ─────────────────────────────────────────────────────────────────────────────


PATIENT_PROFILE_ID = "00000000-0000-0000-0000-000000000002"
PROFILE_ID = "00000000-0000-0000-0000-000000000001"
APPOINTMENT_ID = "bbbbbbbb-0000-0000-0000-000000000001"
OTHER_PATIENT_ID = "99999999-0000-0000-0000-000000000099"

MOCK_APPOINTMENT = {
    "id": APPOINTMENT_ID,
    "patient_id": PATIENT_PROFILE_ID,
    "title": "Cardiology Checkup",
    "doctor_name": "Dr. Karim",
    "location": "Cairo Heart Center",
    "scheduled_at": "2026-05-20T10:00:00+00:00",
    "notes": None,
    "reminder_24h_sent": False,
    "reminder_1h_sent": False,
    "deleted_at": None,
    "created_at": "2026-05-16T09:00:00+00:00",
    "updated_at": "2026-05-16T09:00:00+00:00",
}


def get_mock_app():
    from fastapi import FastAPI
    from app.api.v1.appointments import router
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


# ─── GET /appointments ────────────────────────────────────────────────────────

class TestGetAppointments:

    def test_get_appointments_returns_list(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.gte.return_value.lte.return_value.execute.return_value.data = [
            MOCK_APPOINTMENT
        ]

        response = client.get("/appointments/")
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    def test_get_appointments_empty(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.gte.return_value.lte.return_value.execute.return_value.data = []

        response = client.get("/appointments/")
        assert response.status_code == 200
        assert response.json() == []


# ─── POST /appointments ───────────────────────────────────────────────────────

class TestCreateAppointment:

    def test_create_appointment_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = [
            MOCK_APPOINTMENT
        ]

        response = client.post("/appointments/", json={
            "title": "Cardiology Checkup",
            "doctor_name": "Dr. Karim",
            "location": "Cairo Heart Center",
            "scheduled_at": "2026-05-20T10:00:00+00:00",
        })

        assert response.status_code == 201
        assert response.json()["title"] == "Cardiology Checkup"

    def test_create_appointment_missing_title(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        response = client.post("/appointments/", json={
            "scheduled_at": "2026-05-20T10:00:00+00:00",
        })

        assert response.status_code == 422

    def test_create_appointment_missing_scheduled_at(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        response = client.post("/appointments/", json={
            "title": "Checkup",
        })

        assert response.status_code == 422

    def test_create_appointment_minimal_fields(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = [{
            **MOCK_APPOINTMENT,
            "doctor_name": None,
            "location": None,
        }]

        response = client.post("/appointments/", json={
            "title": "General Checkup",
            "scheduled_at": "2026-06-01T09:00:00+00:00",
        })

        assert response.status_code == 201


# ─── PATCH /appointments/{id} ─────────────────────────────────────────────────

class TestUpdateAppointment:

    def test_update_appointment_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        # Mock fetch existing
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_APPOINTMENT
        # Mock update
        updated = {**MOCK_APPOINTMENT, "doctor_name": "Dr. Hassan"}
        mock_db.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [updated]

        response = client.patch(f"/appointments/{APPOINTMENT_ID}", json={
            "doctor_name": "Dr. Hassan",
        })

        assert response.status_code == 200
        assert response.json()["doctor_name"] == "Dr. Hassan"

    def test_update_appointment_not_found(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.patch(f"/appointments/nonexistent-id", json={
            "title": "New Title",
        })

        assert response.status_code == 404

    def test_update_appointment_wrong_patient(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        # Appointment belongs to a different patient
        wrong_appointment = {**MOCK_APPOINTMENT, "patient_id": OTHER_PATIENT_ID}
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = wrong_appointment

        response = client.patch(f"/appointments/{APPOINTMENT_ID}", json={
            "title": "New Title",
        })

        assert response.status_code == 403

    def test_update_appointment_no_fields(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_APPOINTMENT

        response = client.patch(f"/appointments/{APPOINTMENT_ID}", json={})

        assert response.status_code == 400


# ─── DELETE /appointments/{id} ────────────────────────────────────────────────

class TestDeleteAppointment:

    def test_delete_appointment_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_APPOINTMENT
        mock_db.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [MOCK_APPOINTMENT]

        response = client.delete(f"/appointments/{APPOINTMENT_ID}")
        assert response.status_code == 204

    def test_delete_appointment_not_found(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.delete(f"/appointments/nonexistent-id")
        assert response.status_code == 404

    def test_delete_appointment_wrong_patient(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        wrong_appointment = {**MOCK_APPOINTMENT, "patient_id": OTHER_PATIENT_ID}
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = wrong_appointment

        response = client.delete(f"/appointments/{APPOINTMENT_ID}")
        assert response.status_code == 403