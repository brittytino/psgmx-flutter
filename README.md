# 🎓 PSGMX - Placement Excellence Program

> A comprehensive placement preparation platform for PSG Technology - MCA Batch (2025-2027)

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Production-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## ✨ Features

### 👨‍🎓 For Students
- **📊 LeetCode Integration** - Track daily problem-solving progress
- **✅ Attendance Tracking** - QR-based or manual attendance marking
- **📢 Real-time Announcements** - Instant placement updates and deadlines
- **📈 Performance Analytics** - Personal dashboard with streaks and statistics
- **🎂 Birthday Celebrations** - Automated birthday greetings

### 👥 For Team Leaders
- **📋 Team Management** - Mark attendance for assigned team members
- **✓ Task Verification** - Track team's LeetCode completion
- **📊 Team Analytics** - View team performance metrics

### 🎯 For Coordinators & Placement Reps
- **📣 Broadcast System** - Send announcements to all students
- **📈 Batch Statistics** - Complete batch performance overview
- **🔐 Admin Controls** - Manage users and system configuration

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.27 or higher
- Dart 3.0 or higher
- Supabase account
- Git

### 1. Clone Repository
```bash
git clone https://github.com/your-username/psgmx-flutter.git
cd psgmx-flutter
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Supabase Database
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run database scripts in order (see [database/README.md](database/README.md)):
   - `01_schema.sql`
   - `02_data.sql`
   - `03_functions.sql`
   - `04_rls_policies.sql`
   - `05_sample_data.sql`
   - `09_app_config.sql`

### 4. Configure Environment
Create `.env` file in project root:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 5. Run the App
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 📦 Build for Production

### Web (For Vercel Deployment)
```bash
flutter build web --release --web-renderer canvaskit
```

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

---

## 🌐 Deploy to Vercel

### Quick Deploy
```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

### Environment Variables in Vercel

Configure these in Vercel Dashboard → Project → Settings → Environment Variables:

```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Note**: For Flutter Web, environment variables are compiled into the build. You need to pass them during build:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

### Vercel Configuration
The `vercel.json` file is already configured with:
- Optimized caching strategy
- Security headers (CSP, X-Frame-Options, etc.)
- SPA routing for Flutter Web

---

## 📁 Project Structure

```
lib/
├── core/              # App configuration, theme, constants
├── models/            # Data models (User, Announcement, etc.)
├── providers/         # State management (Provider pattern)
├── services/          # API services (Supabase, LeetCode, etc.)
└── ui/                # Screens and widgets
    ├── auth/          # Authentication screens
    ├── home/          # Dashboard and home screen
    ├── attendance/    # Attendance tracking
    ├── leaderboard/   # LeetCode leaderboard
    ├── profile/       # User profile
    └── widgets/       # Reusable widgets

database/
├── 01_schema.sql      # Database tables and structure
├── 02_data.sql        # Student data (123 students)
├── 03_functions.sql   # Database functions
├── 04_rls_policies.sql # Security policies
├── 05_sample_data.sql # Sample/test data
├── 09_app_config.sql  # App configuration
└── migrations/        # Database migration scripts
```

---

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.27+ (Web, Android, iOS)
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **State Management**: Provider
- **Architecture**: Feature-first with service layer
- **Deployment**: Vercel (Web), GitHub Releases (APK)

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community guidelines.

---

## 📊 Database Schema

Complete database documentation available in [database/README.md](database/README.md)

**Key Tables**:
- `users` - Student and admin profiles
- `whitelist` - Approved email list (123 students)
- `attendance_records` - Attendance tracking
- `leetcode_stats` - LeetCode progress
- `announcements` - Placement updates
- `notifications` - User notifications

---

## 🔒 Security

- Row Level Security (RLS) enabled on all tables
- Email-based OTP authentication
- Role-based access control (Student, Team Leader, Coordinator, Placement Rep)
- Secure API key management

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- PSG College of Technology - MCA Department
- All 123 students of MCA Batch 2025-2027
- Open source Flutter and Supabase communities

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/psgmx-flutter/issues)
- **Email**: support@psgmx.com
- **Documentation**: [Wiki](https://github.com/your-username/psgmx-flutter/wiki)

---

## 🎯 Roadmap

- [x] Basic authentication and user management
- [x] LeetCode integration and leaderboard
- [x] Attendance tracking system
- [x] Real-time announcements
- [x] Web deployment on Vercel
- [ ] Push notifications for mobile
- [ ] Advanced analytics dashboard
- [ ] Interview preparation resources
- [ ] Company-specific preparation modules

---

**Made with ❤️ by PSG MCA Batch 2025-2027**
