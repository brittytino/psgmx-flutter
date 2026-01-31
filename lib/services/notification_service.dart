import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

/// Real-time Notification Service with Supabase Integration
/// Features:
/// - Real-time notifications from database
/// - Push notifications for announcements
/// - Birthday notifications for all users
/// - Attendance reminders for team leaders
/// - Daily LeetCode reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Real-time subscription
  RealtimeChannel? _notificationChannel;
  
  // Cached notifications from database
  List<AppNotification> _cachedNotifications = [];

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    
    // Create notification channels for Android
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
    
    const AndroidNotificationChannel attendanceChannel = AndroidNotificationChannel(
      'psgmx_attendance',
      'Attendance Reminders',
      description: 'Daily attendance marking reminders for team leaders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    // Register channels
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(mainChannel);
    await androidPlugin?.createNotificationChannel(leetcodeChannel);
    await androidPlugin?.createNotificationChannel(birthdayChannel);
    await androidPlugin?.createNotificationChannel(attendanceChannel);
    
    // Initialize settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notification] Tapped: ${details.payload}');
      },
    );
    
    _isInitialized = true;
    
    // Setup real-time subscription after user is authenticated
    _setupRealtimeSubscription();
  }

  /// Setup real-time subscription to notifications table
  void _setupRealtimeSubscription() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    _notificationChannel?.unsubscribe();
    
    _notificationChannel = _supabase
        .channel('notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            debugPrint('[Notification] New notification received: ${payload.newRecord}');
            _handleNewNotification(payload.newRecord);
          },
        )
        .subscribe();
    
    debugPrint('[Notification] Real-time subscription active');
  }

  /// Handle new notification from real-time subscription
  void _handleNewNotification(Map<String, dynamic> data) async {
    try {
      final notification = AppNotification.fromMap(data);
      
      // Add to cache
      _cachedNotifications.insert(0, notification);
      
      // Show push notification
      await _showPushNotification(notification);
    } catch (e) {
      debugPrint('[Notification] Error handling new notification: $e');
    }
  }

  /// Show push notification on device
  Future<void> _showPushNotification(AppNotification notification) async {
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
      styleInformation: BigTextStyleInformation(
        notification.message,
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
        summaryText: _getNotificationTypeName(notification.notificationType),
      ),
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: notification.id,
    );
  }

  /// Get notifications from database (real data, not mock)
  Future<List<AppNotification>> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      // Fetch notifications from database
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            notification_reads!left(read_at, dismissed_at)
          ''')
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(50);
      
      final notifications = <AppNotification>[];
      
      for (var data in response as List) {
        final reads = data['notification_reads'] as List?;
        final hasRead = reads?.isNotEmpty == true;
        
        notifications.add(AppNotification(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          notificationType: NotificationType.fromString(data['notification_type'] ?? 'announcement'),
          tone: data['tone'] != null ? NotificationTone.fromString(data['tone']) : null,
          targetAudience: data['target_audience'] ?? 'all',
          generatedAt: DateTime.tryParse(data['generated_at'] ?? '') ?? DateTime.now(),
          validUntil: data['valid_until'] != null ? DateTime.tryParse(data['valid_until']) : null,
          createdBy: data['created_by'],
          isActive: data['is_active'] ?? true,
          isRead: hasRead,
          readAt: hasRead && reads!.isNotEmpty ? DateTime.tryParse(reads.first['read_at'] ?? '') : null,
        ));
      }
      
      _cachedNotifications = notifications;
      return notifications;
    } catch (e) {
      debugPrint('[Notification] Error fetching notifications: $e');
      return _cachedNotifications;
    }
  }

  /// Mark notification as read in database
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      await _supabase.from('notification_reads').upsert({
        'notification_id': notificationId,
        'user_id': user.id,
        'read_at': DateTime.now().toIso8601String(),
      });
      
      // Update cache
      final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cachedNotifications[index] = _cachedNotifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('[Notification] Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final unreadIds = _cachedNotifications
          .where((n) => n.isRead != true)
          .map((n) => n.id)
          .toList();
      
      for (var id in unreadIds) {
        await _supabase.from('notification_reads').upsert({
          'notification_id': id,
          'user_id': user.id,
          'read_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Update cache
      for (int i = 0; i < _cachedNotifications.length; i++) {
        _cachedNotifications[i] = _cachedNotifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('[Notification] Error marking all as read: $e');
    }
  }

  /// Delete/dismiss notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      await _supabase.from('notification_reads').upsert({
        'notification_id': notificationId,
        'user_id': user.id,
        'dismissed_at': DateTime.now().toIso8601String(),
      });
      
      _cachedNotifications.removeWhere((n) => n.id == notificationId);
    } catch (e) {
      debugPrint('[Notification] Error deleting notification: $e');
    }
  }

  /// Send announcement with push notification to all users
  Future<bool> sendAnnouncement({
    required String title,
    required String message,
    String targetAudience = 'all',
    NotificationTone? tone,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Insert into database (triggers real-time for other users)
      await _supabase.from('notifications').insert({
        'title': title,
        'message': message,
        'notification_type': 'announcement',
        'tone': tone?.name ?? 'friendly',
        'target_audience': targetAudience,
        'created_by': user.id,
        'is_active': true,
      });
      
      // Show push notification locally as well
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: '📢 $title',
        body: message,
        type: NotificationType.announcement,
      );
      
      return true;
    } catch (e) {
      debugPrint('[Notification] Error sending announcement: $e');
      return false;
    }
  }

  /// Send birthday notification to all users for a specific person
  Future<bool> sendBirthdayNotification({
    required String birthdayPersonName,
    required String birthdayPersonId,
  }) async {
    try {
      final firstName = birthdayPersonName.split(' ').first;
      
      // Insert birthday notification into database
      await _supabase.from('notifications').insert({
        'title': '🎂 Happy Birthday, $firstName!',
        'message': 'Let\'s wish $birthdayPersonName a wonderful birthday! 🎉🎈',
        'notification_type': 'announcement',
        'tone': 'friendly',
        'target_audience': 'all',
        'is_active': true,
      });
      
      // Also show local push notification
      await showNotification(
        id: 200 + birthdayPersonId.hashCode % 1000,
        title: '🎂 Happy Birthday, $firstName!',
        body: 'Let\'s wish $birthdayPersonName a wonderful birthday! 🎉🎈',
        type: NotificationType.announcement,
        channel: 'psgmx_birthday',
      );
      
      return true;
    } catch (e) {
      debugPrint('[Notification] Error sending birthday notification: $e');
      return false;
    }
  }

  /// Check and send birthday notifications for today
  Future<void> checkAndSendBirthdayNotifications() async {
    try {
      final now = DateTime.now();
      
      // Get all users with birthday today
      final response = await _supabase
          .from('whitelist')
          .select('email, name, dob')
          .not('dob', 'is', null);
      
      for (var user in response as List) {
        final dob = DateTime.tryParse(user['dob'] ?? '');
        if (dob != null && dob.month == now.month && dob.day == now.day) {
          final name = user['name'] as String? ?? 'Student';
          
          // Check if birthday notification already sent today
          final existingNotif = await _supabase
              .from('notifications')
              .select('id')
              .ilike('title', '%Happy Birthday%$name%')
              .gte('generated_at', DateTime(now.year, now.month, now.day).toIso8601String())
              .maybeSingle();
          
          if (existingNotif == null) {
            await sendBirthdayNotification(
              birthdayPersonName: name,
              birthdayPersonId: user['email'] ?? '',
            );
            debugPrint('[Notification] Birthday notification sent for $name');
          }
        }
      }
    } catch (e) {
      debugPrint('[Notification] Error checking birthdays: $e');
    }
  }

  /// Schedule attendance reminder for team leaders
  Future<void> scheduleAttendanceReminder({
    required bool isTeamLeader,
    required String teamId,
  }) async {
    if (!isTeamLeader) return;
    
    // Schedule daily reminder at 4:45 PM
    await _scheduleDaily(
      id: 300 + teamId.hashCode % 100,
      title: '📋 Mark Today\'s Attendance',
      body: 'Hey Team Leader! Don\'t forget to mark attendance for your team today.',
      hour: 16,
      minute: 45,
      channel: 'psgmx_attendance',
    );
    
    debugPrint('[Notification] Attendance reminder scheduled for team: $teamId');
  }

  /// Cancel attendance reminders
  Future<void> cancelAttendanceReminder(String teamId) async {
    await _notifications.cancel(300 + teamId.hashCode % 100);
  }

  /// Schedule LeetCode reminders
  Future<void> scheduleLeetCodeReminders() async {
    // Daily POTD reminder at 6:00 PM
    await _scheduleDaily(
      id: 100,
      title: '💻 LeetCode Daily Challenge',
      body: 'Keep your streak alive! Solve today\'s problem.',
      hour: 18,
      minute: 0,
      channel: 'psgmx_leetcode',
    );

    // Weekly leaderboard update (Saturday 9:00 AM)
    await _scheduleWeekly(
      id: 101,
      title: '🏆 Weekly Leaderboard Update',
      body: 'Check out who topped the charts this week! Are you in the Top 3?',
      day: DateTime.saturday,
      hour: 9,
      minute: 0,
    );
  }

  Future<void> cancelLeetCodeReminders() async {
    await _notifications.cancel(100);
    await _notifications.cancel(101);
  }

  /// Schedule personal birthday notification
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
    
    var birthdayDate = tz.TZDateTime(tz.local, now.year, dob.month, dob.day, 0, 0);
    
    if (birthdayDate.isBefore(now)) {
      birthdayDate = tz.TZDateTime(tz.local, now.year + 1, dob.month, dob.day, 0, 0);
    }

    try {
      await _notifications.zonedSchedule(
        200,
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
      debugPrint('[Notification] Failed to schedule birthday notification: $e');
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
    String channel = 'psgmx_leetcode',
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == 'psgmx_attendance' ? 'Attendance Reminders' : 'LeetCode Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) return true;
    
    final status = await Permission.notification.request();
    
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
    String channel = 'psgmx_channel_main',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      'PSGMX Notifications',
      channelDescription: 'Important updates and announcements from PSGMX',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFFF6600),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFFF6600),
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: _getNotificationTypeName(type),
      ),
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(id, title, body, details, payload: payload);
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

  /// Show test notification
  Future<void> showTestNotification() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🎉 Welcome to PSGMX Notifications!',
      body: 'Stay updated with announcements, reminders, and important updates!',
      type: NotificationType.announcement,
    );
  }

  int getUnreadCount(List<AppNotification> notifications) {
    return notifications.where((n) => n.isRead != true).length;
  }

  /// Cleanup subscriptions
  void dispose() {
    _notificationChannel?.unsubscribe();
  }
}
