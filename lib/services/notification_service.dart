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
    
    // Android - Create notification channels
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      'psgmx_channel_main',
      'PSGMX Notifications',
      description: 'Important updates and announcements from PSGMX',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF6600),
    );
    
    const AndroidNotificationChannel leetcodeChannel = AndroidNotificationChannel(
      'psgmx_leetcode',
      'LeetCode Reminders',
      description: 'Daily LeetCode problem reminders',
      importance: Importance.defaultImportance,
      playSound: true,
    );
    
    const AndroidNotificationChannel birthdayChannel = AndroidNotificationChannel(
      'psgmx_birthday',
      'Birthday Notifications',
      description: 'Birthday wishes and celebrations',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    // Register channels
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(mainChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(leetcodeChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(birthdayChannel);
    
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
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
        // TODO: Navigate to specific screen based on payload
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
    String? payload,
    NotificationType type = NotificationType.announcement,
  }) async {
    // Choose sound and styling based on notification type
    final androidDetails = AndroidNotificationDetails(
      'psgmx_channel_main', 
      'PSGMX Notifications',
      channelDescription: 'Important updates and announcements from PSGMX',
      importance: Importance.max, 
      priority: Priority.high,
      color: const Color(0xFFFF6600),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFFF6600),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: _getNotificationTypeName(type),
        htmlFormatSummaryText: false,
      ),
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    
    final details = NotificationDetails(
      android: androidDetails, 
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
    
    // Add to in-app notification list
    _mockNotifications.insert(0, AppNotification(
      id: id.toString(),
      title: title,
      message: body,
      notificationType: type,
      targetAudience: 'all',
      generatedAt: DateTime.now(),
      isRead: false,
    ));
  }
  
  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return '⚠️ Alert';
      case NotificationType.motivation:
        return '✨ Motivation';
      case NotificationType.reminder:
        return '⏰ Reminder';
      case NotificationType.announcement:
        return '📢 Announcement';
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
  
  /// Show a test notification to demonstrate the feature
  Future<void> showTestNotification() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🎉 Welcome to PSGMX Notifications!',
      body: 'Stay updated with announcements, reminders, and motivational messages. You\'ll never miss important updates!',
      type: NotificationType.announcement,
    );
  }
  
  /// Send a motivational notification
  Future<void> showMotivationalNotification(String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '✨ Daily Motivation',
      body: message,
      type: NotificationType.motivation,
    );
  }
  
  /// Send a reminder notification
  Future<void> showReminderNotification(String title, String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '⏰ $title',
      body: message,
      type: NotificationType.reminder,
    );
  }
  
  /// Send an alert notification
  Future<void> showAlertNotification(String title, String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '⚠️ $title',
      body: message,
      type: NotificationType.alert,
    );
  }
  
  /// Send an announcement notification
  Future<void> showAnnouncementNotification(String title, String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '📢 $title',
      body: message,
      type: NotificationType.announcement,
    );
  }
  
  /// Get unread notification count
  int getUnreadCount(List<AppNotification> notifications) {
    return notifications.where((n) => n.isRead != true).length;
  }
}
