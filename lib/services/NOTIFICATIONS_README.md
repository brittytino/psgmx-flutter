# PSGMX Notification System

## Overview
The PSGMX app features a comprehensive notification system with beautiful mobile-friendly push notifications, in-app notification management, and customizable notification types.

## Features

### ✨ Push Notifications
- **Beautiful Design**: Styled notifications with custom colors, icons, and BigText layout
- **Sound & Vibration**: Default system sound with vibration patterns
- **LED Indicator**: Orange LED light indicator for notifications
- **Multiple Types**: Announcements, Reminders, Alerts, and Motivation messages
- **Rich Content**: BigText style for longer messages with type indicators

### 🔔 In-App Notifications
- **Notification Badge**: Unread count badge on all bell icons throughout the app
- **Grouped by Date**: Notifications organized by TODAY, YESTERDAY, and older dates
- **Type Icons & Colors**: Each notification type has unique icon and color
- **Mark as Read**: Tap to mark individual notifications as read
- **Swipe to Delete**: Swipe notifications to remove them
- **Filter Tabs**: View All, Unread, or Important (Alerts) notifications

### 🎯 Notification Types

1. **📢 Announcement** (Orange) - General announcements and updates
2. **⏰ Reminder** (Blue) - Task reminders and deadlines
3. **⚠️ Alert** (Red) - Important alerts requiring attention
4. **✨ Motivation** (Purple) - Motivational messages and encouragement

## Usage

### Sending Notifications

```dart
// Get the service
final notifService = Provider.of<NotificationService>(context, listen: false);

// Request permissions first (especially on Android 13+)
final hasPermission = await notifService.requestPermissions();
if (!hasPermission) {
  // Show error message
  return;
}

// Send test notification
await notifService.showTestNotification();

// Send custom notifications
await notifService.showAnnouncementNotification(
  'Google Drive Tomorrow',
  'Prepare your resume and portfolio for the Google placement drive.',
);

await notifService.showReminderNotification(
  'LeetCode Daily Challenge',
  'Don\'t forget to solve today\'s problem to maintain your streak!',
);

await notifService.showMotivationalNotification(
  'Every problem you solve makes you stronger! Keep pushing forward! 💪',
);

await notifService.showAlertNotification(
  'Attendance Below 75%',
  'Your attendance has dropped to 72%. Please maintain minimum 75% to be eligible for placements.',
);
```

### Scheduled Notifications

```dart
// Schedule daily LeetCode reminders
await notifService.scheduleLeetCodeReminders();

// Cancel scheduled reminders
await notifService.cancelLeetCodeReminders();

// Schedule birthday notification
await notifService.scheduleBirthdayNotification(
  dob: userDob,
  userName: userName,
  enabled: true,
);
```

### Notification Bell Widget

The `NotificationBellIcon` widget is used throughout the app:

```dart
Consumer<NotificationService>(
  builder: (context, notifService, _) => FutureBuilder<List<dynamic>>(
    future: notifService.getNotifications(),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data?.where((n) => n.isRead != true).length ?? 0;
      return NotificationBellIcon(unreadCount: unreadCount);
    },
  ),
)
```

## Testing Notifications

1. **Open Notifications Screen**: Tap any notification bell icon in the app
2. **Send Test Notification**: 
   - Tap the three-dot menu (⋮) in the top right
   - Select "Send test notification"
   - You'll see a beautiful push notification appear!
3. **Check In-App List**: The notification also appears in the in-app list

## Permissions

### Android
- Requires `POST_NOTIFICATIONS` permission on Android 13+ (API 33+)
- Automatically requested when sending notifications
- User can enable/disable in device settings

### iOS
- Requests alert, badge, and sound permissions
- User must grant permission on first request

## Notification Channels (Android)

1. **PSGMX Notifications** (`psgmx_channel_main`)
   - High importance
   - Sound, vibration, LED enabled
   - For announcements and general updates

2. **LeetCode Reminders** (`psgmx_leetcode`)
   - Default importance
   - For daily coding reminders

3. **Birthday Notifications** (`psgmx_birthday`)
   - High importance
   - For birthday wishes

## Styling Guidelines

- **Orange Theme**: Primary notification color is #FF6600
- **Big Text Layout**: Uses Android BigTextStyleInformation for better readability
- **Type Indicators**: Each notification shows its type (📢 Announcement, ⏰ Reminder, etc.)
- **Modern Card Design**: In-app notifications use Material 3 card design
- **Smooth Animations**: Fade in/out animations for better UX

## Future Enhancements

- [ ] Deep linking to specific screens when tapping notifications
- [ ] Push notification images/thumbnails
- [ ] Notification actions (reply, mark done, etc.)
- [ ] Custom notification sounds per type
- [ ] Integration with Supabase for server-sent notifications
- [ ] Notification preferences (mute specific types)
- [ ] Group notifications by source

## Technical Details

- **Package**: flutter_local_notifications ^19.5.0
- **Timezone**: timezone ^0.10.1 for scheduled notifications
- **Permissions**: permission_handler ^12.0.1
- **State Management**: Provider pattern
- **Persistence**: Currently in-memory (mock), ready for Supabase integration
