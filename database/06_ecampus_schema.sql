-- ========================================
-- PSG BUNKER – eCampus Tables
-- ========================================
-- File 6: Attendance & CGPA cache from PSG eCampus portal
-- Run this in Supabase SQL Editor AFTER 05_seed_data.sql
-- ========================================

-- Ensure whitelist.reg_no has a UNIQUE constraint
-- (required for FK references below; safe to run even if already set)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'whitelist_reg_no_unique'
          AND conrelid = 'whitelist'::regclass
    ) THEN
        ALTER TABLE whitelist ADD CONSTRAINT whitelist_reg_no_unique UNIQUE (reg_no);
    END IF;
END $$;

-- TABLE: ecampus_attendance
-- One row per student, stores full JSON payload returned by the scraper.
CREATE TABLE IF NOT EXISTS ecampus_attendance (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reg_no     TEXT NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB  NOT NULL,           -- {subjects: [...], summary: {...}}
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ecampus_att_reg_no    ON ecampus_attendance(reg_no);
CREATE INDEX IF NOT EXISTS idx_ecampus_att_synced_at ON ecampus_attendance(synced_at DESC);
-- Index on overall attendance percentage for quick defaulter queries
CREATE INDEX IF NOT EXISTS idx_ecampus_att_pct
    ON ecampus_attendance ((data->'summary'->>'overall_percentage'));

-- TABLE: ecampus_cgpa
-- One row per student, stores full JSON payload returned by the scraper.
CREATE TABLE IF NOT EXISTS ecampus_cgpa (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reg_no     TEXT NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB  NOT NULL,           -- {cgpa, semester_sgpa: [...], courses: [...], ...}
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ecampus_cgpa_reg_no    ON ecampus_cgpa(reg_no);
CREATE INDEX IF NOT EXISTS idx_ecampus_cgpa_synced_at ON ecampus_cgpa(synced_at DESC);
CREATE INDEX IF NOT EXISTS idx_ecampus_cgpa_val
    ON ecampus_cgpa ((data->>'cgpa'));

-- ─── Row-Level Security ─────────────────────────────────────────────────────
ALTER TABLE ecampus_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecampus_cgpa       ENABLE ROW LEVEL SECURITY;

-- Students can only read their own data (match by reg_no stored in users table)
CREATE POLICY "students_read_own_attendance"
    ON ecampus_attendance FOR SELECT
    USING (
        reg_no = (
            SELECT reg_no FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "students_read_own_cgpa"
    ON ecampus_cgpa FOR SELECT
    USING (
        reg_no = (
            SELECT reg_no FROM users WHERE id = auth.uid()
        )
    );

-- Coordinators / placement reps can read all rows
CREATE POLICY "admins_read_all_attendance"
    ON ecampus_attendance FOR SELECT
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

CREATE POLICY "admins_read_all_cgpa"
    ON ecampus_cgpa FOR SELECT
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

-- ─── Helper view: flat attendance summary per student ───────────────────────
CREATE OR REPLACE VIEW v_ecampus_attendance_summary AS
SELECT
    ea.reg_no,
    u.name,
    (ea.data->'summary'->>'total_hours')::int         AS total_hours,
    (ea.data->'summary'->>'total_present')::int        AS total_present,
    (ea.data->'summary'->>'overall_percentage')::numeric AS overall_pct,
    (ea.data->'summary'->>'overall_can_bunk')::int     AS can_bunk,
    (ea.data->'summary'->>'overall_need_attend')::int  AS need_attend,
    ea.synced_at
FROM ecampus_attendance ea
JOIN users u ON u.reg_no = ea.reg_no;

-- ─── Helper view: CGPA per student ──────────────────────────────────────────
CREATE OR REPLACE VIEW v_ecampus_cgpa_summary AS
SELECT
    ec.reg_no,
    u.name,
    (ec.data->>'cgpa')::numeric            AS cgpa,
    (ec.data->>'total_credits')::int       AS total_credits,
    ec.data->>'latest_semester'            AS latest_semester,
    (ec.data->>'total_semesters')::int     AS total_semesters,
    ec.synced_at
FROM ecampus_cgpa ec
JOIN users u ON u.reg_no = ec.reg_no;
