const fs = require('fs');
const path = require('path');

try {
    const inputPath = path.join('scripts', 'correct_users_data.txt');
    const content = fs.readFileSync(inputPath, 'utf8');

    let sqlContent = "-- Bulk update based on verified user data\n";
    let count = 0;

    const lines = content.split('\n');
    lines.forEach(line => {
        line = line.trim();
        if (!line) return;

        // Format is: RegNo | Name | Batch | DOB | LeetCode
        const parts = line.split('|').map(p => p.trim());
        if (parts.length < 5) return;

        const regNo = parts[0];
        const dobRaw = parts[3];
        let leetcodeRaw = parts[4];

        let updates = [];

        // Handle DOB
        if (dobRaw && dobRaw.toUpperCase() !== 'NULL') {
            const dateParts = dobRaw.split('/');
            if (dateParts.length === 3) {
                // dd/MM/yyyy -> yyyy-MM-dd
                const isoDate = `${dateParts[2]}-${dateParts[1]}-${dateParts[0]}`;
                updates.push(`dob = '${isoDate}'`);
            }
        }

        // Handle Leetcode
        if (leetcodeRaw && leetcodeRaw.toUpperCase() !== 'NULL') {
            // Escape single quotes
            leetcodeRaw = leetcodeRaw.replace(/'/g, "''");
            updates.push(`leetcode_username = '${leetcodeRaw}'`);
            updates.push(`leetcode_notifications_enabled = true`);
        }

        if (updates.length > 0) {
            // Use RegNo as unique identifier
            sqlContent += `UPDATE users SET ${updates.join(', ')} WHERE reg_no = '${regNo}';\n`;
            count++;
        }
    });

    const outputPath = path.join('scripts', 'update_users_data.sql');
    fs.writeFileSync(outputPath, sqlContent);
    
    console.log(`Successfully generated SQL updates for ${count} users in ${outputPath}`);

} catch (e) {
    console.error("Error:", e);
}
