-- FCM device tokens — Phase 4b (push notifications)
-- Stores one row per device per user (patient or caregiver).
-- user_id = profiles.id / auth.users.id (the JWT 'sub'). No FK so caregivers
-- without a profiles row can still register a token.

CREATE TABLE IF NOT EXISTS fcm_tokens (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     uuid NOT NULL,
    token       text NOT NULL UNIQUE,
    platform    text,
    created_at  timestamptz DEFAULT now(),
    updated_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens (user_id);
