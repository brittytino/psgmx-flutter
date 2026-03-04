-- ========================================
-- PSG MX PLACEMENT APP - FUNCTIONS & VIEWS
-- ========================================
-- File 3 of 6: Helper Functions & Analytics Views
-- 
-- Creates functions for role checking, date validation,
-- and views for attendance summaries.
-- Run this AFTER 02_policies.sql
-- ========================================

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Check if user has a specific role
CREATE OR REPLACE FUNCTION has_role(user_id UUID, role_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_roles JSONB;
BEGIN
    SELECT roles INTO user_roles FROM users WHERE id = user_id;
    RETURN COALESCE((user_roles->>role_name)::BOOLEAN, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Student attendance summary view used by reports and attendance services
-- Source of truth: whitelist (all 123 students), LEFT JOIN users for UUID/login
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

-- Check if user is placement rep
CREATE OR REPLACE FUNCTION is_placement_rep(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isPlacementRep');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is coordinator
CREATE OR REPLACE FUNCTION is_coordinator(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isCoordinator');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is team leader
CREATE OR REPLACE FUNCTION is_team_leader(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isTeamLeader');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's team ID
CREATE OR REPLACE FUNCTION get_user_team(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_team TEXT;
BEGIN
    SELECT team_id INTO user_team FROM users WHERE id = user_id;
    RETURN user_team;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if date is scheduled for attendance
CREATE OR REPLACE FUNCTION is_date_scheduled(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM scheduled_attendance_dates 
        WHERE date = check_date
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Get scheduled dates in a range
CREATE OR REPLACE FUNCTION get_scheduled_dates(start_date DATE, end_date DATE)
RETURNS TABLE (
    id UUID,
    date DATE,
    scheduled_by UUID,
    notes TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sad.id,
        sad.date,
        sad.scheduled_by,
        sad.notes,
        sad.created_at,
        sad.updated_at
    FROM scheduled_attendance_dates sad
    WHERE sad.date >= start_date AND sad.date <= end_date
    ORDER BY sad.date ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Team task completion stats for a date
CREATE OR REPLACE FUNCTION get_team_task_completion_stats(
    p_team_id TEXT,
    p_date DATE
)
RETURNS TABLE (
    total_members INT,
    completed_count INT,
    completion_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(u.id)::int AS total_members,
        SUM(CASE WHEN tc.completed THEN 1 ELSE 0 END)::int AS completed_count,
        CASE
            WHEN COUNT(u.id) = 0 THEN 0
            ELSE ROUND(SUM(CASE WHEN tc.completed THEN 1 ELSE 0 END)::numeric / COUNT(u.id) * 100, 2)
        END AS completion_percentage
    FROM users u
    LEFT JOIN task_completions tc
        ON tc.user_id = u.id
       AND tc.task_date = p_date
    WHERE u.team_id = p_team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- FIX: LeetCode Username Synchronization
-- ========================================
-- The Unified Update Function
-- Call this from the method UserProvider.updateLeetCodeUsername
CREATE OR REPLACE FUNCTION update_leetcode_username_unified(
    p_user_id UUID,
    p_new_username TEXT
)
RETURNS VOID AS $$
DECLARE
    v_old_username TEXT;
    v_email TEXT;
BEGIN
    -- 1. Get current info (Before update)
    SELECT leetcode_username, email INTO v_old_username, v_email
    FROM users
    WHERE id = p_user_id;

    -- Trim whitespace just in case
    p_new_username := TRIM(p_new_username);

    -- 2. Update users table (The Source of Truth)
    UPDATE users
    SET leetcode_username = p_new_username,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- 3. Update whitelist table (Keep registry in sync)
    IF v_email IS NOT NULL THEN
        UPDATE whitelist
        SET leetcode_username = p_new_username
        WHERE email = v_email;
    END IF;

    -- 4. Handle LeetCode Stats Table (Preserve History)
    IF v_old_username IS NOT NULL AND v_old_username != p_new_username THEN
        
        -- Check if the old username actually has stats
        IF EXISTS (SELECT 1 FROM leetcode_stats WHERE username = v_old_username) THEN
            
            -- Check if the NEW username already exists (collision)
            IF EXISTS (SELECT 1 FROM leetcode_stats WHERE username = p_new_username) THEN
                -- COLLISION: We cannot rename because the new name is already taken.
                -- Best Action: Delete the old artifact so we don't track stale data.
                -- The background fetcher will update the existing "new" record.
                DELETE FROM leetcode_stats WHERE username = v_old_username;
            ELSE
                -- NO COLLISION: Rename the old record to the new username.
                -- This preserves "total_solved", "ranking", etc.
                UPDATE leetcode_stats
                SET username = p_new_username,
                    last_updated = NOW() 
                WHERE username = v_old_username;
            END IF;
        END IF;
    END IF;

    -- 5. Helper: If no stats record exists at all for the new username (and we didn't just rename one),
    -- create a stub so the background fetcher picks it up faster.
    INSERT INTO leetcode_stats (username, total_solved, easy_solved, medium_solved, hard_solved)
    VALUES (p_new_username, 0, 0, 0, 0)
    ON CONFLICT (username) DO NOTHING;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STEP 3 COMPLETE: FUNCTIONS CREATED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '  - has_role';
    RAISE NOTICE '  - is_placement_rep';
    RAISE NOTICE '  - is_coordinator';
    RAISE NOTICE '  - is_team_leader';
    RAISE NOTICE '  - get_user_team';
    RAISE NOTICE '  - is_date_scheduled';
    RAISE NOTICE '  - get_scheduled_dates';
    RAISE NOTICE '  - get_team_task_completion_stats';
    RAISE NOTICE '  - student_attendance_summary (view)';
    RAISE NOTICE '  - update_leetcode_username_unified';
    RAISE NOTICE '';
    RAISE NOTICE 'NEXT: Run 02_policies.sql  (functions must exist before policies)';
    RAISE NOTICE '========================================';
END $$;
