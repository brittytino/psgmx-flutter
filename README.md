# 🎓 PSGMX - Placement Excellence Program

<div align="center">

  ![PSGMX Logo](assets/images/psgmx_logo.png)

  > **A mature, closed-community placement preparation ecosystem for PSG Technology - MCA Batch (2025-2027)**
  
  <br>

  [![Version](https://img.shields.io/badge/version-3.1.5-blue.svg)](pubspec.yaml)
  [![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-Production-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
  [![Firebase](https://img.shields.io/badge/Hosting-Firebase-FFCA28?logo=firebase&logoColor=white)](https://firebase.google.com)
  [![Downloads](https://img.shields.io/github/downloads/brittytino/psgmx-flutter/total?label=Downloads&color=2ea44f)](https://github.com/brittytino/psgmx-flutter/releases)
  [![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Web%20|%20Android-lightgrey)](#)

</div>

---

## 📖 Overview

**PSGMX** is an enterprise-grade academic management platform architected to streamline the placement lifecycle for 123 MCA students. It eliminates manual tracking by unifying attendance, technical preparation (LeetCode), and real-time communication into a single, cohesive ecosystem.

Built with **Flutter** for a responsive cross-platform experience and **Supabase** for robust real-time backend services, it demonstrates a modern, scalable approach to educational software.

---

## ✨ Key Features

### 👨‍🎓 **Student Hub**
- **📊 Live LeetCode Analytics** - Automatic profile syncing and unified dashboard for problem-solving milestones.
- **✅ Smart Attendance** - QR-based digital attendance with "Is Working Day" validation logic.
- **📢 Batch Broadcasts** - Real-time placement alerts, deadline reminders, and prioritized announcements.
- **📅 Daily Targets** - Structured technical tasks with completion tracking and streaks.
- **🎂 Community Spirit** - Automated birthday wishes and peer recognition systems.

### 👥 **Leadership Tools** (Team Leaders)
- **📋 Squad Management** - Team-specific dashboards to monitor member progress.
- **✓ Verification Workflows** - One-click validation for team task completion.
- **📊 Team Insights** - Comparative analytics to identify at-risk students.

### 🎯 **Administration** (Coordinators)
- **🛡️ Audit Trails** - Comprehensive logging of all critical actions (Attendance modifications, Data exports).
- **📝 Batch Management** - Bulk data handling and whitelist controls.
- **🔄 Remote App Control** - `AppConfig` system to force updates or trigger emergency maintenance modes remotely.
- **📣 Broadcast & Notification** - Powerful push notification triggers for immediate reach.

---

## 🛠️ Tech Stack & Architecture

The application follows a **Service-Oriented Architecture (SOA)** with a clear separation of concerns using the Provider pattern.

| Layer | Technologies | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter 3.27+ | Material 3 Design, Responsive Layouts (Web/Mobile) |
| **State Management** | Provider | Scoped instances for Authentication, Data, and UI state |
| **Backend** | Supabase | PostgreSQL Database, Auth, Storage, Edge Functions |
| **Hosting** | Firebase | Global CDN hosting for the Web App |
| **DevOps** | GitHub Actions | CI/CD pipelines for automated web deployment |

---

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.27 or higher)
*   [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)
*   A Supabase Project (Free Tier works)

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/brittytino/psgmx-flutter.git
    cd psgmx-flutter
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**
    Create a `.env` file in the project root:
    ```env
    SUPABASE_URL=your_supabase_project_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```
    *(Refer to `lib/core/constants/supabase_constants.dart` for integration details)*

4.  **Database Initialization**
    The database structure has been consolidated for easy setup. Run these SQL files in your Supabase SQL Editor in order:
    
    | Seq | File | Purpose |
    | :--- | :--- | :--- |
    | 1 | `database/01_schema.sql` | **Core Schema**: Tables, indexes, and extensions |
    | 2 | `database/02_policies.sql` | **Security**: Application of RLS policies |
    | 3 | `database/03_functions.sql` | **Logic**: Helper functions, trigger functions, views |
    | 4 | `database/04_triggers.sql` | **Automation**: Notification triggers & audit mechanisms |
    | 5 | `database/05_seed_data.sql` | **Seed**: Whitelist 123 students & default App Config |

    > 📘 **Full DB Documentation:** See [database/README.md](database/README.md)

5.  **Run the Application**
    ```bash
    # Run on Chrome
    flutter run -d chrome --web-renderer canvaskit

    # Run on Android
    flutter run -d android
    ```

---

## 📁 Project Structure

```
lib/
├── core/              # Global configuration, themes, constants
├── models/            # Type-safe data models (freezed/json_serializable)
├── providers/         # State management controllers
├── services/          # External API integrations (Supabase, LeetCode)
├── ui/                # UI Layer
│   ├── admin/         # Administrative panels
│   ├── auth/          # Authentication flows
│   ├── home/          # Dashboard & navigation
│   ├── tasks/         # Task management & Lists
│   ├── attendance/    # Attendance marking & history
│   ├── leaderboard/   # Gamified ranking system
│   └── widgets/       # Shared UI components
└── main.dart          # Entry point
```

---

## 📦 Deployment

### Web (Firebase Hosting)
This project uses GitHub Actions for continuous deployment.
- **Manual Build:**
  ```bash
  flutter build web --release --web-renderer canvaskit
  firebase deploy --only hosting
  ```
- **Live URL:** [https://psgmxians.web.app](https://psgmxians.web.app)

### Android
- **Build APK:** `flutter build apk --release`
- Releases are managed via GitHub Releases.
- Release pipeline: push to `main` or push a `v*` tag (for example `v2.2.8`) to trigger the Android release workflow.

---

## 🤝 Contributing

Contributions are welcome from the PSG MCA 2025-2027 batch!

1.  **Fork** the project.
2.  **Create** your feature branch (`git checkout -b feature/AmazingFeature`).
3.  **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4.  **Push** to the branch (`git push origin feature/AmazingFeature`).
5.  **Open** a Pull Request.

Please ensure your code passes `flutter analyze` before submitting.

---

## 🔒 Security & Privacy

- **Row Level Security (RLS)**: Strictly enforces data access at the database level.
- **Role-Based Access**: Granular permissions (Student vs. Coordinator vs. Team Leader).
- **Secure Auth**: OTP-based passwordless authentication via Supabase.

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

  **Maintained by Tino Britty J**
  <br>
  [GitHub](https://github.com/brittytino) • [Portfolio](https://tinobritty.me)
  
  *Made with ❤️ for PSG Tech MCA*

</div>
