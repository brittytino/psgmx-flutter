-- =============================================================================
-- MIGRATION: Add Team Leader Verification Support to task_completions
-- =============================================================================
-- Purpose: Add verification tracking columns to allow team leaders to verify
--          task completions submitted by their team members
-- Run this script in Supabase SQL Editor
-- =============================================================================

-- Step 1: Add new columns to task_completions table
-- -----------------------------------------------------------------------------

-- Add verified_by column (references the team leader who verified)
ALTER TABLE task_completions 
ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Add verified_at timestamp
ALTER TABLE task_completions 
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Step 2: Add indexes for performance
-- -----------------------------------------------------------------------------

-- Index for finding tasks verified by a specific team leader
CREATE INDEX IF NOT EXISTS idx_task_completions_verified_by 
ON task_completions(verified_by);

-- Index for finding verified tasks by date
CREATE INDEX IF NOT EXISTS idx_task_completions_verified_at 
ON task_completions(verified_at);

-- Composite index for team leader's verification queries
CREATE INDEX IF NOT EXISTS idx_task_completions_date_verified 
ON task_completions(task_date, verified_by);

-- Step 3: Add helpful comments
-- -----------------------------------------------------------------------------

COMMENT ON COLUMN task_completions.verified_by IS 
'UUID of the team leader who verified this task completion';

COMMENT ON COLUMN task_completions.verified_at IS 
'Timestamp when the task completion was verified by team leader';

-- Step 4: Update RLS Policies for Team Leader Verification
-- -----------------------------------------------------------------------------

-- Allow team leaders to INSERT task completions for their team members
DROP POLICY IF EXISTS "Team leaders can insert team completions" ON task_completions;
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

-- Allow team leaders to UPDATE task completions for their team members
DROP POLICY IF EXISTS "Team leaders can update team completions" ON task_completions;
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

-- Allow coordinators and placement reps to INSERT/UPDATE all completions
DROP POLICY IF EXISTS "Admins can insert all task completions" ON task_completions;
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

DROP POLICY IF EXISTS "Admins can update all task completions" ON task_completions;
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

-- Step 5: Verify the changes
-- -----------------------------------------------------------------------------

-- Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'task_completions'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =============================================================================
-- VERIFICATION QUERIES (Optional - Run these to test)
-- =============================================================================

-- Count total tasks
SELECT COUNT(*) as total_tasks FROM task_completions;

-- Count verified tasks
SELECT COUNT(*) as verified_tasks 
FROM task_completions 
WHERE verified_by IS NOT NULL;

-- Show verification stats by date
SELECT 
    task_date,
    COUNT(*) as total_tasks,
    COUNT(verified_by) as verified_tasks,
    ROUND(COUNT(verified_by)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as verification_percentage
FROM task_completions
WHERE task_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY task_date
ORDER BY task_date DESC;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
