-- =============================================================================
-- 05_notification_prefs.sql — Tasks 24, 26, 27
-- Run in Supabase SQL Editor BEFORE deploying the workers/endpoints.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- DB Fix #2 — Add source column to wellness_checkins
-- Required by Task 24 (checkin_worker relies on source = 'system' default)
-- ---------------------------------------------------------------------------

ALTER TABLE wellness_checkins
    ADD COLUMN IF NOT EXISTS source TEXT
        NOT NULL DEFAULT 'system'
        CHECK (source IN ('patient', 'caregiver', 'system'));

COMMENT ON COLUMN wellness_checkins.source IS
    'Who triggered the check-in: patient (self), caregiver, or system (cron)';


-- ---------------------------------------------------------------------------
-- DB Fix #5 — notification_preferences table
-- Required by Task 27 (preferences endpoint) and Tasks 24/26 (quiet hours)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS notification_preferences (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  UUID NOT NULL REFERENCES patient_profiles(patient_id) ON DELETE CASCADE,
    channel     TEXT NOT NULL DEFAULT 'both'
                    CHECK (channel IN ('push', 'sms', 'both')),
    quiet_from  TIME,           -- e.g. 22:00 — start of quiet window
    quiet_until TIME,           -- e.g. 07:00 — end of quiet window (can cross midnight)
    language    TEXT NOT NULL DEFAULT 'en',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT notification_preferences_patient_unique UNIQUE (patient_id)
);

COMMENT ON TABLE notification_preferences IS
    'Per-patient notification channel and quiet-hour preferences';

CREATE INDEX IF NOT EXISTS idx_notification_preferences_patient_id
    ON notification_preferences (patient_id);

CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_notification_preferences_updated_at
    ON notification_preferences;

CREATE TRIGGER trg_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_notification_preferences_updated_at();


-- ---------------------------------------------------------------------------
-- Supporting: device_token on patient_profiles (used by FCM in Tasks 24 & 26)
-- ---------------------------------------------------------------------------

ALTER TABLE patient_profiles
    ADD COLUMN IF NOT EXISTS device_token TEXT;

COMMENT ON COLUMN patient_profiles.device_token IS
    'Firebase FCM device token for push notifications — updated by Flutter on login';


-- ---------------------------------------------------------------------------
-- Supporting: idempotency constraint for dose_logs (Task 26 reruns)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'dose_logs_dose_id_unique'
    ) THEN
        ALTER TABLE dose_logs
            ADD CONSTRAINT dose_logs_dose_id_unique UNIQUE (dose_id);
    END IF;
END $$;

-- =============================================================================
-- End of migrations
-- =============================================================================
