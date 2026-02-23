-- ========================================
-- PSG MX PLACEMENT APP - SEED DATA
-- ========================================
-- File 5 of 5: Initial Data
-- 
-- 1. Whitelist (Students)
-- 2. App Config (Default Settings)
-- 
-- Run this AFTER 04_triggers.sql
-- ========================================

-- Insert all 123 students into whitelist
INSERT INTO public.whitelist (email, name, reg_no, batch, team_id, dob, leetcode_username, roles) VALUES
-- ========================================
-- BATCH G1: Students 101-132 and 201-232
-- ========================================
('25mx101@psgtech.ac.in', 'BALAJI K', '25MX101', 'G1', 'T20', '2005-10-22', 'V8HjERH7Hj', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx102@psgtech.ac.in', 'Balasubramaniam S', '25MX102', 'G1', 'T04', '2003-07-05', 'Bala_subramaniam', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx103@psgtech.ac.in', 'BarathVikraman S K', '25MX103', 'G1', 'T17', '2002-06-26', 'barathvikramansk', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx104@psgtech.ac.in', 'DEEPIKAA B S', '25MX104', 'G1', 'T13', '2004-11-21', 'DeepikaaBathirappan', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx105@psgtech.ac.in', 'Divya R', '25MX105', 'G1', 'T21', '2004-03-11', 'Divya_ravi11', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx106@psgtech.ac.in', 'Divyadharshini K', '25MX106', 'G1', 'T09', '2004-04-28', 'DivyadharshiniCSD', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx107@psgtech.ac.in', 'Shree Nivetha', '25MX107', 'G1', 'T11', NULL, 'Shree_Nivetha', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx108@psgtech.ac.in', 'Gobbika J M', '25MX108', 'G1', 'T04', '2004-12-17', 'Gobbika_', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx109@psgtech.ac.in', 'GOPINATH R G', '25MX109', 'G1', 'T08', '2005-01-24', 'GOPINATH_R_G', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx110@psgtech.ac.in', 'Harikesan D J', '25MX110', 'G1', 'T20', NULL, 'Harikesan', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx111@psgtech.ac.in', 'Jarjila Denet J', '25MX111', 'G1', 'T07', '2004-05-09', 'jarjiladenet', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx112@psgtech.ac.in', 'Kaavya R', '25MX112', 'G1', 'T21', '2002-09-17', 'kaavya17', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx113@psgtech.ac.in', 'Kaleel ur rahman H', '25MX113', 'G1', 'T19', '2005-04-20', 'Kaleel-ur-rahman', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx114@psgtech.ac.in', 'Kavin M', '25MX114', 'G1', 'T14', '2002-06-26', 'kavinsde', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'),
('25mx115@psgtech.ac.in', 'Krishna Priya M S', '25MX115', 'G1', 'T15', '2004-08-29', 'krishna_priya29_', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx116@psgtech.ac.in', 'Miruna M V', '25MX116', 'G1', 'T06', '2005-06-13', 'mirunavjn', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx117@psgtech.ac.in', 'Mohankumar P', '25MX117', 'G1', 'T10', NULL, 'mohankumarpmj', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx118@psgtech.ac.in', 'OVIYA S', '25MX118', 'G1', 'T04', '2004-10-04', 's_oviya', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx119@psgtech.ac.in', 'Pon Akilesh', '25MX119', 'G1', 'T13', '2003-11-03', 'RemarkableCry10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx120@psgtech.ac.in', 'R Sibidharan', '25MX120', 'G1', 'T03', '2004-09-27', 'Sibidharan27', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx121@psgtech.ac.in', 'Sathish M', '25MX121', 'G1', 'T01', '2005-05-21', 'SathishM29', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx122@psgtech.ac.in', 'K R Shaarukesh', '25MX122', 'G1', 'T21', '2004-06-12', 'shaarukesh12', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx123@psgtech.ac.in', 'Sri Monika J', '25MX123', 'G1', 'T08', '2005-04-20', 'srimonikaa', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx124@psgtech.ac.in', 'Srinithi J', '25MX124', 'G1', 'T16', '2005-03-09', 'Srinithi_J', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx125@psgtech.ac.in', 'STEPHINA SMILY C', '25MX125', 'G1', 'T12', '2004-08-19', '477j3te85r', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx126@psgtech.ac.in', 'Surya Krishna S', '25MX126', 'G1', 'T09', '2004-12-21', 's1P8DF0azg', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx127@psgtech.ac.in', 'Swarna Rathna A', '25MX127', 'G1', 'T18', '2004-09-15', 'SwarnaRathnaAngusamy', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx128@psgtech.ac.in', 'Sweatha A M', '25MX128', 'G1', 'T07', '2002-11-17', 'sweathaangappan', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx129@psgtech.ac.in', 'Thirupathi B', '25MX129', 'G1', 'T10', '2003-09-02', 'thiru_2903', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx130@psgtech.ac.in', 'Vishal Karthikeyan P', '25MX130', 'G1', 'T05', '2003-06-12', 'Vishal_Karthikeyan_P', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx201@psgtech.ac.in', 'Anuvarshini', '25MX201', 'G1', 'T17', NULL, 'Anu_varshini_11', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'),
('25mx202@psgtech.ac.in', 'Arjun Vishwas B', '25MX202', 'G1', 'T19', '2004-07-15', 'arjun_lee', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx203@psgtech.ac.in', 'Badhrinarayanan S K', '25MX203', 'G1', 'T06', '2004-04-11', 'Badhri660', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx204@psgtech.ac.in', 'Chinnaya K', '25MX204', 'G1', 'T15', '2004-09-17', 'CHINNAYA_K', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx205@psgtech.ac.in', 'G Deepika Raja Lakshaya', '25MX205', 'G1', 'T01', '2004-08-22', 'Deepika_200-4', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx206@psgtech.ac.in', 'Devibala N', '25MX206', 'G1', 'T07', '2003-01-22', 'Devibala_N', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx207@psgtech.ac.in', 'Dheepthi R R', '25MX207', 'G1', 'T10', '2004-10-25', 'Dheepthi_ramakrishnan', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx208@psgtech.ac.in', 'Dinakaran T', '25MX208', 'G1', 'T02', NULL, 'Dhina_08', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx209@psgtech.ac.in', 'Divakar', '25MX209', 'G1', 'T11', '2005-03-02', 'divakar-ui', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx210@psgtech.ac.in', 'Gayathri', '25MX210', 'G1', 'T03', NULL, 'Abc123abx', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx211@psgtech.ac.in', 'Joshna K', '25MX211', 'G1', 'T18', NULL, 'Joshna_1304', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx212@psgtech.ac.in', 'Kartheesvaran S', '25MX212', 'G1', 'T17', '2003-07-16', 'Kartheesvaran', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx213@psgtech.ac.in', 'Mowlidharan', '25MX213', 'G1', 'T02', NULL, NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx214@psgtech.ac.in', 'Nagakeerthanaa N', '25MX214', 'G1', 'T14', NULL, 'Nagakeerthanaa2004', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx215@psgtech.ac.in', 'Preethi S', '25MX215', 'G1', 'T17', '2005-07-13', 'preethi_somu', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx216@psgtech.ac.in', 'Priyadharshini S', '25MX216', 'G1', 'T05', '2004-09-15', 'Priyadharshini-Kumar', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx217@psgtech.ac.in', 'RGA Sakthivel Mallaiah', '25MX217', 'G1', 'T11', '2004-06-23', 'Mallaiah23', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx218@psgtech.ac.in', 'Reena Carolin S', '25MX218', 'G1', 'T09', '2003-03-01', 'Reena_carolin', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx219@psgtech.ac.in', 'Saran K', '25MX219', 'G1', 'T16', '2004-05-17', 'Saran_111', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx220@psgtech.ac.in', 'Saravanavel P', '25MX220', 'G1', 'T14', '2004-08-06', 'Sachine800', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx221@psgtech.ac.in', 'Shairaaj V S', '25MX221', 'G1', 'T15', '2005-04-08', 'Shairaajvs', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx222@psgtech.ac.in', 'Shanmuga Priya S', '25MX222', 'G1', 'T05', '2005-05-17', 'shanmugapriya17', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx223@psgtech.ac.in', 'Shanmugappriya K', '25MX223', 'G1', 'T13', '2004-12-07', 'Shanmugappriya_0712', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx224@psgtech.ac.in', 'Sriram S S', '25MX224', 'G1', 'T18', '2003-03-20', 'Sriram_203', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx225@psgtech.ac.in', 'Sriram V', '25MX225', 'G1', 'T16', '2004-02-18', 'sriramvardaraj16', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx226@psgtech.ac.in', 'Sudharsanan G', '25MX226', 'G1', 'T12', '2005-02-21', '_sudhar_sanan_', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx227@psgtech.ac.in', 'Sudherson V', '25MX227', 'G1', 'T03', '2002-09-24', '3z9WJQnMWw', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx228@psgtech.ac.in', 'Supreeth K R', '25MX228', 'G1', 'T06', NULL, 'supreeth_10', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx229@psgtech.ac.in', 'Surya L', '25MX229', 'G1', 'T02', '2004-10-30', 'uWbraHi4Uq', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx230@psgtech.ac.in', 'Thamizhthilaga S D S', '25MX230', 'G1', 'T18', '2003-07-18', 'thamizh_03', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx231@psgtech.ac.in', 'Vaishnavi S', '25MX231', 'G1', 'T01', '2005-08-27', 'vaishnavis2708', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx232@psgtech.ac.in', 'Vishaly S', '25MX232', 'G1', 'T04', '2005-04-12', 'Vishaly_Senthilkumar', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),

-- ========================================
-- BATCH G2: Students 301-363
-- ========================================
('25mx301@psgtech.ac.in', 'Abishek S', '25MX301', 'G2', 'T01', '2004-06-24', '_coder_abi_', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx304@psgtech.ac.in', 'Aravindh Kannan M S', '25MX304', 'G2', 'T07', NULL, 'aravindh245', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx305@psgtech.ac.in', 'Bhuvisha Sri Priya P', '25MX305', 'G2', 'T08', '2004-11-28', 'bhuvishasripriya', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx306@psgtech.ac.in', 'Chittesh', '25MX306', 'G2', 'T06', NULL, 'chittesh', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx307@psgtech.ac.in', 'Darunya Sri M', '25MX307', 'G2', 'T19', NULL, 'Darunya_Sri', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx308@psgtech.ac.in', 'Dayananda J', '25MX308', 'G2', 'T02', NULL, 'DayanandaJ', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx309@psgtech.ac.in', 'Deepa M', '25MX309', 'G2', 'T12', '2004-01-18', 'PPuHO8lVwI', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx310@psgtech.ac.in', 'Dhakshanamoorthy S', '25MX310', 'G2', 'T13', '2004-04-28', 'Dhakshanamoorthy', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx311@psgtech.ac.in', 'Dinesh Kumar', '25MX311', 'G2', 'T14', '2004-08-15', 'Devansh_Kumar', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx312@psgtech.ac.in', 'Dinesh Kumar S', '25MX312', 'G2', 'T09', NULL, 'Dinesh_rrr', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx313@psgtech.ac.in', 'G Lalit Chandran', '25MX313', 'G2', 'T03', '2004-04-20', 'lalitchandran2004', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx314@psgtech.ac.in', 'Hari Anand B', '25MX314', 'G2', 'T03', '2003-05-22', 'HariBalaji', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx315@psgtech.ac.in', 'Induja E', '25MX315', 'G2', 'T02', NULL, 'indujaee', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx316@psgtech.ac.in', 'Jackson Solomon Raj M', '25MX316', 'G2', 'T16', '2003-08-07', 'naanthandaleo', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx317@psgtech.ac.in', 'Janani T G', '25MX317', 'G2', 'T16', NULL, 'u00mGgJrMX', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx318@psgtech.ac.in', 'Jeeva Silviya J', '25MX318', 'G2', 'T04', '2004-05-20', 'jeevasilviya', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'),
('25mx319@psgtech.ac.in', 'Jessica A', '25MX319', 'G2', 'T14', '2004-12-09', 'Jessica96', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx320@psgtech.ac.in', 'Joshnie T', '25MX320', 'G2', 'T10', '2004-07-04', 'joshnie47', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx321@psgtech.ac.in', 'Karthick K', '25MX321', 'G2', 'T15', '2004-10-05', 'Karthick0531', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx322@psgtech.ac.in', 'Kasbiya M', '25MX322', 'G2', 'T18', '2005-04-04', 'kasbiya_l', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx323@psgtech.ac.in', 'Keerthanaa J', '25MX323', 'G2', 'T05', '2005-05-29', 'Kize_Bright', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx324@psgtech.ac.in', 'Kevin Johnson A A', '25MX324', 'G2', 'T21', NULL, 'Kevin_0104', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx325@psgtech.ac.in', 'Kirsaan F', '25MX325', 'G2', 'T20', '2004-08-27', 'ClyHz34SHz', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx326@psgtech.ac.in', 'Meyappan R', '25MX326', 'G2', 'T19', NULL, 'Meyappan_R', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx327@psgtech.ac.in', 'Mithra N', '25MX327', 'G2', 'T06', '2004-09-13', 'im_mithra', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx328@psgtech.ac.in', 'Mithulesh N', '25MX328', 'G2', 'T05', NULL, 'Mithulesh_N', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx329@psgtech.ac.in', 'Mohana Priya M', '25MX329', 'G2', 'T13', '2004-07-19', 'mohanapriya19', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx330@psgtech.ac.in', 'Monish P', '25MX330', 'G2', 'T14', NULL, '9AIYYQsbfu', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx331@psgtech.ac.in', 'Mugundhan K P', '25MX331', 'G2', 'T12', NULL, 'Mukunth06', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx332@psgtech.ac.in', 'Muthu Sailappan', '25MX332', 'G2', 'T01', NULL, 'muthusailappan', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx333@psgtech.ac.in', 'Naga Sruthi M', '25MX333', 'G2', 'T08', '2004-08-20', 'Nagasruthimanivannan', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx334@psgtech.ac.in', 'Nandhithasri', '25MX334', 'G2', 'T03', NULL, 'nandhithasri315', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx335@psgtech.ac.in', 'Naveen Pranab T', '25MX335', 'G2', 'T21', NULL, 'Naveenpranab', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx336@psgtech.ac.in', 'Nitheesh Muthu Krishnan C', '25MX336', 'G2', 'T07', '2005-07-05', 'nitheeshmk5', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": true, "isPlacementRep": false}'),
('25mx337@psgtech.ac.in', 'Nithyashree C', '25MX337', 'G2', 'T19', NULL, 'Nithyashree_C', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx338@psgtech.ac.in', 'Poorani R', '25MX338', 'G2', 'T16', '2005-03-24', 'PooraniMohan24', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx339@psgtech.ac.in', 'Prabhakar O S', '25MX339', 'G2', 'T12', '2004-11-08', 'prabha6769', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx340@psgtech.ac.in', 'Puratchiyan R', '25MX340', 'G2', 'T11', '2004-10-29', 'Puratchiyan', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx341@psgtech.ac.in', 'Radhu Dharsan K M', '25MX341', 'G2', 'T04', '2005-01-06', 'fkenq9S0hw', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx342@psgtech.ac.in', 'Rohithmaheshwaran K', '25MX342', 'G2', 'T07', '2005-05-21', 'Mahesh__rdr', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx343@psgtech.ac.in', 'Sabarish P', '25MX343', 'G2', 'T20', NULL, 'SABARISH_P', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx344@psgtech.ac.in', 'Satya Pramodh R', '25MX344', 'G2', 'T17', NULL, 'SATYA_PRAMODH', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx345@psgtech.ac.in', 'Shri Sanjay M', '25MX345', 'G2', 'T05', '2005-07-26', 'M_Shri_sanjay26', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx346@psgtech.ac.in', 'Siddarth M R', '25MX346', 'G2', 'T17', NULL, 'sidddarthvasi2604', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx347@psgtech.ac.in', 'Sivapradeesh M', '25MX347', 'G2', 'T11', NULL, 'Sivapradeesh_M', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx348@psgtech.ac.in', 'S S Soban', '25MX348', 'G2', 'T01', '2001-12-21', 'sobanss2001', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx349@psgtech.ac.in', 'Sowmiya', '25MX349', 'G2', 'T08', '2003-03-03', 'sowmiya_3', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx350@psgtech.ac.in', 'Srivikashni S', '25MX350', 'G2', 'T09', '2004-09-06', 'SRIVIKASHNI', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx351@psgtech.ac.in', 'Suriya C S', '25MX351', 'G2', 'T06', NULL, 'suriyaCSD', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx352@psgtech.ac.in', 'Tamilini S', '25MX352', 'G2', 'T09', '2004-10-29', 'oi8UIWVPvT', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx353@psgtech.ac.in', 'Thrisha R', '25MX353', 'G2', 'T10', NULL, 'Thrishaa123', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx354@psgtech.ac.in', 'Tino Britty J', '25MX354', 'G2', 'T18', '2004-07-08', 'tinobritty', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": true}'),
('25mx355@psgtech.ac.in', 'Vaishali S', '25MX355', 'G2', 'T20', '2005-01-02', '__Vaishu_7__', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx356@psgtech.ac.in', 'Vignesh M', '25MX356', 'G2', 'T08', '2004-01-31', 'Vix-codes', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx357@psgtech.ac.in', 'Vijaya Sree K', '25MX357', 'G2', 'T15', NULL, '12_zoya', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx358@psgtech.ac.in', 'Vikram Sethupathy S', '25MX358', 'G2', 'T10', '2004-11-17', 'lemonspice17', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx359@psgtech.ac.in', 'Vishnuvardani K S', '25MX359', 'G2', 'T02', '2004-12-24', 'vishnuvardani_2004', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx360@psgtech.ac.in', 'Yaswanth R T', '25MX360', 'G2', 'T11', '2004-07-01', 'yash_3237', '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
('25mx361@psgtech.ac.in', 'Sanjana M', '25MX361', 'G2', 'T12', '2004-04-29', 'sanjana_m29', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx362@psgtech.ac.in', 'Narayanasamy', '25MX362', 'G2', 'T13', NULL, 'Narayana_1080', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
('25mx363@psgtech.ac.in', 'Tharun S', '25MX363', 'G2', 'T14', '2003-04-12', 'Tectonic_', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}')
ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    reg_no = EXCLUDED.reg_no,
    batch = EXCLUDED.batch,
    team_id = EXCLUDED.team_id,
    dob = EXCLUDED.dob,
    leetcode_username = EXCLUDED.leetcode_username,
    roles = EXCLUDED.roles;

-- ========================================
-- SYNC TO USERS TABLE (for login)
-- ========================================
-- Note: This creates users with generated UUIDs
-- Real users are created when they sign up via auth

-- Insert all whitelist entries into users table
INSERT INTO public.users (id, email, reg_no, name, team_id, batch, roles, dob, leetcode_username)
SELECT 
    gen_random_uuid(),  -- Generate UUID since not auth.users yet
    w.email,
    w.reg_no,
    w.name,
    w.team_id,
    COALESCE(w.batch, 'G1'),
    COALESCE(w.roles, '{"isStudent": true}'::jsonb),
    w.dob,
    w.leetcode_username
FROM whitelist w
ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    reg_no = EXCLUDED.reg_no,
    team_id = EXCLUDED.team_id,
    batch = EXCLUDED.batch,
    roles = EXCLUDED.roles,
    dob = EXCLUDED.dob,
    leetcode_username = EXCLUDED.leetcode_username;

-- ========================================
-- INSERT LEETCODE STATS
-- ========================================
INSERT INTO public.leetcode_stats (username, total_solved, easy_solved, medium_solved, hard_solved, ranking)
SELECT 
    leetcode_username,
    0, 0, 0, 0, 0
FROM public.whitelist
WHERE leetcode_username IS NOT NULL AND leetcode_username != ''
ON CONFLICT (username) DO NOTHING;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    whitelist_count INT;
    users_count INT;
    leetcode_count INT;
-- ========================================
-- 2. APP CONFIGURATION
-- ========================================

INSERT INTO app_config (
    min_required_version,
    latest_version,
    force_update,
    update_message,
    github_release_url,
    emergency_block
) VALUES (
    '1.0.0',
    '1.2.0',
    false,
    'A new version of PSGMX is available! Update now to get the latest features and improvements.',
    'https://github.com/psgmx/psgmx-flutter/releases/latest',
    false
) ON CONFLICT DO NOTHING;

-- ========================================
-- VERIFICATION & FINISH
-- ========================================
DO $$
DECLARE
    whitelist_count INT;
    users_count INT;
    leetcode_count INT;
BEGIN
    SELECT COUNT(*) INTO whitelist_count FROM public.whitelist;
    SELECT COUNT(*) INTO users_count FROM public.users;
    SELECT COUNT(*) INTO leetcode_count FROM public.leetcode_stats;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ SEED DATA COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Whitelist entries: %', whitelist_count;
    RAISE NOTICE 'Users created: %', users_count;
    RAISE NOTICE 'App Config: initialized';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'You have successfully set up the PSGMX database!';
    RAISE NOTICE '========================================';
END $$;
