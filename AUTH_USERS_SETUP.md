# Create Auth Users - Setup Guide

Since the Supabase console isn't working for creating users, use this Node.js script instead.

## Quick Start

### Step 1: Install Dependencies
```bash
npm install @supabase/supabase-js
```

### Step 2: Get Your Supabase Credentials
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Click your project
3. Go to **Settings** → **API**
4. Copy these values:
   - **Project URL** → Copy to `SUPABASE_URL`
   - **Service Role** key → Copy to `SERVICE_ROLE_KEY`

⚠️ **IMPORTANT**: Use the **Service Role** key (not the public key)

### Step 3: Update the Script
Edit `create_auth_users.js` and replace:
```javascript
const SUPABASE_URL = 'https://your-project.supabase.co'; // Paste Project URL here
const SERVICE_ROLE_KEY = 'eyJhbGc...'; // Paste service_role key here
```

### Step 4: Run the Script
```bash
node create_auth_users.js
```

You should see:
```
🔐 Creating auth users in Supabase...

⏳ Creating user: 25mx354@psgtech.ac.in
✅ User created: 25mx354@psgtech.ac.in
   ID: 550e8400-e29b-41d4-a716-446655440000
   Password: psgtech@2025

... (3 more users) ...

🎉 All auth users created successfully!
```

## What Gets Created

| Email | Password | Role |
|-------|----------|------|
| 25mx354@psgtech.ac.in | psgtech@2025 | Placement Rep |
| dummy.student@psgtech.ac.in | student123 | Regular Student |
| dummy.leader@psgtech.ac.in | leader123 | Team Leader |
| dummy.coordinator@psgtech.ac.in | coordinator123 | Coordinator |

## Next Steps (After Users Are Created)

1. **Run the SQL Script**:
   - Go to Supabase SQL Editor
   - Select ALL from `complete_user_seed.sql` (Ctrl+A)
   - Paste into SQL Editor
   - Click "Run" to seed user profiles

2. **Test Login**:
   - Run: `flutter run`
   - Email: `25mx354@psgtech.ac.in`
   - Password: `psgtech@2025`

## Troubleshooting

**Error: "SERVICE_ROLE_KEY is invalid"**
- Make sure you copied the `service_role` key, not the `public` key
- The key should start with `eyJhbGc...`

**Error: "SUPABASE_URL is malformed"**
- URL should be: `https://xxxxx.supabase.co` (with https://)
- Don't include trailing slashes

**Error: "User already exists"**
- The user was already created, which is fine
- Proceed to the next step (run SQL script)

**Script still fails:**
- Make sure you have Node.js installed: `node --version`
- Make sure npm packages are installed: `npm install @supabase/supabase-js`
