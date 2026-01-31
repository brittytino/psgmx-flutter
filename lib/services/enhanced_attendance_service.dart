import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import '../models/app_user.dart';

// AttendanceSummary is defined in models/attendance.dart

class ScheduledAttendanceDate {
  final String id;
  final DateTime date;
  final String? scheduledBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduledAttendanceDate({
    required this.id,
    required this.date,
    this.scheduledBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduledAttendanceDate.fromMap(Map<String, dynamic> data) {
    return ScheduledAttendanceDate(
      id: data['id'] ?? '',
      date: DateTime.parse(data['date']),
      scheduledBy: data['scheduled_by'],
      notes: data['notes'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'scheduled_by': scheduledBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final String studentId;
  final String studentName;
  final String regNo;
  final String teamId;
  final AttendanceStatus status;
  final String markedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.studentId,
    required this.studentName,
    required this.regNo,
    required this.teamId,
    required this.status,
    required this.markedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> data) {
    // Support both student_id and user_id columns
    final studentIdValue = data['student_id'] ?? data['user_id'] ?? '';
    return AttendanceRecord(
      id: data['id'] ?? '',
      date: DateTime.parse(data['date']),
      studentId: studentIdValue,
      studentName: data['student_name'] ?? '',
      regNo: data['reg_no'] ?? '',
      teamId: data['team_id'] ?? '',
      status: AttendanceStatus.fromString(data['status'] ?? 'NA'),
      markedBy: data['marked_by'] ?? '',
      notes: data['notes'],
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'user_id': studentId,
      'team_id': teamId,
      'status': status.displayName,
      'marked_by': markedBy,
      'notes': notes,
    };
  }
}

class EnhancedAttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // SCHEDULED DATES MANAGEMENT
  // ========================================

  /// Check if a date is scheduled for attendance marking
  Future<bool> isDateScheduled(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('scheduled_attendance_dates')
          .select('id')
          .eq('date', dateStr)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error checking if date is scheduled: $e');
      return false;
    }
  }

  /// Get all scheduled dates in a date range
  Future<List<ScheduledAttendanceDate>> getScheduledDates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('scheduled_attendance_dates')
          .select()
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: true);

      return (response as List)
          .map((data) => ScheduledAttendanceDate.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get scheduled dates: $e');
    }
  }

  /// Schedule a new date for attendance (Placement Rep only)
  Future<ScheduledAttendanceDate> scheduleDate({
    required DateTime date,
    required String scheduledBy,
    String? notes,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('scheduled_attendance_dates')
          .upsert({
            'date': dateStr,
            'scheduled_by': scheduledBy,
            'notes': notes,
          })
          .select()
          .single();

      return ScheduledAttendanceDate.fromMap(response);
    } catch (e) {
      throw Exception('Failed to schedule date: $e');
    }
  }

  /// Update scheduled date
  Future<ScheduledAttendanceDate> updateScheduledDate({
    required String id,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('scheduled_attendance_dates')
          .update({'notes': notes})
          .eq('id', id)
          .select()
          .single();

      return ScheduledAttendanceDate.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update scheduled date: $e');
    }
  }

  /// Delete scheduled date
  Future<void> deleteScheduledDate(String id) async {
    try {
      await _supabase
          .from('scheduled_attendance_dates')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete scheduled date: $e');
    }
  }

  // ========================================
  // ATTENDANCE MARKING
  // ========================================

  /// Mark attendance for multiple students (Team Leader)
  Future<void> markTeamAttendance({
    required DateTime date,
    required String teamId,
    required Map<String, AttendanceStatus> studentStatuses,
    required String markedBy,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Check if date is scheduled
      final isScheduled = await isDateScheduled(date);
      if (!isScheduled) {
        throw Exception('Attendance can only be marked on scheduled dates');
      }

      // Prepare batch insert/update
      final records = studentStatuses.entries.map((entry) {
        return {
          'date': dateStr,
          'user_id': entry.key,
          'team_id': teamId,
          'status': entry.value.displayName,
          'marked_by': markedBy,
        };
      }).toList();

      // Upsert all records
      await _supabase
          .from('attendance_records')
          .upsert(records, onConflict: 'date,user_id');
    } catch (e) {
      throw Exception('Failed to mark team attendance: $e');
    }
  }

  /// Update single attendance record (Placement Rep)
  Future<void> updateAttendance({
    required String recordId,
    required AttendanceStatus status,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('attendance_records')
          .update({
            'status': status.displayName,
            'notes': notes,
          })
          .eq('id', recordId);
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // ========================================
  // ATTENDANCE RETRIEVAL
  // ========================================

  /// Get student's own attendance records
  Future<List<AttendanceRecord>> getMyAttendance(String studentId) async {
    try {
      final response = await _supabase
          .from('attendance_records')
          .select('*, users!attendance_records_user_id_fkey(name, reg_no)')
          .eq('user_id', studentId)
          .order('date', ascending: false);

      return (response as List).map((data) {
        return AttendanceRecord.fromMap({
          ...data,
          'student_name': data['users']?['name'] ?? '',
          'reg_no': data['users']?['reg_no'] ?? '',
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get my attendance: $e');
    }
  }

  /// Get team attendance for a specific date
  Future<List<AttendanceRecord>> getTeamAttendanceForDate({
    required DateTime date,
    required String teamId,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .rpc('get_team_attendance_for_date', params: {
            'check_date': dateStr,
            'check_team_id': teamId,
          });

      return (response as List).map((data) => AttendanceRecord.fromMap({
        'id': data['student_id'],
        'date': dateStr,
        'student_id': data['student_id'],
        'student_name': data['student_name'] ?? '',
        'reg_no': data['reg_no'] ?? '',
        'team_id': teamId,
        'status': data['status'] ?? 'NA',
        'marked_by': data['marked_by'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to get team attendance for date: $e');
    }
  }

  /// Get all team members with attendance for a date range
  Future<List<AttendanceRecord>> getTeamAttendance({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('attendance_records')
          .select('*, users!attendance_records_user_id_fkey(name, reg_no)')
          .eq('team_id', teamId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((data) {
        return AttendanceRecord.fromMap({
          ...data,
          'student_name': data['users']?['name'] ?? '',
          'reg_no': data['users']?['reg_no'] ?? '',
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get team attendance: $e');
    }
  }

  /// Get all attendance records (Placement Rep only)
  Future<List<AttendanceRecord>> getAllAttendance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('attendance_records')
          .select('*, users!attendance_records_user_id_fkey(name, reg_no)');

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((data) {
        return AttendanceRecord.fromMap({
          ...data,
          'student_name': data['users']?['name'] ?? '',
          'reg_no': data['users']?['reg_no'] ?? '',
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all attendance: $e');
    }
  }

  // ========================================
  // ATTENDANCE SUMMARY
  // ========================================

  /// Get student attendance summary
  Future<AttendanceSummary> getStudentSummary(String studentId) async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select()
          .eq('student_id', studentId)
          .single();

      return AttendanceSummary.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get student summary: $e');
    }
  }

  /// Get team attendance summary
  Future<List<AttendanceSummary>> getTeamSummary(String teamId) async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select()
          .eq('team_id', teamId)
          .order('name');

      return (response as List)
          .map((data) => AttendanceSummary.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get team summary: $e');
    }
  }

  /// Get all students attendance summary (Placement Rep only)
  Future<List<AttendanceSummary>> getAllSummary() async {
    try {
      final response = await _supabase
          .from('student_attendance_summary')
          .select()
          .order('team_id')
          .order('name');

      return (response as List)
          .map((data) => AttendanceSummary.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all summary: $e');
    }
  }

  // ========================================
  // TEAM MANAGEMENT
  // ========================================

  /// Get all team members for attendance marking
  Future<List<AppUser>> getTeamMembers(String teamId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('team_id', teamId)
          .order('reg_no');

      return (response as List)
          .map((data) => AppUser.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get team members: $e');
    }
  }
}
