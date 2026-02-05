-- ========================================
-- CORRECT FIX: Delete mismatched auth users and recreate with matching UUIDs
-- ========================================
-- This ensures auth.users.id = users.id for seamless login
-- ========================================

-- STEP 1: Delete ALL existing auth.users for @psgtech.ac.in
-- (They have wrong/mismatched UUIDs)
DELETE FROM auth.users 
WHERE email LIKE '%@psgtech.ac.in';

-- STEP 2: Create auth.users with EXACT UUIDs from public.users table
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT id, email FROM public.users WHERE email LIKE '%@psgtech.ac.in'
    LOOP
        -- Create auth user with the SAME UUID as users table
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            confirmation_token,
            aud,
            role,
            raw_app_meta_data,
            raw_user_meta_data
        ) VALUES (
            user_record.id,  -- ✅ SAME UUID from users table!
            '00000000-0000-0000-0000-000000000000',
            user_record.email,
            crypt('', gen_salt('bf')),
            NOW(),  -- Email pre-confirmed
            NOW(),
            NOW(),
            '',
            'authenticated',
            'authenticated',
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{}'::jsonb
        );
        
        RAISE NOTICE '✅ Created auth user: % with ID: %', user_record.email, user_record.id;
    END LOOP;
END $$;

-- STEP 3: Delete the database trigger (not needed anymore)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- ========================================
-- VERIFICATION - Check ALL IDs Match
-- ========================================
DO $$
DECLARE
    users_count INT;
    auth_count INT;
    matched_count INT;
    mismatch_count INT;
BEGIN
    SELECT COUNT(*) INTO users_count FROM public.users WHERE email LIKE '%@psgtech.ac.in';
    SELECT COUNT(*) INTO auth_count FROM auth.users WHERE email LIKE '%@psgtech.ac.in';
    
    -- Count matching IDs
    SELECT COUNT(*) INTO matched_count
    FROM public.users u
    INNER JOIN auth.users au ON u.id = au.id AND u.email = au.email
    WHERE u.email LIKE '%@psgtech.ac.in';
    
    -- Count mismatches
    SELECT COUNT(*) INTO mismatch_count
    FROM public.users u
    LEFT JOIN auth.users au ON u.email = au.email
    WHERE u.email LIKE '%@psgtech.ac.in' AND (au.id IS NULL OR u.id != au.id);
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ UUID SYNC COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Users in public.users: %', users_count;
    RAISE NOTICE 'Users in auth.users: %', auth_count;
    RAISE NOTICE 'Perfectly matched IDs: %', matched_count;
    RAISE NOTICE 'Mismatched IDs: %', mismatch_count;
    RAISE NOTICE '';
    
    IF matched_count = users_count AND mismatch_count = 0 THEN
        RAISE NOTICE '🎉 PERFECT! ALL % USERS SYNCED!', users_count;
        RAISE NOTICE '✅ auth.users.id = public.users.id for everyone';
        RAISE NOTICE '✅ All students can now login with OTP';
    ELSE
        RAISE NOTICE '❌ ERROR: % mismatched IDs found', mismatch_count;
        RAISE NOTICE 'Run the script again or check manually';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'TEST LOGIN NOW:';
    RAISE NOTICE '1. Restart Flutter app';
    RAISE NOTICE '2. Enter any student email';
    RAISE NOTICE '3. Get 6-digit OTP';
    RAISE NOTICE '4. Enter code';
    RAISE NOTICE '5. Dashboard loads instantly ✅';
    RAISE NOTICE '========================================';
END $$;

-- Verify query - Should show ALL as "✅ Match"
SELECT 
    'UUID Verification' as check_type,
    u.email,
    u.id as users_id,
    au.id as auth_id,
    CASE 
        WHEN u.id = au.id THEN '✅ Match' 
        WHEN au.id IS NULL THEN '❌ No auth user'
        ELSE '❌ Mismatch' 
    END as status
FROM public.users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.email LIKE '%@psgtech.ac.in'
ORDER BY u.email
LIMIT 20;
