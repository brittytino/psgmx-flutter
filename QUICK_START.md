# 🚀 QUICK START GUIDE

## Prerequisites
- Supabase account (free)
- Flutter SDK installed
- Android device/emulator

---

## Step 1: Create Supabase Project (5 min)

1. Go to https://app.supabase.com
2. Click "New Project"
3. Fill in:
   - Project name: `psgmx-placement-prep`
   - Database password: (save this!)
   - Region: (choose closest to India)
4. Click "Create new project"
5. Wait ~2 minutes for provisioning

---

## Step 2: Run Database Setup (2 min)

1. In Supabase dashboard, click "SQL Editor" (left sidebar)
2. Click "New query"
3. Open `supabase_setup.sql` from project root
4. Copy entire file content
5. Paste into SQL Editor
6. Click "RUN"
7. Wait for "Success. No rows returned"

**Verify:** Click "Table Editor" → You should see 6 tables

---

## Step 3: Configure App (2 min)

1. In Supabase, click "Project Settings" (gear icon)
2. Click "API" in left menu
3. Copy:
   - Project URL (looks like `https://xxx.supabase.co`)
   - `anon` `public` key (NOT service_role!)

4. Open `lib/core/supabase_config.dart` in your editor
5. Replace:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

---

## Step 4: Add Test Users (3 min)

### Option A: Table Editor (Quick)
1. In Supabase, click "Table Editor"
2. Select "whitelist" table
3. Click "Insert row"
4. Fill in:
   - email: `test@psgtech.ac.in`
   - reg_no: `22MCA001`
   - name: `Test User`
   - team_id: `TEAM_A`
   - roles: `{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}`
5. Click "Save"

### Option B: SQL (Bulk)
```sql
INSERT INTO public.whitelist (email, reg_no, name, team_id, roles) VALUES
  ('test@psgtech.ac.in', '22MCA001', 'Test Student', 'TEAM_A', 
   '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'),
  ('leader@psgtech.ac.in', '22MCA002', 'Test Leader', 'TEAM_A', 
   '{"isStudent": true, "isTeamLeader": true, "isCoordinator": false, "isPlacementRep": false}'),
  ('coord@psgtech.ac.in', '22MCA003', 'Test Coordinator', 'ADMIN', 
   '{"isStudent": false, "isTeamLeader": false, "isCoordinator": true, "isPlacementRep": false}'),
  ('rep@psgtech.ac.in', '22MCA004', 'Test Rep', 'ADMIN', 
   '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": true}');
```

---

## Step 5: Run App (1 min)

```bash
cd "d:\Work's\Github\psgmx-flutter"
flutter run
```

---

## Step 6: Test Authentication (2 min)

1. App opens to login screen
2. Enter: `test@psgtech.ac.in`
3. Click "Send Magic Link"
4. Check email inbox (or spam folder)
5. Copy 6-digit code from email
6. Click "Enter Verification Code"
7. Paste code
8. Click "Verify"

**Success:** You should see the student dashboard

---

## Step 7: Test Roles (5 min)

### Test Team Leader:
1. Sign out
2. Login with `leader@psgtech.ac.in`
3. Verify OTP
4. You should see "Team Attendance" tab
5. Try marking attendance (should work before 8 PM IST)

### Test Coordinator:
1. Sign out
2. Login with `coord@psgtech.ac.in`
3. Verify OTP
4. You should see "Publish Task" option
5. Try creating a daily task

### Test Placement Rep:
1. Sign out
2. Login with `rep@psgtech.ac.in`
3. Verify OTP
4. You should see "Override Attendance" option
5. Can override anytime (even after 8 PM)

---

## Common Issues & Fixes

### ❌ "Invalid API key"
**Fix:** Check you copied the `anon` key, not `service_role`

### ❌ "User not authorized in whitelist"
**Fix:** Verify email exists in `whitelist` table (exact match)

### ❌ "Failed to send magic link"
**Fix:** 
- Check Supabase Auth settings: Settings → Authentication → Email
- Ensure email provider is configured

### ❌ OTP not received
**Fix:**
- Check spam folder
- Verify Supabase email provider is enabled
- Try resending after 30 seconds

### ❌ "Cannot mark attendance after 8 PM"
**Fix:** This is CORRECT behavior! Test with device time before 8 PM IST

---

## Production Deployment

### Add Real Students:

**Option 1: Bulk Import via SQL**
```sql
INSERT INTO public.whitelist (email, reg_no, name, team_id, roles) VALUES
  ('student1@psgtech.ac.in', '22MCA101', 'Student Name 1', 'TEAM_A', '{"isStudent": true}'),
  ('student2@psgtech.ac.in', '22MCA102', 'Student Name 2', 'TEAM_A', '{"isStudent": true}'),
  -- ... add all 120 students
```

**Option 2: CSV Import**
1. Prepare CSV: email, reg_no, name, team_id
2. Use Supabase Table Editor → Import CSV
3. Add roles column manually or via SQL UPDATE

### Assign Roles:
```sql
-- Make team leaders
UPDATE public.whitelist 
SET roles = '{"isStudent": true, "isTeamLeader": true}'::jsonb
WHERE email IN ('leader1@psgtech.ac.in', 'leader2@psgtech.ac.in');

-- Make coordinators
UPDATE public.whitelist 
SET roles = '{"isCoordinator": true}'::jsonb
WHERE email IN ('coordinator@psgtech.ac.in');

-- Make placement rep
UPDATE public.whitelist 
SET roles = '{"isPlacementRep": true}'::jsonb
WHERE email = 'placement.rep@psgtech.ac.in';
```

---

## Security Checklist

- [ ] Changed default Supabase database password
- [ ] Using `anon` key in app (NOT service_role)
- [ ] All RLS policies enabled
- [ ] Whitelist populated with only authorized emails
- [ ] Email domain restriction active (@psgtech.ac.in)
- [ ] Time lock tested (8 PM IST cutoff)
- [ ] Audit logs verified for rep overrides

---

## Monitoring

### Check Logs:
1. Supabase Dashboard → Logs
2. Filter by:
   - Auth logs: See login attempts
   - Database logs: See query patterns
   - Error logs: See failures

### Check Usage:
1. Supabase Dashboard → Settings → Usage
2. Monitor:
   - Database size
   - Bandwidth
   - API requests

**Free tier limits:**
- 500 MB database ✅ (You'll use <10 MB)
- 2 GB bandwidth/month ✅ (You'll use <500 MB)
- 50K MAU ✅ (You have 120 users)

---

## Support Resources

- **Supabase Docs:** https://supabase.com/docs
- **Supabase Discord:** https://discord.supabase.com
- **Project Docs:** See `MIGRATION_COMPLETE.md`

---

## Estimated Total Time: 15-20 minutes

1. Create Supabase project: 5 min
2. Run SQL setup: 2 min
3. Configure app: 2 min
4. Add test users: 3 min
5. Run & test: 3 min
6. Test roles: 5 min

**After this, your app is production-ready!**

---

## Success Criteria

✅ App launches without errors  
✅ Login with @psgtech.ac.in works  
✅ OTP verification succeeds  
✅ Role-based dashboards appear  
✅ Attendance marking works (before 8 PM)  
✅ Time lock blocks after 8 PM  
✅ Placement rep can override anytime  
✅ No Firebase code or configs remain  

---

**Ready? Start with Step 1!**
