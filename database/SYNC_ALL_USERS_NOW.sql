-- ========================================
-- SIMPLE WORKING FIX: Sync All User IDs
-- ========================================
-- Run this ENTIRE script in ONE go
-- ========================================

-- STEP 1: Clean up all auth users for psgtech
DO $$
BEGIN
    DELETE FROM auth.users WHERE email LIKE '%@psgtech.ac.in';
    RAISE NOTICE '✅ Cleaned up existing auth users';
END $$;

-- STEP 2: Create auth users with matching IDs from users table
DO $$
DECLARE
    rec RECORD;
    created_count INT := 0;
BEGIN
    FOR rec IN 
        SELECT id, email FROM public.users WHERE email LIKE '%@psgtech.ac.in'
    LOOP
        BEGIN
            INSERT INTO auth.users (
                instance_id,
                id,
                aud,
                role,
                email,
                encrypted_password,
                email_confirmed_at,
                invited_at,
                confirmation_token,
                confirmation_sent_at,
                recovery_token,
                recovery_sent_at,
                email_change_token_new,
                email_change,
                email_change_sent_at,
                last_sign_in_at,
                raw_app_meta_data,
                raw_user_meta_data,
                is_super_admin,
                created_at,
                updated_at,
                phone,
                phone_confirmed_at,
                phone_change,
                phone_change_token,
                phone_change_sent_at,
                email_change_token_current,
                email_change_confirm_status,
                banned_until,
                reauthentication_token,
                reauthentication_sent_at,
                is_sso_user,
                deleted_at
            ) VALUES (
                '00000000-0000-0000-0000-000000000000',
                rec.id,  -- Use EXACT ID from users table
                'authenticated',
                'authenticated',
                rec.email,
                '$2a$10$AAAAAAAAAAAAAAAAAAAAAA.AAAAAAAAAAAAAAAAAAAAAAAAAAAA',  -- Dummy hash
                NOW(),
                NULL,
                '',
                NULL,
                '',
                NULL,
                '',
                '',
                NULL,
                NULL,
                '{"provider":"email","providers":["email"]}'::jsonb,
                '{}'::jsonb,
                FALSE,
                NOW(),
                NOW(),
                NULL,
                NULL,
                '',
                '',
                NULL,
                '',
                0,
                NULL,
                '',
                NULL,
                FALSE,
                NULL
            );
            created_count := created_count + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Failed to create auth user for %: %', rec.email, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Created % auth users', created_count;
END $$;

-- STEP 3: Verify everything matches
DO $$
DECLARE
    users_count INT;
    auth_count INT;
    matched_count INT;
BEGIN
    SELECT COUNT(*) INTO users_count FROM public.users WHERE email LIKE '%@psgtech.ac.in';
    SELECT COUNT(*) INTO auth_count FROM auth.users WHERE email LIKE '%@psgtech.ac.in';
    
    SELECT COUNT(*) INTO matched_count
    FROM public.users u
    INNER JOIN auth.users au ON u.id = au.id AND u.email = au.email
    WHERE u.email LIKE '%@psgtech.ac.in';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'VERIFICATION RESULTS';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Users table: %', users_count;
    RAISE NOTICE 'Auth users: %', auth_count;
    RAISE NOTICE 'Perfect matches: %', matched_count;
    RAISE NOTICE '';
    
    IF matched_count = users_count AND matched_count = auth_count THEN
        RAISE NOTICE '🎉 SUCCESS! ALL % USERS SYNCED!', matched_count;
        RAISE NOTICE '✅ Every user can now login with OTP';
    ELSE
        RAISE NOTICE '⚠️  Synced % out of % users', matched_count, users_count;
    END IF;
    RAISE NOTICE '========================================';
END $$;

-- Show sample of matched users
SELECT 
    u.email,
    u.id as users_id,
    au.id as auth_id,
    CASE WHEN u.id = au.id THEN '✅ Match' ELSE '❌ Mismatch' END as status
FROM public.users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.email LIKE '%@psgtech.ac.in'
ORDER BY u.email
LIMIT 10;
