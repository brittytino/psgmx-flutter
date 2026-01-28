# Changelog

All notable changes to PSG MCA Placement Prep App will be documented in this file.

## [1.0.0] - 2026-01-28

### Production Release

#### ✨ Features
- Complete OTP-based authentication system with password setup
- LeetCode stats integration with real-time leaderboard
- Team-based attendance marking system (all 123 students from whitelist)
- Announcement system with auto-expiry functionality
- Birthday notifications
- Role-based access control (Student, Team Leader, Coordinator, Placement Rep)
- Modern Material 3 UI with dark mode support
- Progress indicators for LeetCode API fetching

#### 🔧 Fixed Issues
- OTP flow now requires password before account creation (single-step form)
- Birthday notification permission errors on Android 12+ (inexact alarms)
- LeetCode API progress indicators with real-time status
- Leaderboard UI overflow (48px) resolved
- Attendance system fetches from whitelist (all students available)
- All opacity assertion errors fixed

#### 🏗️ Architecture
- Provider-based state management
- Supabase backend with PostgreSQL
- RESTful API integration for LeetCode stats
- Row-Level Security (RLS) policies
- Whitelist as source of truth for student roster

#### 📱 Platform Support
- ✅ Android (API 21+)
- ✅ iOS (iOS 12.0+)

---
- Server-side attendance lock enforcement
- Audit logging for admin actions

### Known Limitations
- Requires Firebase Free plan or higher
- Offline mode has limited functionality
- Maximum 123 concurrent users (seeded)

---

## Future Releases

### [1.1.0] - Planned
- Admin dashboard improvements
- Enhanced reporting features
- Batch operations for team management
- Push notifications support

### [1.2.0] - Planned
- Dark mode theme optimization
- Localization support
- Web platform support
- Advanced analytics

---

**For more details, see [README.md](README.md)**
