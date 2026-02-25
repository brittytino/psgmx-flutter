-- ========================================
-- PSG MX PLACEMENT APP - TRIGGERS
-- ========================================
-- File 4 of 5: Automation Triggers
-- 
-- 1. Notification Triggers (New Task, Attendance, Milestones)
-- 2. Maintenance Triggers (Timestamps)
-- 
-- Run this AFTER 03_functions.sql
-- ========================================

-- ========================================
-- 1. NOTIFICATION TRIGGERS
-- ========================================

-- TRIGGER: New Daily Task Notification
CREATE OR REPLACE FUNCTION notify_new_daily_task()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (
        title,
        message,
        notification_type,
        tone,
        target_audience,
        created_by
    ) VALUES (
        'New Task Added: ' || NEW.title,
        'A new ' || NEW.topic_type || ' task has been posted for ' || NEW.date || '. Check it out now!',
        'alert',
        'friendly',
        'all',
        NEW.uploaded_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_daily_task_created ON daily_tasks;
CREATE TRIGGER on_daily_task_created
    AFTER INSERT ON daily_tasks
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_daily_task();


-- TRIGGER: New Attendance Schedule Notification
CREATE OR REPLACE FUNCTION notify_attendance_schedule()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (
        title,
        message,
        notification_type,
        tone,
        target_audience,
        created_by
    ) VALUES (
        'Attendance Scheduled',
        'Attendance marking has been scheduled for ' || NEW.date || '. Team Leaders, please be ready.',
        'reminder',
        'serious',
        'team_leaders',
        NEW.scheduled_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_attendance_scheduled ON scheduled_attendance_dates;
CREATE TRIGGER on_attendance_scheduled
    AFTER INSERT ON scheduled_attendance_dates
    FOR EACH ROW
    EXECUTE FUNCTION notify_attendance_schedule();


-- TRIGGER: LeetCode Milestone Notification
CREATE OR REPLACE FUNCTION notify_leetcode_milestone()
RETURNS TRIGGER AS $$
DECLARE
    milestone INT := 50; -- Notify every 50 problems
    old_milestone INT;
    new_milestone INT;
    display_name TEXT;
BEGIN
    -- Calculate milestones (integer division)
    old_milestone := OLD.total_solved / milestone;
    new_milestone := NEW.total_solved / milestone;

    -- If moved to a new milestone bracket (e.g., 49 -> 50)
    IF new_milestone > old_milestone THEN
        -- Get user's real name from users table (joining on leetcode_username)
        SELECT name INTO display_name
        FROM users
        WHERE leetcode_username = NEW.username
        LIMIT 1;

        -- Fallback to username if real name not found
        IF display_name IS NULL THEN
            display_name := NEW.username;
        END IF;
        
        INSERT INTO notifications (
            title,
            message,
            notification_type,
            tone,
            target_audience,
            created_by
        ) VALUES (
            '🏆 New Milestone Reached!',
            display_name || ' has just solved ' || NEW.total_solved || ' problems! Keep it up!',
            'motivation',
            'friendly',
            'all',
            NULL -- System generated
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_leetcode_stat_update ON leetcode_stats;
CREATE TRIGGER on_leetcode_stat_update
    AFTER UPDATE OF total_solved ON leetcode_stats
    FOR EACH ROW
    WHEN (NEW.total_solved > OLD.total_solved) -- Only on increase
    EXECUTE FUNCTION notify_leetcode_milestone();

-- ========================================
-- 2. AUTH TRIGGER: Auto-create user profile on first login
-- ========================================
-- When a student completes OTP login, Supabase inserts into auth.users.
-- This trigger fires immediately after and copies their data from
-- the whitelist into public.users using the real auth UUID.
-- This is the ONLY correct way to populate users — never use gen_random_uuid().

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    wl RECORD;
BEGIN
    -- Look up this email in the whitelist
    SELECT * INTO wl FROM public.whitelist WHERE email = NEW.email;

    IF wl IS NOT NULL THEN
        -- Create the users row with the real auth UUID
        INSERT INTO public.users (
            id,
            email,
            reg_no,
            name,
            team_id,
            batch,
            roles,
            leetcode_username,
            dob,
            birthday_notifications_enabled,
            leetcode_notifications_enabled,
            task_reminders_enabled,
            attendance_alerts_enabled,
            announcements_enabled
        ) VALUES (
            NEW.id,   -- Real UUID from auth.users — no gen_random_uuid()!
            NEW.email,
            wl.reg_no,
            wl.name,
            wl.team_id,
            COALESCE(wl.batch, 'G1'),
            COALESCE(wl.roles, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
            wl.leetcode_username,
            wl.dob,
            TRUE,
            TRUE,
            TRUE,
            TRUE,
            TRUE
        )
        ON CONFLICT (id) DO NOTHING;  -- Idempotent: safe to re-run
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ========================================
-- 3. MAINTENANCE TRIGGERS
-- ========================================

-- TRIGGER: App Config Timestamp
CREATE OR REPLACE FUNCTION update_app_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS app_config_updated_at ON app_config;
CREATE TRIGGER app_config_updated_at
    BEFORE UPDATE ON app_config
    FOR EACH ROW
    EXECUTE FUNCTION update_app_config_timestamp();

-- ========================================
-- FINISH
-- ========================================
DO $$
BEGIN
    RAISE NOTICE '✅ Triggers & Automations setup successfully.';
    RAISE NOTICE 'NEXT: Run 05_seed_data.sql';
END $$;
