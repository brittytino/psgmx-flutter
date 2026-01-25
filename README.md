# PSGMX - Placement Prep App

**A comprehensive placement preparation companion for PSG Technology MCA batch (2025-2027).**

Built with  using **Flutter** and **Supabase**.

![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white) 
![Supabase](https://img.shields.io/badge/Supabase-Production-3ECF8E?logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
[![Build and Release](https://github.com/brittytino/psgmx-flutter/actions/workflows/release.yml/badge.svg)](https://github.com/brittytino/psgmx-flutter/actions/workflows/release.yml)


---

##  Features

###  For Students
- **Daily Attendance**: QR-code style or manual team leader marking.
- **Placement Tasks**: Daily LeetCode challenges and Core CS topic prep.
- **Announcements**: Real-time notifications for placement drives and deadlines.
- **Analytics**: Track your attendance and LeetCode solving streaks.
- **Personalized Dashboard**: View your specific status and upcoming tasks.

###  For Team Leaders & Coordinators
- **Attendance Management**: Mark attendance for your assigned team members.
- **Task Verification**: Tracking completion of assigned placement work.
- **Broadcast System**: Send announcements to all students or specific groups.
- **Reports**: View batch-wide statistics (Simulated Admin/Rep views).

---

##  Tech Stack

*   **Frontend**: Flutter (Mobile - Android & iOS)
*   **Backend & DB**: Supabase (PostgreSQL, Auth, Realtime)
*   **State Management**: Provider
*   **Architecture**: Service-Repository Pattern with Feature-first folder structure.

---

##  Project Structure

```
lib/
 core/            # App-wide configurations (Theme, Constants, Routes)
 models/          # Data models (AppUser, Announcement, LeetCodeStats)
 providers/       # State management (UserProvider, AnnouncementProvider)
 services/        # External API calls (Supabase, Notifications, Quotes)
 ui/              # Screens and Widgets
    attendance/  # Attendance marking & viewing
    home/        # Dashboard (Role-adaptive)
    profile/     # User profile & Settings
    tasks/       # Daily tasks & Challenges
 main.dart        # Entry point
```

---

##  Role-Based Access Control

The app strictly enforces roles via Supabase RLS and App Logic:

1.  **Student**: View only own data, tasks, and public announcements.
2.  **Team Leader**: Can mark attendance for their specific team.
3.  **Placement Rep**: Full access to batch data, create announcements, manage tasks.
4.  **Coordinator**: View reports and assist Reps.

*(Note: Admin features in the current build may be simulated for demonstration via the Profile > Dev Tools section)*

---

##  Setup & Installation

### Prerequisites
*   Flutter SDK (3.27.0 or later)
*   Supabase Account (Free Tier)

### 1. Clone the Repository
```bash
git clone https://github.com/brittytino/psgmx-flutter.git
cd psgmx-flutter
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Build the App
**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release --no-codesign
```

---

##  Community & Support

- **Contributing**: Check out our [Contributing Guide](CONTRIBUTING.md) to get started.
- **Code of Conduct**: We expect all contributors to follow our [Code of Conduct](CODE_OF_CONDUCT.md).
- **Security**: Please report vulnerabilities according to our [Security Policy](SECURITY.md).
- **Issues**: Use [GitHub Issues](../../issues) for bug reports and feature requests.

---

**© 2026 PSG Placement Team**

