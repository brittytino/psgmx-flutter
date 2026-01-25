import json
import random
from datetime import datetime, timedelta

def random_date(start_year, end_year):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    delta = end - start
    random_days = random.randrange(delta.days)
    return (start + timedelta(days=random_days)).strftime('%Y-%m-%d')

def generate_leetcode(name, reg_no):
    # Create a plausible leetcode username: firstname_lastname_regSuffix
    clean_name = "".join(e for e in name if e.isalnum()).lower()
    return f"{clean_name}_{reg_no.lower()}"

try:
    with open('scripts/users_master.json', 'r') as f:
        users = json.load(f)

    sql_lines = []
    sql_lines.append("-- Bulk update for generic DOB and LeetCode Usernames")
    
    for user in users:
        email = user.get('email')
        name = user.get('name')
        reg_no = user.get('regNo')
        
        if not email or not name or not reg_no:
            continue
            
        dob = random_date(2001, 2003)
        lc_username = generate_leetcode(name, reg_no)
        
        # Escape single quotes in names just in case
        lc_username = lc_username.replace("'", "")
        
        sql = f"UPDATE users SET dob = '{dob}', leetcode_username = '{lc_username}', leetcode_notifications_enabled = true WHERE email = '{email}';"
        sql_lines.append(sql)

    output_file = 'scripts/update_users_data.sql'
    with open(output_file, 'w') as f:
        f.write('\n'.join(sql_lines))
        
    print(f"Successfully generated {len(sql_lines)} update statements in {output_file}")

except Exception as e:
    print(f"Error: {e}")
