import '../models/app_user.dart';
import '../models/task_attendance.dart';
import 'supabase_service.dart';

class SupabaseDbService {
  final SupabaseService _supabaseService;

  SupabaseDbService(this._supabaseService);

  // --- Task Methods ---
  Stream<DailyTask?> getDailyTask(String date) {
    return _supabaseService
        .from('daily_tasks')
        .stream(primaryKey: ['id'])
        .eq('date', date)
        .map((data) {
          if (data.isEmpty) return null;
          return DailyTask.fromMap(data.first, data.first['date']);
        });
  }

  Future<void> publishDailyTask(DailyTask task) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _supabaseService.from('daily_tasks').upsert({
      'date': task.date,
      'leetcode_url': task.leetcodeUrl,
      'cs_topic': task.csTopic,
      'cs_topic_description': task.csTopicDescription,
      'motivation_quote': task.motivationQuote,
      'created_by': currentUser.id,
    });
  }

  // --- Student Methods ---
  Future<List<AppUser>> getTeamMembers(String teamId) async {
    final response = await _supabaseService
        .from('users')
        .select()
        .eq('team_id', teamId)
        .eq('roles->>isStudent', true);

    return response
        .map<AppUser>((data) => AppUser.fromMap(data['id'], data))
        .toList();
  }

  // --- Attendance Methods ---
  Future<bool> isAttendanceSubmitted(String teamId, String date) async {
    final response = await _supabaseService
        .from('attendance_submissions')
        .select('id')
        .eq('date', date)
        .eq('team_id', teamId)
        .maybeSingle();

    return response != null;
  }

  Future<void> submitTeamAttendance(
    String teamId,
    String date,
    String leaderUid,
    List<AttendanceRecord> records,
  ) async {
    try {
      // 1. Insert submission record
      await _supabaseService.from('attendance_submissions').insert({
        'date': date,
        'team_id': teamId,
        'submitted_by': leaderUid,
      });

      // 2. Insert individual attendance records
      final attendanceData = records.map((record) => {
        'date': date,
        'student_uid': record.studentUid,
        'reg_no': record.regNo,
        'team_id': teamId,
        'status': record.isPresent ? 'PRESENT' : 'ABSENT',
        'marked_by': leaderUid,
      }).toList();

      await _supabaseService.from('attendance_records').insert(attendanceData);
    } catch (e) {
      throw Exception('Failed to submit attendance: $e');
    }
  }

  // --- Student View ---
  Stream<List<AttendanceRecord>> getStudentAttendance(String uid) {
    return _supabaseService
        .from('attendance_records')
        .stream(primaryKey: ['id'])
        .eq('student_uid', uid)
        .order('date', ascending: false)
        .map((data) => data
            .map<AttendanceRecord>((item) => AttendanceRecord.fromMap(item, item['id']))
            .toList());
  }

  // --- Rep Override ---
  Future<void> overrideAttendance(
    String regNo,
    String date,
    bool newStatus,
    String repUid,
    String reason,
  ) async {
    try {
      // Get existing record
      final existing = await _supabaseService
          .from('attendance_records')
          .select()
          .eq('date', date)
          .eq('reg_no', regNo)
          .maybeSingle();

      String prevStatus = existing?['status'] ?? 'UNKNOWN';

      // Upsert attendance record
      await _supabaseService.from('attendance_records').upsert({
        'date': date,
        'reg_no': regNo,
        'status': newStatus ? 'PRESENT' : 'ABSENT',
        'overridden_by': repUid,
        if (existing != null) ...{
          'id': existing['id'],
          'student_uid': existing['student_uid'],
          'team_id': existing['team_id'],
          'marked_by': existing['marked_by'],
        },
      });

      // Create audit log
      await _supabaseService.from('audit_logs').insert({
        'actor_id': repUid,
        'action': 'OVERRIDE_ATTENDANCE',
        'target_reg_no': regNo,
        'target_date': date,
        'prev_value': prevStatus,
        'new_value': newStatus ? 'PRESENT' : 'ABSENT',
        'reason': reason,
      });
    } catch (e) {
      throw Exception('Failed to override attendance: $e');
    }
  }
}
