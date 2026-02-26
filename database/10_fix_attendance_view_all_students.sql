-- ============================================================
-- PATCH 10: Fix student_attendance_summary to show all 123 students
-- ============================================================
-- 
-- Root cause: the view was based on the `users` table which only
-- contains students who have signed in (~94). The `whitelist` table
-- is the source of truth for all 123 students in the batch.
--
-- Fix: rebuild the view starting from `whitelist`, LEFT JOINing
-- `users` (for UUID / login info) and `attendance_records`.
-- Students who have never signed in will appear with 0 attendance.
-- ============================================================

-- Drop and recreate the view based on whitelist as source of truth
CREATE OR REPLACE VIEW student_attendance_summary AS
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

-- Grant read access to authenticated users (same as before)
GRANT SELECT ON student_attendance_summary TO authenticated;
GRANT SELECT ON student_attendance_summary TO anon;

-- Verify row count should now = 123
-- SELECT COUNT(*) FROM student_attendance_summary;
