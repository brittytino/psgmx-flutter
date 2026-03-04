-- ============================================================
-- PATCH 14: ca_timetable_global table
-- ============================================================
-- Stores the common CA test timetable (one shared table for
-- all students).  Fetched using the placement rep's eCampus
-- credentials so every student can see the same exam schedule.
--
-- Run this in Supabase SQL Editor ONCE.
-- ============================================================

-- ─── Table ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ca_timetable_global (
    id         INT         PRIMARY KEY DEFAULT 1,
    data       JSONB       NOT NULL DEFAULT '{}',
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_by  TEXT,           -- reg_no of the placement rep who triggered the sync
    CONSTRAINT single_row CHECK (id = 1)
);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE ca_timetable_global ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read the shared timetable
DROP POLICY IF EXISTS "authenticated_read_ca_timetable_global" ON ca_timetable_global;
CREATE POLICY "authenticated_read_ca_timetable_global"
    ON ca_timetable_global FOR SELECT
    TO authenticated
    USING (true);

-- Only service-role (backend) can write
-- No INSERT / UPDATE / DELETE policies → service key bypasses RLS

-- ─── Grant ───────────────────────────────────────────────────────────────────
GRANT SELECT ON ca_timetable_global TO authenticated;

-- ─── Realtime ────────────────────────────────────────────────────────────────
-- Enable live push so the app updates automatically when placement rep re-syncs:
ALTER PUBLICATION supabase_realtime ADD TABLE ca_timetable_global;

-- ─── Seed an empty row so reads never 404 ────────────────────────────────────
INSERT INTO ca_timetable_global (id, data, synced_at)
VALUES (1, '{"headers":[],"rows":[],"note":"Not synced yet"}', NOW())
ON CONFLICT (id) DO NOTHING;
