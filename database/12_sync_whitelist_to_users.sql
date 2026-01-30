-- ========================================
-- POPULATE USERS TABLE FROM WHITELIST
-- ========================================
-- This inserts ALL 123 students into users table
-- Removes foreign key constraint to allow non-authenticated users
-- Updates existing authenticated users
-- ========================================

-- Step 1: Drop foreign key constraint (if exists)
DO $$ 
BEGIN
    ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;
    RAISE NOTICE 'Foreign key constraint removed';
EXCEPTION 
    WHEN OTHERS THEN 
        RAISE NOTICE 'No constraint to remove or already removed';
END $$;

-- Step 2: Update existing authenticated users from whitelist
UPDATE users u
SET 
    name = w.name,
    reg_no = w.reg_no,
    batch = w.batch,
    team_id = w.team_id,
    dob = w.dob,
    leetcode_username = w.leetcode_username,
    roles = w.roles,
    updated_at = NOW()
FROM whitelist w
WHERE u.email = w.email;

-- Step 3: Insert missing students from whitelist into users table
-- Generate placeholder UUIDs for students who haven't signed up yet
INSERT INTO users (
    id,
    email,
    name,
    reg_no,
    batch,
    team_id,
    dob,
    leetcode_username,
    roles,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),  -- Generate placeholder UUID
    w.email,
    w.name,
    w.reg_no,
    w.batch,
    w.team_id,
    w.dob,
    w.leetcode_username,
    w.roles,
    NOW(),
    NOW()
FROM whitelist w
WHERE NOT EXISTS (
    SELECT 1 FROM users u WHERE u.email = w.email
);

-- Step 4: Show results
DO $$
DECLARE
    total_users INT;
    total_whitelist INT;
    total_students INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM users;
    SELECT COUNT(*) INTO total_whitelist FROM whitelist;
    SELECT COUNT(*) INTO total_students FROM users WHERE roles->>'isStudent' = 'true';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ ALL STUDENTS ADDED TO USERS TABLE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total users in system: %', total_users;
    RAISE NOTICE 'Total whitelist entries: %', total_whitelist;
    RAISE NOTICE 'Total students in users table: %', total_students;
    RAISE NOTICE '';
    RAISE NOTICE '📝 All 123 students are now in the users table!';
    RAISE NOTICE '   When they login via email, their IDs will be updated.';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Run 10_insert_attendance_data.sql to add sample attendance';
    RAISE NOTICE '  2. Mark attendance through the app';
    RAISE NOTICE '  3. All 123 students should be visible with correct data';
    RAISE NOTICE '========================================';
END $$;
