-- ============================================================================
-- COMPLETE USER SEEDING SCRIPT
-- PSG Technology MCA (2025-2027) Placement Management System
-- ============================================================================

-- IMPORTANT: Run this script AFTER creating auth users manually via Supabase Dashboard
-- OR use Supabase Auth Admin API to create users programmatically

-- ============================================================================
-- SECTION 1: PLACEMENT REP (You)
-- ============================================================================
-- Email: 25mx354@psgtech.ac.in | Name: Tino Britty J | Team: G2-T07
-- Password: psgtech@2025 (change after first login)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles)
VALUES (
  (SELECT id FROM auth.users WHERE email = '25mx354@psgtech.ac.in'),
  '25mx354@psgtech.ac.in',
  'Tino Britty J',
  '25MX354',
  'G2',
  'G2-T07',
  '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": true}'::jsonb
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  reg_no = EXCLUDED.reg_no,
  team_id = EXCLUDED.team_id,
  roles = EXCLUDED.roles;

-- ============================================================================
-- SECTION 2: DUMMY TEST ACCOUNTS
-- ============================================================================

-- 2.1 Dummy Student (Regular Student)
-- Email: dummy.student@psgtech.ac.in | Password: student123
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'dummy.student@psgtech.ac.in'),
  'dummy.student@psgtech.ac.in',
  'Test Student',
  'DUMMY001',
  'G1',
  'G1-T01',
  '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  reg_no = EXCLUDED.reg_no,
  team_id = EXCLUDED.team_id,
  roles = EXCLUDED.roles;

-- 2.2 Dummy Team Leader
-- Email: dummy.leader@psgtech.ac.in | Password: leader123
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'dummy.leader@psgtech.ac.in'),
  'dummy.leader@psgtech.ac.in',
  'Test Team Leader',
  'DUMMY002',
  'G1',
  'G1-T02',
  '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  reg_no = EXCLUDED.reg_no,
  team_id = EXCLUDED.team_id,
  roles = EXCLUDED.roles;

-- 2.3 Dummy Coordinator
-- Email: dummy.coordinator@psgtech.ac.in | Password: coordinator123
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'dummy.coordinator@psgtech.ac.in'),
  'dummy.coordinator@psgtech.ac.in',
  'Test Coordinator',
  'DUMMY003',
  'G1',
  'G1-T03',
  '{"isStudent": true, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'::jsonb
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  reg_no = EXCLUDED.reg_no,
  team_id = EXCLUDED.team_id,
  roles = EXCLUDED.roles;

-- ============================================================================
-- SECTION 3: ALL 121 REAL STUDENTS (From Master List)
-- ============================================================================

-- Group 1 - Team 1 (G1-T01)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx113@psgtech.ac.in'), '25mx113@psgtech.ac.in', 'Anand S', '25MX113', 'G1', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx132@psgtech.ac.in'), '25mx132@psgtech.ac.in', 'Balaji R', '25MX132', 'G1', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx166@psgtech.ac.in'), '25mx166@psgtech.ac.in', 'Divya Sri S', '25MX166', 'G1', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx187@psgtech.ac.in'), '25mx187@psgtech.ac.in', 'Hariprasad R', '25MX187', 'G1', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx233@psgtech.ac.in'), '25mx233@psgtech.ac.in', 'Kishore M', '25MX233', 'G1', 'G1-T01', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx267@psgtech.ac.in'), '25mx267@psgtech.ac.in', 'Mohan Raj K', '25MX267', 'G1', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 2 (G1-T02)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx114@psgtech.ac.in'), '25mx114@psgtech.ac.in', 'Anantharaman M', '25MX114', 'G1', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx133@psgtech.ac.in'), '25mx133@psgtech.ac.in', 'Balasuriya M', '25MX133', 'G1', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx167@psgtech.ac.in'), '25mx167@psgtech.ac.in', 'Durgadevi S', '25MX167', 'G1', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx188@psgtech.ac.in'), '25mx188@psgtech.ac.in', 'Harish Kumar P', '25MX188', 'G1', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx234@psgtech.ac.in'), '25mx234@psgtech.ac.in', 'Kokila K', '25MX234', 'G1', 'G1-T02', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx268@psgtech.ac.in'), '25mx268@psgtech.ac.in', 'Monica M', '25MX268', 'G1', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 3 (G1-T03)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx115@psgtech.ac.in'), '25mx115@psgtech.ac.in', 'Anbarasan T', '25MX115', 'G1', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx134@psgtech.ac.in'), '25mx134@psgtech.ac.in', 'Balu M', '25MX134', 'G1', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx168@psgtech.ac.in'), '25mx168@psgtech.ac.in', 'Eswaran K', '25MX168', 'G1', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx189@psgtech.ac.in'), '25mx189@psgtech.ac.in', 'Hemalatha S', '25MX189', 'G1', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx235@psgtech.ac.in'), '25mx235@psgtech.ac.in', 'Krishnamoorthy V', '25MX235', 'G1', 'G1-T03', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx269@psgtech.ac.in'), '25mx269@psgtech.ac.in', 'Monisha R', '25MX269', 'G1', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 4 (G1-T04)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx116@psgtech.ac.in'), '25mx116@psgtech.ac.in', 'Ananth K', '25MX116', 'G1', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx135@psgtech.ac.in'), '25mx135@psgtech.ac.in', 'Baskaran S', '25MX135', 'G1', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx169@psgtech.ac.in'), '25mx169@psgtech.ac.in', 'Ganesh Kumar M', '25MX169', 'G1', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx190@psgtech.ac.in'), '25mx190@psgtech.ac.in', 'Indira V', '25MX190', 'G1', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx236@psgtech.ac.in'), '25mx236@psgtech.ac.in', 'Kumaran P', '25MX236', 'G1', 'G1-T04', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx270@psgtech.ac.in'), '25mx270@psgtech.ac.in', 'Muraleedharan S', '25MX270', 'G1', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 5 (G1-T05)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx117@psgtech.ac.in'), '25mx117@psgtech.ac.in', 'Anbarasi M', '25MX117', 'G1', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx136@psgtech.ac.in'), '25mx136@psgtech.ac.in', 'Baskaran V', '25MX136', 'G1', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx170@psgtech.ac.in'), '25mx170@psgtech.ac.in', 'Ganeshkumar R', '25MX170', 'G1', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx191@psgtech.ac.in'), '25mx191@psgtech.ac.in', 'Jagadeesan S', '25MX191', 'G1', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx237@psgtech.ac.in'), '25mx237@psgtech.ac.in', 'Lakshmanan M', '25MX237', 'G1', 'G1-T05', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx271@psgtech.ac.in'), '25mx271@psgtech.ac.in', 'Murali K', '25MX271', 'G1', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 6 (G1-T06)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx118@psgtech.ac.in'), '25mx118@psgtech.ac.in', 'Anil Kumar S', '25MX118', 'G1', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx137@psgtech.ac.in'), '25mx137@psgtech.ac.in', 'Bharathi S', '25MX137', 'G1', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx171@psgtech.ac.in'), '25mx171@psgtech.ac.in', 'Gnanasekaran M', '25MX171', 'G1', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx192@psgtech.ac.in'), '25mx192@psgtech.ac.in', 'Jayakumar R', '25MX192', 'G1', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx238@psgtech.ac.in'), '25mx238@psgtech.ac.in', 'Lakshminarayanan K', '25MX238', 'G1', 'G1-T06', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx272@psgtech.ac.in'), '25mx272@psgtech.ac.in', 'Muralidharan V', '25MX272', 'G1', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 7 (G1-T07)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx119@psgtech.ac.in'), '25mx119@psgtech.ac.in', 'Aravind M', '25MX119', 'G1', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx138@psgtech.ac.in'), '25mx138@psgtech.ac.in', 'Bharathiraja R', '25MX138', 'G1', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx172@psgtech.ac.in'), '25mx172@psgtech.ac.in', 'Gokulnath S', '25MX172', 'G1', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx193@psgtech.ac.in'), '25mx193@psgtech.ac.in', 'Jayaprakash M', '25MX193', 'G1', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx239@psgtech.ac.in'), '25mx239@psgtech.ac.in', 'Magesh R', '25MX239', 'G1', 'G1-T07', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx273@psgtech.ac.in'), '25mx273@psgtech.ac.in', 'Murugan S', '25MX273', 'G1', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 8 (G1-T08)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx120@psgtech.ac.in'), '25mx120@psgtech.ac.in', 'Aravindh Kumar M', '25MX120', 'G1', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx139@psgtech.ac.in'), '25mx139@psgtech.ac.in', 'Bhuvana S', '25MX139', 'G1', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx173@psgtech.ac.in'), '25mx173@psgtech.ac.in', 'Gopi M', '25MX173', 'G1', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx194@psgtech.ac.in'), '25mx194@psgtech.ac.in', 'Jeeva R', '25MX194', 'G1', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx240@psgtech.ac.in'), '25mx240@psgtech.ac.in', 'Mahalakshmi S', '25MX240', 'G1', 'G1-T08', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx274@psgtech.ac.in'), '25mx274@psgtech.ac.in', 'Murugesan M', '25MX274', 'G1', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 9 (G1-T09)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx121@psgtech.ac.in'), '25mx121@psgtech.ac.in', 'Arjun S', '25MX121', 'G1', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx140@psgtech.ac.in'), '25mx140@psgtech.ac.in', 'Bhuvaneshwari M', '25MX140', 'G1', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx174@psgtech.ac.in'), '25mx174@psgtech.ac.in', 'Gopinath K', '25MX174', 'G1', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx195@psgtech.ac.in'), '25mx195@psgtech.ac.in', 'Jeevitha S', '25MX195', 'G1', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx241@psgtech.ac.in'), '25mx241@psgtech.ac.in', 'Mahendran R', '25MX241', 'G1', 'G1-T09', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx275@psgtech.ac.in'), '25mx275@psgtech.ac.in', 'Muthukumar S', '25MX275', 'G1', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 10 (G1-T10)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx122@psgtech.ac.in'), '25mx122@psgtech.ac.in', 'Arun Kumar M', '25MX122', 'G1', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx141@psgtech.ac.in'), '25mx141@psgtech.ac.in', 'Deepa S', '25MX141', 'G1', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx175@psgtech.ac.in'), '25mx175@psgtech.ac.in', 'Gopi Krishna R', '25MX175', 'G1', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx196@psgtech.ac.in'), '25mx196@psgtech.ac.in', 'Kalaiarasan M', '25MX196', 'G1', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx242@psgtech.ac.in'), '25mx242@psgtech.ac.in', 'Mahesh Kumar S', '25MX242', 'G1', 'G1-T10', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx276@psgtech.ac.in'), '25mx276@psgtech.ac.in', 'Muthu Selvam R', '25MX276', 'G1', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 1 - Team 11 (G1-T11)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx123@psgtech.ac.in'), '25mx123@psgtech.ac.in', 'Arun Prasad K', '25MX123', 'G1', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx142@psgtech.ac.in'), '25mx142@psgtech.ac.in', 'Deepak R', '25MX142', 'G1', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx176@psgtech.ac.in'), '25mx176@psgtech.ac.in', 'Gopinath S', '25MX176', 'G1', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx197@psgtech.ac.in'), '25mx197@psgtech.ac.in', 'Kalaiselvi M', '25MX197', 'G1', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx243@psgtech.ac.in'), '25mx243@psgtech.ac.in', 'Mani K', '25MX243', 'G1', 'G1-T11', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx277@psgtech.ac.in'), '25mx277@psgtech.ac.in', 'Muthuraman M', '25MX277', 'G1', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 1 (G2-T01)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx201@psgtech.ac.in'), '25mx201@psgtech.ac.in', 'Kalaiselvan R', '25MX201', 'G2', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx244@psgtech.ac.in'), '25mx244@psgtech.ac.in', 'Manikandan S', '25MX244', 'G2', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx278@psgtech.ac.in'), '25mx278@psgtech.ac.in', 'Nagarajan M', '25MX278', 'G2', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx313@psgtech.ac.in'), '25mx313@psgtech.ac.in', 'Pradeep Kumar R', '25MX313', 'G2', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx355@psgtech.ac.in'), '25mx355@psgtech.ac.in', 'Rajesh M', '25MX355', 'G2', 'G2-T01', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx388@psgtech.ac.in'), '25mx388@psgtech.ac.in', 'Saravanan K', '25MX388', 'G2', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 2 (G2-T02)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx202@psgtech.ac.in'), '25mx202@psgtech.ac.in', 'Kaliappan M', '25MX202', 'G2', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx245@psgtech.ac.in'), '25mx245@psgtech.ac.in', 'Manoj Kumar R', '25MX245', 'G2', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx279@psgtech.ac.in'), '25mx279@psgtech.ac.in', 'Nandakumar S', '25MX279', 'G2', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx314@psgtech.ac.in'), '25mx314@psgtech.ac.in', 'Prakash M', '25MX314', 'G2', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx356@psgtech.ac.in'), '25mx356@psgtech.ac.in', 'Rajkumar S', '25MX356', 'G2', 'G2-T02', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx389@psgtech.ac.in'), '25mx389@psgtech.ac.in', 'Sathish Kumar M', '25MX389', 'G2', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 3 (G2-T03)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx203@psgtech.ac.in'), '25mx203@psgtech.ac.in', 'Kalpana S', '25MX203', 'G2', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx246@psgtech.ac.in'), '25mx246@psgtech.ac.in', 'Maran K', '25MX246', 'G2', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx280@psgtech.ac.in'), '25mx280@psgtech.ac.in', 'Narasimhan R', '25MX280', 'G2', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx315@psgtech.ac.in'), '25mx315@psgtech.ac.in', 'Prakash Kumar S', '25MX315', 'G2', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx357@psgtech.ac.in'), '25mx357@psgtech.ac.in', 'Ramachandran K', '25MX357', 'G2', 'G2-T03', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx390@psgtech.ac.in'), '25mx390@psgtech.ac.in', 'Sathishkumar R', '25MX390', 'G2', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 4 (G2-T04)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx204@psgtech.ac.in'), '25mx204@psgtech.ac.in', 'Kamal S', '25MX204', 'G2', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx247@psgtech.ac.in'), '25mx247@psgtech.ac.in', 'Mathan Kumar M', '25MX247', 'G2', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx281@psgtech.ac.in'), '25mx281@psgtech.ac.in', 'Natarajan K', '25MX281', 'G2', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx316@psgtech.ac.in'), '25mx316@psgtech.ac.in', 'Prasanna Kumar M', '25MX316', 'G2', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx358@psgtech.ac.in'), '25mx358@psgtech.ac.in', 'Ramakrishnan M', '25MX358', 'G2', 'G2-T04', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx391@psgtech.ac.in'), '25mx391@psgtech.ac.in', 'Sathya Prakash K', '25MX391', 'G2', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 5 (G2-T05)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx205@psgtech.ac.in'), '25mx205@psgtech.ac.in', 'Karthick R', '25MX205', 'G2', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx248@psgtech.ac.in'), '25mx248@psgtech.ac.in', 'Mathevan S', '25MX248', 'G2', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx282@psgtech.ac.in'), '25mx282@psgtech.ac.in', 'Naveen Kumar R', '25MX282', 'G2', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx317@psgtech.ac.in'), '25mx317@psgtech.ac.in', 'Praveen Kumar K', '25MX317', 'G2', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx359@psgtech.ac.in'), '25mx359@psgtech.ac.in', 'Raman M', '25MX359', 'G2', 'G2-T05', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx392@psgtech.ac.in'), '25mx392@psgtech.ac.in', 'Selvam R', '25MX392', 'G2', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 6 (G2-T06)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx206@psgtech.ac.in'), '25mx206@psgtech.ac.in', 'Karthikeyan M', '25MX206', 'G2', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx249@psgtech.ac.in'), '25mx249@psgtech.ac.in', 'Mathivannan K', '25MX249', 'G2', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx283@psgtech.ac.in'), '25mx283@psgtech.ac.in', 'Naveenkumar M', '25MX283', 'G2', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx318@psgtech.ac.in'), '25mx318@psgtech.ac.in', 'Praveen Kumar M', '25MX318', 'G2', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx360@psgtech.ac.in'), '25mx360@psgtech.ac.in', 'Ramanan K', '25MX360', 'G2', 'G2-T06', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx393@psgtech.ac.in'), '25mx393@psgtech.ac.in', 'Selvakumar M', '25MX393', 'G2', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 7 (G2-T07) - YOUR TEAM
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx207@psgtech.ac.in'), '25mx207@psgtech.ac.in', 'Karthikeyan S', '25MX207', 'G2', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx250@psgtech.ac.in'), '25mx250@psgtech.ac.in', 'Mayandi R', '25MX250', 'G2', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx284@psgtech.ac.in'), '25mx284@psgtech.ac.in', 'Navin K', '25MX284', 'G2', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx319@psgtech.ac.in'), '25mx319@psgtech.ac.in', 'Pravin Kumar R', '25MX319', 'G2', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
-- YOUR ACCOUNT IS ALREADY INSERTED IN SECTION 1 - ((SELECT id FROM auth.users WHERE email = '25mx354@psgtech.ac.in'), '25mx354@psgtech.ac.in', 'Tino Britty J', '25MX354', 'G2', 'G2-T07', PLACEMENT REP)
((SELECT id FROM auth.users WHERE email = '25mx361@psgtech.ac.in'), '25mx361@psgtech.ac.in', 'Ramanathan M', '25MX361', 'G2', 'G2-T07', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx394@psgtech.ac.in'), '25mx394@psgtech.ac.in', 'Senthil Kumar K', '25MX394', 'G2', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 8 (G2-T08)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx208@psgtech.ac.in'), '25mx208@psgtech.ac.in', 'Karthikraja M', '25MX208', 'G2', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx251@psgtech.ac.in'), '25mx251@psgtech.ac.in', 'Mayilsamy K', '25MX251', 'G2', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx285@psgtech.ac.in'), '25mx285@psgtech.ac.in', 'Nivas R', '25MX285', 'G2', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx320@psgtech.ac.in'), '25mx320@psgtech.ac.in', 'Premkumar S', '25MX320', 'G2', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx362@psgtech.ac.in'), '25mx362@psgtech.ac.in', 'Ramesh Kumar R', '25MX362', 'G2', 'G2-T08', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx395@psgtech.ac.in'), '25mx395@psgtech.ac.in', 'Senthilkumar R', '25MX395', 'G2', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 9 (G2-T09)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx209@psgtech.ac.in'), '25mx209@psgtech.ac.in', 'Karuppasamy M', '25MX209', 'G2', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx252@psgtech.ac.in'), '25mx252@psgtech.ac.in', 'Meenatchi S', '25MX252', 'G2', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx286@psgtech.ac.in'), '25mx286@psgtech.ac.in', 'Palani M', '25MX286', 'G2', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx321@psgtech.ac.in'), '25mx321@psgtech.ac.in', 'Priyadharshini S', '25MX321', 'G2', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx363@psgtech.ac.in'), '25mx363@psgtech.ac.in', 'Ramesh M', '25MX363', 'G2', 'G2-T09', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx396@psgtech.ac.in'), '25mx396@psgtech.ac.in', 'Seran K', '25MX396', 'G2', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- Group 2 - Team 10 (G2-T10)
INSERT INTO public.users (id, email, name, reg_no, batch, team_id, roles) VALUES
((SELECT id FROM auth.users WHERE email = '25mx210@psgtech.ac.in'), '25mx210@psgtech.ac.in', 'Kasi Viswanathan R', '25MX210', 'G2', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx253@psgtech.ac.in'), '25mx253@psgtech.ac.in', 'Meenakshi M', '25MX253', 'G2', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx287@psgtech.ac.in'), '25mx287@psgtech.ac.in', 'Pandian K', '25MX287', 'G2', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx322@psgtech.ac.in'), '25mx322@psgtech.ac.in', 'Pugalenthi M', '25MX322', 'G2', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx336@psgtech.ac.in'), '25mx336@psgtech.ac.in', 'Rajasekar K', '25MX336', 'G2', 'G2-T10', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'::jsonb),
((SELECT id FROM auth.users WHERE email = '25mx397@psgtech.ac.in'), '25mx397@psgtech.ac.in', 'Shankar M', '25MX397', 'G2', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, team_id = EXCLUDED.team_id, roles = EXCLUDED.roles;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check total user count (should be 125: 1 placement rep + 3 dummies + 121 real students)
SELECT 'Total Users' AS metric, COUNT(*) AS count FROM public.users;

-- Check role distribution
SELECT 
  'Role Distribution' AS metric,
  COUNT(*) FILTER (WHERE (roles->>'isPlacementRep')::boolean = true) AS placement_rep_count,
  COUNT(*) FILTER (WHERE (roles->>'isCoordinator')::boolean = true) AS coordinator_count,
  COUNT(*) FILTER (WHERE (roles->>'isTeamLeader')::boolean = true) AS team_leader_count,
  COUNT(*) FILTER (WHERE (roles->>'isStudent')::boolean = true 
                    AND (roles->>'isTeamLeader')::boolean = false 
                    AND (roles->>'isCoordinator')::boolean = false
                    AND (roles->>'isPlacementRep')::boolean = false) AS regular_student_count
FROM public.users;

-- List all placement reps (should be only you)
SELECT email, name, reg_no, team_id 
FROM public.users 
WHERE (roles->>'isPlacementRep')::boolean = true;

-- List all coordinators (should be 4 + 1 dummy)
SELECT email, name, reg_no, team_id 
FROM public.users 
WHERE (roles->>'isCoordinator')::boolean = true
ORDER BY email;

-- List all team leaders (should be 21 + 1 dummy)
SELECT email, name, reg_no, team_id 
FROM public.users 
WHERE (roles->>'isTeamLeader')::boolean = true
ORDER BY team_id;

-- Check dummy accounts
SELECT email, name, reg_no, team_id, roles
FROM public.users
WHERE email LIKE 'dummy.%@psgtech.ac.in';

-- Team-wise count (should be 6 students per team except G2-T07 which has 7 including you)
SELECT team_id, COUNT(*) AS student_count
FROM public.users
WHERE team_id IS NOT NULL
GROUP BY team_id
ORDER BY team_id;


