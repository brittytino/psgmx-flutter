-- ========================================
-- PSG MX PLACEMENT APP - NOTIFICATION TRIGGERS
-- ========================================
-- File 6: Automate Notifications via Database Triggers
-- 
-- Automatically creates records in 'notifications' table when
-- important events occur (New Task, Attendance, etc.)
-- This ensures Realtime updates work perfectly.
-- ========================================

-- 1. TRIGGER: New Daily Task Notification
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


-- 2. TRIGGER: New Attendance Schedule Notification
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


-- 3. TRIGGER: LeetCode Milestone Notification (Example logic)
-- Assuming we want to notify when someone crosses a big milestone (e.g. 100 problems)
-- This requires checking the OLD vs NEW value on update.

CREATE OR REPLACE FUNCTION notify_leetcode_milestone()
RETURNS TRIGGER AS $$
DECLARE
    milestone INT := 50; -- Notify every 50 problems
    old_milestone INT;
    new_milestone INT;
    user_name TEXT;
BEGIN
    -- Calculate milestones (integer division)
    old_milestone := OLD.total_solved / milestone;
    new_milestone := NEW.total_solved / milestone;

    -- If moved to a new milestone bracket (e.g., 49 -> 50)
    IF new_milestone > old_milestone THEN
        -- Get user details if possible (assuming username is the key)
        -- Note: leetcode_stats uses 'username' which might not directly link to a specific user UUID easily if not consistent
        -- But for a general announcement, we can just use the username.
        
        INSERT INTO notifications (
            title,
            message,
            notification_type,
            tone,
            target_audience,
            created_by
        ) VALUES (
            '🏆 New Milestone Reached!',
            NEW.username || ' has just solved ' || NEW.total_solved || ' problems! Keep it up!',
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

-- Success Message
DO $$
BEGIN
    RAISE NOTICE '✅ Notification triggers setup successfully.';
END $$;
