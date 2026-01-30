-- ========================================
-- INSERT ATTENDANCE DATA FOR ALL 5 DATES
-- ========================================
-- Run this AFTER 08 and 09 SQL files
-- This will populate attendance for all 123 students
-- for the 5 placement class dates
-- ========================================

-- Step 1: Verify scheduled dates exist
DO $$
DECLARE
    scheduled_count INT;
BEGIN
    SELECT COUNT(*) INTO scheduled_count FROM scheduled_attendance_dates;
    
    IF scheduled_count = 0 THEN
        RAISE EXCEPTION 'No scheduled dates found. Run 09_populate_scheduled_dates_and_helper.sql first!';
    END IF;
    
    RAISE NOTICE '✓ Found % scheduled dates', scheduled_count;
END $$;

-- Step 2: Insert attendance for Jan 19, 2026 (Session 1)
DO $$
DECLARE
    v_date DATE := '2026-01-19';
    v_count INT := 0;
BEGIN
    RAISE NOTICE 'Inserting attendance for %...', v_date;
    
    INSERT INTO attendance_records (date, student_id, team_id, status, marked_by)
    SELECT 
        v_date,
        u.id,
        u.team_id,
        'PRESENT',
        u.id
    FROM users u
    WHERE u.roles->>'isStudent' = 'true'
    ON CONFLICT (date, student_id) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '✓ Inserted % records for %', v_count, v_date;
END $$;

-- Step 3: Insert attendance for Jan 20, 2026 (Session 2)
DO $$
DECLARE
    v_date DATE := '2026-01-20';
    v_count INT := 0;
BEGIN
    RAISE NOTICE 'Inserting attendance for %...', v_date;
    
    INSERT INTO attendance_records (date, student_id, team_id, status, marked_by)
    SELECT 
        v_date,
        u.id,
        u.team_id,
        'PRESENT',
        u.id
    FROM users u
    WHERE u.roles->>'isStudent' = 'true'
    ON CONFLICT (date, student_id) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '✓ Inserted % records for %', v_count, v_date;
END $$;

-- Step 4: Insert attendance for Jan 22, 2026 (Session 3)
DO $$
DECLARE
    v_date DATE := '2026-01-22';
    v_count INT := 0;
BEGIN
    RAISE NOTICE 'Inserting attendance for %...', v_date;
    
    INSERT INTO attendance_records (date, student_id, team_id, status, marked_by)
    SELECT 
        v_date,
        u.id,
        u.team_id,
        'PRESENT',
        u.id
    FROM users u
    WHERE u.roles->>'isStudent' = 'true'
    ON CONFLICT (date, student_id) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '✓ Inserted % records for %', v_count, v_date;
END $$;

-- Step 5: Insert attendance for Jan 27, 2026 (Session 4)
DO $$
DECLARE
    v_date DATE := '2026-01-27';
    v_count INT := 0;
BEGIN
    RAISE NOTICE 'Inserting attendance for %...', v_date;
    
    INSERT INTO attendance_records (date, student_id, team_id, status, marked_by)
    SELECT 
        v_date,
        u.id,
        u.team_id,
        'PRESENT',
        u.id
    FROM users u
    WHERE u.roles->>'isStudent' = 'true'
    ON CONFLICT (date, student_id) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '✓ Inserted % records for %', v_count, v_date;
END $$;

-- Step 6: Insert attendance for Jan 29, 2026 (Session 5)
DO $$
DECLARE
    v_date DATE := '2026-01-29';
    v_count INT := 0;
BEGIN
    RAISE NOTICE 'Inserting attendance for %...', v_date;
    
    INSERT INTO attendance_records (date, student_id, team_id, status, marked_by)
    SELECT 
        v_date,
        u.id,
        u.team_id,
        'PRESENT',
        u.id
    FROM users u
    WHERE u.roles->>'isStudent' = 'true'
    ON CONFLICT (date, student_id) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '✓ Inserted % records for %', v_count, v_date;
END $$;

-- ========================================
-- VERIFICATION
-- ========================================

DO $$
DECLARE
    total_records INT;
    dates_count INT;
    students_count INT;
BEGIN
    -- Count total attendance records
    SELECT COUNT(*) INTO total_records FROM attendance_records;
    
    -- Count distinct dates
    SELECT COUNT(DISTINCT date) INTO dates_count FROM attendance_records;
    
    -- Count distinct students
    SELECT COUNT(DISTINCT student_id) INTO students_count FROM attendance_records;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ ATTENDANCE DATA INSERTION COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total records: %', total_records;
    RAISE NOTICE 'Unique dates: %', dates_count;
    RAISE NOTICE 'Unique students: %', students_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Expected: N records (students who signed up × 5 dates)';
    RAISE NOTICE 'NOTE: Only students who have signed up (in users table) will have records';
    
    IF students_count < 123 THEN
        RAISE WARNING '% out of 123 students have signed up and have attendance records', students_count;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Manually mark specific students as ABSENT if needed';
    RAISE NOTICE '  2. Run: UPDATE attendance_records SET status = ''ABSENT''';
    RAISE NOTICE '     WHERE date = ''2026-01-19'' AND student_id IN (...);';
    RAISE NOTICE '  3. Restart your Flutter app';
    RAISE NOTICE '  4. Test attendance screens';
    RAISE NOTICE '========================================';
END $$;

-- ========================================
-- QUICK QUERIES FOR MANUAL UPDATES
-- ========================================

-- Example: Mark specific students as ABSENT for Jan 19
/*
UPDATE attendance_records 
SET status = 'ABSENT', updated_at = NOW()
WHERE date = '2026-01-19' 
AND student_id IN (
    SELECT u.id FROM users u WHERE u.reg_no IN ('25MX101', '25MX102')
);
*/

-- View attendance for specific date
-- SELECT 
--     u.reg_no, 
--     u.name, 
--     ar.status,
--     ar.team_id
-- FROM attendance_records ar
-- LEFT JOIN users u ON ar.student_id = u.id
-- WHERE ar.date = '2026-01-19'
-- ORDER BY u.reg_no;

-- View student attendance summary (should show all 123 with data now)
-- SELECT * FROM student_attendance_summary ORDER BY reg_no;

-- View team attendance summary
-- SELECT * FROM team_attendance_summary ORDER BY team_id;
