# Database Migration Guide

## Team Leader Verification Feature - Database Setup

### Overview
This migration adds verification tracking to the `task_completions` table, allowing team leaders to verify task completions submitted by their team members.

### Changes Made
1. Added `verified_by` column - UUID reference to the user who verified
2. Added `verified_at` column - Timestamp of verification
3. Added performance indexes for verification queries

---

## Step-by-Step Migration Instructions

### Step 1: Access Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** from the left sidebar
3. Click **New Query**

### Step 2: Run the Migration Script
Copy and paste the contents of `MIGRATION_add_verification.sql` into the SQL Editor and click **Run**.

**Or** run these commands directly:

```sql
-- Add verified_by column
ALTER TABLE task_completions 
ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Add verified_at column
ALTER TABLE task_completions 
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_task_completions_verified_by 
ON task_completions(verified_by);

CREATE INDEX IF NOT EXISTS idx_task_completions_verified_at 
ON task_completions(verified_at);

CREATE INDEX IF NOT EXISTS idx_task_completions_date_verified 
ON task_completions(task_date, verified_by);
```

### Step 3: Verify Migration Success
Run this query to confirm the new columns exist:

```sql
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'task_completions'
AND table_schema = 'public'
ORDER BY ordinal_position;
```

You should see `verified_by` and `verified_at` in the column list.

---

## Table Structure (After Migration)

```
task_completions
├── id (UUID, PRIMARY KEY)
├── user_id (UUID, NOT NULL, FK → users.id)
├── task_date (DATE, NOT NULL)
├── completed (BOOLEAN, DEFAULT false)
├── completed_at (TIMESTAMPTZ)
├── verified_by (UUID, FK → users.id)           ← NEW
├── verified_at (TIMESTAMPTZ)                    ← NEW
├── created_at (TIMESTAMPTZ)
└── updated_at (TIMESTAMPTZ)

UNIQUE CONSTRAINT: (user_id, task_date)
```

---

## How It Works in the App

### Team Leader View
1. Team leaders navigate to **Tasks** → **Team Verification** tab
2. They see a list of their team members with task completion status
3. For each member, they can:
   - Click **Completed** (green) to verify task as done
   - Click **Incomplete** (orange) to mark task as not done
4. Verification is saved with:
   - `verified_by` = Team leader's user ID
   - `verified_at` = Current timestamp

### Reports View (Placement Representatives)
1. Navigate to **Reports** → **Task Completion** section
2. Click on task completion percentage to see details
3. Filter options now include:
   - **All** - All students
   - **Completed** - Tasks marked as completed
   - **Verified** - Tasks that have been verified by team leaders
   - **Pending** - Tasks not yet completed
4. Each student entry shows:
   - Completion status badge
   - Blue "Verified" badge if verified
   - "Verified by [name]" subtitle showing who verified

---

## API Queries Used

### Load Team Members with Verification Status
```dart
// Get users in team
supabase.from('users')
  .select('id, email, name, reg_no')
  .eq('team_id', teamId)
  
// Get completions with verification
supabase.from('task_completions')
  .select('user_id, completed, verified_by, verified_at')
  .eq('task_date', dateStr)
  .inFilter('user_id', memberIds)
```

### Verify Task Completion
```dart
supabase.from('task_completions').upsert({
  'user_id': studentId,
  'task_date': dateStr,
  'completed': isCompleted,
  'completed_at': isCompleted ? now : null,
  'verified_by': teamLeaderId,
  'verified_at': now,
}, onConflict: 'user_id,task_date')
```

### Get All Students with Verification
```dart
supabase.from('users')
  .select('''
    id, name, reg_no, team_id,
    task_completions!left(
      completed, 
      completed_at, 
      task_date, 
      verified_by, 
      verified_at
    )
  ''')
  .contains('roles', {'isStudent': true})
```

---

## Testing Checklist

After running the migration, test these scenarios:

- [ ] Team leader can see their team members in Team Verification tab
- [ ] Clicking "Completed" saves verification to database
- [ ] Clicking "Incomplete" updates verification status
- [ ] Blue "Verified" badge appears after verification
- [ ] Reports screen shows verification filter chip
- [ ] Reports screen shows "Verified by [name]" for verified tasks
- [ ] Date navigator works for checking different dates
- [ ] Pull-to-refresh reloads team data correctly

---

## Rollback (If Needed)

If you need to remove the verification columns:

```sql
-- Remove indexes
DROP INDEX IF EXISTS idx_task_completions_verified_by;
DROP INDEX IF EXISTS idx_task_completions_verified_at;
DROP INDEX IF EXISTS idx_task_completions_date_verified;

-- Remove columns
ALTER TABLE task_completions DROP COLUMN IF EXISTS verified_by;
ALTER TABLE task_completions DROP COLUMN IF EXISTS verified_at;
```

---

## Troubleshooting

### Error: "column verified_by does not exist"
**Solution**: Run the migration script again. The columns weren't added.

### Error: "relation task_completions does not exist"
**Solution**: Run `10_phase_a_schema.sql` first to create the base table.

### Verification not showing in app
**Solution**: 
1. Check if columns exist: `\d task_completions`
2. Verify data was saved: `SELECT * FROM task_completions WHERE verified_by IS NOT NULL LIMIT 5;`
3. Check app logs for database errors

### Performance issues with large datasets
**Solution**: The indexes should handle large datasets. If still slow, check:
```sql
-- Verify indexes exist
SELECT indexname FROM pg_indexes 
WHERE tablename = 'task_completions';
```

---

## Support

For issues or questions:
1. Check app logs in VS Code terminal
2. Check Supabase logs in dashboard
3. Verify RLS policies allow team leaders to read/write
