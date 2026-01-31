# 📚 PSG MX Placement App - Database Setup

This folder contains all SQL scripts needed to set up the database in **Supabase**.

## 🚀 Quick Start

Run these scripts **in order** in the Supabase SQL Editor:

| # | File | Description | Time |
|---|------|-------------|------|
| 1 | `01_schema.sql` | Creates all tables and indexes | ~5s |
| 2 | `02_data.sql` | Inserts all 123 students | ~10s |
| 3 | `03_functions.sql` | Creates helper functions & views | ~3s |
| 4 | `04_rls_policies.sql` | Sets up access control (RLS) | ~5s |
| 5 | `05_sample_data.sql` | *(Optional)* Sample attendance data | ~5s |

**Total setup time: ~30 seconds**

---

## 📋 What Each Script Does

### 01_schema.sql
Creates all database tables:
- `users` - All user accounts (students, team leaders, coordinators, placement rep)
- `whitelist` - Master list of 123 allowed students
- `leetcode_stats` - LeetCode leaderboard data
- `daily_tasks` - Daily LeetCode and Core subject tasks
- `scheduled_attendance_dates` - Dates when classes are scheduled
- `attendance_records` - Individual attendance records
- `audit_logs` - Tracks important actions
- `notifications` - App notifications
- `notification_reads` - Track read notifications

### 02_data.sql
Inserts student data:
- 123 students into whitelist table
- Syncs data to users table
- Populates LeetCode usernames

### 03_functions.sql
Creates helper functions:
- `has_role()` - Check if user has a role
- `is_placement_rep()` - Check if user is placement rep
- `is_team_leader()` - Check if user is team leader
- `is_date_scheduled()` - Check if date is a class day
- `get_team_attendance_for_date()` - Get attendance for a team

Creates views:
- `student_attendance_summary` - Attendance stats per student
- `team_attendance_summary` - Attendance stats per team

### 04_rls_policies.sql
Sets up Row Level Security (access control):

| Feature | Student | Team Leader | Placement Rep |
|---------|:-------:|:-----------:|:-------------:|
| View own attendance | ✅ | ✅ | ✅ |
| View team attendance | ❌ | ✅ | ✅ |
| View ALL attendance | ❌ | ❌ | ✅ |
| Mark team attendance | ❌ | ✅ | ✅ |
| Mark ANY attendance | ❌ | ❌ | ✅ |
| Edit ANY attendance | ❌ | ❌ | ✅ |
| Delete attendance | ❌ | ❌ | ✅ |

### 05_sample_data.sql
*(Optional)* Creates sample data:
- Scheduled class dates
- Marks all students PRESENT for today
- Utility queries for common operations

---

## 🔧 Common Operations

### Mark Attendance for Today
```sql
INSERT INTO attendance_records (user_id, date, team_id, status, marked_by)
SELECT 
    u.id, CURRENT_DATE, u.team_id, 'PRESENT',
    (SELECT id FROM users WHERE roles->>'isPlacementRep' = 'true' LIMIT 1)
FROM users u
WHERE u.roles->>'isStudent' = 'true'
ON CONFLICT (user_id, date) DO UPDATE SET status = 'PRESENT';
```

### Mark Specific Students Absent
```sql
UPDATE attendance_records ar
SET status = 'ABSENT'
FROM users u
WHERE ar.user_id = u.id
  AND ar.date = CURRENT_DATE
  AND u.email IN (
      '25mx101@psgtech.ac.in',
      '25mx102@psgtech.ac.in'
  );
```

### View Attendance Summary
```sql
SELECT name, reg_no, team_id, present_count, absent_count, attendance_percentage
FROM student_attendance_summary
ORDER BY attendance_percentage DESC;
```

### View Team Summary
```sql
SELECT team_id, total_members, avg_attendance_percentage
FROM team_attendance_summary
ORDER BY team_id;
```

### Find Long Absentees (3+ consecutive days)
```sql
SELECT u.name, u.reg_no, COUNT(*) as consecutive_absences
FROM attendance_records ar
JOIN users u ON ar.user_id = u.id
WHERE ar.status = 'ABSENT'
  AND ar.date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY u.id, u.name, u.reg_no
HAVING COUNT(*) >= 3
ORDER BY consecutive_absences DESC;
```

---

## 👥 User Roles

| Role | Description | Count |
|------|-------------|-------|
| `isStudent` | All students | 123 |
| `isTeamLeader` | Team leaders (one per team) | 21 |
| `isCoordinator` | Coordinators | 4 |
| `isPlacementRep` | Placement Representative | 1 |

**Placement Rep:** Tino Britty J (`25mx354@psgtech.ac.in`)

---

## 📊 Database Schema

```
┌─────────────────────┐     ┌─────────────────────┐
│       users         │     │      whitelist      │
├─────────────────────┤     ├─────────────────────┤
│ id (PK, FK→auth)    │     │ email (PK)          │
│ email               │←────│ name                │
│ reg_no              │     │ reg_no              │
│ name                │     │ batch               │
│ team_id             │     │ team_id             │
│ batch               │     │ roles               │
│ roles (JSONB)       │     │ leetcode_username   │
│ leetcode_username   │     └─────────────────────┘
└─────────────────────┘
         │
         ▼
┌─────────────────────┐     ┌─────────────────────┐
│ attendance_records  │     │  leetcode_stats     │
├─────────────────────┤     ├─────────────────────┤
│ id (PK)             │     │ username (PK)       │
│ user_id (FK→users)  │     │ total_solved        │
│ date                │     │ easy_solved         │
│ team_id             │     │ medium_solved       │
│ status              │     │ hard_solved         │
│ marked_by           │     │ ranking             │
│ UNIQUE(user_id,date)│     └─────────────────────┘
└─────────────────────┘
```

---

## ❓ Troubleshooting

### "Permission denied" error
Make sure you ran `04_rls_policies.sql` and the user has the correct role.

### "duplicate key" error
The data already exists. Use `ON CONFLICT DO UPDATE` or delete existing data first.

### Views not showing data
Run `03_functions.sql` again to recreate the views after schema changes.

### Attendance not saving
Check that:
1. `team_id` is included (NOT NULL constraint)
2. `user_id` matches a user in the `users` table
3. Date is valid

---

## 🔄 Reset Database

To completely reset and start fresh:

```sql
-- Drop all tables (DANGEROUS!)
DROP TABLE IF EXISTS notification_reads CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS attendance_records CASCADE;
DROP TABLE IF EXISTS scheduled_attendance_dates CASCADE;
DROP TABLE IF EXISTS daily_tasks CASCADE;
DROP TABLE IF EXISTS leetcode_stats CASCADE;
DROP TABLE IF EXISTS whitelist CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS attendance_days CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;

-- Then run all scripts again in order
```

---

## 📞 Support

For issues, contact the development team or check the Flutter app logs.
