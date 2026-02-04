import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Background service that checks for birthdays daily at midnight
/// and sends notifications to all users when someone has a birthday.
class BirthdayNotificationService {
  static final BirthdayNotificationService _instance = BirthdayNotificationService._internal();
  factory BirthdayNotificationService() => _instance;
  BirthdayNotificationService._internal();

  Timer? _dailyTimer;
  Timer? _periodicTimer;
  bool _isInitialized = false;

  /// Initialize the birthday checking service
  Future<void> init() async {
    if (_isInitialized) return;
    
    debugPrint('[BirthdayService] Initializing birthday notification service...');
    
    // Run immediate check on startup
    await _checkBirthdays();
    
    // Schedule check at midnight every day
    _scheduleMidnightCheck();
    
    // Also check every 6 hours as backup (in case app misses midnight)
    _schedulePeriodicCheck();
    
    _isInitialized = true;
    debugPrint('[BirthdayService] ✅ Birthday service initialized successfully');
  }

  /// Schedule the midnight birthday check
  void _scheduleMidnightCheck() {
    _dailyTimer?.cancel();
    
    final now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day + 1, 0, 1); // 12:01 AM next day
    
    final timeUntilMidnight = midnight.difference(now);
    
    debugPrint('[BirthdayService] Next midnight check in: ${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes % 60}m');
    
    _dailyTimer = Timer(timeUntilMidnight, () {
      _checkBirthdays();
      // Reschedule for next midnight
      _scheduleMidnightCheck();
    });
  }

  /// Schedule periodic checks every 6 hours as backup
  void _schedulePeriodicCheck() {
    _periodicTimer?.cancel();
    
    // Check every 6 hours
    _periodicTimer = Timer.periodic(const Duration(hours: 6), (_) {
      debugPrint('[BirthdayService] Running periodic birthday check...');
      _checkBirthdays();
    });
  }

  /// Check for birthdays and send notifications
  Future<void> _checkBirthdays() async {
    try {
      final now = DateTime.now();
      debugPrint('[BirthdayService] 🎂 ========================================');
      debugPrint('[BirthdayService] 🎂 Checking birthdays for ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
      debugPrint('[BirthdayService] 🎂 ========================================');
      
      await NotificationService().checkAndSendBirthdayNotifications();
      
      debugPrint('[BirthdayService] ✅ Birthday check completed');
      debugPrint('[BirthdayService] ========================================');
    } catch (e, stackTrace) {
      debugPrint('[BirthdayService] ❌ ========================================');
      debugPrint('[BirthdayService] ❌ CRITICAL ERROR during birthday check:');
      debugPrint('[BirthdayService] ❌ Error: $e');
      debugPrint('[BirthdayService] ❌ StackTrace: $stackTrace');
      debugPrint('[BirthdayService] ❌ ========================================');
    }
  }

  /// Manual trigger for testing
  Future<void> checkNow() async {
    debugPrint('[BirthdayService] Manual birthday check triggered');
    await _checkBirthdays();
  }

  /// Dispose of timers
  void dispose() {
    _dailyTimer?.cancel();
    _periodicTimer?.cancel();
    _isInitialized = false;
    debugPrint('[BirthdayService] Service disposed');
  }
}
