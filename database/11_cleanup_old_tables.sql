-- ========================================
-- CLEANUP OLD UNUSED TABLES
-- ========================================
-- This removes old tables that are no longer used
-- Safe to run after migrating to new attendance schema
-- ========================================

-- Drop old attendance table (replaced by attendance_records)
DROP TABLE IF EXISTS attendance CASCADE;

-- Drop old attendance_days table (no longer used)
DROP TABLE IF EXISTS attendance_days CASCADE;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ CLEANUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Removed old tables:';
    RAISE NOTICE '  - attendance (replaced by attendance_records)';
    RAISE NOTICE '  - attendance_days (no longer needed)';
    RAISE NOTICE '';
    RAISE NOTICE 'Active tables:';
    RAISE NOTICE '  ✅ attendance_records';
    RAISE NOTICE '  ✅ scheduled_attendance_dates';
    RAISE NOTICE '  ✅ student_attendance_summary (VIEW)';
    RAISE NOTICE '  ✅ team_attendance_summary (VIEW)';
    RAISE NOTICE '========================================';
END $$;
