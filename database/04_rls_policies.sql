-- ========================================
-- PSG MX PLACEMENT APP - ROW LEVEL SECURITY
-- ========================================
-- File 4 of 5: RLS Policies (Access Control)
-- 
-- Defines who can read/write what data.
-- Run this AFTER 03_functions.sql
-- ========================================

-- ========================================
-- ENABLE RLS ON ALL TABLES
-- ========================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE leetcode_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_attendance_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads ENABLE ROW LEVEL SECURITY;

-- ========================================
-- USERS TABLE POLICIES
-- ========================================

-- Users can read their own data
DROP POLICY IF EXISTS "users_read_own" ON users;
CREATE POLICY "users_read_own" ON users
    FOR SELECT USING (auth.uid() = id);

-- Placement reps can read all users
DROP POLICY IF EXISTS "users_read_placement_rep" ON users;
CREATE POLICY "users_read_placement_rep" ON users
    FOR SELECT USING (is_placement_rep(auth.uid()));

-- Team leaders can read their team
DROP POLICY IF EXISTS "users_read_team" ON users;
CREATE POLICY "users_read_team" ON users
    FOR SELECT USING (
        is_team_leader(auth.uid()) 
        AND team_id = get_user_team(auth.uid())
    );

-- Coordinators can read all
DROP POLICY IF EXISTS "users_read_coordinator" ON users;
CREATE POLICY "users_read_coordinator" ON users
    FOR SELECT USING (is_coordinator(auth.uid()));

-- Users can update their own profile
DROP POLICY IF EXISTS "users_update_own" ON users;
CREATE POLICY "users_update_own" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Placement reps can update any user
DROP POLICY IF EXISTS "users_update_placement_rep" ON users;
CREATE POLICY "users_update_placement_rep" ON users
    FOR UPDATE USING (is_placement_rep(auth.uid()));

-- New user signup
DROP POLICY IF EXISTS "users_insert_auth" ON users;
CREATE POLICY "users_insert_auth" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ========================================
-- WHITELIST TABLE POLICIES
-- ========================================

DROP POLICY IF EXISTS "whitelist_read_all" ON whitelist;
CREATE POLICY "whitelist_read_all" ON whitelist
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "whitelist_manage_placement_rep" ON whitelist;
CREATE POLICY "whitelist_manage_placement_rep" ON whitelist
    FOR ALL USING (is_placement_rep(auth.uid()));

-- ========================================
-- LEETCODE_STATS TABLE POLICIES
-- ========================================

DROP POLICY IF EXISTS "leetcode_stats_read_all" ON leetcode_stats;
CREATE POLICY "leetcode_stats_read_all" ON leetcode_stats
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "leetcode_stats_manage_auth" ON leetcode_stats;
CREATE POLICY "leetcode_stats_manage_auth" ON leetcode_stats
    FOR ALL USING (auth.role() = 'authenticated');

-- ========================================
-- DAILY_TASKS TABLE POLICIES
-- ========================================

DROP POLICY IF EXISTS "daily_tasks_read_all" ON daily_tasks;
CREATE POLICY "daily_tasks_read_all" ON daily_tasks
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "daily_tasks_insert" ON daily_tasks;
CREATE POLICY "daily_tasks_insert" ON daily_tasks
    FOR INSERT WITH CHECK (
        is_placement_rep(auth.uid()) OR is_coordinator(auth.uid())
    );

DROP POLICY IF EXISTS "daily_tasks_update" ON daily_tasks;
CREATE POLICY "daily_tasks_update" ON daily_tasks
    FOR UPDATE USING (
        is_placement_rep(auth.uid()) OR is_coordinator(auth.uid())
    );

DROP POLICY IF EXISTS "daily_tasks_delete" ON daily_tasks;
CREATE POLICY "daily_tasks_delete" ON daily_tasks
    FOR DELETE USING (is_placement_rep(auth.uid()));

-- ========================================
-- SCHEDULED_ATTENDANCE_DATES POLICIES
-- ========================================

DROP POLICY IF EXISTS "scheduled_dates_read_all" ON scheduled_attendance_dates;
CREATE POLICY "scheduled_dates_read_all" ON scheduled_attendance_dates
    FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS "scheduled_dates_manage" ON scheduled_attendance_dates;
CREATE POLICY "scheduled_dates_manage" ON scheduled_attendance_dates
    FOR ALL TO authenticated USING (
        is_placement_rep(auth.uid()) OR is_coordinator(auth.uid())
    );

-- ========================================
-- ATTENDANCE_RECORDS POLICIES
-- ========================================
-- Key policies for attendance management

-- Students can view their own attendance
DROP POLICY IF EXISTS "attendance_read_own" ON attendance_records;
CREATE POLICY "attendance_read_own" ON attendance_records
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Team leaders can view their team's attendance
DROP POLICY IF EXISTS "attendance_read_team" ON attendance_records;
CREATE POLICY "attendance_read_team" ON attendance_records
    FOR SELECT TO authenticated
    USING (
        is_team_leader(auth.uid()) 
        AND team_id = get_user_team(auth.uid())
    );

-- Placement reps & Coordinators can view ALL attendance
DROP POLICY IF EXISTS "attendance_read_admins" ON attendance_records;
CREATE POLICY "attendance_read_admins" ON attendance_records
    FOR SELECT TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- Team leaders can INSERT attendance for their team (on scheduled dates)
DROP POLICY IF EXISTS "attendance_insert_team_leader" ON attendance_records;
CREATE POLICY "attendance_insert_team_leader" ON attendance_records
    FOR INSERT TO authenticated
    WITH CHECK (
        is_team_leader(auth.uid()) 
        AND team_id = get_user_team(auth.uid())
        AND is_date_scheduled(date)
    );

-- PLACEMENT REP: FULL INSERT ACCESS (all students, any date)
DROP POLICY IF EXISTS "attendance_insert_placement_rep" ON attendance_records;
CREATE POLICY "attendance_insert_placement_rep" ON attendance_records
    FOR INSERT TO authenticated
    WITH CHECK (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- Team leaders can UPDATE attendance they marked
DROP POLICY IF EXISTS "attendance_update_team_leader" ON attendance_records;
CREATE POLICY "attendance_update_team_leader" ON attendance_records
    FOR UPDATE TO authenticated
    USING (marked_by = auth.uid());

-- PLACEMENT REP: FULL UPDATE ACCESS (any attendance record)
DROP POLICY IF EXISTS "attendance_update_placement_rep" ON attendance_records;
CREATE POLICY "attendance_update_placement_rep" ON attendance_records
    FOR UPDATE TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- PLACEMENT REP: DELETE ACCESS
DROP POLICY IF EXISTS "attendance_delete_placement_rep" ON attendance_records;
CREATE POLICY "attendance_delete_placement_rep" ON attendance_records
    FOR DELETE TO authenticated
    USING (is_placement_rep(auth.uid()));

-- ========================================
-- AUDIT_LOGS POLICIES
-- ========================================

DROP POLICY IF EXISTS "audit_logs_read_placement_rep" ON audit_logs;
CREATE POLICY "audit_logs_read_placement_rep" ON audit_logs
    FOR SELECT USING (is_placement_rep(auth.uid()));

DROP POLICY IF EXISTS "audit_logs_insert_auth" ON audit_logs;
CREATE POLICY "audit_logs_insert_auth" ON audit_logs
    FOR INSERT WITH CHECK (auth.uid() = actor_id);

-- ========================================
-- NOTIFICATIONS POLICIES
-- ========================================

DROP POLICY IF EXISTS "notifications_read_active" ON notifications;
CREATE POLICY "notifications_read_active" ON notifications
    FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS "notifications_manage" ON notifications;
CREATE POLICY "notifications_manage" ON notifications
    FOR ALL USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- ========================================
-- NOTIFICATION_READS POLICIES
-- ========================================

DROP POLICY IF EXISTS "notification_reads_own" ON notification_reads;
CREATE POLICY "notification_reads_own" ON notification_reads
    FOR ALL USING (user_id = auth.uid());

-- ========================================
-- GRANT PERMISSIONS
-- ========================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    policy_count INT;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STEP 4 COMPLETE: RLS POLICIES';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total policies created: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'ACCESS CONTROL SUMMARY:';
    RAISE NOTICE '';
    RAISE NOTICE '┌──────────────────┬──────────┬───────────────┬─────────┐';
    RAISE NOTICE '│ Feature          │ Student  │ Team Leader   │ Pl. Rep │';
    RAISE NOTICE '├──────────────────┼──────────┼───────────────┼─────────┤';
    RAISE NOTICE '│ View own attend. │    ✓     │       ✓       │    ✓    │';
    RAISE NOTICE '│ View team attend │    ✗     │       ✓       │    ✓    │';
    RAISE NOTICE '│ View ALL attend. │    ✗     │       ✗       │    ✓    │';
    RAISE NOTICE '│ Mark team attend │    ✗     │       ✓       │    ✓    │';
    RAISE NOTICE '│ Mark ANY attend. │    ✗     │       ✗       │    ✓    │';
    RAISE NOTICE '│ Edit ANY attend. │    ✗     │       ✗       │    ✓    │';
    RAISE NOTICE '│ Delete attend.   │    ✗     │       ✗       │    ✓    │';
    RAISE NOTICE '└──────────────────┴──────────┴───────────────┴─────────┘';
    RAISE NOTICE '';
    RAISE NOTICE 'NEXT: Run 05_sample_data.sql (Optional)';
    RAISE NOTICE '========================================';
END $$;
