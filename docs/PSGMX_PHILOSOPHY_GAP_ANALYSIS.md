1️⃣ What you should do RIGHT NOW (Phase A – Core Discipline)

These 4 features directly complete the PSGMX philosophy you defined.
Without them, the app feels informational, not behavioral.

✅ A1. Task Completion Marking (HIGH PRIORITY)

This is the biggest gap.

Why it matters

Attendance ≠ effort

LeetCode ≠ opened link

Completion must be visible

What to implement

Each daily task:

“Mark as Completed” toggle/button

Stored per student, per date

Visible to:

Student (self)

Team Leader (team)

Placement Rep (all)

What NOT to do

Don’t auto-mark on link click

Don’t make it editable forever

This single feature justifies the app’s existence far more than leaderboards.

➡️ Do this first. No excuses.

✅ A2. Notification Preferences – Make Them Real

Right now your toggles are lying.

Why this is dangerous

Users think they disabled notifications

App still sends them

Trust erodes silently

What to do

Persist all notification toggles to DB

Notification service must:

Read DB preferences

Decide send / don’t send

Settings screen must reflect actual state

This is a trust repair task, not a feature.

✅ A3. Attendance Streak (REAL, not fake)

You already show streaks — but they’re hardcoded.

That’s worse than not showing them.

What to do

Calculate:

Consecutive PRESENT class days

Reset on ABSENT

Skip non-class days

Show:

“Current streak: X class days”

Why

Makes consistency visible

Very low cognitive load

Very high motivational value

✅ A4. Visible Attendance Calculation Explanation

This is subtle but important for disputes.

What to show
Instead of just numbers, show a sentence like:

“Calculated from 45 class days
(Excluding 12 non-class days)”

This protects:

Students

Team Leaders

Placement Rep

And it stops WhatsApp arguments before they start.

2️⃣ What to do NEXT (Phase B – Smart Automation)

These reduce manual chasing.

🟡 B1. Automatic Defaulter Flagging (But Be Careful)

You already have manual detection. Now automate it silently first.

Rule

System flags internally when:

3 consecutive absences OR

Attendance < threshold

Phase 1 behavior

Visible ONLY to:

Team Leader

Placement Rep

Do NOT

Push notification to student immediately

Publicly label them

Later, once stable:

Add private student nudge

🟡 B2. Task Deadline Reminder

This is useful, but secondary.

Simple rule

At 9 PM:

If task not completed → reminder

Respect notification preferences

Don’t over-engineer it.

3️⃣ What to do LATER (Phase C – Recognition & Morale)

Nice, but not urgent.

🔵 C1. Weekly Top Performer Announcement

Your leaderboard already exists. This just adds recognition.

Best practice

Weekly push notification:

“This week’s top solver: X”

In-app banner

No need for fancy graphics yet.

🔵 C2. LeetCode Milestones (50 / 100 / 200)

Good for long-term motivation.

But:

Add AFTER task completion is implemented

Otherwise milestones feel disconnected

4️⃣ What you should DELIBERATELY NOT DO (for now)

This is important.

❌ Offline full functionality
Too complex right now, high bug risk. Defer.

❌ More gamification (XP, levels, coins)
Destroys seriousness.

❌ Student-visible defaulter labels
Will cause resentment and politics.

❌ Auto-punishments
Never automate punishment. Only detection.

5️⃣ So… “now what do I do?” (Clear answer)
👉 Immediate action plan (in order)

Step 1
Implement Task Completion Marking

UI

DB table

Reports integration

Step 2
Fix Notification Preference persistence

DB-backed

Notification logic respects it

Step 3
Replace hardcoded attendance streak

Real calculation

Skip non-class days

Step 4
Add attendance calculation explanation

One line UI change

Huge impact

Stop here. Ship this.

6️⃣ One honest product truth (important)

Right now, your app answers:

“What happened?”

After Phase A, it will answer:

“What did YOU do today?”

That’s the difference between:

A tracker

And a discipline system

You’re extremely close to crossing that line.