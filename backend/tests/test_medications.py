import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
from datetime import date, datetime, timezone, timedelta


# ─────────────────────────────────────────────────────────────────────────────
# Run with: pytest tests/test_medications.py -v
# ─────────────────────────────────────────────────────────────────────────────

PATIENT_PROFILE_ID = "00000000-0000-0000-0000-000000000002"
PROFILE_ID = "00000000-0000-0000-0000-000000000001"
MEDICATION_ID = "aaaaaaaa-0000-0000-0000-000000000001"
OTHER_PATIENT_ID = "99999999-0000-0000-0000-000000000099"

MOCK_SCHEDULE = {"id": "sched-1", "medication_id": MEDICATION_ID, "time_of_day": "08:00"}

MOCK_MEDICATION = {
    "id": MEDICATION_ID,
    "patient_id": PATIENT_PROFILE_ID,
    "name": "Metformin",
    "dose_amount": 500.0,
    "dose_unit": "mg",
    "form": "tablet",
    "instructions": "Take with food",
    "start_date": "2026-05-01",
    "end_date": None,
    "deleted_at": None,
    "created_at": "2026-05-01T08:00:00+00:00",
    "updated_at": None,
}

MOCK_MEDICATION_WITH_SCHEDULES = {
    **MOCK_MEDICATION,
    "medication_schedules": [MOCK_SCHEDULE],
}

VALID_CREATE_PAYLOAD = {
    "name": "Metformin",
    "dose_amount": 500,
    "dose_unit": "mg",
    "form": "tablet",
    "instructions": "Take with food",
    "start_date": "2026-05-01",
    "schedules": [{"time_of_day": "08:00"}],
}


def get_mock_app():
    from fastapi import FastAPI
    from app.api.v1.medications import router
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


# ─── GET /medications ─────────────────────────────────────────────────────────

class TestGetMedications:

    def test_returns_list(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.execute.return_value.data = [
            MOCK_MEDICATION_WITH_SCHEDULES
        ]

        response = client.get("/medications/")
        assert response.status_code == 200
        assert isinstance(response.json(), list)
        assert response.json()[0]["name"] == "Metformin"

    def test_returns_empty_list(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.execute.return_value.data = []

        response = client.get("/medications/")
        assert response.status_code == 200
        assert response.json() == []


# ─── POST /medications ────────────────────────────────────────────────────────

class TestCreateMedication:

    def test_create_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = [MOCK_MEDICATION]
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = MOCK_MEDICATION_WITH_SCHEDULES

        with patch("app.api.v1.medications.generate_doses_for_patient", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = 7
            response = client.post("/medications/", json=VALID_CREATE_PAYLOAD)

        assert response.status_code == 201
        assert response.json()["name"] == "Metformin"
        mock_gen.assert_awaited_once()

    def test_create_missing_name(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        payload = {**VALID_CREATE_PAYLOAD}
        del payload["name"]
        response = client.post("/medications/", json=payload)
        assert response.status_code == 422

    def test_create_missing_schedules(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        payload = {**VALID_CREATE_PAYLOAD, "schedules": []}
        response = client.post("/medications/", json=payload)
        assert response.status_code == 422

    def test_create_invalid_schedule_format(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        payload = {**VALID_CREATE_PAYLOAD, "schedules": [{"time_of_day": "8:00 AM"}]}
        response = client.post("/medications/", json=payload)
        assert response.status_code == 422

    def test_create_invalid_dose_unit(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        payload = {**VALID_CREATE_PAYLOAD, "dose_unit": "spoon"}
        response = client.post("/medications/", json=payload)
        assert response.status_code == 422

    def test_create_negative_dose_amount(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        payload = {**VALID_CREATE_PAYLOAD, "dose_amount": -10}
        response = client.post("/medications/", json=payload)
        assert response.status_code == 422

    def test_create_db_failure(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = None

        response = client.post("/medications/", json=VALID_CREATE_PAYLOAD)
        assert response.status_code == 500

    def test_create_multiple_schedules(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.insert.return_value.execute.return_value.data = [MOCK_MEDICATION]
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            **MOCK_MEDICATION_WITH_SCHEDULES,
            "medication_schedules": [
                {"time_of_day": "08:00"},
                {"time_of_day": "20:00"},
            ],
        }

        with patch("app.api.v1.medications.generate_doses_for_patient", new_callable=AsyncMock):
            response = client.post("/medications/", json={
                **VALID_CREATE_PAYLOAD,
                "schedules": [{"time_of_day": "08:00"}, {"time_of_day": "20:00"}],
            })

        assert response.status_code == 201
        assert len(response.json()["medication_schedules"]) == 2


# ─── PATCH /medications/{id} ──────────────────────────────────────────────────

class TestUpdateMedication:

    def test_update_name_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_MEDICATION
        updated = {**MOCK_MEDICATION_WITH_SCHEDULES, "name": "Metformin XR"}
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = updated

        response = client.patch(f"/medications/{MEDICATION_ID}", json={"name": "Metformin XR"})
        assert response.status_code == 200

    def test_update_not_found(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.patch(f"/medications/nonexistent-id", json={"name": "X"})
        assert response.status_code == 404

    def test_update_wrong_patient(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        wrong_med = {**MOCK_MEDICATION, "patient_id": OTHER_PATIENT_ID}
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = wrong_med

        response = client.patch(f"/medications/{MEDICATION_ID}", json={"name": "X"})
        assert response.status_code == 403

    def test_update_no_fields(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_MEDICATION

        response = client.patch(f"/medications/{MEDICATION_ID}", json={})
        assert response.status_code == 400

    def test_update_schedules_triggers_regeneration(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_MEDICATION
        mock_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = MOCK_MEDICATION_WITH_SCHEDULES

        with patch("app.api.v1.medications.generate_doses_for_patient", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = 5
            response = client.patch(f"/medications/{MEDICATION_ID}", json={
                "schedules": [{"time_of_day": "09:00"}]
            })

        mock_gen.assert_awaited_once()


# ─── DELETE /medications/{id} ─────────────────────────────────────────────────

class TestDeleteMedication:

    def test_delete_success(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = MOCK_MEDICATION
        mock_db.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [MOCK_MEDICATION]

        response = client.delete(f"/medications/{MEDICATION_ID}")
        assert response.status_code == 204

    def test_delete_not_found(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.delete(f"/medications/nonexistent-id")
        assert response.status_code == 404

    def test_delete_wrong_patient(self):
        app, mock_db = get_mock_app()
        client = TestClient(app)

        wrong_med = {**MOCK_MEDICATION, "patient_id": OTHER_PATIENT_ID}
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = wrong_med

        response = client.delete(f"/medications/{MEDICATION_ID}")
        assert response.status_code == 403


# ─── generate_doses_for_patient (service unit tests) ─────────────────────────

class TestGenerateDosesForPatient:

    @pytest.mark.asyncio
    async def test_no_medications_returns_zero(self):
        from app.services.medication_service import generate_doses_for_patient

        mock_db = MagicMock()
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.execute.return_value.data = []

        result = await generate_doses_for_patient(PATIENT_PROFILE_ID, mock_db)
        assert result == 0

    @pytest.mark.asyncio
    async def test_medication_with_no_schedules_skipped(self):
        from app.services.medication_service import generate_doses_for_patient

        mock_db = MagicMock()
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.execute.return_value.data = [
            {
                "id": MEDICATION_ID,
                "start_date": "2026-05-01",
                "end_date": None,
                "medication_schedules": [],
            }
        ]

        result = await generate_doses_for_patient(PATIENT_PROFILE_ID, mock_db)
        assert result == 0

    @pytest.mark.asyncio
    async def test_generates_doses_for_7_days(self):
        from app.services.medication_service import generate_doses_for_patient

        mock_db = MagicMock()
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.execute.return_value.data = [
            {
                "id": MEDICATION_ID,
                "start_date": "2026-01-01",
                "end_date": None,
                "medication_schedules": [{"time_of_day": "08:00"}],
            }
        ]
        mock_db.table.return_value.upsert.return_value.execute.return_value.data = [
            {"id": f"dose-{i}"} for i in range(7)
        ]

        result = await generate_doses_for_patient(PATIENT_PROFILE_ID, mock_db, days_ahead=7)
        assert result == 7

        # Verify upsert was called with ignore_duplicates
        upsert_call = mock_db.table.return_value.upsert.call_args
        assert upsert_call.kwargs.get("ignore_duplicates") is True
        assert "medication_id" in upsert_call.kwargs.get("on_conflict", "")

    @pytest.mark.asyncio
    async def test_respects_end_date(self):
        from app.services.medication_service import generate_doses_for_patient

        now = datetime.now(timezone.utc)
        end_date = (now + timedelta(days=2)).date()

        mock_db = MagicMock()
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.execute.return_value.data = [
            {
                "id": MEDICATION_ID,
                "start_date": "2026-01-01",
                "end_date": end_date.isoformat(),
                "medication_schedules": [{"time_of_day": "08:00"}],
            }
        ]

        inserted_rows = []

        def capture_upsert(rows, **kwargs):
            inserted_rows.extend(rows)
            mock_result = MagicMock()
            mock_result.execute.return_value.data = rows
            return mock_result

        mock_db.table.return_value.upsert.side_effect = capture_upsert

        await generate_doses_for_patient(PATIENT_PROFILE_ID, mock_db, days_ahead=7)

        for row in inserted_rows:
            scheduled = datetime.fromisoformat(row["scheduled_at"])
            assert scheduled.date() <= end_date

    @pytest.mark.asyncio
    async def test_all_inserted_doses_are_pending(self):
        from app.services.medication_service import generate_doses_for_patient

        mock_db = MagicMock()
        mock_db.table.return_value.select.return_value.eq.return_value.is_.return_value.execute.return_value.data = [
            {
                "id": MEDICATION_ID,
                "start_date": "2026-01-01",
                "end_date": None,
                "medication_schedules": [{"time_of_day": "08:00"}],
            }
        ]

        inserted_rows = []

        def capture_upsert(rows, **kwargs):
            inserted_rows.extend(rows)
            mock_result = MagicMock()
            mock_result.execute.return_value.data = rows
            return mock_result

        mock_db.table.return_value.upsert.side_effect = capture_upsert

        await generate_doses_for_patient(PATIENT_PROFILE_ID, mock_db, days_ahead=3)

        assert all(row["status"] == "pending" for row in inserted_rows)
