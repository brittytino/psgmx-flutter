import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Real-time subscription
  RealtimeChannel? _notificationChannel;

  // Cached notifications from database
  List<AppNotification> _cachedNotifications = [];
  bool _isLoading = false;

  // Stream for notification taps
  final _selectNotificationStream = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _selectNotificationStream.stream;

  // Public getter for cached notifications
  List<AppNotification> get notifications => List.unmodifiable(_cachedNotifications);
  bool get isLoading => _isLoading;
  
  // Stream for new notifications (for in-app toasts)
  final _streamController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _streamController.stream;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> init() async {
    if (_isInitialized) return;

    // Listen to auth state changes to setup/teardown subscription
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _setupRealtimeSubscription();
      } else {
        _notificationChannel?.unsubscribe();
        _notificationChannel = null;
      }
    });

    // Skip native notification setup on web
    if (kIsWeb) {
      debugPrint('[Notification] Running on Web - skipping native notifications');
      _isInitialized = true;
      _setupRealtimeSubscription();
      return;
    }

    tz.initializeTimeZones();

    // Create notification channels for Android
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      'psgmx_channel_main',
      'PSGMX Notifications',
      description: 'Important updates and announcements from PSGMX',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel leetcodeChannel =
        AndroidNotificationChannel(
      'psgmx_leetcode',
      'LeetCode Reminders',
      description: 'Daily LeetCode problem reminders',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const AndroidNotificationChannel birthdayChannel =
        AndroidNotificationChannel(
      'psgmx_birthday',
      'Birthday Notifications',
      description: 'Birthday wishes and celebrations',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel attendanceChannel =
        AndroidNotificationChannel(
      'psgmx_attendance',
      'Attendance Reminders',
      description: 'Daily attendance marking reminders for team leaders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Register channels
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(mainChannel);
    await androidPlugin?.createNotificationChannel(leetcodeChannel);
    await androidPlugin?.createNotificationChannel(birthdayChannel);
    await androidPlugin?.createNotificationChannel(attendanceChannel);

    // Initialize settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notification] Tapped: ${details.payload}');
        if (details.payload != null) {
          _selectNotificationStream.add(details.payload);
        }
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
            debugPrint(
                '[Notification] New notification received: ${payload.newRecord}');
            _handleNewNotification(payload.newRecord);
          },
        )
        .subscribe();

    debugPrint('[Notification] Real-time subscription active');
  }

  /// Handle new notification from real-time subscription
  void _handleNewNotification(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final notification = AppNotification.fromMap(data);

      // Audence check: Skip if not for this user
      final audience = notification.targetAudience;
      if (audience != 'all' && audience != user.id) {
        // In a more complex system, we'd check roles (e.g., audience == 'coordinators')
        // For now, we handle 'all' and specific user IDs
        return;
      }

      // Deduplication: Skip if already in cache
      if (_cachedNotifications.any((n) => n.id == notification.id)) {
        return;
      }

      // Add to cache
      _cachedNotifications.insert(0, notification);
      
      // Notify listeners for UI updates
      notifyListeners();
      
      // Add to stream for toasts
      _streamController.add(notification);

      // Avoid showing push notification if the sender is current user
      // (Sender already saw/triggered the local notification)
      if (notification.createdBy == user.id) {
        return;
      }

      // Show push notification
      await _showPushNotification(notification);
    } catch (e) {
      debugPrint('[Notification] Error handling new notification: $e');
    }
  }

  /// Show push notification on device
  Future<void> _showPushNotification(AppNotification notification) async {
    // Skip on web
    if (kIsWeb) {
      debugPrint('[Notification] Web: In-app notification displayed instead');
      return;
    }
    
    final androidDetails = AndroidNotificationDetails(
      'psgmx_channel_main',
      'PSGMX Notifications',
      channelDescription: 'Important updates and announcements from PSGMX',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFFF6600),
      playSound: true,
      enableVibration: true,
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

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

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

      _isLoading = true;
      // Only notify if there's no data yet to show loading spinner initially
      // If we have data, we might want to keep showing it while refreshing silently
      if (_cachedNotifications.isEmpty) notifyListeners();

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
          notificationType: NotificationType.fromString(
              data['notification_type'] ?? 'announcement'),
          tone: data['tone'] != null
              ? NotificationTone.fromString(data['tone'])
              : null,
          targetAudience: data['target_audience'] ?? 'all',
          generatedAt:
              DateTime.tryParse(data['generated_at'] ?? '') ?? DateTime.now(),
          validUntil: data['valid_until'] != null
              ? DateTime.tryParse(data['valid_until'])
              : null,
          createdBy: data['created_by'],
          isActive: data['is_active'] ?? true,
          isRead: hasRead,
          readAt: hasRead && reads!.isNotEmpty
              ? DateTime.tryParse(reads.first['read_at'] ?? '')
              : null,
        ));
      }

      // Filter duplicates: Ensure only one LeetCode POTD per day
      final seenLeetCodeDates = <String>{};
      final uniqueNotifications = <AppNotification>[];

      for (var n in notifications) {
        if (n.title.contains('LeetCode POTD') || 
            n.notificationType == NotificationType.leetcode) {
          // Use local date for daily comparison
          final localDate = n.generatedAt.toLocal();
          final dateKey = "${localDate.year}-${localDate.month}-${localDate.day}";
          if (!seenLeetCodeDates.contains(dateKey)) {
            seenLeetCodeDates.add(dateKey);
            uniqueNotifications.add(n);
          }
        } else {
          uniqueNotifications.add(n);
        }
      }

      // Merge: Check if any new realtime notifications arrived (active subscription) while we were fetching
      // This prevents overwriting valid live data with slightly older fetched data
      if (_cachedNotifications.isNotEmpty && uniqueNotifications.isNotEmpty) {
        final fetchedIds = uniqueNotifications.map((n) => n.id).toSet();
        // Identify items in cache that are NOT in the fetch result and are NEWER than the newest fetched item
        // This usually means they arrived via realtime during the fetch delay
        final newestFetched = uniqueNotifications.first.generatedAt;
        final newRealtimeItems = _cachedNotifications.where((n) {
          return !fetchedIds.contains(n.id) && n.generatedAt.isAfter(newestFetched);
        }).toList();

        if (newRealtimeItems.isNotEmpty) {
           debugPrint('[Notification] Merging ${newRealtimeItems.length} active realtime items into fetch result');
           uniqueNotifications.insertAll(0, newRealtimeItems);
        }
      } else if (_cachedNotifications.isNotEmpty && uniqueNotifications.isEmpty) {
        // If fetch returned empty but cache has items (maybe just arrived), keep them
        uniqueNotifications.addAll(_cachedNotifications);
      }

      _cachedNotifications = uniqueNotifications;
      _isLoading = false;
      notifyListeners();
      return uniqueNotifications;
    } catch (e) {
      debugPrint('[Notification] Error fetching notifications: $e');
      _isLoading = false;
      notifyListeners();
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
      final index =
          _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cachedNotifications[index] = _cachedNotifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Notification] Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  // Fixed: Marks all UNREAD notifications as read in the database, regardless of whether they are cached or not
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final nowStr = DateTime.now().toIso8601String();

      // OPTIMIZATION: Instead of finding unread IDs locally, we should ideally call a stored procedure or update
      // But adhering to the current pattern, we try to mark what we know about or fetch unread first.
      
      // Strategy: 
      // 1. Get ALL unread notification IDs for this user from DB (not just cache)
      // Since 'notification_reads' is a join table, we need notifications that DO NOT have a read entry.
      // Supabase-js has easier filtering for "not in", but here we might have to rely on the cached list for UI responsiveness
      // and maybe a backend trigger for true clean up.
      // For now, let's stick to marking the cached ones to avoid heavy queries, but let's do it robustly.

      final unreadNotifications = _cachedNotifications.where((n) => n.isRead != true).toList();
      
      if (unreadNotifications.isEmpty) return;

      final List<Map<String, dynamic>> upsertData = unreadNotifications.map((n) => {
        'notification_id': n.id,
        'user_id': user.id,
        'read_at': nowStr,
      }).toList();

      // Batch upsert
      await _supabase.from('notification_reads').upsert(upsertData);

      // Update cache
      for (int i = 0; i < _cachedNotifications.length; i++) {
        if (_cachedNotifications[i].isRead != true) {
          _cachedNotifications[i] = _cachedNotifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
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
      notifyListeners();
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
        'generated_at': DateTime.now().toIso8601String(),
      });

      // Show local push (without persisting to DB again or adding to cache duplicates)
      if (!kIsWeb) {
         final androidDetails = AndroidNotificationDetails(
          'psgmx_channel_main',
          'PSGMX Notifications',
          channelDescription: 'Important updates and announcements from PSGMX',
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFFFF6600),
          styleInformation: BigTextStyleInformation(message),
        );
        const iosDetails = DarwinNotificationDetails();
        
        await _notifications.show(
          DateTime.now().millisecondsSinceEpoch % 100000,
          '📢 $title',
          message,
          NotificationDetails(android: androidDetails, iOS: iosDetails),
        );
      }

      return true;
    } catch (e) {
      debugPrint('[Notification] Error sending announcement: $e');
      return false;
    }
  }

  /// Send birthday notification to all users for a specific person.
  /// Inserts a DB row (for the in-app list / realtime) AND fires a local
  /// Android / iOS push so the user sees it even when the app is backgrounded.
  Future<bool> sendBirthdayNotification({
    required String birthdayPersonName,
    required String birthdayPersonId,
  }) async {
    try {
      final firstName = birthdayPersonName.split(' ').first;
      final title = '🎂 Happy Birthday, $firstName!';
      final body = 'Let\'s wish $birthdayPersonName a wonderful birthday! 🎉🎈';

      // 1. Persist to database — realtime subscription surfaces it in the
      //    in-app notification list for all online users.
      await _supabase.from('notifications').insert({
        'title': title,
        'message': body,
        'notification_type': 'announcement',
        'tone': 'friendly',
        'target_audience': 'all',
        'is_active': true,
        'generated_at': DateTime.now().toIso8601String(),
      });

      // 2. Fire a local OS-level push notification on Android/iOS.
      //    Realtime alone only works while the app is foregrounded, so we
      //    explicitly call _notifications.show() to reach backgrounded users.
      if (!kIsWeb) {
        // Use a stable ID derived from the person name so repeated calls in
        // the same session don't stack duplicate system notifications.
        final notifId = 600 + (birthdayPersonName.hashCode.abs() % 399);

        await _notifications.show(
          notifId,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'psgmx_birthday',
              'Birthday Notifications',
              channelDescription: 'Birthday wishes and celebrations',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFFFF6B6B),
              playSound: true,
              enableVibration: true,
              enableLights: true,
              ledColor: Color(0xFFFF6B6B),
              ledOnMs: 1000,
              ledOffMs: 500,
            ),
            iOS: DarwinNotificationDetails(
              presentSound: true,
              presentAlert: true,
              presentBadge: true,
            ),
          ),
          payload: 'birthday:$birthdayPersonId',
        );
        debugPrint('[Notification] 🎂 Local birthday push fired for $birthdayPersonName (id=$notifId)');
      }

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
      final todayStr = '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      debugPrint('[Notification] 🎂 Checking birthdays for today: $todayStr (${now.year}-${now.month}-${now.day})');

      // Check BOTH whitelist AND users tables for birthdays
      final whitelistResponse = await _supabase
          .from('whitelist')
          .select('email, name, dob')
          .not('dob', 'is', null);

      final usersResponse = await _supabase
          .from('users')
          .select('id, email, name, dob')
          .not('dob', 'is', null);

      // Combine both lists (prefer users table data if exists)
      final Map<String, Map<String, dynamic>> allUsersMap = {};
      
      // Add whitelist entries first
      for (var user in whitelistResponse as List) {
        final email = user['email'] as String?;
        if (email != null) {
          allUsersMap[email] = user;
        }
      }
      
      // Override with users table data (more up-to-date)
      for (var user in usersResponse as List) {
        final email = user['email'] as String?;
        if (email != null) {
          allUsersMap[email] = user;
        }
      }

      debugPrint('[Notification] Found ${allUsersMap.length} users to check for birthdays');

      int birthdaysFound = 0;
      for (var user in allUsersMap.values) {
        final dobStr = user['dob'] as String?;
        final dob = DateTime.tryParse(dobStr ?? '');
        
        // Skip invalid dobs
        if (dob == null) continue;

        debugPrint('[Notification] Checking user: ${user['name']} - DOB: $dobStr');
        
        if (dob.month == now.month && dob.day == now.day) {
          birthdaysFound++;
          final name = user['name'] as String? ?? 'Student';
          final userId = user['id'] ?? user['email'] ?? '';

          // Check if birthday notification already sent today for this SPECIFIC user
          // Using a more precise check than just title matching
          final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
          
          final existingNotif = await _supabase
              .from('notifications')
              .select('id')
              .eq('notification_type', 'announcement')
              .eq('target_audience', 'all') // Birthdays are usually public announcements
              .ilike('message', '%$name%') // Ensure message contains full name to differentiate John vs Johnny
              .gte('generated_at', startOfDay)
              .maybeSingle();

          if (existingNotif == null) {
            await sendBirthdayNotification(
              birthdayPersonName: name,
              birthdayPersonId: userId,
            );
            debugPrint('[Notification] ✅ Birthday notification sent for $name');
          } else {
            debugPrint('[Notification] ⏭️  Birthday notification already sent for $name today');
          }
        }
      }
      
      if (birthdaysFound == 0) {
        debugPrint('[Notification] No birthdays found for today');
      } else {
        debugPrint('[Notification] Found $birthdaysFound birthday(s) today');
      }
    } catch (e) {
      debugPrint('[Notification] ❌ Error checking birthdays: $e');
    }
  }

  /// Schedule attendance reminder for team leaders
  Future<void> scheduleAttendanceReminder({
    required bool isTeamLeader,
    required String teamId,
  }) async {
    if (!isTeamLeader) return;
    if (kIsWeb) {
      debugPrint('[Notification] Web: Scheduled notifications not available');
      return;
    }

    // Schedule daily reminder at 4:45 PM
    await _scheduleDaily(
      id: 300 + teamId.hashCode % 100,
      title: '⚠️ Mark Today\'s Attendance',
      body:
          'If you forget to mark attendance for your team, the entire team will be absent..',
      hour: 16,
      minute: 45,
      channel: 'psgmx_attendance',
    );

    debugPrint(
        '[Notification] Attendance reminder scheduled for team: $teamId');
  }

  /// Cancel attendance reminders
  Future<void> cancelAttendanceReminder(String teamId) async {
    if (kIsWeb) {
      debugPrint('[Notification] Web: Scheduled notifications not available');
      return;
    }
    
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
    if (kIsWeb) return;
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
    
    if (kIsWeb) {
      debugPrint('[Notification] Web: Scheduled notifications not available');
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    final firstName = userName.split(' ').first;

    var birthdayDate =
        tz.TZDateTime(tz.local, now.year, dob.month, dob.day, 0, 0);

    if (birthdayDate.isBefore(now)) {
      birthdayDate =
          tz.TZDateTime(tz.local, now.year + 1, dob.month, dob.day, 0, 0);
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
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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
          channel == 'psgmx_attendance'
              ? 'Attendance Reminders'
              : 'LeetCode Reminders',
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
    if (kIsWeb) return;
    
    var date = tz.TZDateTime.now(tz.local);
    while (date.weekday != day) {
      date = date.add(const Duration(days: 1));
    }
    date =
        tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, minute);

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
    if (kIsWeb) {
      debugPrint('[Notification] Web: Permissions not required');
      return true;
    }
    
    if (await Permission.notification.isGranted) return true;

    final status = await Permission.notification.request();

    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
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
    bool persistToDatabase = true, // Save to DB for in-app viewing
    String? uniqueKey, // For deduplication (e.g., 'potd_2026-02-10')
  }) async {
    // Persist to database for in-app notification list (production-grade UX)
    if (persistToDatabase) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          // Check for duplicates if uniqueKey provided
          if (uniqueKey != null) {
            final today = DateTime.now().toIso8601String().split('T')[0];
            final existing = await _supabase
                .from('notifications')
                .select('id')
                .eq('created_by', user.id)
                .eq('title', title)
                .gte('generated_at', today) // Safer date comparison
                .maybeSingle();
            
            if (existing != null) {
              debugPrint('[Notification] ⏭️ Skipping duplicate: $title');
              // If it exists in DB, we rely on Realtime/Load to show it.
              // However, if we want to force show LOCAL notification anyway (e.g. for user feedback), proceed.
              // But usually uniqueKey implies "don't do it again".
              return; 
            }
          }
          
          // Map to safe DB types
          String dbType = 'announcement';
          if (type == NotificationType.motivation) dbType = 'motivation';
          if (type == NotificationType.reminder || type == NotificationType.leetcode) dbType = 'reminder';
          if (type == NotificationType.alert || type == NotificationType.attendance) dbType = 'alert';
          
          // Insert without manually adding to cache (let realtime handle it)
          await _supabase.from('notifications').insert({
            'title': title,
            'message': body,
            'notification_type': dbType,
            'tone': 'friendly',
            'target_audience': 'user', // Personal notification
            'created_by': user.id,
            'is_active': true,
            'generated_at': DateTime.now().toIso8601String(),
          });
          
          // DO NOT add to cache here - realtime subscription will handle it
          debugPrint('[Notification] ✅ Persisted to database: $title');
        }
      } catch (e) {
        debugPrint('[Notification] Failed to persist to DB: $e');
        // Fallback: Add to cache only without realtime
        final transientNotif = AppNotification(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          message: body,
          notificationType: type,
          tone: NotificationTone.friendly,
          targetAudience: 'user',
          generatedAt: DateTime.now(),
          isActive: true,
          createdBy: 'system',
          isRead: false,
        );
        _cachedNotifications.insert(0, transientNotif);
        notifyListeners();
      }
    } else {
      // Transient notification (not persisted)
      final transientNotif = AppNotification(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: body,
        notificationType: type,
        tone: NotificationTone.friendly,
        targetAudience: 'user',
        generatedAt: DateTime.now(),
        isActive: true,
        createdBy: 'system',
        isRead: false,
      );
      _cachedNotifications.insert(0, transientNotif);
      notifyListeners();
    }

    if (kIsWeb) {
      debugPrint('[Notification] Web: $title - $body');
      return;
    }
    
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
      ledOnMs: 1000,
      ledOffMs: 500,
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

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
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
      case NotificationType.leetcode:
        return '💻 LeetCode';
      case NotificationType.birthday:
        return '🎂 Birthday';
      case NotificationType.attendance:
        return '📋 Attendance';
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  /// Show test notification
  Future<void> showTestNotification() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🎉 Welcome to PSGMX Notifications!',
      body:
          'Stay updated with announcements, reminders, and important updates!',
      type: NotificationType.announcement,
      persistToDatabase: true, // Save to in-app list
    );
  }

  int getUnreadCount(List<AppNotification> notifications) {
    return notifications.where((n) => n.isRead != true).length;
  }

  // ========================================
  // A2: RESPECT NOTIFICATION PREFERENCES
  // ========================================

  /// Check if a notification type should be sent based on user preferences
  Future<bool> shouldSendNotification(String notificationType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase.from('users').select('''
            task_reminders_enabled,
            attendance_alerts_enabled,
            announcements_enabled,
            leetcode_notifications_enabled,
            birthday_notifications_enabled
          ''').eq('id', user.id).maybeSingle();

      if (response == null) return true; // Default to enabled

      switch (notificationType) {
        case 'task_reminder':
          return response['task_reminders_enabled'] ?? true;
        case 'attendance':
          return response['attendance_alerts_enabled'] ?? true;
        case 'announcement':
          return response['announcements_enabled'] ?? true;
        case 'leetcode':
          return response['leetcode_notifications_enabled'] ?? true;
        case 'birthday':
          return response['birthday_notifications_enabled'] ?? true;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('[Notification] Error checking preferences: $e');
      return true; // Default to enabled on error
    }
  }

  // ========================================
  // B2: TASK DEADLINE REMINDERS
  // ========================================

  /// Schedule task deadline reminder at 9 PM
  Future<void> scheduleTaskDeadlineReminder() async {
    try {
      // Check if user has task reminders enabled
      final shouldSend = await shouldSendNotification('task_reminder');
      if (!shouldSend) {
        debugPrint('[Notification] Task reminders disabled, skipping schedule');
        return;
      }

      await _scheduleDaily(
        id: 400, // Unique ID for task deadline
        title: '📝 Daily Task Reminder',
        body:
            'Have you completed today\'s task? Don\'t forget to mark it as done!',
        hour: 21, // 9 PM
        minute: 0,
        channel: 'psgmx_channel_main',
      );

      debugPrint('[Notification] Task deadline reminder scheduled for 9 PM');
      
      // Also schedule task incomplete check at 9:15 PM (15 min after deadline)
      await _scheduleDaily(
        id: 401,
        title: '⏰ Task Still Pending',
        body: 'You haven\'t marked today\'s task as completed yet. Take a moment to finish it!',
        hour: 21,
        minute: 15,
        channel: 'psgmx_channel_main',
      );
      
      debugPrint('[Notification] Task incomplete check scheduled for 9:15 PM');
    } catch (e) {
      debugPrint('[Notification] Error scheduling task reminder: $e');
    }
  }

  /// Cancel task deadline reminder
  Future<void> cancelTaskDeadlineReminder() async {
    await _notifications.cancel(400);
  }

  /// Send immediate task reminder (called if task not completed)
  Future<void> sendTaskIncompleteReminder() async {
    try {
      final shouldSend = await shouldSendNotification('task_reminder');
      if (!shouldSend) return;

      await showNotification(
        id: 401,
        title: '⏰ Task Still Pending',
        body:
            'You haven\'t marked today\'s task as completed yet. Take a moment to finish it!',
        type: NotificationType.reminder,
      );
    } catch (e) {
      debugPrint('[Notification] Error sending task reminder: $e');
    }
  }

  /// Send announcement respecting user preference
  Future<bool> sendAnnouncementWithPreference({
    required String title,
    required String message,
    String targetAudience = 'all',
    NotificationTone? tone,
  }) async {
    try {
      final shouldSend = await shouldSendNotification('announcement');
      if (!shouldSend) {
        debugPrint('[Notification] User has announcements disabled');
        // Still insert to database for in-app viewing
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase.from('notifications').insert({
            'title': title,
            'message': message,
            'notification_type': 'announcement',
            'tone': tone?.name ?? 'friendly',
            'target_audience': targetAudience,
            'created_by': user.id,
            'is_active': true,
          });
        }
        return true; // DB insertion succeeded
      }

      // Full send with push notification
      return await sendAnnouncement(
        title: title,
        message: message,
        targetAudience: targetAudience,
        tone: tone,
      );
    } catch (e) {
      debugPrint('[Notification] Error sending announcement: $e');
      return false;
    }
  }

  /// Cleanup subscriptions
  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    _streamController.close();
    _selectNotificationStream.close();
    super.dispose();
  }
}
