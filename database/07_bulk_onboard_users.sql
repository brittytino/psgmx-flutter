-- ========================================
-- PSG BUNKER – Bulk User Onboarding
-- ========================================
-- File 7: Pre-create auth.users for all 123 whitelist entries
-- so students can LOGIN via OTP (not signup).
-- 
-- Run this AFTER 05_seed_data.sql in Supabase SQL Editor.
-- ========================================

-- Insert all whitelist emails into auth.users
-- (this requires service_role / elevated permissions in SQL Editor)
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
    gen_random_uuid(),                              -- id (UUID)
    '00000000-0000-0000-0000-000000000000'::uuid,   -- instance_id (default)
    w.email,                                        -- email
    '',                                             -- encrypted_password (empty - OTP only)
    NOW(),                                          -- email_confirmed_at (confirmed = can login)
    NOW(),                                          -- created_at
    NOW(),                                          -- updated_at
    'authenticated',                                -- aud (audience)
    'authenticated',                                -- role
    '{"provider": "email", "providers": ["email"]}'::jsonb,  -- raw_app_meta_data
    jsonb_build_object('name', w.name, 'reg_no', w.reg_no),  -- raw_user_meta_data
    false,                                          -- is_super_admin
    '',                                             -- confirmation_token
    '',                                             -- email_change
    '',                                             -- email_change_token_new
    ''                                              -- recovery_token
FROM whitelist w
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users au WHERE au.email = w.email
);

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    auth_users_count INT;
    public_users_count INT;
BEGIN
    SELECT COUNT(*) INTO auth_users_count FROM auth.users;
    SELECT COUNT(*) INTO public_users_count FROM public.users;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ BULK ONBOARDING COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Auth users created: %', auth_users_count;
    RAISE NOTICE 'Public users (via trigger): %', public_users_count;
    RAISE NOTICE '';
    RAISE NOTICE 'All 123 students can now LOGIN via OTP.';
    RAISE NOTICE '(Supabase will treat them as existing users, not signups)';
    RAISE NOTICE '========================================';
END $$;
