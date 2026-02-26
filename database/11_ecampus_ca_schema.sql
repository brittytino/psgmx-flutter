-- ============================================================
-- PATCH 11: ecampus_ca_marks table
-- ============================================================
-- Stores CA (Continuous Assessment) internal marks scraped from
-- PSG eCampus for each student.  Structure mirrors ecampus_attendance
-- and ecampus_cgpa for consistency.
--
-- Run this in Supabase SQL Editor ONCE.
-- ============================================================

-- ─── Table ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ecampus_ca_marks (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no     TEXT        NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB       NOT NULL DEFAULT '{}',
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ecampus_ca_reg_no   ON ecampus_ca_marks(reg_no);
CREATE INDEX IF NOT EXISTS idx_ecampus_ca_synced_at ON ecampus_ca_marks(synced_at DESC);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE ecampus_ca_marks ENABLE ROW LEVEL SECURITY;

-- Student reads own row only
CREATE POLICY "student_read_own_ca"
    ON ecampus_ca_marks FOR SELECT
    USING (
        reg_no = (SELECT reg_no FROM users WHERE id = auth.uid())
    );

-- Placement rep / coordinator reads all rows
CREATE POLICY "admin_read_all_ca"
    ON ecampus_ca_marks FOR SELECT
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
GRANT SELECT ON ecampus_ca_marks TO authenticated;

-- ─── Realtime ────────────────────────────────────────────────────────────────
-- Run if you want live push updates (optional but nice):
-- ALTER PUBLICATION supabase_realtime ADD TABLE ecampus_ca_marks;
