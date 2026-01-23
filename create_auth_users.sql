-- ============================================================================
-- CREATE AUTH USERS VIA SQL
-- Run this in Supabase SQL Editor BEFORE running complete_user_seed.sql
-- ============================================================================

-- IMPORTANT: 
-- 1. Go to Supabase SQL Editor
-- 2. Copy all SQL from this file
-- 3. Paste and click "Run"
-- 4. You should see success messages
-- 5. Then run complete_user_seed.sql

-- ============================================================================
-- Create Placement Rep Account (YOU)
-- ============================================================================
-- Email: 25mx354@psgtech.ac.in | Password: psgtech@2025
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  '25mx354@psgtech.ac.in',
  crypt('psgtech@2025', gen_salt('bf')),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Tino Britty J"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- Create Dummy Student Account
-- ============================================================================
-- Email: dummy.student@psgtech.ac.in | Password: student123
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'dummy.student@psgtech.ac.in',
  crypt('student123', gen_salt('bf')),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Test Student"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- Create Dummy Team Leader Account
-- ============================================================================
-- Email: dummy.leader@psgtech.ac.in | Password: leader123
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'dummy.leader@psgtech.ac.in',
  crypt('leader123', gen_salt('bf')),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Test Team Leader"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- Create Dummy Coordinator Account
-- ============================================================================
-- Email: dummy.coordinator@psgtech.ac.in | Password: coordinator123
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'dummy.coordinator@psgtech.ac.in',
  crypt('coordinator123', gen_salt('bf')),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Test Coordinator"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Run this to verify all 4 auth users were created
SELECT email, 
       CASE WHEN raw_user_meta_data->>'name' IS NOT NULL 
            THEN raw_user_meta_data->>'name' 
            ELSE 'N/A' 
       END as name
FROM auth.users 
WHERE email IN (
  '25mx354@psgtech.ac.in',
  'dummy.student@psgtech.ac.in',
  'dummy.leader@psgtech.ac.in',
  'dummy.coordinator@psgtech.ac.in'
)
ORDER BY email;
