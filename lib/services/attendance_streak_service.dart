import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_streak.dart';
import 'attendance_service.dart';

/// Service for calculating real attendance streaks and providing
/// attendance calculation explanations (A3 & A4)
class AttendanceStreakService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AttendanceService _attendanceService = AttendanceService();

  // ========================================
  // A3: REAL ATTENDANCE STREAK CALCULATION
  // ========================================

  /// Get attendance streak for current user
  Future<AttendanceStreak> getMyAttendanceStreak() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return AttendanceStreak.empty();

    return getStudentAttendanceStreak(user.id);
  }

  /// Get attendance streak for a specific student
  Future<AttendanceStreak> getStudentAttendanceStreak(String studentId) async {
    try {
      // Try to use the database function first
      final response = await _supabase.rpc(
        'calculate_attendance_streak',
        params: {'p_user_id': studentId},
      );

      if (response != null && (response as List).isNotEmpty) {
        return AttendanceStreak.fromMap(response[0]);
      }

      // Fallback: Calculate locally if function doesn't exist
      return await _calculateStreakLocally(studentId);
    } catch (e) {
      debugPrint('[AttendanceStreakService] Error from RPC, falling back: $e');
      // Fallback to local calculation
      return await _calculateStreakLocally(studentId);
    }
  }

  /// Local streak calculation (fallback if DB function unavailable)
  Future<AttendanceStreak> _calculateStreakLocally(String studentId) async {
    try {
      // Get all attendance records for the student
      final recordsResponse = await _supabase
          .from('attendance_records')
          .select('date, status')
          .eq('user_id', studentId)
          .order('date', ascending: false);

      // Get scheduled attendance dates info
      final daysResponse = await _supabase
          .from('scheduled_attendance_dates')
          .select('date, is_working_day');

      // Build a map of dates to working day status
      final workingDayMap = <String, bool>{};
      for (var day in daysResponse as List) {
        workingDayMap[day['date']] = day['is_working_day'] ?? true;
      }

      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;
      bool streakBroken = false;
      int totalClassDays = 0;
      int totalNonClassDays = 0;

      // Count class days vs non-class days
      for (var entry in workingDayMap.entries) {
        if (entry.value) {
          totalClassDays++;
        } else {
          totalNonClassDays++;
        }
      }

      // Calculate streaks
      for (var record in recordsResponse as List) {
        final dateStr = record['date'] as String;
        final status = record['status'] as String;

        // Skip non-class days
        final isClassDay = workingDayMap[dateStr] ??
            _attendanceService._isDefaultClassDay(DateTime.parse(dateStr));
        if (!isClassDay) continue;

        if (status == 'PRESENT') {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          // First absence breaks the current streak
          if (!streakBroken) {
            currentStreak = tempStreak;
            streakBroken = true;
          }
          tempStreak = 0;
        }
      }

      // If no absence found, current streak equals temp streak
      if (!streakBroken) {
        currentStreak = tempStreak;
      }

      return AttendanceStreak(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        totalClassDays: totalClassDays,
        totalNonClassDays: totalNonClassDays,
      );
    } catch (e) {
      debugPrint('[AttendanceStreakService] Error calculating locally: $e');
      return AttendanceStreak.empty();
    }
  }

  // ========================================
  // A4: ATTENDANCE CALCULATION EXPLANATION
  // ========================================

  /// Get detailed attendance calculation for current user
  Future<AttendanceCalculation> getMyAttendanceCalculation() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return AttendanceCalculation.empty();

    return getStudentAttendanceCalculation(user.id);
  }

  /// Get detailed attendance calculation for a specific student
  Future<AttendanceCalculation> getStudentAttendanceCalculation(
    String studentId,
  ) async {
    try {
      // Get all attendance records for the student
      final recordsResponse = await _supabase
          .from('attendance_records')
          .select('date, status')
          .eq('user_id', studentId);

      // Get scheduled attendance dates info (all dates marked)
      final daysResponse = await _supabase
          .from('scheduled_attendance_dates')
          .select('date, is_working_day');

      // Build working day map
      final workingDayMap = <String, bool>{};
      for (var day in daysResponse as List) {
        workingDayMap[day['date']] = day['is_working_day'] ?? true;
      }

      // Count stats
      int presentCount = 0;
      int absentCount = 0;
      int totalClassDays = 0;
      int totalNonClassDays = 0;
      DateTime? startDate;
      DateTime? endDate;

      // Get unique dates from scheduled_attendance_dates
      for (var entry in workingDayMap.entries) {
        final date = DateTime.parse(entry.key);
        if (entry.value) {
          totalClassDays++;
        } else {
          totalNonClassDays++;
        }
        if (startDate == null || date.isBefore(startDate)) {
          startDate = date;
        }
        if (endDate == null || date.isAfter(endDate)) {
          endDate = date;
        }
      }

      // Count present/absent from records
      for (var record in recordsResponse as List) {
        final dateStr = record['date'] as String;
        final status = record['status'] as String;

        // Only count class days
        final isClassDay = workingDayMap[dateStr] ??
            _attendanceService._isDefaultClassDay(DateTime.parse(dateStr));

        if (!isClassDay) continue;

        if (status == 'PRESENT') {
          presentCount++;
        } else if (status == 'ABSENT') {
          absentCount++;
        }
      }

      // Calculate percentage
      final percentage =
          totalClassDays > 0 ? (presentCount / totalClassDays) * 100 : 0.0;

      return AttendanceCalculation(
        presentCount: presentCount,
        absentCount: absentCount,
        totalClassDays: totalClassDays,
        totalNonClassDays: totalNonClassDays,
        attendancePercentage: percentage,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('[AttendanceStreakService] Error getting calculation: $e');
      return AttendanceCalculation.empty();
    }
  }

  // ========================================
  // B1: DEFAULTER DETECTION
  // ========================================

  /// Get defaulter flags for a team (Team Leader view)
  Future<List<DefaulterFlag>> getTeamDefaulterFlags(String teamId) async {
    try {
      final response = await _supabase.from('defaulter_flags').select('''
            *,
            users!defaulter_flags_user_id_fkey!inner(team_id)
          ''').eq('users.team_id', teamId).eq('defaulter_status', true);

      return (response as List).map((r) => DefaulterFlag.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[AttendanceStreakService] Error getting team defaulters: $e');
      return [];
    }
  }

  /// Get all defaulter flags (Placement Rep view)
  Future<List<DefaulterFlag>> getAllDefaulterFlags() async {
    try {
      final response = await _supabase
          .from('defaulter_flags')
          .select()
          .eq('defaulter_status', true)
          .order('detected_at', ascending: false);

      return (response as List).map((r) => DefaulterFlag.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[AttendanceStreakService] Error getting all defaulters: $e');
      return [];
    }
  }

  /// Trigger defaulter check (admin only)
  Future<void> runDefaulterCheck({
    double threshold = 75.0,
    int consecutiveDays = 3,
  }) async {
    try {
      await _supabase.rpc('check_and_flag_defaulters', params: {
        'p_threshold': threshold,
        'p_consecutive_days': consecutiveDays,
      });
      debugPrint('[AttendanceStreakService] Defaulter check completed');
    } catch (e) {
      debugPrint('[AttendanceStreakService] Error running defaulter check: $e');
    }
  }
}

// Extension to expose private method for local calculation
extension on AttendanceService {
  bool _isDefaultClassDay(DateTime date) {
    final weekday = date.weekday;

    // Mon (1), Tue (2), Thu (4)
    if (weekday == DateTime.monday ||
        weekday == DateTime.tuesday ||
        weekday == DateTime.thursday) {
      return true;
    }

    // Odd Saturdays ONLY
    if (weekday == DateTime.saturday) {
      final day = date.day;
      if (day <= 7) return true; // 1st
      if (day >= 15 && day <= 21) return true; // 3rd
      if (day >= 29) return true; // 5th
      return false;
    }

    return false;
  }
}
