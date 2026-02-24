-- ========================================
-- PSG BUNKER – eCampus Bunked Subject Cache
-- ========================================
-- File 8: Per-subject bunked details for each student
-- Run this in Supabase SQL Editor AFTER 06_ecampus_schema.sql
-- ========================================

CREATE TABLE IF NOT EXISTS ecampus_bunked_subjects (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reg_no        TEXT NOT NULL REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    course_code   TEXT NOT NULL,
    course_title  TEXT,
    total_hours   INT NOT NULL DEFAULT 0,
    total_present INT NOT NULL DEFAULT 0,
    percentage    NUMERIC,
    can_bunk      INT NOT NULL DEFAULT 0,
    need_attend   INT NOT NULL DEFAULT 0,
    synced_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (reg_no, course_code)
);

CREATE INDEX IF NOT EXISTS idx_ecampus_bunked_reg_no
    ON ecampus_bunked_subjects(reg_no);

CREATE INDEX IF NOT EXISTS idx_ecampus_bunked_synced_at
    ON ecampus_bunked_subjects(synced_at DESC);

-- ─── Row-Level Security ─────────────────────────────────────────────────────
ALTER TABLE ecampus_bunked_subjects ENABLE ROW LEVEL SECURITY;

-- Students can read their own subject-level bunk data
DROP POLICY IF EXISTS "students_read_own_bunked" ON ecampus_bunked_subjects;
CREATE POLICY "students_read_own_bunked"
    ON ecampus_bunked_subjects FOR SELECT
    USING (
        reg_no = (
            SELECT reg_no FROM users WHERE id = auth.uid()
        )
    );

-- Coordinators / placement reps can read all rows
DROP POLICY IF EXISTS "admins_read_all_bunked" ON ecampus_bunked_subjects;
CREATE POLICY "admins_read_all_bunked"
    ON ecampus_bunked_subjects FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
              AND (
                    (roles->>'isCoordinator')::boolean  = true
                 OR (roles->>'isPlacementRep')::boolean = true
              )
        )
    );

-- Only service-role (backend API) can INSERT / UPDATE / DELETE
-- (No client-side write policies – writes go through the FastAPI service)
