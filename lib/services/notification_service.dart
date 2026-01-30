import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    
    // Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
    
    _isInitialized = true;
  }

  // Mock notification storage for demo purposes
  final List<AppNotification> _mockNotifications = [];

  Future<List<AppNotification>> getNotifications() async {
    // Return mock notifications for demo
    if (_mockNotifications.isEmpty) {
      _mockNotifications.addAll([
        AppNotification(
          id: '1',
          title: 'Welcome to PSGMX!',
          message: 'Start your placement preparation journey with us.',
          notificationType: NotificationType.announcement,
          targetAudience: 'all',
          generatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: '2',
          title: 'Daily LeetCode Reminder',
          message: 'Don\'t forget to solve today\'s problem!',
          notificationType: NotificationType.reminder,
          targetAudience: 'all',
          generatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ]);
    }
    return _mockNotifications;
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _mockNotifications.length; i++) {
      _mockNotifications[i] = _mockNotifications[i].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _mockNotifications.removeWhere((n) => n.id == notificationId);
  }

  Future<void> scheduleLeetCodeReminders() async {
    // 1. Daily POTD at 6:00 PM
    await _scheduleDaily(
      id: 100,
      title: "LeetCode Daily Challenge",
      body: "Keep your streak alive! Solve the problem of the day.",
      hour: 18,
      minute: 0,
    );

    // 2. Weekly Motivation (Saturday 9:00 AM)
    await _scheduleWeekly(
      id: 101,
      title: "Weekly Leaderboard Update",
      body: "Check out who topped the charts this week! Are you in the Top 3?",
      day: DateTime.saturday,
      hour: 9, 
      minute: 0,
    );
  }

  Future<void> cancelLeetCodeReminders() async {
    await _notifications.cancel(100);
    await _notifications.cancel(101);
  }

  /// Schedule birthday notification at midnight on user's birthday
  /// Returns true if scheduled successfully
  Future<bool> scheduleBirthdayNotification({
    required DateTime dob,
    required String userName,
    required bool enabled,
  }) async {
    if (!enabled) {
      await cancelBirthdayNotification();
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    final firstName = userName.split(' ').first;
    
    // Calculate next birthday at midnight
    var birthdayDate = tz.TZDateTime(
      tz.local,
      now.year,
      dob.month,
      dob.day,
      0, // Midnight
      0,
    );
    
    // If birthday already passed this year, schedule for next year
    if (birthdayDate.isBefore(now)) {
      birthdayDate = tz.TZDateTime(
        tz.local,
        now.year + 1,
        dob.month,
        dob.day,
        0,
        0,
      );
    }

    try {
      await _notifications.zonedSchedule(
        200, // Birthday notification ID
        '🎂 Happy Birthday, $firstName!',
        'Wishing you a fantastic year ahead filled with success and happiness! 🎉',
        birthdayDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'psgmx_birthday',
            'Birthday Notifications',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFFF6B6B),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to schedule birthday notification: $e');
      return false;
    }
  }

  Future<void> cancelBirthdayNotification() async {
    await _notifications.cancel(200);
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'psgmx_leetcode',
          'LeetCode Reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
  }) async {
    // Helper to find next Saturday
    var date = tz.TZDateTime.now(tz.local);
    while (date.weekday != day) {
      date = date.add(const Duration(days: 1));
    }
    date = tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, minute);
    
    if (date.isBefore(tz.TZDateTime.now(tz.local))) {
      date = date.add(const Duration(days: 7));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      date,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'psgmx_leetcode',
          'LeetCode Reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) return true;
    
    // Request for Android 13+
    final status = await Permission.notification.request();
    
    // For iOS, we use the local notifications plugin method
    final iosImpl = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final bool? result = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    
    return status.isGranted;
  }

  Future<void> showNotification({
    required int id, 
    required String title, 
    required String body, 
    String? payload
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'psgmx_channel_main', 
      'PSGMX Notifications',
      importance: Importance.max, 
      priority: Priority.high,
      color: Color(0xFFFF6600),
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    
    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
