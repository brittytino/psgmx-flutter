-- ========================================
-- PSG BUNKER - Bulk User Onboarding + Repair
-- ========================================
-- File 7: Ensure all whitelist students are fully onboarded.
--
-- What this script does:
-- 1) Creates missing auth.users accounts for whitelist emails.
-- 2) Repairs missing public.users rows (even if trigger did not fire earlier).
-- 3) Syncs profile fields from whitelist -> public.users.
--
-- Run this AFTER 05_seed_data.sql in Supabase SQL Editor.
-- ========================================

-- 1) Create missing auth users for every whitelist email.
--    Requires elevated privileges (SQL Editor / service role context).
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    aud,
    role,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
)
SELECT
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000'::uuid,
    w.email,
    crypt(gen_random_uuid()::text, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    'authenticated',
    'authenticated',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    jsonb_build_object('name', w.name, 'reg_no', w.reg_no),
    false,
    '',
    '',
    '',
    ''
FROM public.whitelist w
WHERE NOT EXISTS (
    SELECT 1
    FROM auth.users au
    WHERE lower(au.email) = lower(w.email)
);

-- 2) Backfill missing public.users rows using auth UUID + whitelist profile.
WITH wl_auth AS (
    SELECT
        au.id AS auth_id,
        w.email,
        w.reg_no,
        w.name,
        w.team_id,
        COALESCE(w.batch, 'G1') AS batch,
        COALESCE(
            w.roles,
            '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb
        ) AS roles,
        w.leetcode_username,
        w.dob
    FROM public.whitelist w
    JOIN auth.users au
        ON lower(au.email) = lower(w.email)
)
INSERT INTO public.users (
    id,
    email,
    reg_no,
    name,
    team_id,
    batch,
    roles,
    leetcode_username,
    dob,
    birthday_notifications_enabled,
    leetcode_notifications_enabled,
    task_reminders_enabled,
    attendance_alerts_enabled,
    announcements_enabled,
    created_at,
    updated_at
)
SELECT
    wa.auth_id,
    wa.email,
    wa.reg_no,
    wa.name,
    wa.team_id,
    wa.batch,
    wa.roles,
    wa.leetcode_username,
    wa.dob,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    NOW(),
    NOW()
FROM wl_auth wa
LEFT JOIN public.users u
    ON u.id = wa.auth_id
WHERE u.id IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM public.users ux
      WHERE lower(ux.email) = lower(wa.email)
         OR upper(ux.reg_no) = upper(wa.reg_no)
  );

-- 3) Sync existing public.users profile fields from whitelist for consistency.
WITH wl_auth AS (
    SELECT
        au.id AS auth_id,
        w.email,
        w.reg_no,
        w.name,
        w.team_id,
        COALESCE(w.batch, 'G1') AS batch,
        COALESCE(
            w.roles,
            '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb
        ) AS roles,
        w.leetcode_username,
        w.dob
    FROM public.whitelist w
    JOIN auth.users au
        ON lower(au.email) = lower(w.email)
)
UPDATE public.users u
SET
    email = wa.email,
    reg_no = wa.reg_no,
    name = wa.name,
    team_id = wa.team_id,
    batch = wa.batch,
    roles = wa.roles,
    leetcode_username = wa.leetcode_username,
    dob = wa.dob,
    updated_at = NOW()
FROM wl_auth wa
WHERE u.id = wa.auth_id;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    whitelist_count INT;
    auth_whitelist_count INT;
    public_whitelist_count INT;
    missing_auth_count INT;
    missing_public_count INT;
    conflicting_public_rows INT;
BEGIN
    SELECT COUNT(*) INTO whitelist_count
    FROM public.whitelist;

    SELECT COUNT(*) INTO auth_whitelist_count
    FROM public.whitelist w
    JOIN auth.users au ON lower(au.email) = lower(w.email);

    SELECT COUNT(*) INTO public_whitelist_count
    FROM public.whitelist w
    JOIN public.users u ON lower(u.email) = lower(w.email);

    SELECT COUNT(*) INTO missing_auth_count
    FROM public.whitelist w
    WHERE NOT EXISTS (
        SELECT 1
        FROM auth.users au
        WHERE lower(au.email) = lower(w.email)
    );

    SELECT COUNT(*) INTO missing_public_count
    FROM public.whitelist w
    JOIN auth.users au ON lower(au.email) = lower(w.email)
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = au.id
    );

    SELECT COUNT(*) INTO conflicting_public_rows
    FROM public.whitelist w
    JOIN auth.users au ON lower(au.email) = lower(w.email)
    JOIN public.users u ON lower(u.email) = lower(w.email)
    WHERE u.id <> au.id;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'BULK ONBOARDING COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Whitelist students       : %', whitelist_count;
    RAISE NOTICE 'auth.users matched       : %', auth_whitelist_count;
    RAISE NOTICE 'public.users matched     : %', public_whitelist_count;
    RAISE NOTICE 'Missing in auth.users    : %', missing_auth_count;
    RAISE NOTICE 'Missing in public.users  : %', missing_public_count;
    RAISE NOTICE 'Email-ID conflicts found : %', conflicting_public_rows;

    IF missing_auth_count = 0 AND missing_public_count = 0 AND conflicting_public_rows = 0 THEN
        RAISE NOTICE 'STATUS: All whitelist students are fully onboarded.';
    ELSE
        RAISE NOTICE 'STATUS: Some inconsistencies remain. Review counts above.';
    END IF;

    RAISE NOTICE '========================================';
END $$;
