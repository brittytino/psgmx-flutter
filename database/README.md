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
```

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

Pre-creates all 123 students in `auth.users` so they can LOGIN via OTP (not signup).
**Without this, you'll get "Signups not allowed for otp" errors.**

1. Open `database/07_bulk_onboard_users.sql`
2. Copy → paste into a **new SQL Editor tab** → click **Run**
3. ✅ Success notice: `BULK ONBOARDING COMPLETE` — `Auth users created: 123`

> The `handle_new_user` trigger automatically creates `public.users` rows.
> After this, all 123 students can login via OTP immediately.

---
### Step 8 — Bunked Subject Cache (`08_ecampus_bunked_schema.sql`)

Creates per-subject bunked details used by the app and the daily sync job.

1. Open `database/08_ecampus_bunked_schema.sql`
2. Copy → paste into a **new SQL Editor tab** → click **Run**
3. ✅ No errors in output panel = success

---
##  Post-Setup Checklist

- [ ] **Table Editor**  `whitelist` has 123 rows
- [ ] **Table Editor**  `app_config` has 1 row
- [ ] **Authentication  Providers  Email**  Enable OTP / magic link
- [ ] **Settings  API**  copy `service_role` key  set as `SUPABASE_SERVICE_KEY` in your FastAPI `.env`

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
