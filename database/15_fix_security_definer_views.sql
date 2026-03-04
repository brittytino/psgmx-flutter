-- ============================================================
-- PATCH 15: Fix SECURITY DEFINER views (Supabase Security Advisory)
-- ============================================================
-- 
-- Issue: Supabase detected 3 views with SECURITY DEFINER property
-- that bypass Row Level Security (RLS) policies.
-- 
-- Affected views:
-- 1. public.v_ecampus_attendance_summary
-- 2. public.v_ecampus_cgpa_summary
-- 3. public.student_attendance_summary
--
-- Fix: Add SECURITY INVOKER to ensure views respect RLS policies
-- and execute with the permissions of the calling user.
--
-- Date: 2026-03-04
-- ============================================================

-- ─── Fix v_ecampus_attendance_summary ───────────────────────────────────────
CREATE OR REPLACE VIEW v_ecampus_attendance_summary 
WITH (security_invoker = true) AS
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

-- ─── Fix v_ecampus_cgpa_summary ─────────────────────────────────────────────
CREATE OR REPLACE VIEW v_ecampus_cgpa_summary 
WITH (security_invoker = true) AS
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

-- ─── Fix student_attendance_summary ─────────────────────────────────────────
CREATE OR REPLACE VIEW student_attendance_summary 
WITH (security_invoker = true) AS
SELECT
    u.id                                         AS student_id,
    u.id                                         AS user_id,
    COALESCE(u.email,   w.email)                 AS email,
    w.reg_no,
    COALESCE(u.name,    w.name)                  AS name,
    COALESCE(u.team_id, w.team_id)               AS team_id,
    COALESCE(u.batch,   w.batch)                 AS batch,

    -- Attendance aggregates (all 0 for students without a users row)
    COALESCE(SUM(CASE WHEN ar.status = 'PRESENT'                    THEN 1 ELSE 0 END), 0)::int AS present_count,
    COALESCE(SUM(CASE WHEN ar.status = 'ABSENT'                     THEN 1 ELSE 0 END), 0)::int AS absent_count,
    COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT')       THEN 1 ELSE 0 END), 0)::int AS total_working_days,

    CASE
        WHEN COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0) = 0
            THEN 0.0
        ELSE ROUND(
            COALESCE(SUM(CASE WHEN ar.status = 'PRESENT' THEN 1 ELSE 0 END), 0)::numeric
            / NULLIF(COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0), 0)
            * 100,
            2
        )
    END AS attendance_percentage

FROM whitelist w
-- Join to users to get UUID and login details (NULL for students who haven't signed up yet)
LEFT JOIN users u  ON u.reg_no  = w.reg_no
-- Only attendance_records rows that exist (none for non-signed-up students)
LEFT JOIN attendance_records ar ON ar.user_id = u.id

WHERE w.reg_no IS NOT NULL

GROUP BY
    w.reg_no,
    w.email,
    w.name,
    w.team_id,
    w.batch,
    u.id,
    u.email,
    u.name,
    u.team_id,
    u.batch;

-- Ensure grants remain in place
GRANT SELECT ON v_ecampus_attendance_summary TO authenticated;
GRANT SELECT ON v_ecampus_attendance_summary TO anon;
GRANT SELECT ON v_ecampus_cgpa_summary TO authenticated;
GRANT SELECT ON v_ecampus_cgpa_summary TO anon;
GRANT SELECT ON student_attendance_summary TO authenticated;
GRANT SELECT ON student_attendance_summary TO anon;

-- ============================================================
-- Verification queries (run these to confirm the fix worked)
-- ============================================================
-- SELECT COUNT(*) FROM student_attendance_summary;
-- SELECT COUNT(*) FROM v_ecampus_attendance_summary;
-- SELECT COUNT(*) FROM v_ecampus_cgpa_summary;
--
-- To verify security_invoker is set, run:
-- SELECT viewname, viewowner, 
--        regexp_match(definition, 'security_invoker') IS NOT NULL as has_security_invoker
-- FROM pg_views 
-- WHERE schemaname = 'public' 
-- AND viewname IN ('student_attendance_summary', 'v_ecampus_attendance_summary', 'v_ecampus_cgpa_summary');
-- ============================================================
