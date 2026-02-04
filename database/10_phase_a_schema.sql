-- ========================================
-- PSGMX PHASE A - PHILOSOPHY GAP CLOSURE
-- ========================================
-- This migration adds tables and columns for:
-- A1: Task Completion Marking
-- A2: Notification Preferences Persistence
-- B1: Automatic Defaulter Flagging
-- ========================================

-- ========================================
-- A1: TASK COMPLETIONS TABLE
-- ========================================
-- Tracks whether a student has completed daily tasks

CREATE TABLE IF NOT EXISTS task_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_date DATE NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, task_date)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON task_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_date ON task_completions(task_date);
CREATE INDEX IF NOT EXISTS idx_task_completions_completed ON task_completions(completed);
CREATE INDEX IF NOT EXISTS idx_task_completions_user_date ON task_completions(user_id, task_date);

-- ========================================
-- A2: NOTIFICATION PREFERENCES (in users table)
-- ========================================
-- Add additional notification preference columns to users table

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS task_reminders_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS attendance_alerts_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS announcements_enabled BOOLEAN DEFAULT TRUE;

-- ========================================
-- B1: DEFAULTER FLAGS TABLE
-- ========================================
-- Tracks students flagged as attendance defaulters

CREATE TABLE IF NOT EXISTS defaulter_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    defaulter_status BOOLEAN NOT NULL DEFAULT FALSE,
    defaulter_reason TEXT NOT NULL,
    consecutive_absences INT DEFAULT 0,
    attendance_percentage DECIMAL(5,2),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_defaulter_flags_user_id ON defaulter_flags(user_id);
CREATE INDEX IF NOT EXISTS idx_defaulter_flags_status ON defaulter_flags(defaulter_status);

-- ========================================
-- RLS POLICIES FOR TASK COMPLETIONS
-- ========================================

ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;

-- Students can view and manage their own completions
CREATE POLICY "Users can view own task completions"
ON task_completions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own task completions"
ON task_completions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own task completions"
ON task_completions FOR UPDATE
USING (auth.uid() = user_id);

-- Team Leaders can view their team's completions
CREATE POLICY "Team leaders can view team completions"
ON task_completions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users u1
        JOIN users u2 ON u1.team_id = u2.team_id
        WHERE u1.id = auth.uid()
        AND u2.id = task_completions.user_id
        AND (u1.roles->>'isTeamLeader')::boolean = true
    )
);

-- Team Leaders can insert/update task completions for their team members (for verification)
CREATE POLICY "Team leaders can insert team completions"
ON task_completions FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users u1
        JOIN users u2 ON u1.team_id = u2.team_id
        WHERE u1.id = auth.uid()
        AND u2.id = task_completions.user_id
        AND (u1.roles->>'isTeamLeader')::boolean = true
    )
);

CREATE POLICY "Team leaders can update team completions"
ON task_completions FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM users u1
        JOIN users u2 ON u1.team_id = u2.team_id
        WHERE u1.id = auth.uid()
        AND u2.id = task_completions.user_id
        AND (u1.roles->>'isTeamLeader')::boolean = true
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users u1
        JOIN users u2 ON u1.team_id = u2.team_id
        WHERE u1.id = auth.uid()
        AND u2.id = task_completions.user_id
        AND (u1.roles->>'isTeamLeader')::boolean = true
    )
);

-- Placement Reps and Coordinators can view all
CREATE POLICY "Admins can view all task completions"
ON task_completions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (
            (roles->>'isPlacementRep')::boolean = true
            OR (roles->>'isCoordinator')::boolean = true
        )
    )
);

-- Placement Reps and Coordinators can insert/update all
CREATE POLICY "Admins can insert all task completions"
ON task_completions FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (
            (roles->>'isPlacementRep')::boolean = true
            OR (roles->>'isCoordinator')::boolean = true
        )
    )
);

CREATE POLICY "Admins can update all task completions"
ON task_completions FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (
            (roles->>'isPlacementRep')::boolean = true
            OR (roles->>'isCoordinator')::boolean = true
        )
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (
            (roles->>'isPlacementRep')::boolean = true
            OR (roles->>'isCoordinator')::boolean = true
        )
    )
);

-- ========================================
-- RLS POLICIES FOR DEFAULTER FLAGS
-- ========================================

ALTER TABLE defaulter_flags ENABLE ROW LEVEL SECURITY;

-- Only Team Leaders, Coordinators, and Placement Reps can view defaulter flags
-- Students should NOT see their own defaulter status
CREATE POLICY "Leaders can view team defaulter flags"
ON defaulter_flags FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users u1
        JOIN users u2 ON u1.team_id = u2.team_id
        WHERE u1.id = auth.uid()
        AND u2.id = defaulter_flags.user_id
        AND (u1.roles->>'isTeamLeader')::boolean = true
    )
);

CREATE POLICY "Admins can view all defaulter flags"
ON defaulter_flags FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (
            (roles->>'isPlacementRep')::boolean = true
            OR (roles->>'isCoordinator')::boolean = true
        )
    )
);

CREATE POLICY "Admins can manage defaulter flags"
ON defaulter_flags FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (
            (roles->>'isPlacementRep')::boolean = true
            OR (roles->>'isCoordinator')::boolean = true
        )
    )
);

-- ========================================
-- FUNCTION: Calculate Attendance Streak
-- ========================================

CREATE OR REPLACE FUNCTION calculate_attendance_streak(p_user_id UUID)
RETURNS TABLE (
    current_streak INT,
    longest_streak INT,
    total_class_days INT,
    total_non_class_days INT
) AS $$
DECLARE
    v_current_streak INT := 0;
    v_longest_streak INT := 0;
    v_temp_streak INT := 0;
    v_total_class_days INT := 0;
    v_total_non_class_days INT := 0;
    rec RECORD;
BEGIN
    -- Count class days and non-class days
    SELECT 
        COUNT(*) FILTER (WHERE is_working_day = true),
        COUNT(*) FILTER (WHERE is_working_day = false)
    INTO v_total_class_days, v_total_non_class_days
    FROM attendance_days;
    
    -- Calculate streaks by iterating through attendance records
    -- ordered by date descending (most recent first)
    FOR rec IN (
        SELECT ar.date, ar.status, COALESCE(ad.is_working_day, true) as is_class_day
        FROM attendance_records ar
        LEFT JOIN attendance_days ad ON ar.date = ad.date
        WHERE ar.user_id = p_user_id
        ORDER BY ar.date DESC
    ) LOOP
        -- Skip non-class days
        IF NOT rec.is_class_day THEN
            CONTINUE;
        END IF;
        
        IF rec.status = 'PRESENT' THEN
            v_temp_streak := v_temp_streak + 1;
            IF v_temp_streak > v_longest_streak THEN
                v_longest_streak := v_temp_streak;
            END IF;
        ELSE
            -- First absence we encounter from most recent
            -- Current streak is what we accumulated before this
            IF v_current_streak = 0 THEN
                v_current_streak := v_temp_streak;
            END IF;
            v_temp_streak := 0;
        END IF;
    END LOOP;
    
    -- If no absence was found, current streak equals temp streak
    IF v_current_streak = 0 THEN
        v_current_streak := v_temp_streak;
    END IF;
    
    RETURN QUERY SELECT v_current_streak, v_longest_streak, v_total_class_days, v_total_non_class_days;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- FUNCTION: Get Task Completion Stats for a Team
-- ========================================

CREATE OR REPLACE FUNCTION get_team_task_completion_stats(p_team_id TEXT, p_date DATE)
RETURNS TABLE (
    total_members INT,
    completed_count INT,
    completion_percentage DECIMAL(5,2)
) AS $$
DECLARE
    v_total INT;
    v_completed INT;
BEGIN
    -- Count total team members
    SELECT COUNT(*) INTO v_total
    FROM users
    WHERE team_id = p_team_id;
    
    -- Count completed tasks for the date
    SELECT COUNT(*) INTO v_completed
    FROM task_completions tc
    JOIN users u ON tc.user_id = u.id
    WHERE u.team_id = p_team_id
    AND tc.task_date = p_date
    AND tc.completed = true;
    
    RETURN QUERY SELECT 
        v_total,
        v_completed,
        CASE WHEN v_total > 0 THEN (v_completed::DECIMAL / v_total * 100) ELSE 0 END;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- FUNCTION: Check and Flag Defaulters
-- ========================================

CREATE OR REPLACE FUNCTION check_and_flag_defaulters(p_threshold DECIMAL DEFAULT 75.0, p_consecutive_days INT DEFAULT 3)
RETURNS VOID AS $$
DECLARE
    rec RECORD;
    v_consecutive INT;
    v_percentage DECIMAL;
BEGIN
    -- Iterate through all students
    FOR rec IN (
        SELECT id, team_id FROM users WHERE (roles->>'isStudent')::boolean = true
    ) LOOP
        -- Calculate consecutive absences
        SELECT COUNT(*) INTO v_consecutive
        FROM (
            SELECT ar.date, ar.status,
                   ROW_NUMBER() OVER (ORDER BY ar.date DESC) as rn
            FROM attendance_records ar
            LEFT JOIN attendance_days ad ON ar.date = ad.date
            WHERE ar.user_id = rec.id
            AND COALESCE(ad.is_working_day, true) = true
            ORDER BY ar.date DESC
            LIMIT 10
        ) recent
        WHERE recent.status = 'ABSENT'
        AND recent.rn <= p_consecutive_days;
        
        -- Calculate attendance percentage
        SELECT 
            CASE WHEN COUNT(*) > 0 
                THEN (COUNT(*) FILTER (WHERE status = 'PRESENT')::DECIMAL / COUNT(*) * 100)
                ELSE 100 
            END
        INTO v_percentage
        FROM attendance_records ar
        LEFT JOIN attendance_days ad ON ar.date = ad.date
        WHERE ar.user_id = rec.id
        AND COALESCE(ad.is_working_day, true) = true;
        
        -- Flag if conditions met
        IF v_consecutive >= p_consecutive_days OR v_percentage < p_threshold THEN
            INSERT INTO defaulter_flags (
                user_id,
                defaulter_status,
                defaulter_reason,
                consecutive_absences,
                attendance_percentage,
                detected_at
            ) VALUES (
                rec.id,
                true,
                CASE 
                    WHEN v_consecutive >= p_consecutive_days AND v_percentage < p_threshold THEN
                        'Consecutive absences AND low attendance percentage'
                    WHEN v_consecutive >= p_consecutive_days THEN
                        'Consecutive absences: ' || v_consecutive || ' days'
                    ELSE
                        'Low attendance percentage: ' || ROUND(v_percentage, 1) || '%'
                END,
                v_consecutive,
                v_percentage,
                NOW()
            )
            ON CONFLICT (user_id) DO UPDATE SET
                defaulter_status = true,
                defaulter_reason = EXCLUDED.defaulter_reason,
                consecutive_absences = EXCLUDED.consecutive_absences,
                attendance_percentage = EXCLUDED.attendance_percentage,
                detected_at = NOW(),
                updated_at = NOW();
        ELSE
            -- Clear flag if conditions no longer met
            UPDATE defaulter_flags
            SET defaulter_status = false,
                resolved_at = NOW(),
                updated_at = NOW()
            WHERE user_id = rec.id
            AND defaulter_status = true;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- SUCCESS MESSAGE
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ PHASE A SCHEMA MIGRATION COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables Added:';
    RAISE NOTICE '  1. task_completions   - Task completion tracking';
    RAISE NOTICE '  2. defaulter_flags    - Defaulter status tracking';
    RAISE NOTICE '';
    RAISE NOTICE 'Columns Added to users:';
    RAISE NOTICE '  - task_reminders_enabled';
    RAISE NOTICE '  - attendance_alerts_enabled';
    RAISE NOTICE '  - announcements_enabled';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Added:';
    RAISE NOTICE '  - calculate_attendance_streak()';
    RAISE NOTICE '  - get_team_task_completion_stats()';
    RAISE NOTICE '  - check_and_flag_defaulters()';
    RAISE NOTICE '========================================';
END $$;
