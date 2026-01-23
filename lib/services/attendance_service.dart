import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import '../models/attendance_day.dart';
import '../models/audit_log.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // WORKING DAY MANAGEMENT
  // ========================================

  Future<AttendanceDay?> getAttendanceDay(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('attendance_days')
          .select()
          .eq('date', dateString)
          .maybeSingle();

      if (response == null) return null;
      return AttendanceDay.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get attendance day: ${e.toString()}');
    }
  }

  Future<bool> isWorkingDay(DateTime date) async {
    final attendanceDay = await getAttendanceDay(date);
    // If no record exists, default to NOT a working day (NA)
    if (attendanceDay == null) return false;
    return attendanceDay.isWorkingDay;
  }

  Future<List<AttendanceDay>> getAttendanceDaysInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startString = startDate.toIso8601String().split('T')[0];
      final endString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('attendance_days')
          .select()
          .gte('date', startString)
          .lte('date', endString)
          .order('date');

      return (response as List)
          .map((data) => AttendanceDay.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get attendance days: ${e.toString()}');
    }
  }

  Future<void> setWorkingDay({
    required DateTime date,
    required bool isWorkingDay,
    required String decidedBy,
    String? reason,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      await _supabase.from('attendance_days').upsert({
        'date': dateString,
        'is_working_day': isWorkingDay,
        'decided_by': decidedBy,
        'reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create audit log
      final auditLog = AuditLog.createWorkingDayChange(
        actorId: decidedBy,
        date: date,
        isWorkingDay: isWorkingDay,
        reason: reason,
      );
      
      await _createAuditLog(auditLog);
    } catch (e) {
      throw Exception('Failed to set working day: ${e.toString()}');
    }
  }

  Future<void> setBulkWorkingDays({
    required List<DateTime> dates,
    required bool isWorkingDay,
    required String decidedBy,
    String? reason,
  }) async {
    try {
      final records = dates.map((date) {
        final dateString = date.toIso8601String().split('T')[0];
        return {
          'date': dateString,
          'is_working_day': isWorkingDay,
          'decided_by': decidedBy,
          'reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.from('attendance_days').upsert(records);
    } catch (e) {
      throw Exception('Failed to set bulk working days: ${e.toString()}');
    }
  }

  // ========================================
  // ATTENDANCE MARKING
  // ========================================

  Future<void> markAttendance({
    required DateTime date,
    required List<Map<String, dynamic>> studentStatuses,
    required String markedBy,
  }) async {
    try {
      // Check if it's a working day
      final workingDay = await isWorkingDay(date);
      if (!workingDay) {
        throw Exception('Cannot mark attendance on non-working days');
      }

      final dateString = date.toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      final records = studentStatuses.map((entry) {
        return {
          'date': dateString,
          'student_id': entry['student_id'],
          'team_id': entry['team_id'],
          'status': entry['status'],
          'marked_by': markedBy,
          'marked_at': now,
          'updated_at': now,
        };
      }).toList();

      await _supabase.from('attendance').upsert(records);
    } catch (e) {
      throw Exception('Failed to mark attendance: ${e.toString()}');
    }
  }

  Future<Attendance?> getStudentAttendance({
    required String studentId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('student_id', studentId)
          .eq('date', dateString)
          .maybeSingle();

      if (response == null) return null;
      return Attendance.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get student attendance: ${e.toString()}');
    }
  }

  Future<List<Attendance>> getTeamAttendanceForDate({
    required String teamId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('team_id', teamId)
          .eq('date', dateString)
          .order('student_id');

      return (response as List)
          .map((data) => Attendance.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get team attendance: ${e.toString()}');
    }
  }

  Future<List<Attendance>> getStudentAttendanceHistory({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('attendance')
          .select()
          .eq('student_id', studentId);

      if (startDate != null) {
        final startString = startDate.toIso8601String().split('T')[0];
        query = query.gte('date', startString);
      }

      if (endDate != null) {
        final endString = endDate.toIso8601String().split('T')[0];
        query = query.lte('date', endString);
      }

      final response = await query.order('date', ascending: false);

      return (response as List)
          .map((data) => Attendance.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get attendance history: ${e.toString()}');
    }
  }

  // ========================================
  // ATTENDANCE ANALYTICS
  // ========================================

  Future<AttendanceSummary> getStudentAttendanceSummary({
    required String studentId,
  }) async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select()
          .eq('student_id', studentId)
          .single();

      return AttendanceSummary.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get attendance summary: ${e.toString()}');
    }
  }

  Future<List<AttendanceSummary>> getAllStudentsAttendanceSummary() async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select()
          .order('attendance_percentage', ascending: false);

      return (response as List)
          .map((data) => AttendanceSummary.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all students summary: ${e.toString()}');
    }
  }

  Future<List<AttendanceSummary>> getTeamAttendanceSummary({
    required String teamId,
  }) async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select()
          .eq('team_id', teamId)
          .order('attendance_percentage', ascending: false);

      return (response as List)
          .map((data) => AttendanceSummary.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get team summary: ${e.toString()}');
    }
  }

  Future<Map<String, double>> getBatchAttendanceSummary() async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select();

      final data = response as List;
      
      final g1Students = data.where((s) => s['batch'] == 'G1');
      final g2Students = data.where((s) => s['batch'] == 'G2');

      final g1Avg = g1Students.isEmpty
          ? 0.0
          : g1Students
                  .map((s) => (s['attendance_percentage'] ?? 0.0).toDouble())
                  .reduce((a, b) => a + b) /
              g1Students.length;

      final g2Avg = g2Students.isEmpty
          ? 0.0
          : g2Students
                  .map((s) => (s['attendance_percentage'] ?? 0.0).toDouble())
                  .reduce((a, b) => a + b) /
              g2Students.length;

      return {
        'G1': g1Avg,
        'G2': g2Avg,
      };
    } catch (e) {
      throw Exception('Failed to get batch summary: ${e.toString()}');
    }
  }

  // ========================================
  // ATTENDANCE OVERRIDE (PLACEMENT REP ONLY)
  // ========================================

  Future<void> overrideAttendance({
    required String attendanceId,
    required AttendanceStatus newStatus,
    required String overriddenBy,
  }) async {
    try {
      // Get existing attendance
      final existing = await _supabase
          .from('attendance')
          .select()
          .eq('id', attendanceId)
          .single();

      final oldStatus = existing['status'];

      // Update attendance
      await _supabase
          .from('attendance')
          .update({
            'status': newStatus.displayName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', attendanceId);

      // Create audit log
      final auditLog = AuditLog.createAttendanceOverride(
        actorId: overriddenBy,
        attendanceId: attendanceId,
        studentId: existing['student_id'],
        oldStatus: oldStatus,
        newStatus: newStatus.displayName,
        date: DateTime.parse(existing['date']),
      );

      await _createAuditLog(auditLog);
    } catch (e) {
      throw Exception('Failed to override attendance: ${e.toString()}');
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  Future<void> _createAuditLog(AuditLog log) async {
    try {
      await _supabase.from('audit_logs').insert(log.toMap());
    } catch (e) {
      // Silent fail - audit logs are important but not critical
      print('Failed to create audit log: $e');
    }
  }

  /// Generate attendance records for all students for working days
  /// This ensures NA is properly set for non-working days
  Future<void> initializeAttendanceForMonth({
    required int year,
    required int month,
    required List<String> studentIds,
    required Map<String, String> studentTeamMap,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final workingDays = await getAttendanceDaysInRange(
        startDate: startDate,
        endDate: endDate,
      );

      final records = <Map<String, dynamic>>[];

      for (final day in workingDays) {
        for (final studentId in studentIds) {
          final status = day.isWorkingDay
              ? AttendanceStatus.absent.displayName
              : AttendanceStatus.na.displayName;

          records.add({
            'date': day.date.toIso8601String().split('T')[0],
            'student_id': studentId,
            'team_id': studentTeamMap[studentId] ?? '',
            'status': status,
            'marked_by': 'system',
          });
        }
      }

      if (records.isNotEmpty) {
        await _supabase.from('attendance').upsert(records);
      }
    } catch (e) {
      throw Exception('Failed to initialize attendance: ${e.toString()}');
    }
  }
}
