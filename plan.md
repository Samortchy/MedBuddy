# MedBuddy — Refactor & Completion Plan
> Created: 2026-06-02 | Read status_now.md first for the bug details this plan fixes.
>
> ⚠️ **This is the ORIGINAL build roadmap (Phases 0–6).** Phases 0–2 are done.
> A separate **pre-Phase-3 bug batch** (profile / medications / edit-navigation / AI-context)
> was found and fixed on 2026-06-02 — see **`CLAUDE.md`** for that work (Phases A/B/C complete).
> Do the CLAUDE.md batch before resuming Phase 3 below.

---

## How to Use This Plan

Each phase below has:
- **What to build** — the feature scope
- **Exact prompt to give the AI** — copy-paste this when starting that phase
- **Files the AI will touch** — so you know what to review
- **Definition of done** — how to verify it worked

Work phases in order. Do NOT jump to Phase 3 before Phase 2 is done — each phase depends on the previous.

---

## Phase 0 — Fix the 5 Critical Bugs First (Before Anything Else)
**Est. time: 1 session**

These bugs cause crashes in the current code. Fix them before writing any new features.

### Bug fixes in order:

#### Fix 1 — `notifications.py` backend rewrite
**Files to touch:** `backend/app/api/v1/notifications.py`

**Prompt for AI:**
```
Rewrite backend/app/api/v1/notifications.py. The current file is broken:
1. It uses `await` on the synchronous supabase-py client (get_db() returns a sync Client, not async).
2. It uses a custom `_acquire_db()` helper instead of FastAPI's `Depends(get_db)`.
3. It reads `current_user["id"]` but the JWT returns `profile_id` as the key (see app/core/auth.py).

Fix it to match the pattern used in every other router in this project:
- Inject `db: Client = Depends(get_db)` and `current_user: dict = Depends(get_current_user)` as function parameters.
- Remove all `await` from supabase calls (they are synchronous).
- Use `current_user["profile_id"]` as the patient_id.
- Keep the same two endpoints: GET and PATCH /patient/notification-preferences.
- The upsert on PATCH should use `on_conflict="patient_id"`.

Reference file for the correct pattern: backend/app/api/v1/medications.py
```

#### Fix 2 — Caregiver provider frontend crash
**File to touch:** `frontend/lib/providers/caregiver_provider.dart`

**Prompt for AI:**
```
Fix frontend/lib/providers/caregiver_provider.dart. The `fetch()` method crashes because:
1. Backend GET /caregiver/patients returns {"patients": [...], "total": N} (a dict).
   Flutter does `response.data as List<dynamic>` which throws TypeError.
   Fix: extract the list with `(response.data['patients'] as List<dynamic>? ?? [])`.

2. `LinkedPatient.fromJson` reads `json['profiles']` which is always null.
   The backend already flattens the data: the response items have top-level fields
   `patient_profile_id`, `full_name`, `phone`, `date_of_birth`, `linked_at`.
   Fix fromJson to read: id from `patient_profile_id`, fullName from `full_name`, phone from `phone`.

Do not change anything else.
```

#### Fix 3 — Symptom log field name mismatch
**File to touch:** `frontend/lib/providers/history_providers.dart`

**Prompt for AI:**
```
Fix the SymptomLogNotifier in frontend/lib/providers/history_providers.dart:

1. In `add(String description)`: change the POST body from `{'description': description}` 
   to `{'body': description, 'input_type': 'text'}`. The backend field is `body`, not `description`.

2. In the GET mapper (inside `fetch()`): 
   - Change `m['description']` → `m['body']`
   - Remove the `severity` field entirely (backend has no severity column; it only has `input_type`)
   - Change `m['created_at']` → `m['logged_at']`
   - Update the `SymptomEntry` creation to only set id, description (from body), timestamp (from logged_at).

Also look at how SymptomEntry is defined in service_interfaces.dart and make sure the fields match.
```

#### Fix 4 — Wellness history timestamp field
**File to touch:** `frontend/lib/providers/history_providers.dart`

**Prompt for AI:**
```
In frontend/lib/providers/history_providers.dart in the `wellnessCheckInsProvider` FutureProvider:
Change `m['created_at']` to `m['completed_at']` for the timestamp field.
The backend wellness_checkins table uses `completed_at`, not `created_at`.
Also wrap the DateTime.parse in a try/catch so a null value doesn't crash:
  timestamp: m['completed_at'] != null ? DateTime.parse(m['completed_at']).toLocal() : DateTime.now(),
```

#### Fix 5 — Emergency events field names
**File to touch:** `frontend/lib/providers/history_providers.dart`

**Prompt for AI:**
```
In frontend/lib/providers/history_providers.dart in the `emergencyEventsProvider` FutureProvider:
1. Change `m['created_at']` → `m['triggered_at']` for the timestamp
2. Change `m['steps']` → `m['emergency_escalation_steps']` in `_parseSteps()`
3. Wrap timestamp parsing in try/catch to avoid crashes on null.

Also check what columns emergency_escalation_steps has (look at backend/app/api/v1/emergency_events.py 
which selects * from emergency_escalation_steps) and map EmergencyStep fields accordingly.
```

---

## Phase 1 — Backend: Add POST /wellness-checkins + Clean Up Workers
**Est. time: 1–2 sessions**

### 1a — Add the missing POST endpoint for wellness check-ins

**Files to touch:**
- `backend/app/api/v1/wellness_checkins.py`
- (Check Supabase for actual `wellness_checkins` table columns first)

**Prompt for AI:**
```
Add a POST /wellness-checkins/ endpoint to backend/app/api/v1/wellness_checkins.py.

The wellness_checkins table has these columns (verify against the Supabase dashboard):
  id, patient_id, mood (int 1-5), energy (int 1-5), pain_level (int 0-10),
  sleep_quality (text: 'poor'|'fair'|'good'|'excellent'), all_meds_taken (bool),
  is_flagged (bool), completed_at (timestamptz)

Create a Pydantic model WellnessCheckinCreate with those fields (all optional except mood/energy).
The endpoint should:
- Require patient auth (Depends(get_current_patient))
- Set patient_id from current_user["patient_profile_id"]
- Set completed_at to datetime.now(timezone.utc).isoformat()
- Auto-set is_flagged=True if pain_level > 7 or mood < 2
- Insert into wellness_checkins and return the created row

Follow the exact same pattern as the POST in visit_summaries.py.
```

### 1b — Verify workers are correct (no active fix needed, just review)

**Files to review (read-only):**
- `backend/app/workers/checkin_worker.py`
- `backend/app/workers/reminder_worker.py`
- `backend/app/workers/escalation_worker.py`
- `backend/app/workers/scheduler.py`

**Prompt for AI:**
```
Read these 4 worker files in backend/app/workers/ and tell me:
1. Are they functional or stub files?
2. Do they correctly query the Supabase tables for patients and notification_preferences?
3. Is the scheduler wired to run on startup (in main.py or similar)?
4. What dependencies do they need (FCM, Twilio) that aren't configured yet?

Do NOT make any changes. Just report the status.
```

---

## Phase 2 — AI Integration (Ali's scope)
**Est. time: 3–5 sessions**  
**Prerequisite:** Ollama running locally with Qwen 2.5 7B loaded

### 2a — AI chat endpoint

**Files to create/touch:**
- `backend/app/api/v1/chat.py` (new)
- `backend/app/api/v1/router.py` (add import)
- `backend/app/ai/pipeline.py` (implement)

**Prompt for AI:**
```
Implement the AI chat endpoint for MedBuddy backend.

Create backend/app/api/v1/chat.py with:
  POST /api/v1/chat
  Request body: { "message": str, "history": [{"role": str, "content": str}] }
  Response: { "content": str, "session_id": str }

The endpoint should:
1. Require patient auth (Depends(get_current_patient))
2. Fetch the patient's profile from patient_profiles + profiles tables (same as GET /patient/profile)
3. Fetch their health conditions from health_conditions table
4. Fetch their medications from medications table  
5. Build a system prompt using app/ai/prompts/system_prompt.py that includes the patient context
6. Call Ollama at http://localhost:11434/api/chat with model "qwen2.5:7b"
7. Return the assistant's response

Use httpx for the Ollama call. Return streaming if ?stream=true query param is set.

The system prompt should include: patient name, conditions, medications, and instructions 
to be a warm supportive medical companion (not a doctor, always recommend consulting a doctor 
for medical decisions).

Also add the router to backend/app/api/v1/router.py.

Base URL for Ollama comes from settings.ollama_base_url (already in config.py).
```

### 2b — STT endpoint (Faster-Whisper)

**Files to create/touch:**
- `backend/app/api/v1/stt.py` (new)
- `backend/app/services/stt_service.py` (implement)
- `backend/app/api/v1/router.py`

**Prompt for AI:**
```
Implement the speech-to-text endpoint using faster-whisper.

Create backend/app/api/v1/stt.py with:
  POST /api/v1/stt
  Accepts: multipart/form-data with field "audio" (audio file, any format)
  Response: { "text": str, "language": str, "confidence": float }

The endpoint should:
1. Require patient auth
2. Accept audio upload via UploadFile
3. Save audio to a temp file
4. Transcribe using faster_whisper.WhisperModel with model_size from settings.whisper_model_size
5. Delete temp file after transcription
6. Return the transcript

Use compute_type="int8" for speed on CPU. The model should be loaded once at startup 
(not per request) — use a module-level singleton or FastAPI lifespan event.

Note: The whisper_model_size is in settings (large-v3 but consider using "base" for dev speed).
Add the router to router.py.
```

### 2c — TTS endpoint (Chatterbox/XTTS)

**Files to create/touch:**
- `backend/app/api/v1/tts.py` (new)
- `backend/app/services/tts_service.py` (implement)
- `backend/app/api/v1/router.py`

**Prompt for AI:**
```
Implement the text-to-speech endpoint using Chatterbox TTS.

Create backend/app/api/v1/tts.py with:
  POST /api/v1/tts
  Request body: { "text": str, "voice": str (optional, default "default") }
  Response: audio/wav binary stream (StreamingResponse)

The endpoint should:
1. Require patient auth
2. Accept text input
3. Synthesize speech using the chatterbox library (pip install chatterbox-tts)
   Model path from settings.chatterbox_model_path
4. Return the audio as a streaming response with content-type audio/wav

If chatterbox is not available, fall back to pyttsx3 as a dev-mode TTS.
Add the router to router.py.
```

### 2d — Wire AI services to Flutter screens

**Files to touch:**
- `frontend/lib/services/service_interfaces.dart` (implement concrete classes)
- `frontend/lib/main.dart` (inject into S-17 and S-17b routes)
- `frontend/lib/screens/patient/checkin/s17_ai_buddy_chat.dart`
- `frontend/lib/screens/patient/checkin/s17b_wellness_checkin.dart`

**Prompt for AI:**
```
Wire the AI backend services to the Flutter AI chat and wellness check-in screens.

Context:
- Backend base URL: http://10.0.2.2:8000/api/v1 (Android emulator)
- Auth token is attached automatically by the Dio interceptor in api_service.dart
- The screens already accept nullable AIService, STTService, TTSService parameters

Tasks:
1. In frontend/lib/services/service_interfaces.dart, create concrete implementations:
   - DioAIService implements AIService: calls POST /chat with message + history list
   - DioSTTService implements STTService: calls POST /stt with audio bytes as multipart
   - DioTTSService implements TTSService: calls POST /tts and returns audio bytes

2. In frontend/lib/main.dart, update the routes for '/ai-chat' and '/checkin' to inject 
   the concrete services:
   '/ai-chat': (context) => AIBuddyChatScreen(
     aiService: DioAIService(ref.read(apiServiceProvider)),
     sttService: DioSTTService(ref.read(apiServiceProvider)),
     ttsService: DioTTSService(ref.read(apiServiceProvider)),
   )
   (These routes need to be ConsumerWidgets to access ref — refactor accordingly)

3. In the wellness check-in screen (s17b), after the user completes all questions,
   call POST /wellness-checkins/ with the answers collected during the session.
   Create a provider or inline call for this.

Keep changes minimal — do not refactor screens, only wire the service injection.
```

---

## Phase 3 — Emergency Backend (Fall Detection + Agora)
**Est. time: 2–3 sessions**  
**Prerequisite:** Phase 2 done, Agora account credentials set in .env

### 3a — Emergency trigger endpoint

**Files to create/touch:**
- `backend/app/api/v1/emergency.py` (new)
- `backend/app/services/emergency_service.py` (implement)
- `backend/app/api/v1/router.py`

**Prompt for AI:**
```
Implement the emergency trigger endpoint for MedBuddy.

Create backend/app/api/v1/emergency.py with two endpoints:

1. POST /api/v1/emergency/trigger
   Request body: { "event_type": "fall_detected"|"manual_sos", "gps_coordinates": str (optional) }
   Response: { "event_id": str, "agora_channel": str, "agora_token": str }
   
   This endpoint should:
   - Require patient auth
   - Insert a row into emergency_events table with patient_id, event_type, triggered_at=now, gps_coordinates
   - Generate an Agora RTC token for the patient (channel name = event_id)
   - Return the event_id and Agora channel info

2. POST /api/v1/emergency/verify
   Request body: { "event_id": str, "verified": bool, "factor": "factor1"|"factor2" }
   Response: { "status": str }
   
   This endpoint should:
   - Require patient auth
   - Insert a row into emergency_escalation_steps with event_id, step type, outcome
   - If verified=True: update event with resolved_at=now, outcome="handled_by_caregiver"
   - If verified=False on factor2: start escalation (log that Agora was needed)

Also implement the Agora token generation in backend/app/services/emergency_service.py.
Use the agora-token Python package (pip install agora-token-builder).
Agora credentials are in settings: agora_app_id, agora_app_certificate.

Add the router to router.py.
```

### 3b — Agora token endpoint

**Files to touch:**
- `backend/app/api/v1/agora.py` (currently empty — implement)
- `backend/app/services/agora_service.py` (implement)

**Prompt for AI:**
```
Implement the Agora RTC token endpoint.

backend/app/api/v1/agora.py currently exists but is empty (1 line). Implement it with:

POST /api/v1/agora/token
Request body: { "channel_name": str, "uid": int (optional, default 0) }
Response: { "token": str, "channel_name": str, "uid": int, "expires_at": str }

Use agora-token-builder package. Token should be valid for 3600 seconds (1 hour).
Use settings.agora_app_id and settings.agora_app_certificate.
Require patient or caregiver auth (Depends(get_current_user)).

Also implement backend/app/services/agora_service.py with a generate_token(channel_name, uid) function.
```

### 3c — Wire fall detection to backend in Flutter

**Files to touch:**
- `frontend/lib/providers/fall_provider.dart`
- `frontend/lib/screens/patient/emergency/fall_verification_screen.dart`
- `frontend/lib/screens/patient/emergency/fall_agora_screen.dart`

**Prompt for AI:**
```
Wire the fall detection flow to the backend in the Flutter app.

Current state: fall_provider.dart only manages local UI state (idle/detected/cancelled/confirmed).
No API calls are made when a fall happens.

Changes needed:

1. In fall_provider.dart, inject the Dio instance and add:
   - `triggerEmergency()` async method: calls POST /emergency/trigger with event_type="fall_detected"
     and stores the returned event_id and agora_channel_name in state
   - `verifyLiveness(bool verified, String factor)` async method: 
     calls POST /emergency/verify with event_id, verified, factor

2. In fall_verification_screen.dart (S-20):
   - When the screen loads after a fall is confirmed, call fall_provider.triggerEmergency()
   - On successful name match: call fall_provider.verifyLiveness(true, "factor1")
   - On failed factor 2: call fall_provider.verifyLiveness(false, "factor2")

3. In fall_agora_screen.dart (S-21):
   - Call GET /agora/token with the channel_name from fall_provider state
   - Use the returned token to join the Agora channel via agora_rtc_engine plugin

Keep the existing UI screens intact — only add the backend wiring.
The Agora plugin (agora_rtc_engine) is already in pubspec.yaml.
```

---

## Phase 4 — Caregiver Features
**Est. time: 2–3 sessions**  
**Prerequisite:** Phase 1–2 done

### 4a — Caregiver patient detail endpoints

**Files to touch:**
- `backend/app/api/v1/caregiver.py` (extend)

**Prompt for AI:**
```
Add caregiver-specific read endpoints to backend/app/api/v1/caregiver.py.
These let a caregiver view a specific patient's data.

Add these endpoints (all require caregiver auth AND a check that the caregiver is linked to the patient):

1. GET /caregiver/patients/{patient_id}/medications
   Returns the patient's medications (same as GET /medications/ but for a linked patient)

2. GET /caregiver/patients/{patient_id}/wellness-checkins
   Returns the patient's recent wellness check-ins (last 30)

3. GET /caregiver/patients/{patient_id}/emergency-events
   Returns the patient's emergency events

4. GET /caregiver/patients/{patient_id}/profile
   Returns the patient's full profile

For each: verify that a caregiver_patient_links row exists with status='active' 
linking this caregiver_id to the patient_id. Return 403 if not linked.

Follow the same pattern as the existing GET endpoints in this file.
```

### 4b — FCM push notification integration

**Files to touch:**
- `backend/app/services/notification_service.py` (implement)
- `backend/app/workers/checkin_worker.py` (wire to FCM)
- `backend/app/workers/reminder_worker.py` (wire to FCM)

**Prompt for AI:**
```
Implement Firebase Cloud Messaging push notifications in MedBuddy backend.

Read backend/app/services/notification_service.py and backend/app/models/notification.py first.

Then implement the send_push_notification function using firebase-admin SDK:
  pip install firebase-admin

The FIREBASE_SERVICE_ACCOUNT_JSON env var contains a base64-encoded service account JSON.
Decode it, parse as JSON, and use it to initialize the firebase_admin app.

Implement:
  async def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None)

Then wire this into:
1. The checkin_worker: send a push when it's check-in time for a patient
2. The reminder_worker: send a push when a medication dose is due

For the caregiver emergency screen: when POST /emergency/trigger is called,
query caregiver_patient_links for the patient's linked caregivers, 
fetch their FCM tokens from a patient_fcm_tokens table (create if doesn't exist),
and send an emergency push to each caregiver.

Note: Flutter FCM token storage endpoint also needs to be created:
  POST /api/v1/notifications/fcm-token  body: { "token": str }
  This saves the FCM token for the authenticated user.
```

---

## Phase 5 — Symptom Log + Visit Summary AI Processing
**Est. time: 1–2 sessions**  
**Prerequisite:** Phase 2 (STT + AI) done

### 5a — AI-powered visit summary from voice

**Files to touch:**
- `backend/app/api/v1/visit_summaries.py` (add AI processing endpoint)

**Prompt for AI:**
```
Add an endpoint to backend/app/api/v1/visit_summaries.py that processes a raw 
voice transcript and produces a structured visit summary using the LLM.

POST /api/v1/visit-summaries/process-transcript
Request body: { "raw_transcript": str, "appointment_id": str (optional) }
Response: same as VisitSummaryCreate fields (diagnosis, medications_changed, instructions, next_appointment)

The endpoint should:
1. Require patient auth
2. Call Ollama at settings.ollama_base_url with model "qwen2.5:7b"
3. Use a structured prompt asking the model to extract: diagnosis, medications changed, 
   follow-up instructions, and next appointment date from the transcript
4. Parse the model's JSON response
5. Insert the structured summary into visit_summaries table and return the row

Use httpx to call Ollama. The model should return JSON (use ollama's "format": "json" option).
```

### 5b — Symptom log AI severity flagging

**Files to touch:**
- `backend/app/api/v1/symptom_logs.py`

**Prompt for AI:**
```
Extend POST /api/v1/symptom-logs/ in backend/app/api/v1/symptom_logs.py to automatically 
flag concerning symptom descriptions using keyword matching and AI.

After inserting the symptom log:
1. Run a simple keyword check first (chest pain, breathing, stroke, fall, 911, emergency → auto-flag)
2. If no keyword match but the body text is > 20 chars, optionally send to LLM for assessment
3. If flagged, update the row with a severity field (add severity column to schema: 'normal'|'watch'|'flagged')
4. Return the row with severity included

Also add a GET /symptom-logs/?severity=flagged query param to filter by severity.

Note: First check if the symptom_logs table actually has a severity column in Supabase.
If not, describe what SQL migration is needed.
```

---

## Phase 6 — Cleanup & Production Hardening
**Est. time: 1 session**

### Prompt for AI:
```
Review and harden the MedBuddy FastAPI backend for production readiness.

Tasks:
1. Add rate limiting to sensitive endpoints (POST /emergency/trigger, POST /chat, POST /stt)
   Use slowapi (pip install slowapi) with limit: 10/minute for chat, 3/minute for emergency.

2. Add request logging middleware that logs: method, path, status_code, response_time_ms.
   Add to app/main.py.

3. Verify all endpoints that take a patient_id from the URL (caregiver endpoints for reading 
   patient data) properly check the caregiver_patient_links table before returning data.

4. Move the hardcoded Supabase URL and anonKey from frontend/lib/main.dart into a 
   flutter_dotenv or compile-time const — they should not be visible in plain source code.
   In main.dart lines 65-66, use const String.fromEnvironment() or a config file.

5. Add health checks for Ollama and Supabase to GET /health:
   Return {"status": "ok", "ollama": "ok"|"down", "supabase": "ok"|"down"}

Do not refactor unrelated code.
```

---

## Quick Reference: File Map

| Feature | Backend file | Frontend file |
|---------|-------------|---------------|
| Auth | Supabase (no backend file) | `providers/auth_provider.dart` |
| Patient profile | `api/v1/patient_profile.py` | `providers/patient_provider.dart` |
| Medications | `api/v1/medications.py` | `providers/medication_provider.dart` |
| Dose logs | `api/v1/dose_logs.py` | `providers/medication_provider.dart` |
| Appointments | `api/v1/appointments.py` | `providers/appointment_provider.dart` |
| Health conditions | `api/v1/health_conditions.py` | `providers/history_providers.dart` |
| Emergency contacts | `api/v1/emergency_contacts.py` | `providers/history_providers.dart` |
| Wellness check-ins | `api/v1/wellness_checkins.py` | `providers/history_providers.dart` |
| Symptom logs | `api/v1/symptom_logs.py` | `providers/history_providers.dart` |
| Visit summaries | `api/v1/visit_summaries.py` | `screens/patient/history/s29_visit_summary.dart` |
| Emergency events | `api/v1/emergency_events.py` | `providers/history_providers.dart` |
| Caregiver linking | `api/v1/caregiver.py` | `providers/caregiver_provider.dart` |
| Notifications | `api/v1/notifications.py` (broken) | `screens/patient/profile/s27_app_settings.dart` |
| AI chat | `api/v1/chat.py` (not created) | `screens/patient/checkin/s17_ai_buddy_chat.dart` |
| STT | `api/v1/stt.py` (not created) | `services/service_interfaces.dart` |
| TTS | `api/v1/tts.py` (not created) | `services/service_interfaces.dart` |
| Emergency trigger | `api/v1/emergency.py` (not created) | `providers/fall_provider.dart` |
| Agora tokens | `api/v1/agora.py` (empty) | `screens/patient/emergency/fall_agora_screen.dart` |
