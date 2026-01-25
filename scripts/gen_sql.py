
import re

# 1. READ EXISTING SEED
# I'll rely on the regex pattern to extract existing tuples
# INSERT INTO public.whitelist (email, name, reg_no, batch, team_id, roles) VALUES
# ('...', '...', '...', '...', '...', '...'),
existing_data = {} # reg_no -> {email, name, batch, team_id, roles}

try:
    with open('../complete_user_seed.sql', 'r', encoding='utf-8') as f:
        content = f.read()
        # Regex to find values tuple.
        # ('email', 'name', 'reg_no', 'batch', 'team_id', 'roles')
        # Note: roles is a json string like '{"..."}'
        pattern = re.compile(r"\('([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'(\{.*?\})'\)")
        matches = pattern.findall(content)
        for m in matches:
            email, name, reg_no, batch, team_id, roles = m
            # Normalize reg_no
            reg_no_key = reg_no.upper().strip()
            existing_data[reg_no_key] = {
                'email': email,
                'name': name,
                'batch': batch,
                'team_id': team_id,
                'roles': roles
            }
except Exception as e:
    print(f"Error reading seed: {e}")

# 2. RAW NEW DATA
raw_data = """
25MX101 | BALAJI K | G1 | 22/10/2005 | V8HjERH7Hj
25MX102 | Balasubramaniam S | G1 | 05/07/2003 | Bala_subramaniam
25MX103 | BarathVikraman S K | G1 | 26/06/2002 | barathvikramansk
25MX104 | DEEPIKAA B S | G1 | 21/11/2004 | DeepikaaBathirappan
25MX105 | Divya R | G1 | 11/03/2004 | Divya_ravi11
25MX106 | Divyadharshini K | G1 | 28/04/2004 | DivyadharshiniCSD
25MX107 | Shree Nivetha | G1 | NULL | Shree_Nivetha
25MX108 | Gobbika J M | G1 | 17/12/2004 | Gobbika_
25MX109 | GOPINATH R G | G1 | 24/01/2005 | GOPINATH_R_G
25MX110 | Harikesan D J | G1 | NULL | Harikesan
25MX111 | Jarjila Denet J | G1 | 09/05/2004 | jarjiladenet
25MX112 | Kaavya R | G1 | 17/09/2002 | kaavya17
25MX113 | Kaleel ur rahman H | G1 | 20/04/2005 | Kaleel-ur-rahman
25MX114 | Kavin M | G1 | 26/06/2002 | kavinsde
25MX115 | Krishna Priya M S | G1 | 29/08/2004 | krishna_priya29_
25MX116 | Miruna M V | G1 | 13/06/2005 | mirunavjn
25MX117 | Mohankumar P | G1 | NULL | mohankumarpmj
25MX118 | OVIYA S | G1 | 04/10/2004 | s_oviya
25MX119 | Pon Akilesh | G1 | 03/11/2003 | RemarkableCry10
25MX120 | R Sibidharan | G1 | 27/09/2004 | Sibidharan27
25MX121 | Sathish M | G1 | 21/05/2005 | SathishM29
25MX122 | K R Shaarukesh | G1 | 12/06/2004 | shaarukesh12
25MX123 | Sri Monika J | G1 | 20/04/2005 | srimonikaa
25MX124 | Srinithi J | G1 | 09/03/2005 | Srinithi_J
25MX125 | STEPHINA SMILY C | G1 | 19/08/2004 | 477j3te85r
25MX126 | Surya Krishna S | G1 | 21/12/2004 | s1P8DF0azg
25MX127 | Swarna Rathna A | G1 | 15/09/2004 | SwarnaRathnaAngusamy
25MX128 | Sweatha A M | G1 | 17/11/2002 | sweathaangappan
25MX129 | Thirupathi B | G1 | 02/09/2003 | thiru_2903
25MX130 | Vishal Karthikeyan P | G1 | 12/06/2003 | Vishal_Karthikeyan_P
25MX201 | Anuvarshini | G1 | NULL | Anu_varshini_11
25MX202 | Arjun Vishwas B | G1 | 15/07/2004 | arjun_lee
25MX203 | Badhrinarayanan S K | G1 | 11/04/2004 | Badhri660
25MX204 | Chinnaya K | G1 | 17/09/2004 | CHINNAYA_K
25MX205 | G Deepika Raja Lakshaya | G1 | 22/08/2004 | Deepika_200-4
25MX206 | Devibala N | G1 | 22/01/2003 | Devibala_N
25MX207 | Dheepthi R R | G1 | 25/10/2004 | Dheepthi_ramakrishnan
25MX208 | Dinakaran T | G1 | NULL | Dhina_08
25MX209 | Divakar | G1 | 02/03/2005 | divakar-ui
25MX210 | Gayathri | G1 | NULL | Abc123abx
25MX211 | Joshna K | G1 | NULL | Joshna_1304
25MX212 | Kartheesvaran S | G1 | 16/07/2003 | Kartheesvaran
25MX213 | NULL | G1 | NULL | NULL
25MX214 | Nagakeerthanaa N | G1 | NULL | Nagakeerthanaa2004
25MX215 | Preethi S | G1 | 13/07/2005 | preethi_somu
25MX216 | Priyadharshini S | G1 | 15/09/2004 | Priyadharshini-Kumar
25MX217 | RGA Sakthivel Mallaiah | G1 | 23/06/2004 | Mallaiah23
25MX218 | Reena Carolin S | G1 | 01/03/2003 | Reena_carolin
25MX219 | Saran K | G1 | 17/05/2004 | Saran_111
25MX220 | Saravanavel P | G1 | 06/08/2004 | Sachine800
25MX221 | Shairaaj V S | G1 | 08/04/2005 | Shairaajvs
25MX222 | Shanmuga Priya S | G1 | 17/05/2005 | shanmugapriya17
25MX223 | Shanmugappriya K | G1 | 07/12/2004 | Shanmugappriya_0712
25MX224 | Sriram S S | G1 | 20/03/2003 | Sriram_203
25MX225 | Sriram V | G1 | 18/02/2004 | sriramvardaraj16
25MX226 | Sudharsanan G | G1 | 21/02/2005 | _sudhar_sanan_
25MX227 | Sudherson V | G1 | 24/09/2002 | 3z9WJQnMWw
25MX228 | Supreeth K R | G1 | NULL | supreeth_10
25MX229 | Surya L | G1 | 30/10/2004 | uWbraHi4Uq
25MX230 | Thamizhthilaga S D S | G1 | 18/07/2003 | thamizh_03
25MX231 | Vaishnavi S | G1 | 27/08/2005 | vaishnavis2708
25MX232 | Vishaly S | G1 | 12/04/2005 | Vishaly_Senthilkumar
25MX301 | Abishek S | G2 | 24/06/2004 | _coder_abi_
25MX304 | Aravindh Kannan M S | G2 | NULL | aravindh245
25MX305 | Bhuvisha Sri Priya P | G2 | 28/11/2004 | bhuvishasripriya
25MX306 | Chittesh | G2 | NULL | chittesh
25MX307 | Darunya Sri M | G2 | NULL | Darunya_Sri
25MX308 | Dayananda J | G2 | NULL | DayanandaJ
25MX309 | Deepa M | G2 | 18/01/2004 | PPuHO8lVwI
25MX310 | Dhakshanamoorthy S | G2 | 28/04/2004 | Dhakshanamoorthy
25MX312 | Dinesh | G2 | NULL | Dinesh_rrr
25MX313 | G Lalit Chandran | G2 | 20/04/2004 | lalitchandran2004
25MX314 | Hari Anand B | G2 | 22/05/2003 | HariBalaji
25MX315 | Induja E | G2 | NULL | indujaee
25MX316 | Jackson Solomon Raj M | G2 | 07/08/2003 | naanthandaleo
25MX317 | Janani T G | G2 | NULL | u00mGgJrMX
25MX318 | Jeeva Silviya J | G2 | 20/05/2004 | jeevasilviya
25MX319 | Jessica A | G2 | 09/12/2004 | Jessica96
25MX320 | Joshnie T | G2 | 04/07/2004 | joshnie47
25MX321 | Karthick K | G2 | 05/10/2004 | Karthick0531
25MX322 | Kasbiya M | G2 | 04/04/2005 | kasbiya_l
25MX323 | Keerthanaa J | G2 | 29/05/2005 | Kize_Bright
25MX324 | Kevin Johnson A A | G2 | NULL | Kevin_0104
25MX325 | Kirsaan F | G2 | 27/08/2004 | ClyHz34SHz
25MX326 | Meyappan R | G2 | NULL | Meyappan_R
25MX327 | Mithra N | G2 | 13/09/2004 | im_mithra
25MX328 | Mithulesh N | G2 | NULL | Mithulesh_N
25MX329 | Mohana Priya M | G2 | 19/07/2004 | mohanapriya19
25MX330 | Monish P | G2 | NULL | 9AIYYQsbfu
25MX331 | Mugundhan K P | G2 | NULL | Mukunth06
25MX332 | Muthu Sailappan | G2 | NULL | muthusailappan
25MX333 | Naga Sruthi M | G2 | 20/08/2004 | Nagasruthimanivannan
25MX334 | Nandhithasri | G2 | NULL | nandhithasri315
25MX335 | Naveen Pranab T | G2 | NULL | Naveenpranab
25MX336 | Nitheesh Muthu Krishnan C | G2 | 05/07/2005 | nitheeshmk5
25MX337 | Nithyashree C | G2 | NULL | Nithyashree_C
25MX338 | Poorani R | G2 | 24/03/2005 | PooraniMohan24
25MX339 | Prabhakar O S | G2 | 08/11/2004 | prabha6769
25MX340 | Puratchiyan R | G2 | 29/10/2004 | Puratchiyan
25MX341 | Radhu Dharsan K M | G2 | 06/01/2005 | fkenq9S0hw
25MX342 | Rohithmaheshwaran K | G2 | 21/05/2005 | Mahesh__rdr
25MX343 | Sabarish P | G2 | NULL | SABARISH_P
25MX344 | Satya Pramodh R | G2 | NULL | SATYA_PRAMODH
25MX345 | Shri Sanjay M | G2 | 26/07/2005 | M_Shri_sanjay26
25MX346 | Siddarth M R | G2 | NULL | sidddarthvasi2604
25MX347 | Sivapradeesh M | G2 | NULL | Sivapradeesh_M
25MX348 | S S Soban | G2 | 21/12/2001 | sobanss2001
25MX349 | Sowmiya | G2 | 03/03/2003 | sowmiya_3
25MX350 | Srivikashni S | G2 | 06/09/2004 | SRIVIKASHNI
25MX351 | Suriya C S | G2 | NULL | suriyaCSD
25MX352 | Tamilini S | G2 | 29/10/2004 | oi8UIWVPvT
25MX353 | Thrisha R | G2 | NULL | Thrishaa123
25MX354 | Tino Britty J | G2 | 08/07/2004 | tinobritty
25MX355 | Vaishali S | G2 | 02/01/2005 | __Vaishu_7__
25MX356 | Vignesh M | G2 | 31/01/2004 | Vix-codes
25MX357 | Vijaya Sree K | G2 | NULL | 12_zoya
25MX358 | Vikram Sethupathy S | G2 | 17/11/2004 | lemonspice17
25MX359 | Vishnuvardani K S | G2 | 24/12/2004 | vishnuvardani_2004
25MX360 | Yaswanth R T | G2 | 01/07/2004 | yash_3237
25MX361 | Sanjana M | G2 | 29/04/2004 | sanjana_m29
25MX362 | Narayanasamy | G2 | NULL | Narayana_1080
25MX363 | Tharun S | G2 | 12/04/2003 | Tectonic_
"""

# 3. BUILD SQL CONTENT

def fmt_val(v):
    if v == 'NULL' or v is None:
        return 'NULL'
    return f"'{v}'"

def convert_date(d_str):
    # dd/mm/yyyy -> yyyy-mm-dd
    if not d_str or d_str.strip() == 'NULL':
        return 'NULL'
    try:
        parts = d_str.strip().split('/')
        if len(parts) == 3:
            return f"{parts[2]}-{parts[1]}-{parts[0]}"
    except:
        pass
    return 'NULL'

# SQL Header
sql_out = """-- ============================================================================
-- PSGMX: Complete User Seed v2 (Updated with DOB and LeetCode)
-- ============================================================================

-- 1. Ensure Table Schema has new columns
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS leetcode_username TEXT,
ADD COLUMN IF NOT EXISTS dob DATE,
ADD COLUMN IF NOT EXISTS birthday_notifications_enabled BOOLEAN DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS public.whitelist (
  email TEXT PRIMARY KEY,
  name TEXT,
  reg_no TEXT,
  batch TEXT,
  team_id TEXT,
  roles JSONB,
  dob DATE,
  leetcode_username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Truncate Whitelist
TRUNCATE TABLE public.whitelist;

-- 3. Insert Data
INSERT INTO public.whitelist (email, name, reg_no, batch, team_id, dob, leetcode_username, roles) VALUES
"""

values_list = []

# Process raw data
lines = raw_data.strip().split('\n')
for line in lines:
    parts = [p.strip() for p in line.split('|')]
    if len(parts) < 5:
        continue
    
    reg_no = parts[0]
    name = parts[1]
    batch = parts[2]
    dob_raw = parts[3]
    leetcode = parts[4]
    
    if reg_no == 'NULL': continue
    
    # Defaults
    email = f"{reg_no.lower()}@psgtech.ac.in"
    dob_val = convert_date(dob_raw)
    leet_val = fmt_val(leetcode)
    dob_sql = fmt_val(dob_val) if dob_val != 'NULL' else 'NULL'
    
    # Lookup specific roles/team from previous seed
    roles_json = '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'
    team_id = 'T00' # Default if not found
    
    if reg_no in existing_data:
        old = existing_data[reg_no]
        roles_json = old['roles']
        team_id = old['team_id']
        email = old['email'] # Preserve specific email casings if any
    
    # Special fix for dummy users or specific overwrites
    
    values_list.append(f"('{email}', '{name.replace('\'', '\'\'')}', '{reg_no}', '{batch}', '{team_id}', {dob_sql}, {leet_val}, '{roles_json}')")

sql_out += ",\n".join(values_list) + ";"

# 4. Sync SQL
sql_out += """

-- 4. Sync Public Users
-- Update existing users with new fields
UPDATE public.users u
SET 
  team_id = w.team_id,
  roles = w.roles,
  batch = w.batch,
  name = w.name,
  reg_no = w.reg_no,
  dob = w.dob,
  leetcode_username = w.leetcode_username
FROM public.whitelist w
WHERE u.email = w.email;

-- 5. Insert new users into public.users (Optional - usually they sign up)
-- We won't auto-insert into users table to avoid auth ID mismatches, 
-- but ensuring whitelist is populated allows the Trigger/Function to work on Signup.

-- 6. Verification
SELECT COUNT(*) as whitelist_count FROM public.whitelist;
"""

with open('../complete_user_seed_v2.sql', 'w', encoding='utf-8') as f:
    f.write(sql_out)

print("SQL Generated successfully.")
