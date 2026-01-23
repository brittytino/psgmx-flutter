#!/usr/bin/env node

/**
 * Create Auth Users Script - V2 (Direct HTTP)
 * Creates 4 auth users in Supabase using direct HTTP requests
 * 
 * SETUP:
 * 1. Get your Supabase credentials from: https://app.supabase.com/project/_/settings/api
 * 2. Replace SUPABASE_URL and SERVICE_ROLE_KEY below
 * 3. Run: node create_auth_users_v2.js
 */

const https = require('https');
const querystring = require('querystring');

// ============================================================================
// CONFIGURE YOUR SUPABASE CREDENTIALS HERE
// ============================================================================
const SUPABASE_URL = 'https://dsucqgrwyimtuhebvmpx.supabase.co'; // Project URL
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzdWNxZ3J3eWltdHVoZWJ2bXB4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTA4MDAwMSwiZXhwIjoyMDg0NjU2MDAxfQ.VLlUceKYUuIAj-SDNpcN4dJ4WwHy5Y1NeTmw15h6fFo'; // service_role key

// Users to create
const usersToCreate = [
  {
    email: '25mx354@psgtech.ac.in',
    password: 'psgtech@2025',
    name: 'Tino Britty J',
  },
  {
    email: 'dummy.student@psgtech.ac.in',
    password: 'student123',
    name: 'Test Student',
  },
  {
    email: 'dummy.leader@psgtech.ac.in',
    password: 'leader123',
    name: 'Test Team Leader',
  },
  {
    email: 'dummy.coordinator@psgtech.ac.in',
    password: 'coordinator123',
    name: 'Test Coordinator',
  },
];

// ============================================================================
// CREATE AUTH USER VIA HTTP
// ============================================================================
function createAuthUserHTTP(email, password, name) {
  return new Promise((resolve, reject) => {
    const url = new URL(SUPABASE_URL);
    const path = '/auth/v1/admin/users';

    const requestBody = JSON.stringify({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: {
        name: name,
      },
    });

    const options = {
      hostname: url.hostname,
      port: 443,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody),
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
      },
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          if (res.statusCode === 201) {
            const user = JSON.parse(data);
            resolve({ success: true, userId: user.user.id });
          } else if (res.statusCode === 400) {
            const error = JSON.parse(data);
            if (error.msg && error.msg.includes('already registered')) {
              resolve({ success: false, reason: 'User already exists' });
            } else {
              resolve({ success: false, reason: error.msg || error.error_description });
            }
          } else {
            resolve({ success: false, reason: `HTTP ${res.statusCode}` });
          }
        } catch (err) {
          resolve({ success: false, reason: `Parse error: ${err.message}` });
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(requestBody);
    req.end();
  });
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================
async function main() {
  console.log('🔐 Creating auth users in Supabase...\n');

  let successCount = 0;
  let skippedCount = 0;
  let failureCount = 0;

  for (const user of usersToCreate) {
    try {
      process.stdout.write(`⏳ Creating user: ${user.email}... `);

      const result = await createAuthUserHTTP(user.email, user.password, user.name);

      if (result.success) {
        console.log('✅');
        console.log(`   ID: ${result.userId}`);
        console.log(`   Password: ${user.password}\n`);
        successCount++;
      } else {
        if (result.reason === 'User already exists') {
          console.log('⏭️  (already exists)');
          console.log(`   Reason: ${result.reason}\n`);
          skippedCount++;
        } else {
          console.log('❌');
          console.log(`   Error: ${result.reason}\n`);
          failureCount++;
        }
      }
    } catch (error) {
      console.log('❌');
      console.log(`   Error: ${error.message}\n`);
      failureCount++;
    }
  }

  // Summary
  console.log('============================================================================');
  console.log(`✅ Created: ${successCount} | ⏭️  Skipped: ${skippedCount} | ❌ Failed: ${failureCount}`);
  console.log('============================================================================\n');

  if (successCount + skippedCount === usersToCreate.length) {
    console.log('🎉 All auth users ready!');
    console.log('\n📋 Next steps:');
    console.log('1. Copy ALL SQL from complete_user_seed.sql (Ctrl+A)');
    console.log('2. Go to Supabase SQL Editor');
    console.log('3. Paste and click "Run"');
    console.log('4. Wait for "✅ INSERT" messages');
    console.log('\n✨ Your system is ready!');
  } else {
    console.log('⚠️  Some users failed. Please check errors above.');
    console.log('\nIf errors persist, try:');
    console.log('1. Verify SERVICE_ROLE_KEY is correct');
    console.log('2. Verify SUPABASE_URL has format: https://xxxxx.supabase.co');
    console.log('3. Check Supabase project is active');
    process.exit(1);
  }
}

// Run the script
main();
