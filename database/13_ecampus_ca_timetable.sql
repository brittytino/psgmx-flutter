-- ============================================================
-- PATCH 13: ecampus_ca_timetable table
-- ============================================================
-- Stores CA (Continuous Assessment) test timetable scraped from
-- PSG eCampus for each student.  Mirrors ecampus_attendance
-- and ecampus_ca_marks for consistency.
--
-- Run this in Supabase SQL Editor ONCE.
-- ============================================================

-- ─── Table ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ecampus_ca_timetable (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no     TEXT        NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB       NOT NULL DEFAULT '{}',
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ecampus_ca_tt_reg_no   ON ecampus_ca_timetable(reg_no);
CREATE INDEX IF NOT EXISTS idx_ecampus_ca_tt_synced_at ON ecampus_ca_timetable(synced_at DESC);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE ecampus_ca_timetable ENABLE ROW LEVEL SECURITY;

-- Student reads own row only
DROP POLICY IF EXISTS "student_read_own_ca_timetable" ON ecampus_ca_timetable;
CREATE POLICY "student_read_own_ca_timetable"
    ON ecampus_ca_timetable FOR SELECT
    USING (
        reg_no = (SELECT reg_no FROM users WHERE id = auth.uid())
    );

-- Placement rep / coordinator reads all rows
DROP POLICY IF EXISTS "admin_read_all_ca_timetable" ON ecampus_ca_timetable;
CREATE POLICY "admin_read_all_ca_timetable"
    ON ecampus_ca_timetable FOR SELECT
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

-- Only service-role (backend) writes – no client INSERT/UPDATE policies.

-- ─── Grant ───────────────────────────────────────────────────────────────────
GRANT SELECT ON ecampus_ca_timetable TO authenticated;

-- ─── Realtime ────────────────────────────────────────────────────────────────
-- Run if you want live push updates (optional but nice):
-- ALTER PUBLICATION supabase_realtime ADD TABLE ecampus_ca_timetable;
