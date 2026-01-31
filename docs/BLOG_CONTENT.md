# PSGMX - Placement Preparation App

A comprehensive placement preparation companion built for PSG Technology MCA batch (2025-2027). This mobile application streamlines attendance tracking, LeetCode progress monitoring, and placement-related communications.

---

## Product Overview

PSGMX is a Flutter-based mobile application designed to manage the placement preparation workflow for MCA students. It connects to a Supabase backend for real-time data synchronization and secure authentication.

### Core Modules

| Module | Description |
|--------|-------------|
| **Attendance** | Team leaders mark daily attendance for their assigned groups |
| **LeetCode Tracker** | Real-time leaderboard with stats fetched from LeetCode API |
| **Announcements** | Placement reps broadcast updates with auto-expiry |
| **Tasks** | Daily challenges and Core CS topic assignments |
| **Reports** | Batch-wide statistics and individual progress |

### Role-Based Access

| Role | Permissions |
|------|-------------|
| **Student** | View own attendance, tasks, announcements, and LeetCode stats |
| **Team Leader** | Mark attendance for assigned team members |
| **Coordinator** | View reports and assist placement reps |
| **Placement Rep** | Full access: create announcements, manage tasks, view all data |

### Technical Specifications

- **Framework**: Flutter 3.27+
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **State Management**: Provider
- **Platforms**: Android (API 21+), iOS (12.0+)
- **Architecture**: Service-Repository pattern with feature-first structure

---

## Features

### For Students

- **Daily Attendance**: View your attendance status and history
- **Placement Tasks**: Access daily LeetCode challenges and Core CS prep materials
- **Announcements**: Receive real-time notifications for placement drives and deadlines
- **LeetCode Stats**: Track your solving streaks on a live leaderboard
- **Personalized Dashboard**: Role-adaptive home screen with relevant information
- **Birthday Notifications**: Get notified about classmates' birthdays

### For Team Leaders

- **Team Attendance**: Mark attendance for your team members in a single tap
- **Member List**: View your team roster with contact details
- **Status Overview**: Check who has marked attendance for the day

### For Placement Reps

- **Broadcast System**: Send announcements to all students or specific groups
- **Task Management**: Create and assign daily tasks
- **Reports**: Access batch-wide attendance and performance statistics
- **User Management**: View and manage student roster

---

## Installation Guide

### Android Installation

#### Method 1: Direct APK Download (Recommended)

1. Open browser on your Android device
2. Go to: **https://github.com/brittytino/psgmx-flutter/releases/latest**
3. Download `app-release.apk`
4. If prompted, allow installation from unknown sources:
   - Go to **Settings > Security > Install unknown apps**
   - Enable permission for your browser
5. Open the downloaded APK file
6. Tap **Install**
7. Once installed, tap **Open** to launch the app

#### Method 2: Using QR Code

Scan the QR code below to directly download the latest APK:

```
[Generate QR code pointing to your releases page]
```

#### Troubleshooting Android Installation

| Issue | Solution |
|-------|----------|
| "App not installed" error | Enable **Unknown Sources** in Settings > Security |
| "Parse error" | Ensure you downloaded the complete file. Re-download if interrupted |
| App crashes on launch | Ensure Android version is 5.0 (Lollipop) or higher |
| Play Protect warning | Tap **Install Anyway** - the app is not on Play Store yet |

---

### iOS Installation

iOS installation requires additional steps since the app is distributed as an unsigned IPA.

#### Prerequisites

- macOS computer with Xcode installed
- Apple Developer account (free tier works)
- iOS device connected via USB
- AltStore or Sideloadly installed on your computer

#### Method 1: Using AltStore (Recommended)

**Step 1: Install AltStore on your computer**

1. Download AltStore from: **https://altstore.io**
2. Install AltServer on your Mac or Windows PC
3. Connect your iPhone via USB

**Step 2: Install AltStore on your iPhone**

1. Open AltServer on your computer
2. Click the AltServer icon in menu bar (Mac) or system tray (Windows)
3. Select **Install AltStore > [Your Device Name]**
4. Enter your Apple ID and password
5. AltStore will appear on your iPhone

**Step 3: Install PSGMX**

1. Download `psgmx_ios_unsigned.ipa` from:
   **https://github.com/brittytino/psgmx-flutter/releases/latest**
2. Transfer the IPA to your iPhone using AirDrop or Files app
3. Open AltStore on your iPhone
4. Go to **My Apps** tab
5. Tap **+** button and select the IPA file
6. The app will install and appear on your home screen

#### Method 2: Using Sideloadly

1. Download Sideloadly from: **https://sideloadly.io**
2. Connect your iPhone via USB
3. Open Sideloadly and drag the IPA file into the window
4. Enter your Apple ID credentials
5. Click **Start** to begin installation
6. Trust the developer certificate on your iPhone:
   - Go to **Settings > General > VPN & Device Management**
   - Tap your Apple ID under Developer App
   - Tap **Trust**

#### Troubleshooting iOS Installation

| Issue | Solution |
|-------|----------|
| "Unable to install" | Ensure you have a valid Apple ID signed in |
| App expires after 7 days | Re-install using AltStore. Free accounts require refresh every 7 days |
| "Untrusted Developer" | Go to Settings > General > VPN & Device Management and trust the certificate |
| AltStore not showing device | Ensure iTunes/Finder recognizes your device first |

---

## First-Time Setup

### Account Registration

1. Launch the PSGMX app
2. Enter your registered email (must be in the student whitelist)
3. Check your email for the OTP code
4. Enter the OTP and set your password
5. Your profile will auto-populate from the whitelist data

### Profile Information

Your profile includes:
- Name and Registration Number
- Batch and Team assignment
- LeetCode username (for leaderboard tracking)
- Role permissions

---

## How to Use

### Dashboard

The home screen displays:
- Today's attendance status
- Current announcements
- LeetCode streak and rank
- Quick actions based on your role

### Marking Attendance (Team Leaders)

1. Navigate to **Attendance** tab
2. Select the date (if marking for today)
3. Toggle attendance for each team member
4. Tap **Submit** to save

### Viewing LeetCode Leaderboard

1. Navigate to **Leaderboard** from the home screen
2. View rankings sorted by problems solved
3. Tap any student to see detailed stats
4. Pull down to refresh with latest data

### Announcements

1. Go to **Notifications** tab
2. View all active announcements
3. Expired announcements are automatically hidden
4. Placement Reps can create new announcements from this screen

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.7 | Jan 2026 | Latest stable release |
| 1.0.5 | Jan 28, 2026 | OTP auth fix, LeetCode integration, Android 12+ compatibility |

---

## System Requirements

### Android
- Android 5.0 (Lollipop) or higher
- 50 MB free storage
- Internet connection required

### iOS
- iOS 12.0 or higher
- 80 MB free storage
- Internet connection required

---

## Privacy & Security

- All data is stored securely on Supabase with Row-Level Security (RLS)
- Authentication uses secure OTP-based email verification
- No personal data is shared with third parties
- LeetCode data is fetched from public profiles only

---

## Support

- **Issues**: https://github.com/brittytino/psgmx-flutter/issues
- **Repository**: https://github.com/brittytino/psgmx-flutter

---

## License

MIT License - See [LICENSE](https://github.com/brittytino/psgmx-flutter/blob/main/LICENSE) for details.

---

*Built with Flutter and Supabase by PSG Placement Team © 2026*
