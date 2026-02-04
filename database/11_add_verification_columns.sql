-- Add verification columns to task_completions table
-- Run this migration after 10_phase_a_schema.sql

-- Add verified_by column
ALTER TABLE task_completions 
ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Add verified_at column
ALTER TABLE task_completions 
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Add index for verification queries
CREATE INDEX IF NOT EXISTS idx_task_completions_verified_by ON task_completions(verified_by);

-- Comment on new columns
COMMENT ON COLUMN task_completions.verified_by IS 'Team leader who verified this task completion';
COMMENT ON COLUMN task_completions.verified_at IS 'Timestamp when the task was verified';
