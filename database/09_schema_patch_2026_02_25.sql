-- ========================================
-- PSG MX - Schema Patch (2026-02-25)
-- Fix missing columns and tables used by the app.
-- Run this in Supabase SQL Editor for existing databases.
-- ========================================

-- Users: notification preferences
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS attendance_alerts_enabled BOOLEAN DEFAULT TRUE;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS announcements_enabled BOOLEAN DEFAULT TRUE;

UPDATE users
SET attendance_alerts_enabled = TRUE
WHERE attendance_alerts_enabled IS NULL;

UPDATE users
SET announcements_enabled = TRUE
WHERE announcements_enabled IS NULL;

-- Announcements table
CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_priority BOOLEAN NOT NULL DEFAULT FALSE,
    expiry_date TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_priority ON announcements(is_priority DESC);

-- Task completions: align with app
ALTER TABLE task_completions
    ADD COLUMN IF NOT EXISTS task_date DATE;

ALTER TABLE task_completions
    ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT FALSE;

ALTER TABLE task_completions
    ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

UPDATE task_completions tc
SET task_date = dt.date
FROM daily_tasks dt
WHERE tc.task_date IS NULL
    AND tc.task_id = dt.id;

UPDATE task_completions
SET completed = (status IN ('completed', 'verified'))
WHERE completed IS NULL;

-- Allow task_id to be nullable if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'task_completions'
          AND column_name = 'task_id'
    ) THEN
        ALTER TABLE task_completions ALTER COLUMN task_id DROP NOT NULL;
    END IF;
END $$;

-- Drop old unique constraint on (user_id, task_id) if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'task_completions_user_id_task_id_key'
          AND conrelid = 'task_completions'::regclass
    ) THEN
        ALTER TABLE task_completions
            DROP CONSTRAINT task_completions_user_id_task_id_key;
    END IF;
END $$;

-- Add unique constraint on (user_id, task_date)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'task_completions_user_id_task_date_key'
          AND conrelid = 'task_completions'::regclass
    ) THEN
        ALTER TABLE task_completions
            ADD CONSTRAINT task_completions_user_id_task_date_key
            UNIQUE (user_id, task_date);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_completions_task_date ON task_completions(task_date);

-- Defaulter flags table used by reports and services
CREATE TABLE IF NOT EXISTS defaulter_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    defaulter_status BOOLEAN NOT NULL DEFAULT FALSE,
    defaulter_reason TEXT NOT NULL DEFAULT '',
    consecutive_absences INT NOT NULL DEFAULT 0,
    attendance_percentage NUMERIC(5,2),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES users(id),
    notes TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_defaulter_status ON defaulter_flags(defaulter_status);
CREATE INDEX IF NOT EXISTS idx_defaulter_detected_at ON defaulter_flags(detected_at DESC);

-- Compatibility view expected by attendance/report screens
-- Fixed: use whitelist as source of truth so all 123 students appear (not just logged-in ~94)
CREATE OR REPLACE VIEW student_attendance_summary AS
SELECT
    u.id                                         AS student_id,
    u.id                                         AS user_id,
    COALESCE(u.email,   w.email)                 AS email,
    w.reg_no,
    COALESCE(u.name,    w.name)                  AS name,
    COALESCE(u.team_id, w.team_id)               AS team_id,
    COALESCE(u.batch,   w.batch)                 AS batch,
    COALESCE(SUM(CASE WHEN ar.status = 'PRESENT'              THEN 1 ELSE 0 END), 0)::int AS present_count,
    COALESCE(SUM(CASE WHEN ar.status = 'ABSENT'               THEN 1 ELSE 0 END), 0)::int AS absent_count,
    COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0)::int AS total_working_days,
    CASE
        WHEN COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0) = 0 THEN 0.0
        ELSE ROUND(
            COALESCE(SUM(CASE WHEN ar.status = 'PRESENT' THEN 1 ELSE 0 END), 0)::numeric
            / NULLIF(COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0), 0)
            * 100,
            2
        )
    END AS attendance_percentage
FROM whitelist w
LEFT JOIN users u  ON u.reg_no  = w.reg_no
LEFT JOIN attendance_records ar ON ar.user_id = u.id
WHERE w.reg_no IS NOT NULL
GROUP BY
    w.reg_no, w.email, w.name, w.team_id, w.batch,
    u.id, u.email, u.name, u.team_id, u.batch;

-- RLS for defaulter_flags
ALTER TABLE defaulter_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "defaulter_read_own" ON defaulter_flags;
CREATE POLICY "defaulter_read_own" ON defaulter_flags
FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "defaulter_read_team" ON defaulter_flags;
CREATE POLICY "defaulter_read_team" ON defaulter_flags
FOR SELECT TO authenticated
USING (
    is_team_leader(auth.uid())
    AND EXISTS (
        SELECT 1
        FROM users
        WHERE users.id = defaulter_flags.user_id
          AND users.team_id = get_user_team(auth.uid())
    )
);

DROP POLICY IF EXISTS "defaulter_read_admin" ON defaulter_flags;
CREATE POLICY "defaulter_read_admin" ON defaulter_flags
FOR SELECT TO authenticated
USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

DROP POLICY IF EXISTS "defaulter_manage_admin" ON defaulter_flags;
CREATE POLICY "defaulter_manage_admin" ON defaulter_flags
FOR ALL TO authenticated
USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()))
WITH CHECK (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- ========================================
-- After running this patch, re-run:
-- 02_policies.sql
-- 03_functions.sql
-- 04_triggers.sql
-- ========================================
