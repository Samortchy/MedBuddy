# MedBuddy — Current Status Snapshot
> Last updated: 2026-06-02 | Phase 2 + Pre-Phase-3 bug batch (A/B/C/D) complete | Branch: main
>
> See `CLAUDE.md` for the full pre-Phase-3 bug batch (7 bugs + 2 bonus fixes + Phase D polish) — Phases A, B, C, D done. Phase 3+ (Emergency/Agora, FCM) remain.

---

## 1. Phase Completion

| Phase | What | Status |
|-------|------|--------|
| Phase 0 | Bug fixes (5 critical bugs) | ✅ Done — 29/29 tests pass |
| Phase 1 | POST /wellness-checkins, workers fixed | ✅ Done — 19/19 tests pass |
| Phase 2a | POST /chat (OpenRouter LLM) | ✅ Done — 39/39 tests pass |
| Phase 2b | POST /stt (faster-whisper large-v3-turbo) | ✅ Done — 39/39 tests pass |
| Phase 2c | POST /tts (Chatterbox Multilingual Arabic) | ✅ Done — 39/39 tests pass |
| Phase 2d | Flutter AI screens wired | ✅ Done — analyze clean |
| Post Phase 2 | Medication refresh bug fix | ✅ Fixed — await added to add_edit.dart |
| Bug batch A | Med overflow, dup-add block, display dedup | ✅ Done — analyze clean |
| Bug batch B | Dedicated profile edit screens + routing + dup-insert fix | ✅ Done — 5 editors, 39/39 tests |
| Bug batch C | AI patient-context injection in /chat | ✅ Done — needs backend restart |
| Bug batch (bonus) | Deleted-med schedule filter + profile placeholder | ✅ Done |
| Bug batch D | Caregiver list/revoke endpoints + wiring, placeholder removed | ✅ Done |
| Phase 3 | Emergency trigger + Agora (patient side) | ✅ Done — backend + fall/verify/Agora wiring; caregiver auto-join needs Phase 4 |
| Phase 4a | Caregiver detail views (meds/wellness/emergencies/profile + last check-in) | ✅ Done |
| Phase 4b | FCM push (token reg + emergency push + caregiver call join) | ✅ Done — run sql/08 + full rebuild |
| Phase 4 | Caregiver detail endpoints + FCM | ❌ Not started |
| Phase 5 | AI visit summaries + symptom flagging | ❌ Not started |
| Phase 6 | Rate limiting + production hardening | ❌ Not started |

---

## 2. All Backend Endpoints

Base URL (dev): `http://localhost:8000/api/v1`
Auth: All endpoints except `/health` require `Authorization: Bearer <supabase_access_token>`

| # | Method | Path | Auth | Status |
|---|--------|------|------|--------|
| 1 | GET | `/health` | None | ✅ Working |
| 2 | GET | `/api/v1/medications/` | Patient | ✅ Working |
| 3 | POST | `/api/v1/medications/` | Patient | ✅ Working |
| 4 | PATCH | `/api/v1/medications/{id}` | Patient | ✅ Working |
| 5 | DELETE | `/api/v1/medications/{id}` | Patient | ✅ Working |
| 6 | GET | `/api/v1/appointments/` | Patient | ✅ Working |
| 7 | POST | `/api/v1/appointments/` | Patient | ✅ Working |
| 8 | PATCH | `/api/v1/appointments/{id}` | Patient | ✅ Working |
| 9 | DELETE | `/api/v1/appointments/{id}` | Patient | ✅ Working |
| 10 | GET | `/api/v1/patient/profile` | Patient | ✅ Working |
| 11 | PATCH | `/api/v1/patient/profile` | Patient | ✅ Working |
| 12 | POST | `/api/v1/caregiver/invite` | Patient | ✅ Working |
| 13 | POST | `/api/v1/caregiver/accept` | Any user | ✅ Working |
| 14 | GET | `/api/v1/caregiver/patients` | Caregiver | ✅ Working |
| 15 | GET | `/api/v1/dose-logs/` | Patient | ✅ Working |
| 16 | POST | `/api/v1/dose-logs/` | Patient | ✅ Working |
| 17 | GET | `/api/v1/emergency-contacts/` | Patient | ✅ Working |
| 18 | POST | `/api/v1/emergency-contacts/` | Patient | ✅ Working |
| 19 | PATCH | `/api/v1/emergency-contacts/{id}` | Patient | ✅ Working |
| 20 | DELETE | `/api/v1/emergency-contacts/{id}` | Patient | ✅ Working |
| 21 | GET | `/api/v1/health-conditions/` | Patient | ✅ Working |
| 22 | POST | `/api/v1/health-conditions/` | Patient | ✅ Working |
| 23 | PATCH | `/api/v1/health-conditions/{id}` | Patient | ✅ Working |
| 24 | DELETE | `/api/v1/health-conditions/{id}` | Patient | ✅ Working |
| 25 | GET | `/api/v1/wellness-checkins/` | Patient | ✅ Working |
| 26 | GET | `/api/v1/wellness-checkins/today` | Patient | ✅ Working |
| 27 | GET | `/api/v1/wellness-checkins/{id}` | Patient | ✅ Working |
| 28 | POST | `/api/v1/wellness-checkins/` | Patient | ✅ Working (Phase 1) |
| 29 | GET | `/api/v1/symptom-logs/` | Patient | ✅ Working |
| 30 | POST | `/api/v1/symptom-logs/` | Patient | ✅ Working |
| 31 | DELETE | `/api/v1/symptom-logs/{id}` | Patient | ✅ Working |
| 32 | GET | `/api/v1/visit-summaries/` | Patient | ✅ Working |
| 33 | GET | `/api/v1/visit-summaries/{id}` | Patient | ✅ Working |
| 34 | POST | `/api/v1/visit-summaries/` | Patient | ✅ Working |
| 35 | PATCH | `/api/v1/visit-summaries/{id}` | Patient | ✅ Working |
| 36 | GET | `/api/v1/emergency-events/` | Patient | ✅ Working |
| 37 | GET | `/api/v1/emergency-events/{id}` | Patient | ✅ Working |
| 38 | GET | `/api/v1/emergency-events/{id}/steps` | Patient | ✅ Working |
| 39 | GET | `/api/v1/patient/notification-preferences` | Patient | ✅ Working |
| 40 | PATCH | `/api/v1/patient/notification-preferences` | Patient | ✅ Working |
| 41 | POST | `/api/v1/chat` | Any user | ✅ Working — OpenRouter Llama 3.3 70B |
| 42 | POST | `/api/v1/stt` | Any user | ✅ Code done — downloads model on first call |
| 43 | POST | `/api/v1/tts` | Any user | ✅ Code done — downloads base model on first call |

### Phase 3 endpoints (✅ implemented):

| Endpoint | Purpose |
|----------|---------|
| `POST /api/v1/emergency/trigger` | Log fall/SOS event, return Agora channel + token |
| `POST /api/v1/emergency/verify` | Liveness step; resolve (false alarm) or escalate |
| `POST /api/v1/agora/token` | Mint 1-hour Agora RTC token |
| `GET /api/v1/caregiver/my-caregivers` | Patient's linked caregivers (Phase D) |
| `DELETE /api/v1/caregiver/links/{id}` | Patient revokes a caregiver (Phase D) |

### Phase 4a endpoints (✅ implemented):

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/caregiver/patients/{id}/profile` | Linked patient's profile (caregiver, link-checked) |
| `GET /api/v1/caregiver/patients/{id}/medications` | Linked patient's active meds |
| `GET /api/v1/caregiver/patients/{id}/wellness-checkins` | Linked patient's recent check-ins |
| `GET /api/v1/caregiver/patients/{id}/emergency-events` | Linked patient's emergency events |

### Phase 4b (✅ implemented):

| Item | Purpose |
|------|---------|
| `POST /api/v1/patient/fcm-token` | Register a device's FCM token (patient or caregiver) |
| `emergency/trigger` → `notify_caregivers` | Sends FCM push to linked caregivers' devices |
| Flutter `fcm_service` + `caregiver_emergency_call` | Token registration; tap push → caregiver joins Agora call |
| `backend/sql/08_fcm_tokens.sql` | `fcm_tokens` table (run in Supabase) |

---

## 3. Flutter — Wiring Status

| Screen | Route | Backend wired | Status |
|--------|-------|---------------|--------|
| S-17 AI Buddy Chat | `/ai-chat` | POST /chat, STT, TTS | ✅ Wired (Phase 2d) |
| S-17b Wellness Check-in | `/checkin` | POST /chat session, POST /wellness-checkins | ✅ Wired (Phase 2d) |
| S-20 Fall Verification | `/fall-verification` | POST /emergency/trigger | ❌ Phase 3 |
| S-21 Agora Channel | `/fall-agora` | POST /agora/token | ❌ Phase 3 |
| All other screens | — | — | ✅ Wired in Phase 0/1 |

---

## 4. Known Remaining Issues

| ID | Where | Problem | Phase |
|----|-------|---------|-------|
| TTS-1 | Backend | Chatterbox base model downloads on first call (~500MB). Fine-tuned weights at `D:\epoch_1\epoch_1\model.safetensors` overlay on top. | 2 (model DL) |
| STT-1 | Backend | Whisper large-v3-turbo downloads on first call (~1.5GB). | 2 (model DL) |
| FALL-1 | Frontend | `fall_provider.dart` manages local UI state only — no API calls to backend yet | 3 |
| AGORA-1 | Backend | `agora.py` is empty stub | 3 |
| FCM-1 | Backend | Push notifications stubbed to log-only — no `device_token` column yet | 4 |

---

## 5. How to Run

**Backend:**
```powershell
conda activate medbuddy-backend
cd D:\projects-last-semester\MedBuddy\backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Tests:**
```powershell
conda activate medbuddy-backend
cd D:\projects-last-semester\MedBuddy
python tests/get_tokens.py          # refresh tokens (expire every 1 hour)
python -m pytest tests/phase1_test.py tests/phase2_test.py -v
python tests/test_phase2_manual.py  # manual test with readable output
```

**Flutter:**
```powershell
cd D:\projects-last-semester\MedBuddy\frontend
flutter run
```
