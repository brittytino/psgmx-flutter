#!/usr/bin/env node

/**
 * Create Auth Users Script
 * Creates 4 auth users in Supabase before running the SQL seed script
 * 
 * SETUP:
 * 1. Install dependencies: npm install @supabase/supabase-js
 * 2. Get your Supabase credentials from: https://app.supabase.com/project/_/settings/api
 * 3. Replace SUPABASE_URL and SERVICE_ROLE_KEY below
 * 4. Run: node create_auth_users.js
 */

const { createClient } = require('@supabase/supabase-js');

// ============================================================================
// CONFIGURE YOUR SUPABASE CREDENTIALS HERE
// ============================================================================
const SUPABASE_URL = 'https://dsucqgrwyimtuhebvmpx.supabase.co'; // Project URL (format: https://xxxxx.supabase.co)
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzdWNxZ3J3eWltdHVoZWJ2bXB4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTA4MDAwMSwiZXhwIjoyMDg0NjU2MDAxfQ.VLlUceKYUuIAj-SDNpcN4dJ4WwHy5Y1NeTmw15h6fFo'; // service_role key

// Users to create
const usersToCreate = [
  {
    email: '25mx354@psgtech.ac.in',
    password: 'psgtech@2025',
    name: 'Tino Britty J (Placement Rep)',
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
// CREATE AUTH USERS
// ============================================================================
async function createAuthUsers() {
  // Validate credentials
  if (
    SUPABASE_URL === 'YOUR_SUPABASE_URL' ||
    SERVICE_ROLE_KEY === 'YOUR_SERVICE_ROLE_KEY'
  ) {
    console.error('❌ ERROR: Please configure SUPABASE_URL and SERVICE_ROLE_KEY');
    console.error('   1. Go to: https://app.supabase.com/project/_/settings/api');
    console.error('   2. Copy "Project URL" → SUPABASE_URL');
    console.error('   3. Copy "service_role" key → SERVICE_ROLE_KEY');
    process.exit(1);
  }

  // Initialize Supabase Admin Client
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  console.log('🔐 Creating auth users in Supabase...\n');

  let successCount = 0;
  let failureCount = 0;

  for (const user of usersToCreate) {
    try {
      console.log(`⏳ Creating user: ${user.email}`);

      const { data, error } = await supabase.auth.admin.createUser({
        email: user.email,
        password: user.password,
        email_confirm: true, // Auto-confirm email
        user_metadata: {
          name: user.name,
        },
      });

      if (error) {
        throw error;
      }

      console.log(`✅ User created: ${user.email}`);
      console.log(`   ID: ${data.user.id}`);
      console.log(`   Password: ${user.password}\n`);
      successCount++;
    } catch (error) {
      console.error(`❌ Failed to create ${user.email}`);
      console.error(`   Error: ${error.message}\n`);
      failureCount++;
    }
  }

  // Summary
  console.log('============================================================================');
  console.log(`✅ Summary: ${successCount} created, ❌ ${failureCount} failed`);
  console.log('============================================================================\n');

  if (successCount === usersToCreate.length) {
    console.log('🎉 All auth users created successfully!');
    console.log('\nNext steps:');
    console.log('1. Copy all SQL from complete_user_seed.sql');
    console.log('2. Paste into Supabase SQL Editor');
    console.log('3. Run the script to seed user profiles');
    console.log('\n✨ Your placement management system is ready!');
  } else {
    console.log('⚠️  Some users failed to create. Please check the errors above.');
    process.exit(1);
  }
}

// Run the script
createAuthUsers();
