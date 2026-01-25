const fs = require('fs');
const path = require('path');

function randomDate(startYear, endYear) {
    const start = new Date(startYear, 0, 1);
    const end = new Date(endYear, 11, 31);
    const date = new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
    return date.toISOString().split('T')[0];
}

function generateLeetCode(name, regNo) {
    const cleanName = name.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
    return `${cleanName}_${regNo.toLowerCase()}`;
}

try {
    const jsonPath = path.join('scripts', 'users_master.json');
    const users = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

    let sqlContent = "-- Bulk update for generic DOB and LeetCode Usernames\n";

    users.forEach(user => {
        if (!user.email || !user.name || !user.regNo) return;

        const dob = randomDate(2001, 2003);
        let lcUsername = generateLeetCode(user.name, user.regNo);
        
        // Basic SQL escaping
        lcUsername = lcUsername.replace(/'/g, ""); 
        
        sqlContent += `UPDATE users SET dob = '${dob}', leetcode_username = '${lcUsername}', leetcode_notifications_enabled = true WHERE email = '${user.email}';\n`;
    });

    const outputPath = path.join('scripts', 'update_users_data.sql');
    fs.writeFileSync(outputPath, sqlContent);
    
    console.log(`Successfully generated SQL updates for ${users.length} users in ${outputPath}`);

} catch (e) {
    console.error("Error:", e);
}
