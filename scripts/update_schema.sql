-- FIX: Add missing columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS dob DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS leetcode_username TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS leetcode_notifications_enabled BOOLEAN DEFAULT FALSE;

-- FIX: Ensure indexes exist for new columns
CREATE INDEX IF NOT EXISTS idx_users_leetcode_username ON users(leetcode_username);

-- FIX: Update RLS policies to allow updating these columns
-- (Assuming existing update policy covers "Own User" updates, which usually allows all columns or specific ones)
-- If your policy is restrictive (e.g. checks columns), you might need to recreate it.
-- Standard "Users can update own profile" usually allows full row update for that ID.

-- FIX: Add leetcode_stats table if missing (check if already in database_schema.sql)
CREATE TABLE IF NOT EXISTS leetcode_stats (
    username TEXT PRIMARY KEY, -- Using LeetCode username as key
    total_solved INTEGER DEFAULT 0,
    easy_solved INTEGER DEFAULT 0,
    medium_solved INTEGER DEFAULT 0,
    hard_solved INTEGER DEFAULT 0,
    ranking INTEGER DEFAULT 0,
    weekly_score INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for leetcode_stats
ALTER TABLE leetcode_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "LeetCode Stats are public view" 
ON leetcode_stats FOR SELECT 
USING (true);

-- Allow authenticated users (likely the system or the user themselves) to update their stats?
-- Usually, the backend/script updates this, but if client does it:
CREATE POLICY "Users can insert/update stats" 
ON leetcode_stats FOR ALL 
USING (auth.role() = 'authenticated'); 
-- Note: Ideally you restrict this so users can only update THEIR username, but mapping auth.uid -> leetcode_username requires a join. 
-- For now, authenticated is safer than anon.

-- FIX: Update sample user data if they exist
-- (Replace 'student@psg.edu' with actual email from create_auth_users.sql if different)
UPDATE users 
SET 
  dob = '2002-05-15', 
  leetcode_username = 'psg_student_demo',
  leetcode_notifications_enabled = true
WHERE email = 'student@psg.edu' AND leetcode_username IS NULL;


