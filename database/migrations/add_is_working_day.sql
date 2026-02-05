-- ========================================
-- MIGRATION: Add is_working_day column to scheduled_attendance_dates
-- Date: 2026-02-05
-- Purpose: Fix PostgrestException for missing is_working_day column
-- ========================================

-- Add is_working_day column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'scheduled_attendance_dates' 
        AND column_name = 'is_working_day'
    ) THEN
        ALTER TABLE scheduled_attendance_dates 
        ADD COLUMN is_working_day BOOLEAN NOT NULL DEFAULT TRUE;
        
        RAISE NOTICE 'Column is_working_day added successfully';
    ELSE
        RAISE NOTICE 'Column is_working_day already exists';
    END IF;
END $$;

-- Update existing records to set is_working_day based on weekday
UPDATE scheduled_attendance_dates
SET is_working_day = (EXTRACT(DOW FROM date) NOT IN (0, 6))
WHERE is_working_day IS NULL;

RAISE NOTICE 'Migration completed: is_working_day column added and existing records updated';
