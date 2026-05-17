import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient


# ─────────────────────────────────────────────────────────────────────────────
# Covers tasks #17, #18, #19:
#   #17  GET  /patient/profile
#        PATCH /patient/profile
#   #18  POST /caregiver/invite
#        POST /caregiver/accept
#   #19  GET  /caregiver/patients
#
# Run with: pytest tests/test_caregiver.py -v
# ─────────────────────────────────────────────────────────────────────────────

PROFILE_ID = "00000000-0000-0000-0000-000000000001"
PATIENT_PROFILE_ID = "00000000-0000-0000-0000-000000000002"
CAREGIVER_PROFILE_ID = "00000000-0000-0000-0000-000000000003"
INVITE_ID = "cccccccc-0000-0000-0000-000000000001"
LINK_ID = "dddddddd-0000-0000-0000-000000000001"

MOCK_PATIENT_USER = {
    "profile_id": PROFILE_ID,
    "patient_profile_id": PATIENT_PROFILE_ID,
    "role": "patient",
}
MOCK_CAREGIVER_USER = {
    "profile_id": CAREGIVER_PROFILE_ID,
    "patient_profile_id": None,
    "role": "caregiver",
}

MOCK_PROFILE_ROW = {
    "id": PROFILE_ID,
    "full_name": "Ahmed Ali",
    "phone": "+20100000000",
    "date_of_birth": "1990-01-15",
    "avatar_url": None,
}

MOCK_PATIENT_PROFILE_ROW = {
    "id": PATIENT_PROFILE_ID,
    "profile_id": PROFILE_ID,
    "weight_kg": 75.0,
    "height_cm": 175.0,
    "blood_type": "O+",
    "allergies": None,
    "created_at": "2026-05-01T10:00:00+00:00",
    "updated_at": "2026-05-01T10:00:00+00:00",
    "profiles": MOCK_PROFILE_ROW,
}

MOCK_INVITE = {
    "id": INVITE_ID,
    "patient_id": PATIENT_PROFILE_ID,
    "code": "ABC123",
    "expires_at": "2099-12-31T23:59:59+00:00",
    "used": False,
    "used_by": None,
    "created_at": "2026-05-17T10:00:00+00:00",
}

MOCK_LINK = {
    "id": LINK_ID,
    "caregiver_id": CAREGIVER_PROFILE_ID,
    "patient_id": PATIENT_PROFILE_ID,
    "created_at": "2026-05-17T11:00:00+00:00",
}


# ═══════════════════════════════════════════════════════════════════════════════
# Task #17 — Patient Profile
# ═══════════════════════════════════════════════════════════════════════════════

def get_patient_profile_app():
    from fastapi import FastAPI
    from app.api.v1.patient_profile import router
    from app.core.dependencies import get_current_patient
    from app.core.database import get_db

    app = FastAPI()
    app.include_router(router)

    mock_db = MagicMock()
    app.dependency_overrides[get_db] = lambda: mock_db
    app.dependency_overrides[get_current_patient] = lambda: MOCK_PATIENT_USER

    return app, mock_db


class TestGetPatientProfile:

    def test_get_profile_success(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = (
            MOCK_PATIENT_PROFILE_ROW
        )

        response = client.get("/patient/profile")
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Ahmed Ali"
        assert data["blood_type"] == "O+"
        assert data["weight_kg"] == 75.0

    def test_get_profile_not_found(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.get("/patient/profile")
        assert response.status_code == 404

    def test_get_profile_flattens_nested_profiles(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = (
            MOCK_PATIENT_PROFILE_ROW
        )

        response = client.get("/patient/profile")
        assert response.status_code == 200
        data = response.json()
        # profiles key should be merged into root, not nested
        assert "profiles" not in data
        assert "full_name" in data


class TestUpdatePatientProfile:

    def test_update_profile_fields_success(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        updated_row = {
            **MOCK_PATIENT_PROFILE_ROW,
            "profiles": {**MOCK_PROFILE_ROW, "full_name": "Ahmed Hassan"},
        }
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = updated_row

        response = client.patch("/patient/profile", json={"full_name": "Ahmed Hassan"})
        assert response.status_code == 200
        assert response.json()["full_name"] == "Ahmed Hassan"

    def test_update_patient_fields_success(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        updated_row = {**MOCK_PATIENT_PROFILE_ROW, "weight_kg": 80.0}
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = updated_row

        response = client.patch("/patient/profile", json={"weight_kg": 80.0})
        assert response.status_code == 200
        assert response.json()["weight_kg"] == 80.0

    def test_update_no_fields_returns_400(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        response = client.patch("/patient/profile", json={})
        assert response.status_code == 400

    def test_update_invalid_weight_returns_422(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        response = client.patch("/patient/profile", json={"weight_kg": -10})
        assert response.status_code == 422

    def test_update_multiple_fields(self):
        app, mock_db = get_patient_profile_app()
        client = TestClient(app)

        updated_row = {
            **MOCK_PATIENT_PROFILE_ROW,
            "weight_kg": 78.0,
            "blood_type": "A+",
            "profiles": {**MOCK_PROFILE_ROW, "phone": "+20111111111"},
        }
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = updated_row

        response = client.patch("/patient/profile", json={
            "phone": "+20111111111",
            "weight_kg": 78.0,
            "blood_type": "A+",
        })
        assert response.status_code == 200


# ═══════════════════════════════════════════════════════════════════════════════
# Task #18 — Caregiver Invite & Accept
# ═══════════════════════════════════════════════════════════════════════════════

def get_caregiver_app():
    from fastapi import FastAPI
    from app.api.v1.caregiver import router
    from app.core.dependencies import get_current_patient, get_current_user, get_current_caregiver
    from app.core.database import get_db

    app = FastAPI()
    app.include_router(router)

    mock_db = MagicMock()
    app.dependency_overrides[get_db] = lambda: mock_db
    app.dependency_overrides[get_current_patient] = lambda: MOCK_PATIENT_USER
    app.dependency_overrides[get_current_user] = lambda: MOCK_CAREGIVER_USER
    app.dependency_overrides[get_current_caregiver] = lambda: MOCK_CAREGIVER_USER

    return app, mock_db


class TestCreateCaregiverInvite:

    def test_invite_created_successfully(self):
        app, mock_db = get_caregiver_app()
        # Override to patient for this endpoint
        from app.core.dependencies import get_current_patient
        app.dependency_overrides[get_current_patient] = lambda: MOCK_PATIENT_USER

        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = [MOCK_INVITE]

        response = client.post("/caregiver/invite")
        assert response.status_code == 201
        data = response.json()
        assert "code" in data
        assert len(data["code"]) == 6
        assert data["patient_id"] == PATIENT_PROFILE_ID

    def test_invite_db_failure_returns_500(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = []

        response = client.post("/caregiver/invite")
        assert response.status_code == 500

    def test_invite_returns_expires_at(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = [MOCK_INVITE]

        response = client.post("/caregiver/invite")
        assert response.status_code == 201
        assert "expires_at" in response.json()


class TestAcceptCaregiverInvite:

    def test_accept_invite_success(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        # Step 1: find invite
        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = MOCK_INVITE
        # Step 2: no existing link
        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        # Step 3: insert link
        mock_db.table.return_value.insert.return_value.execute.return_value.data = [MOCK_LINK]

        response = client.post("/caregiver/accept", json={"code": "ABC123"})
        assert response.status_code == 200
        data = response.json()
        assert data["caregiver_id"] == CAREGIVER_PROFILE_ID
        assert data["patient_id"] == PATIENT_PROFILE_ID

    def test_accept_invite_not_found(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.post("/caregiver/accept", json={"code": "XXXXXX"})
        assert response.status_code == 404

    def test_accept_invite_expired(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        expired_invite = {**MOCK_INVITE, "expires_at": "2020-01-01T00:00:00+00:00"}
        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = expired_invite

        response = client.post("/caregiver/accept", json={"code": "ABC123"})
        assert response.status_code == 400
        assert "expired" in response.json()["detail"].lower()

    def test_accept_invite_already_linked(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = MOCK_INVITE
        # Caregiver already linked to this patient
        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [MOCK_LINK]

        response = client.post("/caregiver/accept", json={"code": "ABC123"})
        assert response.status_code == 409

    def test_accept_invite_invalid_code_length(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        response = client.post("/caregiver/accept", json={"code": "AB"})
        assert response.status_code == 422

    def test_accept_invite_missing_code(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        response = client.post("/caregiver/accept", json={})
        assert response.status_code == 422

    def test_accept_invite_link_db_failure(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = MOCK_INVITE
        mock_db.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        mock_db.table.return_value.insert.return_value.execute.return_value.data = []

        response = client.post("/caregiver/accept", json={"code": "ABC123"})
        assert response.status_code == 500


# ═══════════════════════════════════════════════════════════════════════════════
# Task #19 — Caregiver Dashboard
# ═══════════════════════════════════════════════════════════════════════════════

class TestGetCaregiverPatients:

    def test_get_patients_success(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {
                "id": LINK_ID,
                "caregiver_id": CAREGIVER_PROFILE_ID,
                "patient_id": PATIENT_PROFILE_ID,
                "created_at": "2026-05-17T11:00:00+00:00",
                "patient_profiles": {
                    "id": PATIENT_PROFILE_ID,
                    "profiles": {
                        "full_name": "Ahmed Ali",
                        "phone": "+20100000000",
                        "date_of_birth": "1990-01-15",
                    },
                },
            }
        ]

        response = client.get("/caregiver/patients")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["patients"]) == 1
        assert data["patients"][0]["full_name"] == "Ahmed Ali"
        assert data["patients"][0]["patient_profile_id"] == PATIENT_PROFILE_ID

    def test_get_patients_empty(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = []

        response = client.get("/caregiver/patients")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert data["patients"] == []

    def test_get_patients_multiple(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        PATIENT_2_ID = "00000000-0000-0000-0000-000000000099"
        mock_db.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {
                "id": LINK_ID,
                "caregiver_id": CAREGIVER_PROFILE_ID,
                "patient_id": PATIENT_PROFILE_ID,
                "created_at": "2026-05-17T11:00:00+00:00",
                "patient_profiles": {
                    "id": PATIENT_PROFILE_ID,
                    "profiles": {"full_name": "Ahmed Ali", "phone": None, "date_of_birth": None},
                },
            },
            {
                "id": "eeeeeeee-0000-0000-0000-000000000001",
                "caregiver_id": CAREGIVER_PROFILE_ID,
                "patient_id": PATIENT_2_ID,
                "created_at": "2026-05-16T08:00:00+00:00",
                "patient_profiles": {
                    "id": PATIENT_2_ID,
                    "profiles": {"full_name": "Sara Mohamed", "phone": "+20111111111", "date_of_birth": "1985-06-20"},
                },
            },
        ]

        response = client.get("/caregiver/patients")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        names = [p["full_name"] for p in data["patients"]]
        assert "Ahmed Ali" in names
        assert "Sara Mohamed" in names

    def test_get_patients_null_profile_fields(self):
        app, mock_db = get_caregiver_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {
                "id": LINK_ID,
                "caregiver_id": CAREGIVER_PROFILE_ID,
                "patient_id": PATIENT_PROFILE_ID,
                "created_at": "2026-05-17T11:00:00+00:00",
                "patient_profiles": {
                    "id": PATIENT_PROFILE_ID,
                    "profiles": None,
                },
            }
        ]

        response = client.get("/caregiver/patients")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        # Null profile gracefully returns None fields
        assert data["patients"][0]["full_name"] is None
