-- ========================================
-- LEETCODE FEATURE TABLES
-- ========================================

CREATE TABLE IF NOT EXISTS public.leetcode_stats (
    username TEXT PRIMARY KEY,
    total_solved INT DEFAULT 0,
    easy_solved INT DEFAULT 0,
    medium_solved INT DEFAULT 0,
    hard_solved INT DEFAULT 0,
    ranking INT DEFAULT 0,
    weekly_score INT DEFAULT 0, -- Solved in last 7 days
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: Public read, Authenticated update (via App logic or Edge Function)
ALTER TABLE public.leetcode_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read of stats" ON public.leetcode_stats
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated users to update stats" ON public.leetcode_stats
    FOR ALL USING (auth.role() = 'authenticated');

-- ========================================
-- NOTIFICATIONS PREFERENCES
-- ========================================
-- Already in users table (birthday_notifications_enabled), 
-- but adding specific LeetCode toggle if not present
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS leetcode_notifications_enabled BOOLEAN DEFAULT true;
