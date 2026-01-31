-- ========================================
-- PSG MX PLACEMENT APP - SAMPLE DATA (OPTIONAL)
-- ========================================
-- File 5 of 5: Sample Attendance Data
-- 
-- This file is OPTIONAL. Run only if you want
-- to populate sample attendance for testing.
-- Run this AFTER 04_rls_policies.sql
-- ========================================

-- ========================================
-- SCHEDULED CLASS DATES
-- ========================================
-- Add scheduled dates for placement classes
INSERT INTO scheduled_attendance_dates (date, notes) VALUES
    ('2026-01-19', 'Session 1 - Arrays & Strings'),
    ('2026-01-20', 'Session 2 - Linked Lists'),
    ('2026-01-22', 'Session 3 - Trees & Graphs'),
    ('2026-01-27', 'Session 4 - Dynamic Programming'),
    ('2026-01-28', 'Session 5 - System Design'),
    ('2026-01-31', 'Session 6 - Mock Interviews'),
    ('2026-02-03', 'Session 7 - HR Round Prep'),
    ('2026-02-04', 'Session 8 - Final Review')
ON CONFLICT (date) DO NOTHING;

-- ========================================
-- MARK TODAY'S ATTENDANCE (All Present)
-- ========================================
-- Change CURRENT_DATE to a specific date if needed

INSERT INTO attendance_records (user_id, date, team_id, status, marked_by, created_at)
SELECT 
    u.id,
    CURRENT_DATE,
    u.team_id,
    'PRESENT',
    (SELECT id FROM users WHERE roles->>'isPlacementRep' = 'true' LIMIT 1),
    NOW()
FROM users u
WHERE u.roles->>'isStudent' = 'true'
ON CONFLICT (user_id, date) 
DO UPDATE SET 
    status = EXCLUDED.status,
    marked_by = EXCLUDED.marked_by;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    scheduled_count INT;
    attendance_count INT;
    present_count INT;
    absent_count INT;
BEGIN
    SELECT COUNT(*) INTO scheduled_count FROM scheduled_attendance_dates;
    SELECT COUNT(*) INTO attendance_count FROM attendance_records WHERE date = CURRENT_DATE;
    SELECT COUNT(*) INTO present_count FROM attendance_records WHERE date = CURRENT_DATE AND status = 'PRESENT';
    SELECT COUNT(*) INTO absent_count FROM attendance_records WHERE date = CURRENT_DATE AND status = 'ABSENT';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STEP 5 COMPLETE: SAMPLE DATA';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Scheduled class dates: %', scheduled_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Today''s Attendance (%):',  CURRENT_DATE;
    RAISE NOTICE '  Total records: %', attendance_count;
    RAISE NOTICE '  Present: %', present_count;
    RAISE NOTICE '  Absent: %', absent_count;
    RAISE NOTICE '';
    RAISE NOTICE '🎉 DATABASE SETUP COMPLETE!';
    RAISE NOTICE '';
    RAISE NOTICE 'You can now:';
    RAISE NOTICE '  1. Start the Flutter app';
    RAISE NOTICE '  2. Login with any whitelisted email';
    RAISE NOTICE '  3. View attendance, LeetCode stats, etc.';
    RAISE NOTICE '========================================';
END $$;

-- ========================================
-- UTILITY: MARK SPECIFIC STUDENTS ABSENT
-- ========================================
-- Uncomment and modify the emails to mark specific students absent

/*
UPDATE attendance_records ar
SET status = 'ABSENT'
FROM users u
WHERE ar.user_id = u.id
  AND ar.date = CURRENT_DATE
  AND u.email IN (
      '25mx101@psgtech.ac.in',
      '25mx102@psgtech.ac.in'
  );
*/

-- ========================================
-- UTILITY: MARK ATTENDANCE FOR A PAST DATE
-- ========================================
-- Uncomment to mark all students for a specific past date

/*
INSERT INTO attendance_records (user_id, date, team_id, status, marked_by, created_at)
SELECT 
    u.id,
    '2026-01-27'::DATE,  -- Change this date
    u.team_id,
    'PRESENT',
    (SELECT id FROM users WHERE roles->>'isPlacementRep' = 'true' LIMIT 1),
    NOW()
FROM users u
WHERE u.roles->>'isStudent' = 'true'
ON CONFLICT (user_id, date) DO NOTHING;
*/

-- ========================================
-- UTILITY: VIEW ATTENDANCE SUMMARY
-- ========================================
-- Run this to see attendance stats

/*
SELECT 
    name,
    reg_no,
    team_id,
    present_count,
    absent_count,
    attendance_percentage
FROM student_attendance_summary
ORDER BY attendance_percentage DESC
LIMIT 20;
*/

-- ========================================
-- UTILITY: VIEW TEAM SUMMARY
-- ========================================

/*
SELECT 
    team_id,
    total_members,
    avg_attendance_percentage,
    total_present,
    total_absent
FROM team_attendance_summary
ORDER BY avg_attendance_percentage DESC;
*/
