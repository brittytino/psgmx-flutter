# Changelog

All notable changes to PSG MCA Placement Prep App will be documented in this file.

## [1.0.0] - 2026-01-21

### Initial Release

#### Added
- Flutter mobile application with Material 3 design
- Firebase email link authentication (@psgtech.ac.in only)
- Role-based access control (Student, Team Leader, Coordinator, Placement Rep)
- Attendance tracking with 8 PM server-side lock
- Daily task management with LeetCode and CS topics
- Responsive UI with adaptive layout (mobile/tablet)
- Offline support with local caching
- Firestore Rules for security and business logic
- User seeding script for initial data population
- Comprehensive error handling and logging

#### Architecture
- Free Tier Firebase (no scheduled Cloud Functions)
- Provider for state management
- GoRouter for navigation
- MVVM pattern for code organization

#### Security
- Email domain validation
- Whitelist-based onboarding
- Role-based Firestore Rules
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
