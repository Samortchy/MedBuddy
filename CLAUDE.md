# MedBuddy — Project Guide & Pre-Phase-3 Fix Plan

> Last updated: 2026-06-02
> Scope of this document: everything that must be fixed **before Phase 3 (Emergency + Agora)** begins.
> This is a PLAN. No code in this plan has been implemented yet.

---

## 1. Project Overview

MedBuddy is an AI-powered elderly health companion (university semester project).

| Layer | Tech | Location |
|-------|------|----------|
| Frontend | Flutter 3.x / Dart 3.11+, Riverpod 2.5.1, Dio 5.4 | `frontend/` |
| Backend | FastAPI (Python), runs on port 8000 | `backend/` |
| DB | Supabase (Postgres + Auth) — project `tcyrehuatbtlfvnttkgc` | Supabase cloud |
| AI | OpenRouter (Llama 3.3 70B) chat, faster-whisper STT, Chatterbox TTS | `backend/app/services/` |

### Architecture essentials
- **Auth-only Supabase.** Flutter uses Supabase purely for login/signup/session. Role (`patient`/`caregiver`) lives in JWT `user_metadata`. All data access goes through the FastAPI backend using its service-role key.
- **HTTP:** single Dio instance in `api_service.dart` with an interceptor that injects `Authorization: Bearer <supabase access token>`; on 401 it signs out.
- **Base URL:** `http://10.0.2.2:8000/api/v1` (Android emulator → host localhost). Never use `localhost`/`127.0.0.1` on the emulator.
- **State:** Riverpod `StateNotifier`/`FutureProvider` in `frontend/lib/providers/`.
- **Backend env:** conda env `medbuddy-backend` at `C:\Users\User\.conda\envs\medbuddy-backend`. Use its `python.exe` / `uvicorn.exe` / `pytest.exe` directly.

### Run commands
```powershell
# Backend
conda activate medbuddy-backend
cd D:\projects-last-semester\MedBuddy\backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Frontend
cd D:\projects-last-semester\MedBuddy\frontend
flutter run
```

---

## 2. Current Status

- **Phases 0–2 complete:** bug fixes, wellness check-in POST, workers, AI chat/STT/TTS, Flutter AI screens wired.
- **Pre-Phase-3 bug batch (this document) — Phases A, B, C, D COMPLETE (2026-06-02).** All 7 reported bugs fixed + 2 bonus fixes (deleted-med lingering in schedule, fake profile placeholder) + Phase D polish (caregiver list/revoke, placeholder removed). See §6 for per-phase detail.
- **AI patient-context confirmed working in-app** (assistant correctly answers name/medications).
- **Phase 3+ not started:** Emergency trigger + Agora, caregiver detail endpoints + FCM, AI visit summaries, production hardening.

### Verification status
- `flutter analyze`: 0 new issues (15 pre-existing, unrelated).
- Backend pytest (phase1 + phase2): 39/39 pass.
- Backend imports + Pydantic model + AI prompt builder: OK.
- ⚠️ **Requires `database/schema_edit.sql` to have been run in Supabase** (adds `gender`/`pain_baseline`, dedup indexes + cleanup).

---

## 3. Authoritative DB Schema (relevant tables)

Key facts the fixes depend on:

- **`profiles`**: `id`, `role`, `full_name`, `phone`, `date_of_birth (date)`, `preferred_language (default 'en')`, `avatar_url`. **No `gender` column. No `pain_baseline`.**
- **`patient_profiles`**: `id`, `profile_id (unique)`, `mobility_level`, `cognitive_state`, `fall_detection_enabled`, `checkin_time (time, default 09:00)`, `checkin_frequency (int, default 1)`, `medication_grace_mins`. FK `patient_id` in child tables → `patient_profiles.id`.
- **`health_conditions`**: `patient_id`, `name`, `diagnosed_at`, `notes`. **No UNIQUE(patient_id, name).**
- **`medications`**: `patient_id`, `name`, `dose_amount`, `dose_unit`, `frequency`, `instructions`, `start_date`, `end_date`, `is_active`, `deleted_at` (soft delete). **No UNIQUE(patient_id, name).**
- **`emergency_contacts`**: `patient_id`, `name`, `relationship`, `phone`, `priority`. No unique constraint.
- **`caregiver_patient_links`**: `caregiver_id`, `patient_id`, `status (link_status)`, `linked_at`.
- **`wellness_checkins`**: columns are `mood_score`, `energy_score`, `pain_level`, `sleep_quality (smallint 1-5)`, `meds_confirmed`, `ai_flags (array)`, `completed_at`. (Frontend already maps these correctly.)

---

## 4. Bugs & Root Causes (the batch to fix)

### BUG-1 — Duplicate health conditions & medications on profile
- **Symptom:** same condition/medication appears multiple times.
- **Root cause:** the duplicates are **real DB rows**. Providers replace (don't accumulate) state, so the API is returning dupes.
  - `onboarding_provider.dart::_submitMedications()` does **not** delete existing meds before inserting (unlike `_submitConditions` / `_submitContacts` which delete-first). Every re-submit re-inserts all meds.
  - No `UNIQUE(patient_id, name)` constraint on `medications` or `health_conditions`.
  - The broken edit flow (BUG-6) re-runs `submit()`, compounding it.
- **Fix:** (a) prevent duplicate inserts, (b) add DB partial-unique indexes, (c) defensive display dedup, (d) one-time cleanup of existing dupes.

### BUG-2 — Profile completeness shows 85 (static or calculated?)
- **Answer:** it is **calculated** — `main.dart::_MyProfileRoute` lines ~213-221: name 20 + DOB 15 + conditions 20 + meds 15 + contacts 15 + check-in 15 = 100.
- **Why 85:** DOB is missing → −15. Same root cause as BUG-3. Fixing DOB makes this reach 100.
- The `85` literal in `s25_my_profile.dart` is a placeholder profile only used when the provider is null (not the real path).

### BUG-3 — Basic info: age shows 0 (language English is CORRECT — leave it)
- **Root cause:** `_ageFromDob()` returns 0 when `profiles.date_of_birth` is null. This patient's DOB was never persisted (profile predates DOB-writing onboarding, or basic-info was never completed) — and edit is broken, so it can't be corrected.
- Backend persists/returns DOB correctly (`patient_profile.py`). The fix is to make the basic-info editor write a real DOB (date picker), which also fixes BUG-2.
- **Language:** `_languageDisplay(null)` → "English". User confirmed this is correct. **Do not change language logic.**

### BUG-4 — Medications overflow (yellow/black RenderFlex stripes)
- **Location:** `s25_my_profile.dart` (~lines 148-178). The Medications card uses a `Row` with an **unbounded `Text`** (med names joined by `, `) + a count badge, no `Expanded`/`Flexible` → horizontal overflow with many/long meds.
- (`med_schedule.dart` is fine — it already uses `Expanded`.)
- **Fix:** render meds as a chip `Wrap` (like conditions) or wrap the `Text` in `Expanded`.

### BUG-5 — No duplicate validation on medication add
- **Location:** `add_edit.dart::_save()` posts with no pre-check; backend `medications.py` POST inserts unconditionally.
- **Fix (decided rule):** block when a medication with the **same name (case-insensitive)** already exists, regardless of dose. Message: *"You already have this medication — edit it instead."* Frontend guard + backend 409 as defense-in-depth.
- (Future nuance: if same-name-different-dose ever needs to be allowed, relax to name+dose. Out of scope now.)

### BUG-6 — Edit navigation completely broken
- **Symptoms:** tapping edit on any section throws you into the onboarding wizard from the start; "edit medications" opens a blank Add form.
- **Root causes (compounding):**
  1. **Section-name mismatch** — `main.dart::_MyProfileRoute.onEditSection` switch only handles `basic_info/conditions/medications/contacts`, but the screen sends `'emergency_contacts'`, `'checkin_prefs'`, and `'all'` → all fall to `default → /profile/basic`. Even contacts is broken (`emergency_contacts` ≠ `contacts`).
  2. **Edit targets are the onboarding wizard** — S04 doesn't prefill, its Next button hardcodes `push(S05Conditions())`, and the chain ends at S10 `submit()` which delete+reinserts conditions/contacts and re-PATCHes profile (a data-corruption path).
  3. **Medication edit** routes to `/add-medication` with no argument → blank Add form, not an editor of existing meds.
- **Fix (decided): dedicated edit screens** — see Phase B.

### BUG-7 — AI chat has no patient context
- **Root cause:** backend `/chat` (`ai.py`) never loads patient data; it uses the client-supplied `system_prompt` or the generic default in `llm_service.py`. Frontend `ApiAIService.sendMessage` sends only `message` + `history`, no system prompt. The LLM literally has no patient info.
- **Fix (decided): backend-side context injection** — see Phase C.

---

## 5. Additional Concerns Found (address opportunistically)

- **Caregivers always empty on profile** — `main.dart` hardcodes `caregivers: []`. Needs a "list my caregivers" endpoint (none exists; `caregiver.py` only has the caregiver→patients direction).
- **Fake check-in prefs on profile** — `checkInHour: 9`, `checkInVoiceMode: false`, `painBaseline: 0`, `gender: ''` are hardcoded in the mapping despite real `checkin_time`/`checkin_frequency` being available.
- **`gender` is never persisted** — no DB column. Onboarding collects it and drops it.
- **`pain_baseline` is never persisted** — no DB column.
- **Two parallel profile models** (`PatientProfileData` vs `PatientProfile`) bridged manually in `main.dart`.
- **Hardcoded placeholder "Arthur Mitchell"** in `s25_my_profile.dart` — risk of showing fake data if provider is null.
- **Supabase anonKey hardcoded** in `main.dart` (tracked separately for Phase 6 hardening).

---

## 6. Fix Plan — Phases (do in order)

### Phase A — Quick UI & safety fixes ✅ DONE
> Medications card now renders a chip `Wrap` (no overflow); add-medication blocks duplicate names (frontend pre-check + backend 409); conditions & medication lists deduped on display; completeness confirmed calculated.

**A1. Medication overflow (BUG-4)** — `frontend/lib/screens/patient/profile/s25_my_profile.dart`
- Replace the medications `Row` Text with a chip `Wrap` (mirror the conditions section), keep the "N active" badge above/beside the wrap. Verify with 10+ long-named meds.

**A2. Duplicate-add validation (BUG-5)** — `frontend/lib/screens/patient/medications/add_edit.dart` (+ backend `medications.py`)
- In `_save()`, **add-mode only**, before POST: compare trimmed lowercased name against `ref.read(medicationProvider).medications`. If match → set `_error` to the "edit instead" message and return.
- Backend: in POST, query existing non-deleted meds for `(patient_id, lower(name))`; if found return `409 Conflict`.

**A3. Defensive display dedup (BUG-1 mitigation)** — `frontend/lib/providers/history_providers.dart`, `main.dart`
- Dedup conditions by lowercased name in `healthConditionsProvider`.
- Dedup the medication list mapping in `_MyProfileRoute` by lowercased name. (Display safety net; real fix is Phase B.)

**A4. Confirm completeness (BUG-2)** — no code change; it's already calculated. Reaches 100 once DOB is fixed in Phase B.

### Phase B — Edit navigation rebuild + data correctness ✅ DONE
> 5 dedicated editors built under `frontend/lib/screens/patient/profile/edit/` (+ shared `edit_scaffold.dart`): basic info (name/DOB picker/gender), conditions (diff-based save), medications (list + per-row edit/delete + add), contacts (list + add/edit dialog/delete), check-in prefs (time/frequency/pain slider). `main.dart` routing rewritten — section names mapped correctly, `'all'` opens an edit-hub bottom sheet, providers refresh on return, onboarding prefill removed. `_submitMedications` now deletes-first. Backend + `PatientProfileUpdate` accept `gender`/`pain_baseline`. `EmergencyContactData` carries `id`.

**B1. Dedicated edit screens (BUG-6)** — new files under `frontend/lib/screens/patient/profile/edit/`
Create standalone editors that **prefill current data, save via API, then `pop()` back to profile** — fully decoupled from the onboarding wizard:
- `edit_basic_info.dart` — name (text), **DOB (date picker → real `date_of_birth`)**. Saves via `PATCH /patient/profile`. (Gender omitted unless a column is added — see B4.)
- `edit_conditions.dart` — add/remove conditions with dedup; `POST` / `DELETE /health-conditions`.
- `edit_medications.dart` — **list existing meds** with per-row Edit (→ `AddEditMedication(medication: m)`) and Delete, plus Add. Fixes the "blank Add form" issue.
- `edit_contacts.dart` — add/edit/remove; `POST`/`PATCH`/`DELETE /emergency-contacts`.
- `edit_checkin_prefs.dart` — check-in time + frequency; `PATCH /patient/profile`.

**B2. Fix routing/section names** — `main.dart::_MyProfileRoute.onEditSection`
- Map every section the screen actually emits: `basic_info`, `conditions`, `medications`, `emergency_contacts`, `checkin_prefs`, and `all` (top-right pencil → an edit hub or basic info). Route each to its new dedicated editor. Remove the `prefillFromProfile`/onboarding push entirely.
- After any editor pops, invalidate/refresh the relevant providers so the profile updates.

**B3. Prevent duplicate inserts at the source (BUG-1)**
- `onboarding_provider.dart::_submitMedications()` — delete existing meds first (match the conditions/contacts pattern), OR skip names that already exist.
- Add DB partial-unique indexes (one-time SQL, see §7).
- One-time cleanup SQL to remove existing dupes (see §7).

**B4. Persist gender + pain_baseline (DECIDED: keep both).** Columns are added by `database/schema_edit.sql` (`profiles.gender`, `patient_profiles.pain_baseline`). Wire the basic-info editor to save `gender`, the check-in-prefs editor to save `pain_baseline`, and send both in `PATCH /patient/profile` (backend `patient_profile.py` + `PatientProfileUpdate` model must accept them). Feed both into the AI context in Phase C.

### Phase C — AI patient context (BUG-7), backend-side ✅ DONE
> `app/ai/prompts/system_prompt.py` now has `build_patient_system_prompt()` (extends `MEDBUDDY_SYSTEM_PROMPT` with name/age/gender/language/conditions/meds). `/chat` injects it server-side via `_build_patient_context()` for authenticated patients when the client sends no explicit prompt. Caregivers (no `patient_profile_id`) skip injection. Fixes wellness check-in too (same service). Requires backend restart to take effect.

**C1.** `backend/app/api/v1/ai.py` `/chat` — after auth, fetch for `current_user["patient_profile_id"]` / `profile_id`:
- profile (full_name, date_of_birth→age, preferred_language)
- `health_conditions` (names)
- active `medications` (name, dose, frequency)

**C2.** Build a context-rich system prompt server-side (extend `MEDBUDDY_SYSTEM_PROMPT` in `llm_service.py` or a helper in `app/ai/prompts/system_prompt.py`, which is currently empty). Inject patient facts so "what is my name / my medications" work. Server prompt is authoritative; ignore/augment any client `system_prompt`.
**C3.** Pass the assembled prompt into `llm_service.chat(...)`. This automatically fixes the wellness check-in too (same service).
**C4.** Keep responses short/warm per existing rules. Match patient language.

### Phase D — Profile fidelity polish ✅ DONE
- ✅ Real check-in hour + pain baseline + gender wired into the profile mapping; profile route shows loading/retry instead of the fake "Arthur Mitchell" placeholder.
- ✅ Added `GET /caregiver/my-caregivers` + `DELETE /caregiver/links/{link_id}` (patient auth); `myCaregiversProvider` (patient_provider.dart) feeds the Caregiver Access section; invite + revoke both wired in `main.dart` and invalidate the provider.
- ✅ Removed the dead placeholder profile constant from `s25_my_profile.dart`; `profile` is now a required non-null param.
- ⬜ `checkInVoiceMode` still hardcoded `false` — no DB column exists; left as-is (would need a migration).

### Bonus fixes (found during Phase B verification) ✅ DONE
- **Deleted medication lingered on the schedule:** `get_dose_logs` (dose_logs.py) now filters out doses whose medication is soft-deleted (`deleted_at IS NULL`). Also corrects the "X of Y taken" count.
- **Fake placeholder profile:** `_MyProfileRoute` shows a loading spinner / retry when profile data is null instead of the hardcoded "Arthur Mitchell" demo profile (which also caused empty edit screens mid-load).

---

## 7. One-time SQL (run in Supabase; not auto-applied)

```sql
-- Cleanup existing duplicate medications (keep earliest non-deleted per patient+name)
WITH ranked AS (
  SELECT id, ROW_NUMBER() OVER (
    PARTITION BY patient_id, lower(name)
    ORDER BY created_at
  ) AS rn
  FROM medications
  WHERE deleted_at IS NULL
)
UPDATE medications SET deleted_at = now()
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Cleanup duplicate health conditions (keep earliest)
WITH ranked AS (
  SELECT id, ROW_NUMBER() OVER (
    PARTITION BY patient_id, lower(name)
    ORDER BY created_at
  ) AS rn
  FROM health_conditions
)
DELETE FROM health_conditions
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Prevent future dupes
CREATE UNIQUE INDEX IF NOT EXISTS uq_medications_patient_name_active
  ON medications (patient_id, lower(name))
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_health_conditions_patient_name
  ON health_conditions (patient_id, lower(name));
```

---

## 8. Open Questions / Decisions Pending

1. **Top-right pencil (`'all'`)** — should it open a small "edit hub" menu, or just jump to Basic Info? *Default: edit hub.*
2. **DOB for the affected patient** — fixed naturally once the user re-saves via the new basic-info editor (date picker). No data migration needed unless you want to backfill.

## 9. Decisions Already Made
- Edit navigation → **dedicated edit screens** (Phase B).
- AI patient context → **backend-side injection** (Phase C).
- Duplicate-medication rule → **same name, case-insensitive** (dose ignored) (BUG-5).
- DB dedup → **add partial-unique indexes + app-level guards + one-time cleanup** (§7 / `database/schema_edit.sql`).
- **Keep gender + pain_baseline** → columns added in `database/schema_edit.sql`; wire them in Phase B and feed into AI context in Phase C.
