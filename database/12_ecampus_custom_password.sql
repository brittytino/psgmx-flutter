-- ============================================================
-- Migration 12 – Custom eCampus Passwords (2026-02-26)
-- ============================================================
-- Some students change their eCampus portal login password from
-- the default DOB-derived format (e.g. 08jul04) to a custom one.
-- This migration adds support for storing that custom password so
-- automated syncs continue to work correctly for those students.
--
-- Security design:
--   • ecampus_password is NEVER returned to the Flutter client.
--   • Column-level REVOKE prevents authenticated / anon PostgREST
--     requests from selecting it even if they ask for *.
--   • Only the service_role backend (ecampus_api.py) can read it.
--   • Students can WRITE their own row (existing UPDATE RLS covers it).
--   • ecampus_password_set is a safe boolean flag the app reads to
--     display "Custom password set" vs "Default (from DOB)".
-- ============================================================

-- 1. Add columns to the users table --------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS ecampus_password     TEXT    DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS ecampus_password_set BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Column-level security: revoke SELECT on the secret column
--    from every non-service role.
REVOKE SELECT (ecampus_password) ON public.users FROM authenticated;
REVOKE SELECT (ecampus_password) ON public.users FROM anon;

-- 3. Documentation
COMMENT ON COLUMN public.users.ecampus_password IS
  'Custom eCampus portal password. Set ONLY when the student changed '
  'their password from the default DOB-derived format. '
  'NEVER exposed to the client – readable only by service_role (backend).';

COMMENT ON COLUMN public.users.ecampus_password_set IS
  'True when the student has saved a custom eCampus password in the app. '
  'Safe to read on the client side.';

-- 4. Sync the flag for any passwords that may already be present
--    (no-op on a fresh install; safe to run multiple times).
UPDATE public.users
SET ecampus_password_set = TRUE
WHERE ecampus_password IS NOT NULL
  AND ecampus_password != ''
  AND ecampus_password_set = FALSE;
