-- ========================================
-- PSG MX PLACEMENT APP - DATABASE SCHEMA
-- ========================================
-- File 1 of 6: Schema Creation
-- 
-- This creates all tables, indexes, and extensions.
-- Run this FIRST in Supabase SQL Editor.
-- ========================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- TABLE 1: users
-- ========================================
-- Stores all user data (students, team leaders, coordinators, placement rep)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    reg_no TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    team_id TEXT,
    batch TEXT NOT NULL CHECK (batch IN ('G1', 'G2')),
    roles JSONB NOT NULL DEFAULT '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}',
    leetcode_username TEXT,
    dob DATE,
    birthday_notifications_enabled BOOLEAN DEFAULT TRUE,
    leetcode_notifications_enabled BOOLEAN DEFAULT TRUE,
    task_reminders_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_reg_no ON users(reg_no);
CREATE INDEX IF NOT EXISTS idx_users_team_id ON users(team_id);
CREATE INDEX IF NOT EXISTS idx_users_batch ON users(batch);
CREATE INDEX IF NOT EXISTS idx_users_roles ON users USING GIN(roles);

-- ========================================
-- TABLE 2: whitelist
-- ========================================
-- Master list of allowed students (123 students)
CREATE TABLE IF NOT EXISTS whitelist (
    email TEXT PRIMARY KEY,
    name TEXT,
    reg_no TEXT,
    batch TEXT,
    team_id TEXT,
    dob DATE,
    leetcode_username TEXT,
    roles JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);
CREATE INDEX IF NOT EXISTS idx_whitelist_reg_no ON whitelist(reg_no);

-- ========================================
-- TABLE 3: leetcode_stats
-- ========================================
-- LeetCode statistics for leaderboard
CREATE TABLE IF NOT EXISTS leetcode_stats (
    username TEXT PRIMARY KEY,
    total_solved INT DEFAULT 0,
    easy_solved INT DEFAULT 0,
    medium_solved INT DEFAULT 0,
    hard_solved INT DEFAULT 0,
    ranking INT DEFAULT 0,
    weekly_score INT DEFAULT 0,
    profile_picture TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leetcode_stats_total ON leetcode_stats(total_solved DESC);
CREATE INDEX IF NOT EXISTS idx_leetcode_stats_weekly ON leetcode_stats(weekly_score DESC);

-- ========================================
-- TABLE 4: daily_tasks
-- ========================================
-- Daily LeetCode and Core subject tasks
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
    UNIQUE(date, topic_type)
);

CREATE INDEX IF NOT EXISTS idx_daily_tasks_date ON daily_tasks(date);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_topic_type ON daily_tasks(topic_type);

-- ========================================
-- TABLE 5: scheduled_attendance_dates
-- ========================================
-- Dates when placement classes are scheduled
CREATE TABLE IF NOT EXISTS scheduled_attendance_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    is_working_day BOOLEAN NOT NULL DEFAULT TRUE,
    scheduled_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scheduled_dates_date ON scheduled_attendance_dates(date);

-- ========================================
-- TABLE 6: attendance_records
-- ========================================
-- Individual attendance records
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    team_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PRESENT', 'ABSENT', 'NA')),
    marked_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)  -- Enables bulk upsert
);

CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance_records(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_team_id ON attendance_records(team_id);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance_records(status);

-- ========================================
-- TABLE 7: audit_logs
-- ========================================
-- Tracks all important actions
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID NOT NULL REFERENCES users(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ========================================
-- TABLE 8: notifications
-- ========================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('motivation', 'reminder', 'alert', 'announcement')),
    tone TEXT CHECK (tone IN ('serious', 'friendly', 'humorous')),
    target_audience TEXT NOT NULL CHECK (target_audience IN ('all', 'students', 'team_leaders', 'coordinators', 'placement_reps', 'G1', 'G2')),
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- ========================================
-- TABLE 9: notification_reads
-- ========================================
CREATE TABLE IF NOT EXISTS notification_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dismissed_at TIMESTAMPTZ,
    UNIQUE(notification_id, user_id)
);

-- ========================================
-- TABLE 10: attendance_days (legacy)
-- ========================================
CREATE TABLE IF NOT EXISTS attendance_days (
    date DATE PRIMARY KEY,
    is_working_day BOOLEAN NOT NULL DEFAULT true,
    decided_by UUID REFERENCES users(id),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================
-- TABLE 11: task_completions
-- ========================================
-- Tracks daily task completion and verification
CREATE TABLE IF NOT EXISTS task_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES daily_tasks(id) ON DELETE CASCADE,
    proof_link TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'verified', 'rejected')),
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, task_id)
);
CREATE INDEX IF NOT EXISTS idx_completions_user_id ON task_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_completions_task_id ON task_completions(task_id);

-- ========================================
-- TABLE 12: app_config
-- ========================================
CREATE TABLE IF NOT EXISTS app_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    min_required_version TEXT NOT NULL DEFAULT '1.0.0',
    latest_version TEXT NOT NULL DEFAULT '1.0.0',
    force_update BOOLEAN NOT NULL DEFAULT false,
    update_message TEXT DEFAULT 'A new version of PSGMX is available.',
    github_release_url TEXT DEFAULT 'https://github.com/psgmx/psgmx-flutter/releases/latest',
    android_download_url TEXT,
    ios_download_url TEXT,
    emergency_block BOOLEAN NOT NULL DEFAULT false,
    emergency_message TEXT DEFAULT 'App temporarily unavailable.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by TEXT
);

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STEP 1 COMPLETE: SCHEMA CREATED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '  1. users';
    RAISE NOTICE '  2. whitelist';
    RAISE NOTICE '  3. leetcode_stats';
    RAISE NOTICE '  4. daily_tasks';
    RAISE NOTICE '  5. scheduled_attendance_dates';
    RAISE NOTICE '  6. attendance_records';
    RAISE NOTICE '  7. audit_logs';
    RAISE NOTICE '  8. notifications';
    RAISE NOTICE '  9. notification_reads';
    RAISE NOTICE ' 10. attendance_days';
    RAISE NOTICE ' 11. task_completions';
    RAISE NOTICE ' 12. app_config';
    RAISE NOTICE '';
    RAISE NOTICE 'NEXT: Run 02_policies.sql';
    RAISE NOTICE '========================================';
END $$;
