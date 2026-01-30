import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

/// A facade service specifically designed to support the UI's needs
/// aggregating underlying Supabase calls.
class SupabaseDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // Task Management
  // ==========================================

  /// Publishes daily tasks.
  /// The UI presents this as a single form, but we store it as multiple rows
  /// in the daily_tasks table (one for LeetCode, one for Core topic).
  Future<void> publishDailyTask(CompositeTask task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final updates = <Future>[];

    // 1. Insert LeetCode Task
    if (task.leetcodeUrl.isNotEmpty) {
      updates.add(_supabase.from('daily_tasks').upsert({
        'date': task.date,
        'topic_type': 'leetcode',
        'title': 'Daily LeetCode',
        'reference_link': task.leetcodeUrl,
        'uploaded_by': user.id,
      }, onConflict: 'date, topic_type, title'));
    }

    // 2. Insert Core Task
    if (task.csTopic.isNotEmpty) {
      updates.add(_supabase.from('daily_tasks').upsert({
        'date': task.date,
        'topic_type': 'core',
        'title': task.csTopic,
        'subject': task.csTopicDescription,
        // We use 'subject' column for description storage as per our interpretation
        'uploaded_by': user.id,
      }, onConflict: 'date, topic_type, title'));
    }

    await Future.wait(updates);
  }

  /// Retrieves the tasks for a day and combines them into a single view model
  Stream<CompositeTask?> getDailyTask(String dateStr) {
    return _supabase
        .from('daily_tasks')
        .stream(primaryKey: ['id'])
        .eq('date', dateStr)
        .map((rows) {
          if (rows.isEmpty) return null;

          String leetcode = '';
          String topic = '';
          String desc = '';

          for (var row in rows) {
            final type = row['topic_type'];
            if (type == 'leetcode') {
              leetcode = row['reference_link'] ?? '';
            } else if (type == 'core') {
              topic = row['title'] ?? '';
              desc = row['subject'] ?? ''; // Using subject for description
            }
          }

          if (leetcode.isEmpty && topic.isEmpty) return null;

          return CompositeTask(
            date: dateStr,
            leetcodeUrl: leetcode,
            csTopic: topic,
            csTopicDescription: desc,
            motivationQuote: '',
          );
        });
  }

  // ==========================================
  // Attendance Management
  // ==========================================

  Future<bool> isAttendanceSubmitted(String teamId, String date) async {
    // Check if any attendance record exists for this team on this date
    // marked by the team leader vs a rep override?
    // Usually one record per student.
    final count = await _supabase
        .from('attendance_records')
        .count()
        .eq('team_id', teamId)
        .eq('date', date);

    return count > 0;
  }

  Future<List<AppUser>> getTeamMembers(String teamId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('team_id', teamId)
        .order('reg_no');

    return (response as List).map((e) => AppUser.fromMap(e)).toList();
  }

  Future<void> submitTeamAttendance(String teamId, String date,
      String markedByUid, List<AttendanceRecord> records) async {
    final validRecords = records
        .map((r) => {
              'date': date,
              'student_id': r.studentUid,
              'team_id': teamId,
              'status': r.isPresent ? 'PRESENT' : 'ABSENT',
              'marked_by': markedByUid,
            })
        .toList();

    await _supabase
        .from('attendance_records')
        .upsert(validRecords, onConflict: 'date, student_id');
  }

  Future<void> overrideAttendance(String regNo, String date, bool isPresent,
      String actorId, String reason) async {
    // 1. Find student by Reg No
    final studentRes = await _supabase
        .from('users')
        .select('id, team_id')
        .eq('reg_no', regNo)
        .maybeSingle();

    if (studentRes == null) {
      throw Exception("Student with Reg No $regNo not found");
    }

    final studentId = studentRes['id'];
    final teamId = studentRes['team_id'];

    // 2. Upsert Attendance
    await _supabase.from('attendance_records').upsert({
      'date': date,
      'student_id': studentId,
      'team_id': teamId ?? 'NA',
      'status': isPresent ? 'PRESENT' : 'ABSENT',
      'marked_by': actorId
    }, onConflict: 'date, student_id');

    // 3. Log Audit
    await _supabase.from('audit_logs').insert({
      'actor_id': actorId,
      'action': 'OVERRIDE_ATTENDANCE',
      'entity_type': 'attendance',
      'entity_id': studentId,
      'metadata': {
        'date': date,
        'new_status': isPresent ? 'PRESENT' : 'ABSENT',
        'reason': reason
      }
    });
  }

  Stream<List<AttendanceRecord>> getStudentAttendance(String studentId) {
    return _supabase
        .from('attendance_records')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('date', ascending: false)
        .map((rows) => rows
            .map((row) => AttendanceRecord(
                  id: row['id'],
                  date: row['date'],
                  studentUid: row['student_id'],
                  regNo: '', // Not needed for list view
                  teamId: row['team_id'],
                  isPresent: row['status'] == 'PRESENT',
                  timestamp: DateTime.parse(row['created_at']),
                  markedBy: row['marked_by'],
                ))
            .toList());
  }

  // ==========================================
  // Bulk & Advanced Operations
  // ==========================================

  Future<int> bulkPublishTasks(List<CompositeTask> tasks) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final List<Map<String, dynamic>> rows = [];

    for (var task in tasks) {
      if (task.leetcodeUrl.isNotEmpty) {
        rows.add({
          'date': task.date,
          'topic_type': 'leetcode',
          'title': 'Daily LeetCode',
          'reference_link': task.leetcodeUrl,
          'uploaded_by': user.id,
        });
      }
      if (task.csTopic.isNotEmpty) {
        rows.add({
          'date': task.date,
          'topic_type': 'core',
          'title': task.csTopic,
          'subject': task.csTopicDescription,
          'uploaded_by': user.id,
        });
      }
    }

    if (rows.isEmpty) return 0;

    await _supabase
        .from('daily_tasks')
        .upsert(rows, onConflict: 'date, topic_type, title');
    return rows.length;
  }

  Future<Map<String, dynamic>> getPlacementStats() async {
    try {
      // 1. Total Students from USERS table (all 123 students now in users)
      final usersResponse = await _supabase
          .from('users')
          .select()
          .eq('roles->>isStudent', 'true');
      final totalStudents = (usersResponse as List).length;

      // 2. Count today's attendance
      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendanceResponse = await _supabase
          .from('attendance_records')
          .select()
          .eq('date', today)
          .eq('status', 'PRESENT');
      final todayPresent = (attendanceResponse as List).length;

      return {
        'total_students': totalStudents,
        'today_present': todayPresent,
      };
    } catch (e) {
      // Return safe defaults if query fails
      return {
        'total_students': 0,
        'today_present': 0,
      };
    }
  }

  Future<List<AppUser>> getAllStudents() async {
    final response = await _supabase.from('users').select().order('reg_no');

    return (response as List)
        .map((e) => AppUser.fromMap(e))
        .where((u) => u.isStudent)
        .toList();
  }
}

/// Helper model for the UI to handle the combo-task view
class CompositeTask {
  final String date;
  final String leetcodeUrl;
  final String csTopic;
  final String csTopicDescription;
  final String motivationQuote;

  CompositeTask({
    required this.date,
    required this.leetcodeUrl,
    required this.csTopic,
    required this.csTopicDescription,
    required this.motivationQuote,
  });
}

/// Helper model for UI attendance operations
class AttendanceRecord {
  final String id;
  final String date;
  final String studentUid;
  final String regNo;
  final String teamId;
  final bool isPresent;
  final DateTime timestamp;
  final String markedBy;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.studentUid,
    required this.regNo,
    required this.teamId,
    required this.isPresent,
    required this.timestamp,
    required this.markedBy,
  });
}
