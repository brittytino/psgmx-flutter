import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

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
