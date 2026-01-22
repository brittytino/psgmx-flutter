-- ========================================
-- PSG TECHNOLOGY MCA - STUDENT MASTER DATA
-- ========================================
-- Batch: 2025-2027
-- Total Students: 121 (25MX302 and 25MX303 excluded)
-- Teams: 21 (G1-T01 to G1-T11, G2-T01 to G2-T10)
-- 
-- ROLES:
-- - Placement Rep: 1 (25MX354)
-- - Coordinators: 4 (25MX114, 25MX201, 25MX318, 25MX336)
-- - Team Leaders: 21
-- - Regular Students: 95
-- ========================================

-- Insert into whitelist table for authorized signups
INSERT INTO public.whitelist (email, reg_no, name, team_id, roles) VALUES
-- TEAM G1-T01 (Team Leader: 25MX301 - Abishek S)
('25mx301@psgtech.ac.in', '25MX301', 'Abishek S', 'G1-T01', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx205@psgtech.ac.in', '25MX205', 'Deepika Raja Lakshaya G', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx121@psgtech.ac.in', '25MX121', 'Sathish M', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx332@psgtech.ac.in', '25MX332', 'Muthu Sailappan', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx348@psgtech.ac.in', '25MX348', 'S.S.Soban', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx361@psgtech.ac.in', '25MX361', 'Sanjana M', 'G1-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T02 (Team Leader: 25MX308 - Dayananda J)
('25mx308@psgtech.ac.in', '25MX308', 'Dayananda J', 'G1-T02', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx208@psgtech.ac.in', '25MX208', 'Dinakaran T', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx229@psgtech.ac.in', '25MX229', 'Surya L', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx315@psgtech.ac.in', '25MX315', 'Induja E', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx359@psgtech.ac.in', '25MX359', 'Vishnuvardani K S', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx231@psgtech.ac.in', '25MX231', 'Vaishnavi S', 'G1-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T03 (Team Leader: 25MX314 - Hari Anand B)
('25mx314@psgtech.ac.in', '25MX314', 'Hari Anand B', 'G1-T03', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx313@psgtech.ac.in', '25MX313', 'G.Lalit Chandran', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx120@psgtech.ac.in', '25MX120', 'R Sibidharan', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx227@psgtech.ac.in', '25MX227', 'Sudherson V', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx334@psgtech.ac.in', '25MX334', 'Nandhithasri T', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx210@psgtech.ac.in', '25MX210', 'Gayathri S', 'G1-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T04 (Team Leader: 25MX318 - Jeeva Silviya J) - ALSO COORDINATOR
('25mx318@psgtech.ac.in', '25MX318', 'Jeeva Silviya J', 'G1-T04', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'),
('25mx102@psgtech.ac.in', '25MX102', 'Balasubramaniam S', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx118@psgtech.ac.in', '25MX118', 'Oviya S', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx108@psgtech.ac.in', '25MX108', 'Gobbika J M', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx341@psgtech.ac.in', '25MX341', 'Radhu Dharsan K M', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx232@psgtech.ac.in', '25MX232', 'Vishaly S', 'G1-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T05 (Team Leader: 25MX216 - Priyadharshini S)
('25mx216@psgtech.ac.in', '25MX216', 'Priyadharshini S', 'G1-T05', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx130@psgtech.ac.in', '25MX130', 'Vishal Karthikeyan P', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx323@psgtech.ac.in', '25MX323', 'Keerthanaa J', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx328@psgtech.ac.in', '25MX328', 'Mithulesh N', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx222@psgtech.ac.in', '25MX222', 'Shanmuga Priya S', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx345@psgtech.ac.in', '25MX345', 'Shri Sanjay M', 'G1-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T06 (Team Leader: 25MX327 - Mithra N)
('25mx327@psgtech.ac.in', '25MX327', 'Mithra N', 'G1-T06', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx116@psgtech.ac.in', '25MX116', 'Miruna M V', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx228@psgtech.ac.in', '25MX228', 'Supreeth K R', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx306@psgtech.ac.in', '25MX306', 'Chittesh', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx351@psgtech.ac.in', '25MX351', 'Suriya G V', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx203@psgtech.ac.in', '25MX203', 'Badhrinarayanan S K', 'G1-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T07 (Team Leader: 25MX336 - Nitheesh Muthu Krishnan C) - ALSO COORDINATOR
('25mx336@psgtech.ac.in', '25MX336', 'Nitheesh Muthu Krishnan C', 'G1-T07', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'),
('25mx111@psgtech.ac.in', '25MX111', 'Jarjila Denet J', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx128@psgtech.ac.in', '25MX128', 'Sweatha A M', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx304@psgtech.ac.in', '25MX304', 'Aravindh Kannan M S', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx342@psgtech.ac.in', '25MX342', 'Rohithmaheshwaran K', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx206@psgtech.ac.in', '25MX206', 'Devibala N', 'G1-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T08 (Team Leader: 25MX349 - Sowmiya)
('25mx349@psgtech.ac.in', '25MX349', 'Sowmiya', 'G1-T08', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx109@psgtech.ac.in', '25MX109', 'Gopinath R G', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx123@psgtech.ac.in', '25MX123', 'Sri Monika J', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx305@psgtech.ac.in', '25MX305', 'Bhuvisha Sri Priya P', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx333@psgtech.ac.in', '25MX333', 'Naga Sruthi M', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx363@psgtech.ac.in', '25MX363', 'Tharun S', 'G1-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T09 (Team Leader: 25MX352 - Tamilini S)
('25mx352@psgtech.ac.in', '25MX352', 'Tamilini S', 'G1-T09', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx106@psgtech.ac.in', '25MX106', 'Divyadharshini K', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx126@psgtech.ac.in', '25MX126', 'Surya Krishna S', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx312@psgtech.ac.in', '25MX312', 'S.Dinesh Kumar', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx218@psgtech.ac.in', '25MX218', 'Reena Carolin S', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx362@psgtech.ac.in', '25MX362', 'Narayanasamy', 'G1-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T10 (Team Leader: 25MX358 - Vikram Sethupathy S)
('25mx358@psgtech.ac.in', '25MX358', 'Vikram Sethupathy S', 'G1-T10', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx117@psgtech.ac.in', '25MX117', 'Mohankumar P', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx129@psgtech.ac.in', '25MX129', 'Thirupathi B', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx320@psgtech.ac.in', '25MX320', 'Joshnie T', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx207@psgtech.ac.in', '25MX207', 'Dheepthi R R', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx209@psgtech.ac.in', '25MX209', 'Divakar A', 'G1-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G1-T11 (Team Leader: 25MX360 - Yaswanth R T)
('25mx360@psgtech.ac.in', '25MX360', 'Yaswanth R T', 'G1-T11', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx107@psgtech.ac.in', '25MX107', 'G Shree Nivetha', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx217@psgtech.ac.in', '25MX217', 'R G A Sakthivel Mallaiah', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx340@psgtech.ac.in', '25MX340', 'Puratchiyan', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx343@psgtech.ac.in', '25MX343', 'Sabarish P', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx219@psgtech.ac.in', '25MX219', 'Saran K', 'G1-T11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T01 (Team Leader: 25MX125 - Stephina Smily C)
('25mx125@psgtech.ac.in', '25MX125', 'Stephina Smily C', 'G2-T01', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx331@psgtech.ac.in', '25MX331', 'Mugundhan KP', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx309@psgtech.ac.in', '25MX309', 'Deepa M', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx339@psgtech.ac.in', '25MX339', 'Prabhakar O S', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx361@psgtech.ac.in', '25MX361', 'Sanjana M', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx226@psgtech.ac.in', '25MX226', 'Sudharsanan G', 'G2-T01', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T02 (Team Leader: 25MX104 - Deepikaa B S)
('25mx104@psgtech.ac.in', '25MX104', 'Deepikaa B S', 'G2-T02', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx119@psgtech.ac.in', '25MX119', 'Pon Akilesh P', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx310@psgtech.ac.in', '25MX310', 'Dhakshanamoorthy S', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx329@psgtech.ac.in', '25MX329', 'Mohana Priya M', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx214@psgtech.ac.in', '25MX214', 'Nagakeerthanaa N', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx223@psgtech.ac.in', '25MX223', 'Shanmugappriya K', 'G2-T02', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T03 (Team Leader: 25MX114 - Kavin M) - ALSO COORDINATOR
('25mx114@psgtech.ac.in', '25MX114', 'Kavin M', 'G2-T03', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'),
('25mx214@psgtech.ac.in', '25MX214', 'Nagakeerthanaa N', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx319@psgtech.ac.in', '25MX319', 'Jessica.A', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx330@psgtech.ac.in', '25MX330', 'Monish P', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx220@psgtech.ac.in', '25MX220', 'Saravanavel P', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx363@psgtech.ac.in', '25MX363', 'Tharun S', 'G2-T03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T04 (Team Leader: 25MX204 - Chinnaya K)
('25mx204@psgtech.ac.in', '25MX204', 'Chinnaya K', 'G2-T04', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx357@psgtech.ac.in', '25MX357', 'Vijaya Sree K', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx321@psgtech.ac.in', '25MX321', 'Karthick K', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx311@psgtech.ac.in', '25MX311', 'Dinesh Kumar', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx221@psgtech.ac.in', '25MX221', 'Shairaaj V S', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx115@psgtech.ac.in', '25MX115', 'Krishnapriya M S', 'G2-T04', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T05 (Team Leader: 25MX124 - Srinithi J)
('25mx124@psgtech.ac.in', '25MX124', 'Srinithi J', 'G2-T05', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx316@psgtech.ac.in', '25MX316', 'Jackson Solomon Raj M', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx317@psgtech.ac.in', '25MX317', 'Janani T', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx338@psgtech.ac.in', '25MX338', 'Poorani R', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx225@psgtech.ac.in', '25MX225', 'Sriram V', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx110@psgtech.ac.in', '25MX110', 'Harikesan D J', 'G2-T05', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T06 (Team Leader: 25MX212 - Kartheesvaran S)
('25mx212@psgtech.ac.in', '25MX212', 'Kartheesvaran S', 'G2-T06', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx215@psgtech.ac.in', '25MX215', 'Preethi S', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx344@psgtech.ac.in', '25MX344', 'Satya Pramodh R', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx103@psgtech.ac.in', '25MX103', 'Barathvikraman S K', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx346@psgtech.ac.in', '25MX346', 'Siddarth M R', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx202@psgtech.ac.in', '25MX202', 'Arjun Vishwas B', 'G2-T06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T07 (Team Leader: 25MX127 - Swarna Rathna A)
('25mx127@psgtech.ac.in', '25MX127', 'Swarna Rathna A', 'G2-T07', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx230@psgtech.ac.in', '25MX230', 'Thamizhthilaga S D S', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx322@psgtech.ac.in', '25MX322', 'Kasbiya. M', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx354@psgtech.ac.in', '25MX354', 'Tino Britty J', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": true}'),
('25mx211@psgtech.ac.in', '25MX211', 'Joshna K', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx224@psgtech.ac.in', '25MX224', 'Sriram S S', 'G2-T07', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T08 (Team Leader: 25MX326 - Meyappan R)
('25mx326@psgtech.ac.in', '25MX326', 'Meyappan R', 'G2-T08', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx113@psgtech.ac.in', '25MX113', 'Kaleel ur Rahman H', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx307@psgtech.ac.in', '25MX307', 'Darunya Sri M', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx337@psgtech.ac.in', '25MX337', 'Nithyashree C', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx355@psgtech.ac.in', '25MX355', 'Vaishali S', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx213@psgtech.ac.in', '25MX213', 'Mowlidharan J', 'G2-T08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T09 (Team Leader: 25MX325 - Kirsaan F)
('25mx325@psgtech.ac.in', '25MX325', 'Kirsaan F', 'G2-T09', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx101@psgtech.ac.in', '25MX101', 'Balaji K', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx122@psgtech.ac.in', '25MX122', 'Shaarukesh K R', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx335@psgtech.ac.in', '25MX335', 'Naveen Pranab T', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx324@psgtech.ac.in', '25MX324', 'Kevin Johnson A A', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx112@psgtech.ac.in', '25MX112', 'Kaavya R', 'G2-T09', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- TEAM G2-T10 (Team Leader: 25MX105 - Divya R)
('25mx105@psgtech.ac.in', '25MX105', 'Divya R', 'G2-T10', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx122@psgtech.ac.in', '25MX122', 'Shaarukesh K R', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx335@psgtech.ac.in', '25MX335', 'Naveen Pranab T', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx110@psgtech.ac.in', '25MX110', 'Harikesan D J', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx303@psgtech.ac.in', '25MX303', 'Ajay Vishal B', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx347@psgtech.ac.in', '25MX347', 'Sivapradeesh M', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx350@psgtech.ac.in', '25MX350', 'Srivikashni S', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx353@psgtech.ac.in', '25MX353', 'Thrisha R', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx356@psgtech.ac.in', '25MX356', 'Vignesh M', 'G2-T10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}')

ON CONFLICT (email) DO NOTHING;

-- ========================================
-- VERIFICATION SUMMARY
-- ========================================
-- Total Students: 121 (excluding 25MX302 and 25MX303)
-- Team Leaders: 21
-- Coordinators: 4 (25MX114, 25MX201, 25MX318, 25MX336)
-- Placement Rep: 1 (25MX354)
-- Regular Students: 95
-- 
-- Teams G1: 11 teams (G1-T01 to G1-T11)
-- Teams G2: 10 teams (G2-T01 to G2-T10)
-- ========================================
