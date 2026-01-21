# PSG MCA Placement Prep App

A Flutter app for PSG Technology MCA placement batch (2025-2027) with attendance tracking, daily tasks, and role-based access.

**Author**: [Tino Britty J](https://github.com/brittytino) - Placement Representative  
**Purpose**: Built for convenience during placement season 🎓

![Flutter](https://img.shields.io/badge/Flutter-3.2+-blue) ![Firebase](https://img.shields.io/badge/Firebase-Free%20Tier-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## What It Does

- 📧 Email authentication (@psgtech.ac.in only)
- 📋 Daily attendance tracking with 8 PM hard lock
- 💡 LeetCode + CS topics with daily motivation quotes
- 👥 Role-based access (Student, Team Leader, Coordinator, Rep)
- 📱 Works on mobile, tablet, desktop
- ⚡ Free Firebase tier (no paid features needed)

## Quick Setup

### 1. Clone & Install
```bash
git clone https://github.com/brittytino/psgmx-flutter.git
cd psgmx-flutter
flutter pub get
```

### 2. Firebase Setup
- Download `google-services.json` from [Firebase Console](https://console.firebase.google.com)
- Save to `android/app/google-services.json`
- Deploy rules: `firebase deploy --only firestore:rules`

### 3. Seed Test Data
```bash
cd scripts
node seed_users.js
```

### 4. Run
```bash
flutter run
```

## Tech Stack

| Component | Tech |
|-----------|------|
| Frontend | Flutter 3.2+ + Material 3 |
| State | Provider + GoRouter |
| Backend | Firebase Auth + Firestore |
| Architecture | MVVM |

## Login Test Accounts

After seeding, use any email from `scripts/users_master.json`:
```
Email: student@psgtech.ac.in
(Email link sent to console)
```

## Database Schema

| Collection | Purpose |
|-----------|---------|
| `users/` | Student profiles with roles |
| `attendance_submissions/` | Daily team attendance |
| `attendance_records/` | Individual records |
| `daily_tasks/` | LeetCode + CS topics |
| `audit_logs/` | Admin overrides |

## Key Features

### Attendance Lock
- Hard stop at 8 PM (server-side via Firestore Rules)
- Students can submit before 8 PM only
- Team leaders aggregate submissions

### Roles
- **Student**: View & submit attendance, view tasks
- **Team Leader**: Submit team attendance
- **Coordinator**: Full access, manage users
- **Placement Rep**: Override attendance, audit logs

### Daily Tasks
- LeetCode problem + link
- CS topic + description
- Motivation quote

## Build & Deploy

### Build for Devices
```bash
# Android
flutter build apk --debug
flutter build appbundle  # For Play Store

# iOS
flutter build ios
```

### Deploy Backend
```bash
# Firestore rules only (free tier)
firebase deploy --only firestore:rules

# With functions (requires Blaze plan)
firebase deploy --only firestore:rules,functions
```

## Development

```bash
# Run tests
flutter test

# Check code quality
dart analyze

# Format code
dart format lib/
```

## File Structure

```
lib/
├── main.dart              # App initialization
├── core/
│   ├── app_router.dart   # Navigation routes
│   └── theme/            # Material 3 theme
├── models/               # Data models
├── providers/            # State management
├── services/             # Business logic
└── ui/                   # UI screens

functions/src/
├── index.ts              # Auth triggers

scripts/
└── seed_users.js         # Populate test data
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "User not found" on login | Run `node scripts/seed_users.js` |
| Can't submit after 8 PM | Firestore rule intentionally blocks it |
| Firebase not initializing | Check `google-services.json` is in right place |
| Build fails | Run `flutter clean && flutter pub get` |

## Contributing

1. Fork repo
2. Create feature branch: `git checkout -b feature/xyz`
3. Test thoroughly
4. Submit PR

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT - see [LICENSE](LICENSE)

## Code of Conduct

Be respectful to all contributors. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for updates and roadmap.

---

**Built for PSG Technology MCA Placement Batch 2025-2027**

Questions? Open an [issue](https://github.com/brittytino/psgmx-flutter/issues) or [discussion](https://github.com/brittytino/psgmx-flutter/discussions)


## Features

- **Email Link Authentication** - Secure @psgtech.ac.in authentication
- **Role-Based Access Control** - Student, Team Leader, Coordinator, Placement Rep roles
- **Attendance Tracking** - Daily attendance with 8 PM hard lock (enforced by Firestore Rules)
- **Daily Tasks** - LeetCode problems and CS topics with motivation quotes
- **Responsive UI** - Material 3 design with adaptive layout (mobile/tablet/desktop)
- **Offline Ready** - Works with poor connectivity
- **Free Tier** - Designed to run on Firebase Free plan

## Architecture

### Tech Stack
- **Frontend**: Flutter 3.2+, Material 3, Provider state management, GoRouter navigation
- **Backend**: Firebase Auth (email link), Firestore database
- **Infrastructure**: Free tier architecture (no scheduled functions)

### Security Model
- Firestore Rules enforce role-based access
- 8 PM attendance lock enforced server-side
- Email domain validation (@psgtech.ac.in only)
- Whitelist-based user onboarding

## Quick Start

### Prerequisites
- Flutter SDK 3.2 or later
- Android 12+ or iOS 11+
- Firebase project (Free plan)

### Installation

1. **Clone and Setup**
   ```bash
   git clone https://github.com/yourusername/psgmx-flutter.git
   cd psgmx-flutter
   flutter pub get
   ```

2. **Firebase Configuration**
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/`

3. **Seed Initial Data**
   ```bash
   cd scripts
   node seed_users.js
   ```

4. **Run**
   ```bash
   flutter run
   ```

## Project Structure

```
├── lib/
│   ├── main.dart
│   ├── core/app_router.dart
│   ├── models/
│   ├── providers/
│   ├── services/
│   └── ui/
├── functions/src/index.ts
├── firestore.rules
└── scripts/seed_users.js
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

MIT License - see [LICENSE](LICENSE).

---

**Built with ❤️ for PSG Technology Students**
