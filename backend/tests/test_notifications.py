"""
Comprehensive test suite for the notification stack:

  * app/models/notification.py
  * app/services/notification_service.py
  * app/workers/scheduler.py
  * app/workers/reminder_worker.py

External systems (Firebase, Supabase) are fully mocked — no network calls.
"""

import json
import os
import sys
import tempfile
import types
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# ---------------------------------------------------------------------------
# Stub app.core.config / app.core.database BEFORE importing modules under test.
# Ahmed owns the real implementations; in isolation these stubs let the
# notification tests import cleanly.
# ---------------------------------------------------------------------------

if "app.core.config" not in sys.modules or not getattr(
    sys.modules.get("app.core.config"), "settings", None
):
    _config_mod = types.ModuleType("app.core.config")

    class _Settings:
        FIREBASE_CREDENTIALS_JSON = json.dumps(
            {
                "type": "service_account",
                "project_id": "fake-project",
                "private_key_id": "x",
                "private_key": "x",
                "client_email": "x@x.iam.gserviceaccount.com",
                "client_id": "1",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
            }
        )
        SUPABASE_URL = "http://localhost"
        SUPABASE_KEY = "test-key"

    _config_mod.settings = _Settings()
    sys.modules["app.core.config"] = _config_mod


if "app.core.database" not in sys.modules or not hasattr(
    sys.modules.get("app.core.database"), "get_db"
):
    _db_mod = types.ModuleType("app.core.database")

    async def _get_db():  # pragma: no cover - replaced per-test
        yield None

    _db_mod.get_db = _get_db
    sys.modules["app.core.database"] = _db_mod


from app.models.notification import (  # noqa: E402
    AppointmentReminderContext,
    MedicationReminderContext,
    PushPayload,
    PushResult,
)
from app.services import notification_service  # noqa: E402
from app.workers import reminder_worker  # noqa: E402
from app.workers import scheduler as scheduler_module  # noqa: E402


# ===========================================================================
# Helpers
# ===========================================================================


def _make_async_db(rows_by_table: dict[str, list[list[dict]]]):
    """
    Build a mock async Supabase client. `rows_by_table` maps table name to a
    list of batches; each call to db.table(name)...execute() pops one batch.
    """
    counters: dict[str, int] = {name: 0 for name in rows_by_table}
    captured_calls: dict[str, list[dict]] = {name: [] for name in rows_by_table}

    def table(name: str):
        record: dict = {"select": None, "gte": [], "lt": [], "eq": [], "neq": []}

        builder = MagicMock()

        def _select(cols):
            record["select"] = cols
            return builder

        def _gte(col, val):
            record["gte"].append((col, val))
            return builder

        def _lt(col, val):
            record["lt"].append((col, val))
            return builder

        def _eq(col, val):
            record["eq"].append((col, val))
            return builder

        def _neq(col, val):
            record["neq"].append((col, val))
            return builder

        builder.select.side_effect = _select
        builder.gte.side_effect = _gte
        builder.lt.side_effect = _lt
        builder.eq.side_effect = _eq
        builder.neq.side_effect = _neq

        async def execute():
            idx = counters[name]
            batches = rows_by_table[name]
            data = batches[idx] if idx < len(batches) else []
            counters[name] = idx + 1
            captured_calls[name].append(record)
            res = MagicMock()
            res.data = data
            return res

        builder.execute = execute
        return builder

    db = MagicMock()
    db.table = table
    db._captured_calls = captured_calls
    db._counters = counters
    return db


def _patch_get_db(db):
    """Patch reminder_worker.get_db to yield the supplied db mock once."""

    async def _gen():
        yield db

    return patch.object(reminder_worker, "get_db", _gen)


# ===========================================================================
# Section 1 — app/models/notification.py
# ===========================================================================


class TestPushPayload:
    def test_defaults_empty_data(self):
        p = PushPayload(device_token="t", title="hi", body="there")
        assert p.data == {}

    def test_accepts_string_data(self):
        p = PushPayload(
            device_token="t",
            title="hi",
            body="there",
            data={"type": "x", "id": "1"},
        )
        assert p.data == {"type": "x", "id": "1"}

    def test_round_trip_via_dict(self):
        p = PushPayload(device_token="t", title="hi", body="b", data={"k": "v"})
        d = p.model_dump()
        p2 = PushPayload.model_validate(d)
        assert p2 == p

    def test_missing_required_field_raises(self):
        with pytest.raises(Exception):
            PushPayload(title="hi", body="b")  # type: ignore[call-arg]


class TestPushResult:
    def test_success_with_message_id(self):
        r = PushResult(success=True, message_id="abc")
        assert r.success is True
        assert r.message_id == "abc"
        assert r.error is None

    def test_failure_with_error(self):
        r = PushResult(success=False, error="boom")
        assert r.success is False
        assert r.message_id is None
        assert r.error == "boom"

    def test_defaults_optional_fields_to_none(self):
        r = PushResult(success=True)
        assert r.message_id is None
        assert r.error is None


class TestReminderContextSchemas:
    def test_medication_context_fields(self):
        when = datetime(2030, 1, 1, 8, 30, tzinfo=timezone.utc)
        ctx = MedicationReminderContext(
            patient_id="p1",
            medication_name="Aspirin",
            dose_scheduled_at=when,
            device_token="tok",
        )
        assert ctx.patient_id == "p1"
        assert ctx.medication_name == "Aspirin"
        assert ctx.dose_scheduled_at == when
        assert ctx.device_token == "tok"

    def test_appointment_context_fields(self):
        when = datetime(2030, 1, 1, 9, 0, tzinfo=timezone.utc)
        ctx = AppointmentReminderContext(
            patient_id="p1",
            appointment_title="Cardiology",
            appointment_at=when,
            device_token="tok",
        )
        assert ctx.appointment_title == "Cardiology"
        assert ctx.appointment_at == when


# ===========================================================================
# Section 2 — app/services/notification_service.py
# ===========================================================================


class TestLoadCredentials:
    def test_loads_from_file_path(self):
        cred_payload = {
            "type": "service_account",
            "project_id": "p",
            "private_key_id": "k",
            "private_key": "x",
            "client_email": "x@x.iam.gserviceaccount.com",
            "client_id": "1",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
        }
        with tempfile.NamedTemporaryFile(
            "w", suffix=".json", delete=False
        ) as fh:
            json.dump(cred_payload, fh)
            path = fh.name

        try:
            with patch.object(
                notification_service.settings,
                "FIREBASE_CREDENTIALS_JSON",
                path,
            ), patch.object(
                notification_service.credentials,
                "Certificate",
                return_value="CERT_FROM_PATH",
            ) as mock_cert:
                result = notification_service._load_credentials()
            mock_cert.assert_called_once_with(path)
            assert result == "CERT_FROM_PATH"
        finally:
            os.unlink(path)

    def test_loads_from_json_string(self):
        cred_payload = {"type": "service_account", "project_id": "p"}
        with patch.object(
            notification_service.settings,
            "FIREBASE_CREDENTIALS_JSON",
            json.dumps(cred_payload),
        ), patch.object(
            notification_service.credentials,
            "Certificate",
            return_value="CERT_FROM_DICT",
        ) as mock_cert:
            result = notification_service._load_credentials()
        mock_cert.assert_called_once_with(cred_payload)
        assert result == "CERT_FROM_DICT"

    def test_invalid_json_raises(self):
        with patch.object(
            notification_service.settings,
            "FIREBASE_CREDENTIALS_JSON",
            "not-json-and-not-a-path",
        ):
            with pytest.raises(json.JSONDecodeError):
                notification_service._load_credentials()


class TestEnsureInitialized:
    def test_skips_when_app_already_initialized(self):
        with patch.object(
            notification_service.firebase_admin, "get_app", return_value=MagicMock()
        ), patch.object(
            notification_service.firebase_admin, "initialize_app"
        ) as mock_init:
            notification_service._ensure_initialized()
        mock_init.assert_not_called()

    def test_initializes_when_no_app(self):
        with patch.object(
            notification_service.firebase_admin,
            "get_app",
            side_effect=ValueError("no app"),
        ), patch.object(
            notification_service, "_load_credentials", return_value="CERT"
        ), patch.object(
            notification_service.firebase_admin, "initialize_app"
        ) as mock_init:
            notification_service._ensure_initialized()
        mock_init.assert_called_once_with("CERT")


class TestSendPush:
    @pytest.mark.asyncio
    async def test_send_push_success(self):
        with patch.object(
            notification_service, "_ensure_initialized", lambda: None
        ), patch.object(
            notification_service.messaging, "send", return_value="msg-1"
        ) as mock_send:
            result = await notification_service.send_push(
                device_token="tok",
                title="T",
                body="B",
                data={"k": "v"},
            )
        assert isinstance(result, PushResult)
        assert result.success is True
        assert result.message_id == "msg-1"
        assert result.error is None
        mock_send.assert_called_once()
        sent_msg = mock_send.call_args.args[0]
        assert sent_msg.token == "tok"
        assert sent_msg.notification.title == "T"
        assert sent_msg.notification.body == "B"
        assert sent_msg.data == {"k": "v"}

    @pytest.mark.asyncio
    async def test_send_push_with_no_data_defaults_to_empty(self):
        with patch.object(
            notification_service, "_ensure_initialized", lambda: None
        ), patch.object(
            notification_service.messaging, "send", return_value="msg-2"
        ) as mock_send:
            result = await notification_service.send_push(
                device_token="tok",
                title="T",
                body="B",
            )
        assert result.success is True
        sent_msg = mock_send.call_args.args[0]
        assert sent_msg.data == {}

    @pytest.mark.asyncio
    async def test_send_push_firebase_error(self):
        from firebase_admin.exceptions import FirebaseError

        err = FirebaseError(code="unavailable", message="boom")
        with patch.object(
            notification_service, "_ensure_initialized", lambda: None
        ), patch.object(
            notification_service.messaging, "send", side_effect=err
        ):
            result = await notification_service.send_push(
                device_token="tok",
                title="T",
                body="B",
            )
        assert result.success is False
        assert result.message_id is None
        assert result.error is not None
        assert "boom" in result.error

    @pytest.mark.asyncio
    async def test_send_push_never_raises_on_generic_exception(self):
        with patch.object(
            notification_service, "_ensure_initialized", lambda: None
        ), patch.object(
            notification_service.messaging,
            "send",
            side_effect=RuntimeError("network down"),
        ):
            result = await notification_service.send_push(
                device_token="tok",
                title="T",
                body="B",
            )
        assert result.success is False
        assert result.error is not None
        assert "network down" in result.error

    @pytest.mark.asyncio
    async def test_send_push_runs_messaging_in_executor(self):
        seen = {}

        def slow_send(_msg):
            import threading

            seen["thread"] = threading.current_thread().name
            return "msg-thread"

        with patch.object(
            notification_service, "_ensure_initialized", lambda: None
        ), patch.object(
            notification_service.messaging, "send", side_effect=slow_send
        ):
            result = await notification_service.send_push("tok", "T", "B")
        assert result.success is True
        assert seen.get("thread") is not None


# ===========================================================================
# Section 3 — app/workers/reminder_worker.py
# ===========================================================================


class TestExtractHelpers:
    def test_fcm_token_from_dict(self):
        assert reminder_worker._extract_fcm_token(
            {"profiles": {"fcm_token": "abc"}}
        ) == "abc"

    def test_fcm_token_from_list(self):
        assert reminder_worker._extract_fcm_token(
            {"profiles": [{"fcm_token": "abc"}]}
        ) == "abc"

    def test_fcm_token_none_when_missing(self):
        assert reminder_worker._extract_fcm_token({}) is None
        assert reminder_worker._extract_fcm_token({"profiles": None}) is None
        assert reminder_worker._extract_fcm_token({"profiles": []}) is None
        assert (
            reminder_worker._extract_fcm_token({"profiles": {"fcm_token": None}})
            is None
        )

    def test_medication_name_from_dict(self):
        assert (
            reminder_worker._extract_medication_name(
                {"medications": {"name": "Aspirin"}}
            )
            == "Aspirin"
        )

    def test_medication_name_from_list(self):
        assert (
            reminder_worker._extract_medication_name(
                {"medications": [{"name": "Aspirin"}]}
            )
            == "Aspirin"
        )

    def test_medication_name_none_when_missing(self):
        assert reminder_worker._extract_medication_name({}) is None
        assert reminder_worker._extract_medication_name({"medications": []}) is None

    def test_parse_dt_handles_iso_string(self):
        result = reminder_worker._parse_dt("2030-01-01T08:00:00+00:00")
        assert result == datetime(2030, 1, 1, 8, 0, tzinfo=timezone.utc)

    def test_parse_dt_handles_z_suffix(self):
        result = reminder_worker._parse_dt("2030-01-01T08:00:00Z")
        assert result == datetime(2030, 1, 1, 8, 0, tzinfo=timezone.utc)

    def test_parse_dt_returns_datetime_unchanged(self):
        dt = datetime(2030, 1, 1, tzinfo=timezone.utc)
        assert reminder_worker._parse_dt(dt) == dt

    def test_parse_dt_invalid_returns_none(self):
        assert reminder_worker._parse_dt("not-a-date") is None
        assert reminder_worker._parse_dt(None) is None


class TestMedicationReminderJob:
    @pytest.mark.asyncio
    async def test_sends_push_for_each_due_dose(self):
        now = datetime.now(timezone.utc)
        rows = [
            {
                "id": "dose-1",
                "scheduled_at": (now + timedelta(minutes=5)).isoformat(),
                "status": "pending",
                "medication_id": "m1",
                "patient_id": "p1",
                "medications": {"name": "Aspirin"},
                "profiles": {"fcm_token": "tok-1"},
            },
            {
                "id": "dose-2",
                "scheduled_at": (now + timedelta(minutes=10)).isoformat(),
                "status": "pending",
                "medication_id": "m2",
                "patient_id": "p2",
                "medications": {"name": "Vitamin D"},
                "profiles": {"fcm_token": "tok-2"},
            },
        ]
        db = _make_async_db({"doses": [rows]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.medication_reminder_job()

        assert mock_send.await_count == 2
        tokens = {c.args[0] for c in mock_send.await_args_list}
        assert tokens == {"tok-1", "tok-2"}

    @pytest.mark.asyncio
    async def test_skips_rows_without_fcm_token(self):
        now = datetime.now(timezone.utc)
        rows = [
            {
                "id": "dose-1",
                "scheduled_at": (now + timedelta(minutes=5)).isoformat(),
                "status": "pending",
                "medication_id": "m1",
                "patient_id": "p1",
                "medications": {"name": "Aspirin"},
                "profiles": {"fcm_token": None},
            },
            {
                "id": "dose-2",
                "scheduled_at": (now + timedelta(minutes=10)).isoformat(),
                "status": "pending",
                "medication_id": "m2",
                "patient_id": "p2",
                "medications": {"name": "Vitamin D"},
                "profiles": None,
            },
        ]
        db = _make_async_db({"doses": [rows]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.medication_reminder_job()

        mock_send.assert_not_called()

    @pytest.mark.asyncio
    async def test_passes_correct_payload_to_send_push(self):
        now = datetime.now(timezone.utc)
        scheduled = now + timedelta(minutes=5)
        rows = [
            {
                "id": "dose-99",
                "scheduled_at": scheduled.isoformat(),
                "status": "pending",
                "medication_id": "med-99",
                "patient_id": "patient-99",
                "medications": {"name": "Lipitor"},
                "profiles": {"fcm_token": "tok-99"},
            }
        ]
        db = _make_async_db({"doses": [rows]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.medication_reminder_job()

        token, title, body, data = mock_send.await_args.args
        assert token == "tok-99"
        assert title == "Time to take your medication"
        assert "Lipitor" in body
        assert scheduled.strftime("%H:%M") in body
        assert data == {
            "type": "medication_reminder",
            "dose_id": "dose-99",
            "patient_id": "patient-99",
        }

    @pytest.mark.asyncio
    async def test_query_uses_correct_window_and_filters(self):
        db = _make_async_db({"doses": [[]]})
        mock_send = AsyncMock(return_value=PushResult(success=True))

        before = datetime.now(timezone.utc)
        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.medication_reminder_job()
        after = datetime.now(timezone.utc)

        recorded = db._captured_calls["doses"][0]
        assert recorded["select"] is not None
        assert "scheduled_at" in recorded["select"]
        assert "profiles(fcm_token)" in recorded["select"]
        assert ("status", "pending") in recorded["eq"]
        gte_cols = {col for col, _ in recorded["gte"]}
        lt_cols = {col for col, _ in recorded["lt"]}
        assert "scheduled_at" in gte_cols
        assert "scheduled_at" in lt_cols

        # window_end - window_start should be ~15 minutes
        gte_val = dict(recorded["gte"])["scheduled_at"]
        lt_val = dict(recorded["lt"])["scheduled_at"]
        start = datetime.fromisoformat(gte_val)
        end = datetime.fromisoformat(lt_val)
        delta = end - start
        assert timedelta(minutes=14, seconds=59) <= delta <= timedelta(minutes=15, seconds=1)
        assert before - timedelta(seconds=2) <= start <= after + timedelta(seconds=2)

    @pytest.mark.asyncio
    async def test_does_not_raise_when_query_explodes(self):
        async def bad_get_db():
            raise RuntimeError("db gone")
            yield  # pragma: no cover

        with patch.object(reminder_worker, "get_db", bad_get_db):
            # Must not raise.
            await reminder_worker.medication_reminder_job()

    @pytest.mark.asyncio
    async def test_continues_after_per_row_send_failure(self):
        now = datetime.now(timezone.utc)
        rows = [
            {
                "id": "dose-1",
                "scheduled_at": (now + timedelta(minutes=5)).isoformat(),
                "status": "pending",
                "medication_id": "m1",
                "patient_id": "p1",
                "medications": {"name": "A"},
                "profiles": {"fcm_token": "tok-1"},
            },
            {
                "id": "dose-2",
                "scheduled_at": (now + timedelta(minutes=10)).isoformat(),
                "status": "pending",
                "medication_id": "m2",
                "patient_id": "p2",
                "medications": {"name": "B"},
                "profiles": {"fcm_token": "tok-2"},
            },
        ]
        db = _make_async_db({"doses": [rows]})
        results = [
            PushResult(success=False, error="fcm-down"),
            PushResult(success=True, message_id="ok"),
        ]
        mock_send = AsyncMock(side_effect=results)

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.medication_reminder_job()

        assert mock_send.await_count == 2

    @pytest.mark.asyncio
    async def test_handles_empty_result(self):
        db = _make_async_db({"doses": [[]]})
        mock_send = AsyncMock(return_value=PushResult(success=True))
        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.medication_reminder_job()
        mock_send.assert_not_called()


class TestAppointmentReminderJob:
    @pytest.mark.asyncio
    async def test_sends_push_for_daily_window(self):
        now = datetime.now(timezone.utc)
        daily = [
            {
                "id": "appt-1",
                "title": "Cardiology",
                "appointment_at": (now + timedelta(hours=24)).isoformat(),
                "status": "confirmed",
                "patient_id": "p1",
                "profiles": {"fcm_token": "tok-1"},
            }
        ]
        db = _make_async_db({"appointments": [daily, []]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()

        assert mock_send.await_count == 1
        token, title, body, data = mock_send.await_args.args
        assert token == "tok-1"
        assert title == "Upcoming appointment reminder"
        assert "Cardiology" in body
        assert data["type"] == "appointment_reminder"
        assert data["appointment_id"] == "appt-1"
        assert data["patient_id"] == "p1"

    @pytest.mark.asyncio
    async def test_sends_push_for_soon_window(self):
        now = datetime.now(timezone.utc)
        soon = [
            {
                "id": "appt-soon",
                "title": "Quick chat",
                "appointment_at": (now + timedelta(minutes=30)).isoformat(),
                "status": "confirmed",
                "patient_id": "p2",
                "profiles": {"fcm_token": "tok-2"},
            }
        ]
        db = _make_async_db({"appointments": [[], soon]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()

        assert mock_send.await_count == 1
        assert mock_send.await_args.args[0] == "tok-2"

    @pytest.mark.asyncio
    async def test_deduplicates_across_windows(self):
        now = datetime.now(timezone.utc)
        dup = {
            "id": "appt-dup",
            "title": "Annual physical",
            "appointment_at": (now + timedelta(hours=24)).isoformat(),
            "status": "confirmed",
            "patient_id": "p1",
            "profiles": {"fcm_token": "tok-1"},
        }
        db = _make_async_db({"appointments": [[dup], [dict(dup)]]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()

        assert mock_send.await_count == 1

    @pytest.mark.asyncio
    async def test_skips_rows_without_fcm_token(self):
        now = datetime.now(timezone.utc)
        rows = [
            {
                "id": "appt-1",
                "title": "X",
                "appointment_at": (now + timedelta(hours=24)).isoformat(),
                "status": "confirmed",
                "patient_id": "p1",
                "profiles": None,
            },
            {
                "id": "appt-2",
                "title": "Y",
                "appointment_at": (now + timedelta(hours=24)).isoformat(),
                "status": "confirmed",
                "patient_id": "p2",
                "profiles": {"fcm_token": None},
            },
        ]
        db = _make_async_db({"appointments": [rows, []]})
        mock_send = AsyncMock(return_value=PushResult(success=True, message_id="m"))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()

        mock_send.assert_not_called()

    @pytest.mark.asyncio
    async def test_excludes_cancelled_via_neq_filter(self):
        db = _make_async_db({"appointments": [[], []]})
        mock_send = AsyncMock(return_value=PushResult(success=True))

        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()

        for record in db._captured_calls["appointments"]:
            assert ("status", "cancelled") in record["neq"]

    @pytest.mark.asyncio
    async def test_query_uses_two_windows(self):
        db = _make_async_db({"appointments": [[], []]})
        mock_send = AsyncMock(return_value=PushResult(success=True))

        before = datetime.now(timezone.utc)
        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()
        after = datetime.now(timezone.utc)

        assert len(db._captured_calls["appointments"]) == 2

        # First window: ~23h -> ~25h (centered ~24h)
        first = db._captured_calls["appointments"][0]
        first_start = datetime.fromisoformat(dict(first["gte"])["appointment_at"])
        first_end = datetime.fromisoformat(dict(first["lt"])["appointment_at"])
        assert (first_end - first_start) == timedelta(hours=2)
        # centered on now+24h
        approx_center = first_start + (first_end - first_start) / 2
        assert before + timedelta(hours=24) - timedelta(seconds=2) <= approx_center <= after + timedelta(hours=24) + timedelta(seconds=2)

        # Second window: ~25m -> ~35m (centered ~30m)
        second = db._captured_calls["appointments"][1]
        second_start = datetime.fromisoformat(dict(second["gte"])["appointment_at"])
        second_end = datetime.fromisoformat(dict(second["lt"])["appointment_at"])
        assert (second_end - second_start) == timedelta(minutes=10)

    @pytest.mark.asyncio
    async def test_does_not_raise_when_db_fails(self):
        async def bad_get_db():
            raise RuntimeError("db gone")
            yield  # pragma: no cover

        with patch.object(reminder_worker, "get_db", bad_get_db):
            await reminder_worker.appointment_reminder_job()

    @pytest.mark.asyncio
    async def test_handles_empty_results(self):
        db = _make_async_db({"appointments": [[], []]})
        mock_send = AsyncMock(return_value=PushResult(success=True))
        with _patch_get_db(db), patch.object(reminder_worker, "send_push", mock_send):
            await reminder_worker.appointment_reminder_job()
        mock_send.assert_not_called()


# ===========================================================================
# Section 4 — app/workers/scheduler.py
# ===========================================================================


class TestScheduler:
    EXPECTED_IDS = {
        "medication_reminder",
        "appointment_reminder_daily",
        "appointment_reminder_interval",
    }

    @pytest.fixture(autouse=True)
    def _fresh_scheduler(self):
        """
        Replace the module-level scheduler with a fresh instance for each test.

        The real scheduler latches onto the first event loop it sees on start(),
        and pytest-asyncio gives each test a new loop — so reusing the same
        scheduler instance across tests blows up with 'Event loop is closed'.
        """
        from apscheduler.schedulers.asyncio import AsyncIOScheduler

        original = scheduler_module.scheduler
        scheduler_module.scheduler = AsyncIOScheduler(timezone="UTC")
        try:
            yield
        finally:
            if scheduler_module.scheduler.running:
                try:
                    scheduler_module.scheduler.shutdown(wait=False)
                except Exception:
                    pass
            scheduler_module.scheduler = original

    def _cleanup(self):
        sched = scheduler_module.scheduler
        for jid in self.EXPECTED_IDS:
            try:
                sched.remove_job(jid)
            except Exception:
                pass

    @pytest.mark.asyncio
    async def test_lifespan_starts_and_registers_all_jobs(self):
        self._cleanup()
        sched = scheduler_module.scheduler
        async with scheduler_module.lifespan(app=MagicMock()):
            assert sched.running is True
            job_ids = {j.id for j in sched.get_jobs()}
            assert self.EXPECTED_IDS.issubset(job_ids)

    @pytest.mark.asyncio
    async def test_lifespan_shutdown_is_called_on_exit(self):
        self._cleanup()
        sched = scheduler_module.scheduler
        with patch.object(sched, "shutdown", wraps=sched.shutdown) as mock_shutdown:
            async with scheduler_module.lifespan(app=MagicMock()):
                pass
            mock_shutdown.assert_called_once()
            assert mock_shutdown.call_args.kwargs.get("wait") is False

    @pytest.mark.asyncio
    async def test_register_jobs_uses_misfire_grace_time(self):
        self._cleanup()
        sched = scheduler_module.scheduler
        async with scheduler_module.lifespan(app=MagicMock()):
            for jid in self.EXPECTED_IDS:
                job = sched.get_job(jid)
                assert job is not None
                assert job.misfire_grace_time == 60

    @pytest.mark.asyncio
    async def test_register_jobs_is_idempotent(self):
        """replace_existing=True means calling _register_jobs twice is safe."""
        self._cleanup()
        sched = scheduler_module.scheduler
        async with scheduler_module.lifespan(app=MagicMock()):
            scheduler_module._register_jobs()  # second call must not raise
            job_ids = {j.id for j in sched.get_jobs()}
            assert self.EXPECTED_IDS.issubset(job_ids)

    @pytest.mark.asyncio
    async def test_medication_job_is_interval_15min(self):
        from apscheduler.triggers.interval import IntervalTrigger

        self._cleanup()
        sched = scheduler_module.scheduler
        async with scheduler_module.lifespan(app=MagicMock()):
            job = sched.get_job("medication_reminder")
            assert isinstance(job.trigger, IntervalTrigger)
            assert job.trigger.interval == timedelta(minutes=15)

    @pytest.mark.asyncio
    async def test_appointment_daily_job_is_cron_8am(self):
        from apscheduler.triggers.cron import CronTrigger

        self._cleanup()
        sched = scheduler_module.scheduler
        async with scheduler_module.lifespan(app=MagicMock()):
            job = sched.get_job("appointment_reminder_daily")
            assert isinstance(job.trigger, CronTrigger)
            fields = {f.name: str(f) for f in job.trigger.fields}
            assert fields["hour"] == "8"
            assert fields["minute"] == "0"

    @pytest.mark.asyncio
    async def test_appointment_interval_job_is_30min(self):
        from apscheduler.triggers.interval import IntervalTrigger

        self._cleanup()
        sched = scheduler_module.scheduler
        async with scheduler_module.lifespan(app=MagicMock()):
            job = sched.get_job("appointment_reminder_interval")
            assert isinstance(job.trigger, IntervalTrigger)
            assert job.trigger.interval == timedelta(minutes=30)

    def test_scheduler_timezone_is_utc(self):
        # APScheduler stores timezone as pytz/zoneinfo object whose str/key is "UTC".
        tz = scheduler_module.scheduler.timezone
        assert str(tz) == "UTC"
