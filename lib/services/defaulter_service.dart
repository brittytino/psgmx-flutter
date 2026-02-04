import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_streak.dart';

/// Service for managing defaulter detection and flagging (B1)
/// This service is for Team Leaders and Placement Reps only
class DefaulterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Default thresholds
  static const double defaultAttendanceThreshold = 75.0;
  static const int defaultConsecutiveAbsences = 3;

  // ========================================
  // DEFAULTER DETECTION
  // ========================================

  /// Run defaulter check manually (admin only)
  Future<void> runDefaulterCheck({
    double threshold = defaultAttendanceThreshold,
    int consecutiveDays = defaultConsecutiveAbsences,
  }) async {
    try {
      await _supabase.rpc('check_and_flag_defaulters', params: {
        'p_threshold': threshold,
        'p_consecutive_days': consecutiveDays,
      });
      debugPrint('[DefaulterService] Defaulter check completed');
    } catch (e) {
      debugPrint(
          '[DefaulterService] Error running check (may need fallback): $e');
      // Fallback to local calculation if DB function unavailable
      await _runLocalDefaulterCheck(threshold, consecutiveDays);
    }
  }

  /// Local defaulter check fallback
  Future<void> _runLocalDefaulterCheck(
      double threshold, int consecutiveDays) async {
    try {
      // Get all students
      final studentsResponse = await _supabase
          .from('users')
          .select('id, team_id')
          .contains('roles', {'isStudent': true});

      for (var student in studentsResponse as List) {
        final studentId = student['id'] as String;

        // Get attendance records
        final recordsResponse = await _supabase
            .from('attendance_records')
            .select('date, status')
            .eq('user_id', studentId)
            .order('date', ascending: false)
            .limit(30);

        final records = recordsResponse as List;

        // Count consecutive absences
        int consecutiveAbsences = 0;
        for (var record in records) {
          if (record['status'] == 'ABSENT') {
            consecutiveAbsences++;
          } else {
            break;
          }
        }

        // Calculate attendance percentage
        final presentCount =
            records.where((r) => r['status'] == 'PRESENT').length;
        final totalCount = records.length;
        final percentage =
            totalCount > 0 ? (presentCount / totalCount) * 100 : 100.0;

        // Check if should be flagged
        final shouldFlag =
            consecutiveAbsences >= consecutiveDays || percentage < threshold;

        if (shouldFlag) {
          String reason;
          if (consecutiveAbsences >= consecutiveDays &&
              percentage < threshold) {
            reason = 'Consecutive absences AND low attendance percentage';
          } else if (consecutiveAbsences >= consecutiveDays) {
            reason = 'Consecutive absences: $consecutiveAbsences days';
          } else {
            reason =
                'Low attendance percentage: ${percentage.toStringAsFixed(1)}%';
          }

          await _supabase.from('defaulter_flags').upsert({
            'user_id': studentId,
            'defaulter_status': true,
            'defaulter_reason': reason,
            'consecutive_absences': consecutiveAbsences,
            'attendance_percentage': percentage,
            'detected_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
        } else {
          // Clear flag if conditions no longer met
          await _supabase
              .from('defaulter_flags')
              .update({
                'defaulter_status': false,
                'resolved_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', studentId)
              .eq('defaulter_status', true);
        }
      }
    } catch (e) {
      debugPrint('[DefaulterService] Error in local check: $e');
    }
  }

  // ========================================
  // TEAM LEADER VIEWS
  // ========================================

  /// Get defaulters in a team (Team Leader view)
  Future<List<DefaulterInfo>> getTeamDefaulters(String teamId) async {
    try {
      final response = await _supabase
          .from('defaulter_flags')
          .select('''
            *,
            users!defaulter_flags_user_id_fkey!inner(id, name, reg_no, team_id, email)
          ''')
          .eq('users.team_id', teamId)
          .eq('defaulter_status', true)
          .order('detected_at', ascending: false);

      return (response as List).map((r) {
        final user = r['users'] as Map<String, dynamic>;
        return DefaulterInfo(
          flag: DefaulterFlag.fromMap(r),
          studentName: user['name'] ?? '',
          studentRegNo: user['reg_no'] ?? '',
          studentEmail: user['email'] ?? '',
          teamId: user['team_id'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[DefaulterService] Error getting team defaulters: $e');
      return [];
    }
  }

  /// Get count of defaulters in a team
  Future<int> getTeamDefaulterCount(String teamId) async {
    try {
      final defaulters = await getTeamDefaulters(teamId);
      return defaulters.length;
    } catch (e) {
      return 0;
    }
  }

  // ========================================
  // PLACEMENT REP VIEWS
  // ========================================

  /// Get all defaulters (Placement Rep view)
  Future<List<DefaulterInfo>> getAllDefaulters() async {
    try {
      final response = await _supabase
          .from('defaulter_flags')
          .select('''
            *,
            users!defaulter_flags_user_id_fkey!inner(id, name, reg_no, team_id, email, batch)
          ''')
          .eq('defaulter_status', true)
          .order('detected_at', ascending: false);

      return (response as List).map((r) {
        final user = r['users'] as Map<String, dynamic>;
        return DefaulterInfo(
          flag: DefaulterFlag.fromMap(r),
          studentName: user['name'] ?? '',
          studentRegNo: user['reg_no'] ?? '',
          studentEmail: user['email'] ?? '',
          teamId: user['team_id'] ?? '',
          batch: user['batch'],
        );
      }).toList();
    } catch (e) {
      debugPrint('[DefaulterService] Error getting all defaulters: $e');
      return [];
    }
  }

  /// Get defaulters grouped by team
  Future<Map<String, List<DefaulterInfo>>> getDefaultersByTeam() async {
    final defaulters = await getAllDefaulters();
    final grouped = <String, List<DefaulterInfo>>{};

    for (var d in defaulters) {
      final team = d.teamId ?? 'Unknown';
      grouped.putIfAbsent(team, () => []);
      grouped[team]!.add(d);
    }

    return grouped;
  }

  /// Get defaulter statistics
  Future<DefaulterStats> getDefaulterStats() async {
    try {
      final allDefaulters = await getAllDefaulters();

      // Count by reason type
      int lowAttendanceCount = 0;
      int consecutiveAbsenceCount = 0;
      int bothCount = 0;

      for (var d in allDefaulters) {
        final reason = d.flag.defaulterReason.toLowerCase();
        if (reason.contains('and')) {
          bothCount++;
        } else if (reason.contains('consecutive')) {
          consecutiveAbsenceCount++;
        } else {
          lowAttendanceCount++;
        }
      }

      return DefaulterStats(
        totalDefaulters: allDefaulters.length,
        lowAttendanceCount: lowAttendanceCount,
        consecutiveAbsenceCount: consecutiveAbsenceCount,
        bothCount: bothCount,
      );
    } catch (e) {
      debugPrint('[DefaulterService] Error getting stats: $e');
      return DefaulterStats.empty();
    }
  }

  // ========================================
  // NOTIFICATIONS (B1 - Admin Only)
  // ========================================

  /// Notify team leader about defaulters
  Future<void> notifyTeamLeaderAboutDefaulters(String teamId) async {
    try {
      final defaulters = await getTeamDefaulters(teamId);
      if (defaulters.isEmpty) return;

      // Get team leader
      final leaderResponse = await _supabase
          .from('users')
          .select('id, name')
          .eq('team_id', teamId)
          .contains('roles', {'isTeamLeader': true}).maybeSingle();

      if (leaderResponse == null) return;

      // Create in-app notification for team leader
      await _supabase.from('notifications').insert({
        'title': '⚠️ Attendance Alert: ${defaulters.length} student(s) flagged',
        'message':
            'Team $teamId has ${defaulters.length} student(s) with attendance issues. Please check the reports.',
        'notification_type': 'alert',
        'tone': 'serious',
        'target_audience': 'team_leaders',
        'is_active': true,
      });

      debugPrint('[DefaulterService] Notified team leader of $teamId');
    } catch (e) {
      debugPrint('[DefaulterService] Error notifying team leader: $e');
    }
  }

  /// Notify placement rep about all defaulters
  Future<void> notifyPlacementRepAboutDefaulters() async {
    try {
      final stats = await getDefaulterStats();
      if (stats.totalDefaulters == 0) return;

      await _supabase.from('notifications').insert({
        'title': '📊 Weekly Defaulter Report',
        'message':
            'There are ${stats.totalDefaulters} students flagged for attendance issues. '
                '${stats.lowAttendanceCount} low attendance, ${stats.consecutiveAbsenceCount} consecutive absences.',
        'notification_type': 'alert',
        'tone': 'serious',
        'target_audience': 'placement_reps',
        'is_active': true,
      });

      debugPrint('[DefaulterService] Notified placement rep');
    } catch (e) {
      debugPrint('[DefaulterService] Error notifying placement rep: $e');
    }
  }

  // ========================================
  // RESOLUTION
  // ========================================

  /// Resolve a defaulter flag (mark as resolved)
  Future<bool> resolveDefaulterFlag({
    required String userId,
    required String resolvedBy,
    String? notes,
  }) async {
    try {
      await _supabase.from('defaulter_flags').update({
        'defaulter_status': false,
        'resolved_at': DateTime.now().toIso8601String(),
        'resolved_by': resolvedBy,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('[DefaulterService] Error resolving flag: $e');
      return false;
    }
  }
}

/// Combined model for defaulter info with user details
class DefaulterInfo {
  final DefaulterFlag flag;
  final String studentName;
  final String studentRegNo;
  final String studentEmail;
  final String? teamId;
  final String? batch;

  const DefaulterInfo({
    required this.flag,
    required this.studentName,
    required this.studentRegNo,
    required this.studentEmail,
    this.teamId,
    this.batch,
  });
}

/// Statistics about defaulters
class DefaulterStats {
  final int totalDefaulters;
  final int lowAttendanceCount;
  final int consecutiveAbsenceCount;
  final int bothCount;

  const DefaulterStats({
    required this.totalDefaulters,
    required this.lowAttendanceCount,
    required this.consecutiveAbsenceCount,
    required this.bothCount,
  });

  factory DefaulterStats.empty() {
    return const DefaulterStats(
      totalDefaulters: 0,
      lowAttendanceCount: 0,
      consecutiveAbsenceCount: 0,
      bothCount: 0,
    );
  }
}
