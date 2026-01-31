-- ========================================
-- PSG MX PLACEMENT APP - FUNCTIONS & VIEWS
-- ========================================
-- File 3 of 5: Helper Functions & Analytics Views
-- 
-- Creates functions for role checking, date validation,
-- and views for attendance summaries.
-- Run this AFTER 02_data.sql
-- ========================================

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Check if user has a specific role
CREATE OR REPLACE FUNCTION has_role(user_id UUID, role_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_roles JSONB;
BEGIN
    SELECT roles INTO user_roles FROM users WHERE id = user_id;
    RETURN COALESCE((user_roles->>role_name)::BOOLEAN, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is placement rep
CREATE OR REPLACE FUNCTION is_placement_rep(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isPlacementRep');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is coordinator
CREATE OR REPLACE FUNCTION is_coordinator(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isCoordinator');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is team leader
CREATE OR REPLACE FUNCTION is_team_leader(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isTeamLeader');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's team ID
CREATE OR REPLACE FUNCTION get_user_team(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_team TEXT;
BEGIN
    SELECT team_id INTO user_team FROM users WHERE id = user_id;
    RETURN user_team;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if date is scheduled for attendance
CREATE OR REPLACE FUNCTION is_date_scheduled(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM scheduled_attendance_dates 
        WHERE date = check_date
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Get scheduled dates in a range
CREATE OR REPLACE FUNCTION get_scheduled_dates(start_date DATE, end_date DATE)
RETURNS TABLE (
    id UUID,
    date DATE,
    scheduled_by UUID,
    notes TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sad.id,
        sad.date,
        sad.scheduled_by,
        sad.notes,
        sad.created_at,
        sad.updated_at
    FROM scheduled_attendance_dates sad
    WHERE sad.date >= start_date AND sad.date <= end_date
    ORDER BY sad.date ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Get team attendance for a specific date
CREATE OR REPLACE FUNCTION get_team_attendance_for_date(
    check_date DATE,
    check_team_id TEXT
)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    reg_no TEXT,
    status TEXT,
    marked_by UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as student_id,
        u.name as student_name,
        u.reg_no,
        COALESCE(ar.status, 'NA') as status,
        ar.marked_by
    FROM users u
    LEFT JOIN attendance_records ar ON u.id = ar.user_id AND ar.date = check_date
    WHERE u.team_id = check_team_id
    AND u.roles->>'isStudent' = 'true'
    ORDER BY u.reg_no;
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================
-- TRIGGERS
-- ========================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_attendance_records_updated_at ON attendance_records;
CREATE TRIGGER update_attendance_records_updated_at 
    BEFORE UPDATE ON attendance_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_scheduled_dates_updated_at ON scheduled_attendance_dates;
CREATE TRIGGER update_scheduled_dates_updated_at 
    BEFORE UPDATE ON scheduled_attendance_dates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_tasks_updated_at ON daily_tasks;
CREATE TRIGGER update_daily_tasks_updated_at 
    BEFORE UPDATE ON daily_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- VIEWS FOR ANALYTICS
-- ========================================

-- Drop existing views
DROP VIEW IF EXISTS team_attendance_summary CASCADE;
DROP VIEW IF EXISTS student_attendance_summary CASCADE;

-- Student Attendance Summary
-- Shows attendance stats for all 123 students
CREATE VIEW student_attendance_summary AS
SELECT 
    u.id as student_id,
    u.id as user_id,  -- Alias for compatibility
    u.email,
    u.reg_no,
    u.name,
    u.team_id,
    u.batch,
    COALESCE(present.cnt, 0) as present_count,
    COALESCE(absent.cnt, 0) as absent_count,
    COALESCE(present.cnt, 0) + COALESCE(absent.cnt, 0) as total_working_days,
    CASE 
        WHEN COALESCE(present.cnt, 0) + COALESCE(absent.cnt, 0) = 0 THEN 0.0
        ELSE ROUND(
            (COALESCE(present.cnt, 0)::NUMERIC / 
             (COALESCE(present.cnt, 0) + COALESCE(absent.cnt, 0))::NUMERIC) * 100,
            1
        )
    END as attendance_percentage
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM attendance_records
    WHERE status = 'PRESENT'
    GROUP BY user_id
) present ON u.id = present.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM attendance_records
    WHERE status = 'ABSENT'
    GROUP BY user_id
) absent ON u.id = absent.user_id
WHERE u.roles->>'isStudent' = 'true'
ORDER BY u.reg_no;

-- Team Attendance Summary
-- Shows aggregated stats per team
CREATE VIEW team_attendance_summary AS
SELECT 
    team_id,
    COUNT(*) as total_members,
    ROUND(AVG(attendance_percentage), 1) as avg_attendance_percentage,
    SUM(present_count) as total_present,
    SUM(absent_count) as total_absent
FROM student_attendance_summary
WHERE team_id IS NOT NULL
GROUP BY team_id
ORDER BY team_id;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    fn_count INT;
    view_count INT;
BEGIN
    SELECT COUNT(*) INTO fn_count 
    FROM pg_proc 
    WHERE proname IN ('has_role', 'is_placement_rep', 'is_coordinator', 'is_team_leader', 'get_user_team', 'is_date_scheduled');
    
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_name IN ('student_attendance_summary', 'team_attendance_summary');
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STEP 3 COMPLETE: FUNCTIONS & VIEWS';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Functions created: %', fn_count;
    RAISE NOTICE 'Views created: %', view_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Functions:';
    RAISE NOTICE '  • has_role(user_id, role_name)';
    RAISE NOTICE '  • is_placement_rep(user_id)';
    RAISE NOTICE '  • is_coordinator(user_id)';
    RAISE NOTICE '  • is_team_leader(user_id)';
    RAISE NOTICE '  • get_user_team(user_id)';
    RAISE NOTICE '  • is_date_scheduled(date)';
    RAISE NOTICE '';
    RAISE NOTICE 'Views:';
    RAISE NOTICE '  • student_attendance_summary';
    RAISE NOTICE '  • team_attendance_summary';
    RAISE NOTICE '';
    RAISE NOTICE 'NEXT: Run 04_rls_policies.sql';
    RAISE NOTICE '========================================';
END $$;
