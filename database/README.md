#  Database Setup Guide

PostgreSQL / Supabase schema for **PSGMX Placement Prep App**  new project setup.

---

##  Critical: Run Order

The policies in `02_policies.sql` call helper functions defined in `03_functions.sql`.
**You must run functions before policies.**

```
01_schema.sql → 03_functions.sql → 02_policies.sql
→ 04_triggers.sql → 05_seed_data.sql → 06_ecampus_schema.sql
→ 07_bulk_onboard_users.sql → 08_ecampus_bunked_schema.sql
→ 09_schema_patch_2026_02_25.sql → 10_fix_attendance_view_all_students.sql
→ 11_ecampus_ca_schema.sql → 12_ecampus_custom_password.sql
→ 13_ecampus_ca_timetable.sql → 14_ca_timetable_global.sql
→ 15_fix_security_definer_views.sql ⚠️ SECURITY FIX
```

> **⚠️ IMPORTANT:** If you receive Supabase Security Advisor warnings about SECURITY DEFINER views, run patch `15_fix_security_definer_views.sql`

---

##  Step-by-Step: Supabase SQL Editor

Go to your Supabase project  **SQL Editor**  **New query**
Paste each file's content, click **Run**, verify the success notice, then move to the next.

---

### Step 1  Schema (`01_schema.sql`)

Creates all 12 tables, indexes, and extensions.

1. Open `database/01_schema.sql`
2. Copy entire file  paste into SQL Editor  click **Run**
3.  Success notice: `STEP 1 COMPLETE: SCHEMA CREATED`

Tables created: `users`, `whitelist`, `leetcode_stats`, `daily_tasks`,
`scheduled_attendance_dates`, `attendance_records`, `audit_logs`,
`notifications`, `notification_reads`, `attendance_days`,
`task_completions`, `app_config`

---

### Step 2  Functions (`03_functions.sql`)  Must run BEFORE policies

Creates helper functions used by RLS policies and the Flutter app.

1. Open `database/03_functions.sql`
2. Copy  paste into a **new SQL Editor tab**  click **Run**
3.  Success notice: `STEP 3 COMPLETE: FUNCTIONS CREATED`

Functions: `has_role`, `is_placement_rep`, `is_coordinator`, `is_team_leader`,
`get_user_team`, `is_date_scheduled`, `get_scheduled_dates`,
`update_leetcode_username_unified`

---

### Step 3  Policies (`02_policies.sql`)

Enables Row-Level Security on all tables.

1. Open `database/02_policies.sql`
2. Copy  paste into a **new SQL Editor tab**  click **Run**
3.  Success notice: `STEP 3 COMPLETE: RLS POLICIES`

---

### Step 4  Triggers (`04_triggers.sql`)

Automates notifications and timestamp updates.

1. Open `database/04_triggers.sql`
2. Copy  paste into a **new SQL Editor tab**  click **Run**
3.  Success notice: `Triggers & Automations setup successfully.`

Triggers:
- New task posted  notification to all
- Attendance scheduled  reminder to team leaders
- LeetCode milestone (every 50 problems)  celebratory notification
- `app_config` update  auto `updated_at`

---

### Step 5  Seed Data (`05_seed_data.sql`)

Inserts all 123 students into whitelist and creates the default `app_config` row.

1. Open `database/05_seed_data.sql`
2. Copy  paste into a **new SQL Editor tab**  click **Run**
3.  Success notice: `SEED DATA COMPLETE`  `Whitelist entries: 123`

> Re-running is safe  `ON CONFLICT DO NOTHING` prevents duplicates.

---

### Step 6  eCampus Tables (`06_ecampus_schema.sql`)

Creates Bunker screen cache tables (PSG eCampus scraper output).

1. Open `database/06_ecampus_schema.sql`
2. Copy  paste into a **new SQL Editor tab**  click **Run**
3.  No errors in output panel = success

Tables created: `ecampus_attendance`, `ecampus_cgpa`
View created: `v_ecampus_attendance_summary`

---
### Step 7 — Bulk Onboard Users (`07_bulk_onboard_users.sql`) ⚡ CRITICAL

Pre-creates all 123 students in `auth.users` and repairs missing `public.users` rows so attendance features work for every student.
**Without this, you'll get "Signups not allowed for otp" errors.**

1. Open `database/07_bulk_onboard_users.sql`
2. Copy → paste into a **new SQL Editor tab** → click **Run**
3. Success notice includes verification counts for:
    - `Whitelist students`
    - `auth.users matched`
    - `public.users matched`
    - `Missing in auth.users`
    - `Missing in public.users`

> The script also backfills `public.users` if trigger-created rows are missing.
> After this, all whitelist students should be fully attendance-ready.

---
### Step 8 — Bunked Subject Cache (`08_ecampus_bunked_schema.sql`)

Creates per-subject bunked details used by the app and the daily sync job.

1. Open `database/08_ecampus_bunked_schema.sql`
2. Copy → paste into a **new SQL Editor tab** → click **Run**
3. ✅ No errors in output panel = success

---
### Step 9 — Security Patches (`09-14_*.sql`)

Apply schema patches and CA exam features in numerical order.

1. Run patches 09-14 in sequence if you need attendance fixes, CA exams, or custom password features
2. ✅ Success notices vary per patch — check for errors in output panel

---
### Step 10 — Fix Security Definer Views (`15_fix_security_definer_views.sql`) ⚠️ SECURITY FIX

**Apply this patch if Supabase Security Advisor reports SECURITY DEFINER warnings.**

**What it fixes:**
- `v_ecampus_attendance_summary` — Now respects RLS policies
- `v_ecampus_cgpa_summary` — Now respects RLS policies  
- `student_attendance_summary` — Now respects RLS policies

**How to apply:**
```sql
1. Go to Supabase → SQL Editor → New query
2. Copy contents of database/15_fix_security_definer_views.sql
3. Click Run
4. ✅ Should see 3 view recreation notices
```

**Verification:**
```sql
-- Verify all three views now use security_invoker
SELECT viewname, viewowner,
       pg_get_viewdef(schemaname || '.' || viewname, true) as definition
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('student_attendance_summary', 'v_ecampus_attendance_summary', 'v_ecampus_cgpa_summary');
```

Expected output should show `WITH (security_invoker='t')` in the definitions.

After running this patch, re-check **Supabase Dashboard → Advisors → Security Advisor** — the 3 errors should be resolved.

---
##  Post-Setup Checklist

- [ ] **Table Editor**  `whitelist` has 123 rows
- [ ] **Table Editor**  `app_config` has 1 row
- [ ] **Authentication  Providers  Email**  Enable OTP / magic link
- [ ] **Settings  API**  copy `service_role` key  set as `SUPABASE_SERVICE_KEY` in your FastAPI `.env`
- [ ] **Security Advisor** has 0 errors (run patch 15 if you see SECURITY DEFINER warnings)

---

##  File Reference

| File | Run Order | Purpose |
|------|-----------|---------|
| `01_schema.sql` | 1st | All tables, indexes, extensions |
| `03_functions.sql` | 2nd | Helper functions (must precede policies) |
| `02_policies.sql` | 3rd | Row-Level Security rules |
| `04_triggers.sql` | 4th | Auto-notifications, timestamps, auth trigger |
| `05_seed_data.sql` | 5th | 123-student whitelist + app config |
| `06_ecampus_schema.sql` | 6th | Bunker screen attendance/CGPA cache |
| `07_bulk_onboard_users.sql` | 7th ⚡ | Pre-create auth.users for all 123 (enables OTP login) |
| `08_ecampus_bunked_schema.sql` | 8th | Per-subject bunked cache |
| `09_schema_patch_2026_02_25.sql` | 9th | Schema patches for attendance fixes |
| `10_fix_attendance_view_all_students.sql` | 10th | Fix attendance view to show all 123 students |
| `11_ecampus_ca_schema.sql` | 11th | CA exam schema |
| `12_ecampus_custom_password.sql` | 12th | Custom password authentication |
| `13_ecampus_ca_timetable.sql` | 13th | CA exam timetable |
| `14_ca_timetable_global.sql` | 14th | Global CA timetable |
| `15_fix_security_definer_views.sql` | 15th ⚠️ | **Security Fix: Remove SECURITY DEFINER from views** |

---

##  Schema Overview

| Table | Description |
|-------|-------------|
| `users` | Auth-linked student profiles (name, reg_no, batch, roles) |
| `whitelist` | Master registry of 123 allowed students |
| `app_config` | Remote version config & maintenance mode |
| `attendance_records` | Daily Present/Absent per student |
| `scheduled_attendance_dates` | Dates when attendance marking is open |
| `daily_tasks` | LeetCode / Core tasks assigned by coordinators |
| `task_completions` | Student submissions + verification |
| `leetcode_stats` | Synced LeetCode counts & ranking |
| `notifications` | System-generated alerts |
| `notification_reads` | Per-user read/dismiss tracking |
| `ecampus_attendance` | Scraped eCampus attendance JSON cache |
| `ecampus_cgpa` | Scraped eCampus CGPA JSON cache |
