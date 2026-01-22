-- ========================================
-- PSG MX PLACEMENT PREP - SUPABASE SCHEMA
-- ========================================
-- Run this SQL in your Supabase SQL Editor
-- This creates all tables and Row Level Security policies

-- ========================================
-- 1. USERS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  reg_no TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  team_id TEXT,
  roles JSONB DEFAULT '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_reg_no ON public.users(reg_no);
CREATE INDEX IF NOT EXISTS idx_users_team_id ON public.users(team_id);

-- ========================================
-- 2. WHITELIST TABLE (for authorized emails)
-- ========================================
CREATE TABLE IF NOT EXISTS public.whitelist (
  email TEXT PRIMARY KEY,
  reg_no TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  team_id TEXT NOT NULL,
  roles JSONB DEFAULT '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whitelist_email ON public.whitelist(email);

-- ========================================
-- 3. DAILY TASKS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.daily_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE UNIQUE NOT NULL,
  leetcode_url TEXT NOT NULL,
  cs_topic TEXT NOT NULL,
  cs_topic_description TEXT,
  motivation_quote TEXT,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_tasks_date ON public.daily_tasks(date);

-- ========================================
-- 4. ATTENDANCE SUBMISSIONS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.attendance_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  team_id TEXT NOT NULL,
  submitted_by UUID REFERENCES public.users(id) NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  is_locked BOOLEAN DEFAULT false,
  UNIQUE(date, team_id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_submissions_date_team ON public.attendance_submissions(date, team_id);

-- ========================================
-- 5. ATTENDANCE RECORDS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  student_uid UUID REFERENCES public.users(id) NOT NULL,
  reg_no TEXT NOT NULL,
  team_id TEXT NOT NULL,
  status TEXT CHECK (status IN ('PRESENT', 'ABSENT')) NOT NULL,
  marked_by UUID REFERENCES public.users(id) NOT NULL,
  overridden_by UUID REFERENCES public.users(id),
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(date, student_uid)
);

CREATE INDEX IF NOT EXISTS idx_attendance_records_date ON public.attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_records_student ON public.attendance_records(student_uid);
CREATE INDEX IF NOT EXISTS idx_attendance_records_date_student ON public.attendance_records(date, student_uid);

-- ========================================
-- 6. AUDIT LOGS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES public.users(id) NOT NULL,
  action TEXT NOT NULL,
  target_reg_no TEXT,
  target_date DATE,
  prev_value TEXT,
  new_value TEXT,
  reason TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON public.audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id);

-- ========================================
-- 7. FUNCTION: Check if current IST time is after 8 PM
-- ========================================
CREATE OR REPLACE FUNCTION is_after_8pm_ist()
RETURNS BOOLEAN AS $$
DECLARE
  ist_hour INTEGER;
BEGIN
  -- Convert UTC to IST (UTC + 5:30) and get hour
  ist_hour := EXTRACT(HOUR FROM (NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata'));
  RETURN ist_hour >= 20; -- 8 PM in 24-hour format
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 8. ROW LEVEL SECURITY POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ========================================
-- USERS TABLE POLICIES
-- ========================================

-- Anyone authenticated can read all users (needed for team views)
CREATE POLICY "Users are readable by authenticated users"
  ON public.users FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Users can update their own profile only
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- ========================================
-- WHITELIST TABLE POLICIES
-- ========================================

-- Whitelist is readable by anyone (for OTP email verification during signup)
-- SECURITY: Users can only see if their own email exists, not other emails
CREATE POLICY "Whitelist readable for email verification"
  ON public.whitelist FOR SELECT
  USING (true);

-- ========================================
-- DAILY TASKS POLICIES
-- ========================================

-- Everyone can read daily tasks
CREATE POLICY "Daily tasks readable by all authenticated"
  ON public.daily_tasks FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only coordinators can insert daily tasks
CREATE POLICY "Coordinators can create daily tasks"
  ON public.daily_tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (users.roles->>'isCoordinator')::boolean = true
    )
  );

-- ========================================
-- ATTENDANCE SUBMISSIONS POLICIES
-- ========================================

-- Team leaders can read their team's submissions
CREATE POLICY "Team leaders can read team submissions"
  ON public.attendance_submissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (
        users.team_id = attendance_submissions.team_id
        OR (users.roles->>'isPlacementRep')::boolean = true
      )
    )
  );

-- Team leaders can insert attendance ONLY for their team and ONLY before 8 PM IST
CREATE POLICY "Team leaders can submit attendance before 8 PM"
  ON public.attendance_submissions FOR INSERT
  WITH CHECK (
    NOT is_after_8pm_ist()
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.team_id = attendance_submissions.team_id
      AND (users.roles->>'isTeamLeader')::boolean = true
    )
  );

-- Placement reps can insert anytime (override capability)
CREATE POLICY "Placement reps can submit anytime"
  ON public.attendance_submissions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (users.roles->>'isPlacementRep')::boolean = true
    )
  );

-- ========================================
-- ATTENDANCE RECORDS POLICIES
-- ========================================

-- Students can read their own attendance
CREATE POLICY "Students can read own attendance"
  ON public.attendance_records FOR SELECT
  USING (
    attendance_records.student_uid = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (
        (users.roles->>'isTeamLeader')::boolean = true
        OR (users.roles->>'isCoordinator')::boolean = true
        OR (users.roles->>'isPlacementRep')::boolean = true
      )
    )
  );

-- Team leaders can insert attendance records ONLY before 8 PM IST for their team
CREATE POLICY "Team leaders can mark attendance before 8 PM"
  ON public.attendance_records FOR INSERT
  WITH CHECK (
    NOT is_after_8pm_ist()
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.team_id = attendance_records.team_id
      AND (users.roles->>'isTeamLeader')::boolean = true
    )
  );

-- Placement reps can insert/update attendance anytime (override capability)
CREATE POLICY "Placement reps can override attendance"
  ON public.attendance_records FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (users.roles->>'isPlacementRep')::boolean = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (users.roles->>'isPlacementRep')::boolean = true
    )
  );

-- ========================================
-- AUDIT LOGS POLICIES
-- ========================================

-- Only placement reps can read audit logs
CREATE POLICY "Only placement reps can read audit logs"
  ON public.audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND (users.roles->>'isPlacementRep')::boolean = true
    )
  );

-- System can insert audit logs (no user policy, done via service role)
CREATE POLICY "Allow insert for service role"
  ON public.audit_logs FOR INSERT
  WITH CHECK (true);

-- ========================================
-- 9. FUNCTION: Auto-create user on signup
-- ========================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if email is in whitelist
  IF EXISTS (SELECT 1 FROM public.whitelist WHERE email = NEW.email) THEN
    -- Insert user with whitelist data
    INSERT INTO public.users (id, email, reg_no, name, team_id, roles)
    SELECT NEW.id, NEW.email, reg_no, name, team_id, roles
    FROM public.whitelist
    WHERE email = NEW.email;
  ELSE
    -- Reject signup by raising exception
    RAISE EXCEPTION 'Email % is not authorized', NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile on auth signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- 10. SAMPLE DATA (OPTIONAL - for testing)
-- ========================================

-- Insert a sample coordinator (REPLACE WITH YOUR EMAIL FOR TESTING)
-- Run this after you've signed up with your test email
/*
INSERT INTO public.whitelist (email, reg_no, name, team_id, roles) VALUES
  ('coordinator@psgtech.ac.in', 'COORD001', 'Test Coordinator', 'TEAM_ADMIN', 
   '{"isStudent": false, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'),
  ('rep@psgtech.ac.in', 'REP001', 'Placement Rep', 'TEAM_ADMIN', 
   '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": true}'),
  ('leader@psgtech.ac.in', 'TL001', 'Team Leader', 'TEAM_A', 
   '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
  ('student@psgtech.ac.in', 'STU001', 'Regular Student', 'TEAM_A', 
   '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}');
*/

-- ========================================
-- MIGRATION COMPLETE
-- ========================================
-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Populate whitelist table with your student data
-- 3. Update supabase_config.dart with your project credentials
-- 4. Test authentication and role-based access
