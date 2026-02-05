# 🗄️ Database Setup Guide

Complete PostgreSQL/Supabase database schema for PSGMX Placement Prep App.

## 📋 Quick Start

Run these SQL files in order in your Supabase SQL Editor:

1. **01_schema.sql** - Creates all tables, indexes, and extensions
2. **02_data.sql** - Inserts 123 students into whitelist
3. **03_functions.sql** - Creates database functions and triggers
4. **04_rls_policies.sql** - Sets up Row Level Security
5. **05_sample_data.sql** - (Optional) Adds sample announcements and attendance
6. **09_app_config.sql** - App version control configuration
7. **migrations/** - Run any migration scripts if updating existing database

## 📁 File Structure

```
database/
├── README.md                    # This file
├── 01_schema.sql               # Database tables and structure
├── 02_data.sql                 # Student data (123 students)
├── 03_functions.sql            # Database functions and triggers
├── 04_rls_policies.sql         # Security policies
├── 05_sample_data.sql          # Sample data for testing
├── 09_app_config.sql           # App update configuration
└── migrations/                 # Database migrations
    └── add_is_working_day.sql  # Adds is_working_day column
```

## 🔧 Setup Instructions

### 1. Create a Supabase Project
- Go to [supabase.com](https://supabase.com)
- Create a new project
- Note down your project URL and anon key

### 2. Run Database Scripts
```sql
-- In Supabase SQL Editor, run each file in order:
-- 1. Copy contents of 01_schema.sql → Execute
-- 2. Copy contents of 02_data.sql → Execute
-- 3. Copy contents of 03_functions.sql → Execute
-- 4. Copy contents of 04_rls_policies.sql → Execute
-- 5. Copy contents of 05_sample_data.sql → Execute (optional)
-- 6. Copy contents of 09_app_config.sql → Execute
```

### 3. Enable Email Auth
- Go to Authentication → Providers
- Enable Email provider
- Configure email templates if needed

### 4. Get API Keys
- Go to Settings → API
- Copy `Project URL` and `anon public` key
- These will be used in your Flutter app

## 🗂️ Database Tables

### Core Tables
- **users** - All user data (students, leaders, coordinators, reps)
- **whitelist** - Approved email list (123 students)
- **teams** - Team information (21 teams)

### Attendance System
- **scheduled_attendance_dates** - Class day schedules
- **attendance_records** - Individual attendance records

### Communication
- **announcements** - Placement announcements and updates
- **notifications** - User notifications

### LeetCode Integration
- **leetcode_stats** - Student LeetCode progress tracking

### Audit
- **audit_logs** - System activity tracking

### Configuration
- **app_config** - App version control and updates

## 🔒 Security

All tables have Row Level Security (RLS) enabled. Policies ensure:
- Students can only see their own data
- Team leaders can manage their team
- Coordinators have broader access
- Placement reps have full access

## 🚀 Migrations

When updating an existing database, run migration scripts:

```sql
-- Example: Adding new column
-- Copy contents of migrations/add_is_working_day.sql → Execute
```

## 📊 Sample Data

File `05_sample_data.sql` includes:
- Sample announcements
- Sample attendance dates
- Test data for development

**Note**: Skip this file in production if you don't want sample data.

## 🔍 Verification

After setup, verify tables were created:

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check student count
SELECT COUNT(*) FROM whitelist;  -- Should return 123

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

## 🆘 Troubleshooting

### Issue: "relation does not exist"
- Ensure you ran 01_schema.sql first
- Check for any errors in the SQL execution

### Issue: "permission denied"
- Verify RLS policies in 04_rls_policies.sql were applied
- Check user authentication is working

### Issue: "column does not exist"
- Run the migration scripts in migrations/ folder
- Check schema is up to date

## 📞 Support

For database issues:
1. Check Supabase logs in Dashboard → Database → Logs
2. Verify all SQL scripts executed without errors
3. Review RLS policies if access issues occur

## 🔄 Backup

Always backup before making changes:
- Supabase Dashboard → Database → Backups
- Can restore to any point in time
