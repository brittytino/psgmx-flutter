-- ========================================
-- ATTENDANCE SYSTEM WITH SCHEDULED DATES
-- ========================================
-- This schema supports scheduled attendance marking
-- Only on dates marked as "scheduled" by placement reps
-- can team leaders mark attendance
-- ========================================

-- Table: scheduled_attendance_dates
-- Stores dates when placement classes are scheduled
CREATE TABLE IF NOT EXISTS scheduled_attendance_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    scheduled_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scheduled_dates_date ON scheduled_attendance_dates(date);
CREATE INDEX IF NOT EXISTS idx_scheduled_dates_scheduled_by ON scheduled_attendance_dates(scheduled_by);

-- Table: attendance_records
-- Stores individual attendance records
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PRESENT', 'ABSENT', 'NA')),
    marked_by UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One record per student per date
    UNIQUE(date, student_id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance_records(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_team ON attendance_records(team_id);
CREATE INDEX IF NOT EXISTS idx_attendance_marked_by ON attendance_records(marked_by);
CREATE INDEX IF NOT EXISTS idx_attendance_date_team ON attendance_records(date, team_id);

-- ========================================
-- VIEWS - Drop existing if they exist
-- ========================================
DROP VIEW IF EXISTS student_attendance_summary CASCADE;
DROP VIEW IF EXISTS team_attendance_summary CASCADE;

-- ========================================
-- VIEW: student_attendance_summary
-- ========================================
CREATE VIEW student_attendance_summary AS
SELECT 
    u.id as student_id,
    u.name,
    u.reg_no,
    u.email,
    u.team_id,
    u.batch,
    COUNT(CASE WHEN ar.status = 'PRESENT' THEN 1 END) as present_count,
    COUNT(CASE WHEN ar.status = 'ABSENT' THEN 1 END) as absent_count,
    COUNT(ar.id) as total_marked_days,
    ROUND(
        (COUNT(CASE WHEN ar.status = 'PRESENT' THEN 1 END)::numeric / 
        NULLIF(COUNT(ar.id), 0)) * 100, 
        2
    ) as attendance_percentage
FROM users u
LEFT JOIN attendance_records ar ON u.id = ar.student_id
WHERE u.roles->>'isStudent' = 'true'
GROUP BY u.id, u.name, u.reg_no, u.email, u.team_id, u.batch;

-- ========================================
-- VIEW: team_attendance_summary  
-- ========================================
CREATE VIEW team_attendance_summary AS
SELECT 
    ar.team_id,
    u.batch,
    COUNT(DISTINCT ar.student_id) as team_size,
    COUNT(CASE WHEN ar.status = 'PRESENT' THEN 1 END) as total_present,
    COUNT(CASE WHEN ar.status = 'ABSENT' THEN 1 END) as total_absent,
    COUNT(ar.id) as total_records,
    ROUND(
        (COUNT(CASE WHEN ar.status = 'PRESENT' THEN 1 END)::numeric / 
        NULLIF(COUNT(ar.id), 0)) * 100, 
        2
    ) as team_attendance_percentage
FROM attendance_records ar
LEFT JOIN users u ON ar.student_id = u.id
GROUP BY ar.team_id, u.batch;

-- ========================================
-- FUNCTIONS
-- ========================================

-- Function: Check if date is scheduled for attendance
CREATE OR REPLACE FUNCTION is_date_scheduled(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM scheduled_attendance_dates 
        WHERE date = check_date
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function: Get scheduled dates in range
CREATE OR REPLACE FUNCTION get_scheduled_dates(
    start_date DATE,
    end_date DATE
)
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

-- Function: Get team attendance for a specific date
CREATE OR REPLACE FUNCTION get_team_attendance_for_date(
    check_date DATE,
    check_team_id TEXT
)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    reg_no TEXT,
    status TEXT,
    marked_by UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as student_id,
        u.name as student_name,
        u.reg_no,
        COALESCE(ar.status, 'NA') as status,
        ar.marked_by
    FROM users u
    LEFT JOIN attendance_records ar ON u.id = ar.student_id AND ar.date = check_date
    WHERE u.team_id = check_team_id
    AND u.roles->>'isStudent' = 'true'
    ORDER BY u.reg_no;
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

ALTER TABLE scheduled_attendance_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- Scheduled Dates Policies

-- Everyone can view scheduled dates
CREATE POLICY "Everyone can view scheduled dates"
ON scheduled_attendance_dates FOR SELECT
TO authenticated
USING (true);

-- Only placement reps can insert/update/delete scheduled dates
CREATE POLICY "Placement reps can manage scheduled dates"
ON scheduled_attendance_dates FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (roles->>'isPlacementRep' = 'true' OR roles->>'isCoordinator' = 'true')
    )
);

-- Attendance Records Policies

-- Students can view their own attendance
CREATE POLICY "Students can view own attendance"
ON attendance_records FOR SELECT
TO authenticated
USING (student_id = auth.uid());

-- Team leaders can view their team's attendance
CREATE POLICY "Team leaders can view team attendance"
ON attendance_records FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users u1
        WHERE u1.id = auth.uid()
        AND u1.roles->>'isTeamLeader' = 'true'
        AND u1.team_id = attendance_records.team_id
    )
);

-- Coordinators and Reps can view all attendance
CREATE POLICY "Admins can view all attendance"
ON attendance_records FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (roles->>'isPlacementRep' = 'true' OR roles->>'isCoordinator' = 'true')
    )
);

-- Team leaders can mark attendance for their team on scheduled dates
CREATE POLICY "Team leaders can mark team attendance"
ON attendance_records FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = auth.uid()
        AND u.roles->>'isTeamLeader' = 'true'
        AND u.team_id = attendance_records.team_id
        AND is_date_scheduled(attendance_records.date)
    )
);

-- Team leaders can update attendance they marked
CREATE POLICY "Team leaders can update own marked attendance"
ON attendance_records FOR UPDATE
TO authenticated
USING (
    marked_by = auth.uid()
    OR EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (roles->>'isPlacementRep' = 'true' OR roles->>'isCoordinator' = 'true')
    )
);

-- Placement reps can insert/update/delete any attendance
CREATE POLICY "Placement reps can manage all attendance"
ON attendance_records FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND (roles->>'isPlacementRep' = 'true' OR roles->>'isCoordinator' = 'true')
    )
);

-- ========================================
-- TRIGGERS
-- ========================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_attendance_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER attendance_records_updated_at
    BEFORE UPDATE ON attendance_records
    FOR EACH ROW
    EXECUTE FUNCTION update_attendance_updated_at();

CREATE TRIGGER scheduled_dates_updated_at
    BEFORE UPDATE ON scheduled_attendance_dates
    FOR EACH ROW
    EXECUTE FUNCTION update_attendance_updated_at();

-- ========================================
-- INITIAL DATA (OPTIONAL)
-- ========================================
-- Add some sample scheduled dates for testing
-- Uncomment if you want to add sample data

/*
INSERT INTO scheduled_attendance_dates (date, notes) VALUES
    ('2026-01-30', 'Placement class - Data Structures'),
    ('2026-01-31', 'Placement class - Algorithms'),
    ('2026-02-03', 'Placement class - System Design')
ON CONFLICT (date) DO NOTHING;
*/
