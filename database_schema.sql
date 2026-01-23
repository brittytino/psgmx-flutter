-- ========================================
-- PSG Technology Placement Management System
-- Complete Database Schema with RLS
-- Production-Grade for 2-Year Stability
-- ========================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- TABLE: users
-- ========================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    reg_no TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    team_id TEXT,
    batch TEXT NOT NULL CHECK (batch IN ('G1', 'G2')),
    roles JSONB NOT NULL DEFAULT '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_reg_no ON users(reg_no);
CREATE INDEX IF NOT EXISTS idx_users_team_id ON users(team_id);
CREATE INDEX IF NOT EXISTS idx_users_batch ON users(batch);
CREATE INDEX IF NOT EXISTS idx_users_roles ON users USING GIN(roles);

-- ========================================
-- TABLE: attendance_days
-- ========================================
CREATE TABLE IF NOT EXISTS attendance_days (
    date DATE PRIMARY KEY,
    is_working_day BOOLEAN NOT NULL DEFAULT true,
    decided_by UUID REFERENCES users(id),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_attendance_days_date ON attendance_days(date);
CREATE INDEX IF NOT EXISTS idx_attendance_days_is_working ON attendance_days(is_working_day);

-- ========================================
-- TABLE: daily_tasks
-- ========================================
CREATE TABLE IF NOT EXISTS daily_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    topic_type TEXT NOT NULL CHECK (topic_type IN ('leetcode', 'core')),
    title TEXT NOT NULL,
    reference_link TEXT,
    subject TEXT,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(date, topic_type, title)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_daily_tasks_date ON daily_tasks(date);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_topic_type ON daily_tasks(topic_type);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_uploaded_by ON daily_tasks(uploaded_by);

-- ========================================
-- TABLE: attendance
-- ========================================
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PRESENT', 'ABSENT', 'NA')),
    marked_by UUID NOT NULL REFERENCES users(id),
    marked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(date, student_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_team_id ON attendance(team_id);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);
CREATE INDEX IF NOT EXISTS idx_attendance_marked_by ON attendance(marked_by);

-- ========================================
-- TABLE: audit_logs
-- ========================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID NOT NULL REFERENCES users(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_metadata ON audit_logs USING GIN(metadata);

-- ========================================
-- TABLE: notifications
-- ========================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('motivation', 'reminder', 'alert', 'announcement')),
    tone TEXT CHECK (tone IN ('serious', 'friendly', 'humorous')),
    target_audience TEXT NOT NULL CHECK (target_audience IN ('all', 'students', 'team_leaders', 'coordinators', 'placement_reps')),
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_active ON notifications(is_active);
CREATE INDEX IF NOT EXISTS idx_notifications_generated_at ON notifications(generated_at DESC);

-- ========================================
-- TABLE: notification_reads
-- ========================================
CREATE TABLE IF NOT EXISTS notification_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dismissed_at TIMESTAMPTZ,
    UNIQUE(notification_id, user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notification_reads_user ON notification_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_reads_notification ON notification_reads(notification_id);

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to check if user has specific role
CREATE OR REPLACE FUNCTION has_role(user_id UUID, role_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_roles JSONB;
BEGIN
    SELECT roles INTO user_roles FROM users WHERE id = user_id;
    RETURN COALESCE((user_roles->role_name)::BOOLEAN, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is placement rep
CREATE OR REPLACE FUNCTION is_placement_rep(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isPlacementRep');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is coordinator
CREATE OR REPLACE FUNCTION is_coordinator(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isCoordinator');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is team leader
CREATE OR REPLACE FUNCTION is_team_leader(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isTeamLeader');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's team
CREATE OR REPLACE FUNCTION get_user_team(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_team TEXT;
BEGIN
    SELECT team_id INTO user_team FROM users WHERE id = user_id;
    RETURN user_team;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if date is working day
CREATE OR REPLACE FUNCTION is_working_day(check_date DATE)
RETURNS BOOLEAN AS $$
DECLARE
    working_day_record RECORD;
BEGIN
    SELECT * INTO working_day_record FROM attendance_days WHERE date = check_date;
    
    -- If no record exists, default to NOT a working day (NA)
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    RETURN working_day_record.is_working_day;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads ENABLE ROW LEVEL SECURITY;

-- ========================================
-- USERS TABLE RLS POLICIES
-- ========================================

-- Policy: Users can read their own data
CREATE POLICY users_read_own ON users
    FOR SELECT
    USING (auth.uid() = id);

-- Policy: Placement reps can read all users
CREATE POLICY users_read_placement_rep ON users
    FOR SELECT
    USING (is_placement_rep(auth.uid()));

-- Policy: Team leaders can read their team members
CREATE POLICY users_read_team ON users
    FOR SELECT
    USING (
        is_team_leader(auth.uid()) 
        AND team_id = get_user_team(auth.uid())
    );

-- Policy: Coordinators can read all users
CREATE POLICY users_read_coordinator ON users
    FOR SELECT
    USING (is_coordinator(auth.uid()));

-- Policy: Only placement reps can update users
CREATE POLICY users_update_placement_rep ON users
    FOR UPDATE
    USING (is_placement_rep(auth.uid()));

-- Policy: Users can be inserted (for registration)
CREATE POLICY users_insert_auth ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ========================================
-- ATTENDANCE_DAYS TABLE RLS POLICIES
-- ========================================

-- Policy: Everyone can read attendance days
CREATE POLICY attendance_days_read_all ON attendance_days
    FOR SELECT
    USING (TRUE);

-- Policy: Only placement reps and coordinators can insert/update
CREATE POLICY attendance_days_insert ON attendance_days
    FOR INSERT
    WITH CHECK (
        is_placement_rep(auth.uid()) 
        OR is_coordinator(auth.uid())
    );

CREATE POLICY attendance_days_update ON attendance_days
    FOR UPDATE
    USING (
        is_placement_rep(auth.uid()) 
        OR is_coordinator(auth.uid())
    );

-- ========================================
-- DAILY_TASKS TABLE RLS POLICIES
-- ========================================

-- Policy: Everyone can read daily tasks
CREATE POLICY daily_tasks_read_all ON daily_tasks
    FOR SELECT
    USING (TRUE);

-- Policy: Only placement reps and coordinators can insert
CREATE POLICY daily_tasks_insert ON daily_tasks
    FOR INSERT
    WITH CHECK (
        is_placement_rep(auth.uid()) 
        OR is_coordinator(auth.uid())
    );

-- Policy: Only placement reps and coordinators can update their own tasks
CREATE POLICY daily_tasks_update ON daily_tasks
    FOR UPDATE
    USING (
        (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()))
        AND uploaded_by = auth.uid()
    );

-- Policy: Only placement reps can delete tasks
CREATE POLICY daily_tasks_delete ON daily_tasks
    FOR DELETE
    USING (is_placement_rep(auth.uid()));

-- ========================================
-- ATTENDANCE TABLE RLS POLICIES
-- ========================================

-- Policy: Students can read their own attendance
CREATE POLICY attendance_read_own ON attendance
    FOR SELECT
    USING (student_id = auth.uid());

-- Policy: Team leaders can read their team's attendance
CREATE POLICY attendance_read_team ON attendance
    FOR SELECT
    USING (
        is_team_leader(auth.uid()) 
        AND team_id = get_user_team(auth.uid())
    );

-- Policy: Coordinators can read all attendance
CREATE POLICY attendance_read_coordinator ON attendance
    FOR SELECT
    USING (is_coordinator(auth.uid()));

-- Policy: Placement reps can read all attendance
CREATE POLICY attendance_read_placement_rep ON attendance
    FOR SELECT
    USING (is_placement_rep(auth.uid()));

-- Policy: Team leaders can insert attendance for their team
CREATE POLICY attendance_insert_team_leader ON attendance
    FOR INSERT
    WITH CHECK (
        is_team_leader(auth.uid()) 
        AND team_id = get_user_team(auth.uid())
        AND is_working_day(date)
    );

-- Policy: Placement reps can insert attendance for anyone
CREATE POLICY attendance_insert_placement_rep ON attendance
    FOR INSERT
    WITH CHECK (is_placement_rep(auth.uid()));

-- Policy: Only placement reps can update attendance (overrides)
CREATE POLICY attendance_update_placement_rep ON attendance
    FOR UPDATE
    USING (is_placement_rep(auth.uid()));

-- ========================================
-- AUDIT_LOGS TABLE RLS POLICIES
-- ========================================

-- Policy: Only placement reps can read audit logs
CREATE POLICY audit_logs_read_placement_rep ON audit_logs
    FOR SELECT
    USING (is_placement_rep(auth.uid()));

-- Policy: Authenticated users can insert audit logs
CREATE POLICY audit_logs_insert_auth ON audit_logs
    FOR INSERT
    WITH CHECK (auth.uid() = actor_id);

-- ========================================
-- NOTIFICATIONS TABLE RLS POLICIES
-- ========================================

-- Policy: Everyone can read active notifications
CREATE POLICY notifications_read_all ON notifications
    FOR SELECT
    USING (is_active = TRUE);

-- Policy: Only placement reps and coordinators can insert notifications
CREATE POLICY notifications_insert ON notifications
    FOR INSERT
    WITH CHECK (
        is_placement_rep(auth.uid()) 
        OR is_coordinator(auth.uid())
    );

-- Policy: Only placement reps can update/delete notifications
CREATE POLICY notifications_update ON notifications
    FOR UPDATE
    USING (is_placement_rep(auth.uid()));

CREATE POLICY notifications_delete ON notifications
    FOR DELETE
    USING (is_placement_rep(auth.uid()));

-- ========================================
-- NOTIFICATION_READS TABLE RLS POLICIES
-- ========================================

-- Policy: Users can read their own notification reads
CREATE POLICY notification_reads_read_own ON notification_reads
    FOR SELECT
    USING (user_id = auth.uid());

-- Policy: Users can insert their own notification reads
CREATE POLICY notification_reads_insert_own ON notification_reads
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can update their own notification reads
CREATE POLICY notification_reads_update_own ON notification_reads
    FOR UPDATE
    USING (user_id = auth.uid());

-- ========================================
-- TRIGGERS
-- ========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_days_updated_at BEFORE UPDATE ON attendance_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_tasks_updated_at BEFORE UPDATE ON daily_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- INITIAL DATA
-- ========================================

-- Insert the placement rep user (25mx354@psgtech.ac.in)
-- Note: This will be inserted after auth.users is created
-- The actual user creation happens through Supabase Auth

-- ========================================
-- VIEWS FOR ANALYTICS
-- ========================================

-- View: Student attendance summary
CREATE OR REPLACE VIEW student_attendance_summary AS
SELECT 
    u.id as student_id,
    u.email,
    u.reg_no,
    u.name,
    u.team_id,
    u.batch,
    COUNT(CASE WHEN a.status = 'PRESENT' THEN 1 END) as present_count,
    COUNT(CASE WHEN a.status = 'ABSENT' THEN 1 END) as absent_count,
    COUNT(CASE WHEN a.status != 'NA' THEN 1 END) as total_working_days,
    CASE 
        WHEN COUNT(CASE WHEN a.status != 'NA' THEN 1 END) = 0 THEN 0
        ELSE ROUND(
            (COUNT(CASE WHEN a.status = 'PRESENT' THEN 1 END)::NUMERIC / 
             COUNT(CASE WHEN a.status != 'NA' THEN 1 END)::NUMERIC) * 100, 
            2
        )
    END as attendance_percentage
FROM users u
LEFT JOIN attendance a ON u.id = a.student_id
WHERE (u.roles->>'isStudent')::BOOLEAN = TRUE
GROUP BY u.id, u.email, u.reg_no, u.name, u.team_id, u.batch;

-- View: Team attendance summary
CREATE OR REPLACE VIEW team_attendance_summary AS
SELECT 
    team_id,
    batch,
    COUNT(DISTINCT student_id) as team_size,
    ROUND(AVG(attendance_percentage), 2) as avg_attendance_percentage
FROM student_attendance_summary
WHERE team_id IS NOT NULL
GROUP BY team_id, batch;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- Grant permissions on tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Grant permissions on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
-- Database schema created successfully
-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Create auth user for 25mx354@psgtech.ac.in
-- 3. Insert corresponding user record in users table
-- 4. Configure working days in attendance_days table
-- ========================================
