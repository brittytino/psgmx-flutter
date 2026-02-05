-- ========================================
-- COMPLETE FIX: Disable Email Confirmation + Mark Users as Confirmed
-- ========================================
-- Run this ENTIRE script in Supabase SQL Editor
-- This will make ALL users able to login with OTP
-- ========================================

-- STEP 1: Disable email confirmation requirement (if config table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'config') THEN
    UPDATE auth.config 
    SET config = jsonb_set(
      config, 
      '{MAILER_AUTOCONFIRM}', 
      'true'::jsonb
    )
    WHERE config ? 'MAILER_AUTOCONFIRM';
    
    RAISE NOTICE '✅ Email auto-confirmation enabled in config';
  ELSE
    RAISE NOTICE '⚠️  Config table not found - change setting in Dashboard UI';
  END IF;
END $$;

-- STEP 2: Mark ALL existing auth users as email-confirmed
-- This allows them to receive OTP tokens instead of confirmation links
UPDATE auth.users
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    confirmation_token = '',
    confirmation_sent_at = NULL,
    updated_at = NOW()
WHERE email LIKE '%@psgtech.ac.in'
  AND (email_confirmed_at IS NULL OR confirmation_token IS NOT NULL OR confirmation_token != '');

-- STEP 3: Ensure database trigger exists for auto-profile creation
-- (This was created earlier, but let's make sure it's active)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Only create profile if user is in whitelist
  IF EXISTS (SELECT 1 FROM public.whitelist WHERE email = NEW.email) THEN
    
    INSERT INTO public.users (
      id, 
      email, 
      reg_no, 
      name, 
      batch, 
      team_id, 
      roles,
      dob,
      leetcode_username,
      birthday_notifications_enabled,
      leetcode_notifications_enabled
    )
    SELECT 
      NEW.id,
      w.email,
      w.reg_no,
      w.name,
      COALESCE(w.batch, 'G1'),
      w.team_id,
      COALESCE(w.roles, '{"isStudent": true}'::jsonb),
      w.dob,
      w.leetcode_username,
      true,
      true
    FROM public.whitelist w
    WHERE w.email = NEW.email
    ON CONFLICT (email) DO UPDATE SET
      id = EXCLUDED.id,
      reg_no = EXCLUDED.reg_no,
      name = EXCLUDED.name,
      batch = EXCLUDED.batch,
      team_id = EXCLUDED.team_id,
      roles = EXCLUDED.roles,
      dob = EXCLUDED.dob,
      leetcode_username = EXCLUDED.leetcode_username;
    
    RAISE LOG 'Profile created for user: %', NEW.email;
  ELSE
    RAISE LOG 'User not in whitelist: %', NEW.email;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't block auth
    RAISE LOG 'Error creating profile for %: %', NEW.email, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger (drop first to avoid conflicts)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    total_users INT;
    confirmed_users INT;
    whitelist_count INT;
    trigger_exists BOOL;
    autoconfirm_setting TEXT;
BEGIN
    -- Count users
    SELECT COUNT(*) INTO total_users 
    FROM auth.users 
    WHERE email LIKE '%@psgtech.ac.in';
    
    SELECT COUNT(*) INTO confirmed_users 
    FROM auth.users 
    WHERE email LIKE '%@psgtech.ac.in' 
    AND email_confirmed_at IS NOT NULL;
    
    SELECT COUNT(*) INTO whitelist_count 
    FROM public.whitelist;
    
    -- Check trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'on_auth_user_created'
    ) INTO trigger_exists;
    
    -- Check autoconfirm setting
    BEGIN
        SELECT config->>'MAILER_AUTOCONFIRM' INTO autoconfirm_setting
        FROM auth.config
        WHERE config ? 'MAILER_AUTOCONFIRM'
        LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        autoconfirm_setting := 'not_found';
    END;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ PRODUCTION FIX COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Whitelist entries: % students', whitelist_count;
    RAISE NOTICE 'Auth users exist: %', total_users;
    RAISE NOTICE 'Email confirmed: %', confirmed_users;
    RAISE NOTICE 'Auto-profile trigger: %', CASE WHEN trigger_exists THEN '✅ ACTIVE' ELSE '❌ NOT FOUND' END;
    RAISE NOTICE 'Email autoconfirm: %', COALESCE(autoconfirm_setting, 'default');
    RAISE NOTICE '';
    
    IF confirmed_users = total_users AND total_users > 0 THEN
        RAISE NOTICE '✅ ALL USERS CAN NOW LOGIN WITH OTP!';
    ELSIF total_users = 0 THEN
        RAISE NOTICE '⚠️  No users in auth.users yet';
        RAISE NOTICE 'Users will be created when they request OTP';
    ELSE
        RAISE NOTICE '⚠️  % users still need confirmation', (total_users - confirmed_users);
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'TEST NOW:';
    RAISE NOTICE '1. Restart Flutter app';
    RAISE NOTICE '2. Try any student email (e.g., 25mx343@psgtech.ac.in)';
    RAISE NOTICE '3. Click "Get OTP"';
    RAISE NOTICE '4. Check email for 6-digit code';
    RAISE NOTICE '5. Enter code → Login successful ✅';
    RAISE NOTICE '========================================';
END $$;
