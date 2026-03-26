import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/attendance_day.dart';
import '../models/audit_log.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _dateKey(DateTime date) => date.toIso8601String().split('T')[0];

  // ========================================
  // WORKING DAY MANAGEMENT
  // ========================================

  Future<AttendanceDay?> getAttendanceDay(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('scheduled_attendance_dates')
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
    return attendanceDay?.isWorkingDay ?? false;
  }

  Future<List<AttendanceDay>> getAttendanceDaysInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startString = startDate.toIso8601String().split('T')[0];
      final endString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('scheduled_attendance_dates')
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

  Future<List<DateTime>> getWorkingDaysWithinRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (endDate.isBefore(startDate)) {
      throw Exception('End date cannot be earlier than start date');
    }

    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    final days = await getAttendanceDaysInRange(
      startDate: normalizedStart,
      endDate: normalizedEnd,
    );

    return days
        .where((day) => day.isWorkingDay)
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toList();
  }

  Future<void> setWorkingDay({
    required DateTime date,
    required bool isWorkingDay,
    required String decidedBy,
    String? reason,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];

      await _supabase.from('scheduled_attendance_dates').upsert({
        'date': dateString,
        'is_working_day': isWorkingDay,
        'scheduled_by': decidedBy,
        'notes': reason,
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
          'scheduled_by': decidedBy,
          'notes': reason,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.from('scheduled_attendance_dates').upsert(records);
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
      final normalized = DateTime(date.year, date.month, date.day);
      if (normalized.isAfter(_today)) {
        throw Exception('Attendance cannot be marked for future dates');
      }

      // Check if it's a working day
      final workingDay = await isWorkingDay(normalized);
      if (!workingDay) {
        throw Exception('Cannot mark attendance on non-working days');
      }

      final dateString = _dateKey(normalized);
      final now = DateTime.now().toIso8601String();

      final records = studentStatuses.map((entry) {
        return {
          'date': dateString,
          'user_id': entry['user_id'] ?? entry['student_id'],
          'team_id': entry['team_id'],
          'status': entry['status'],
          'marked_by': markedBy,
          'updated_at': now,
        };
      }).toList();

      await _supabase.from('attendance_records').upsert(records);
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
          .from('attendance_records')
          .select()
          .eq('user_id', studentId)
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
          .from('attendance_records')
          .select()
          .eq('team_id', teamId)
          .eq('date', dateString)
          .order('user_id');

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
          .from('attendance_records')
          .select()
          .eq('user_id', studentId);

      if (startDate != null) {
        final startString = startDate.toIso8601String().split('T')[0];
        query = query.gte('date', startString);
      }

      final cappedEndDate = endDate == null || endDate.isAfter(_today)
          ? _today
          : DateTime(endDate.year, endDate.month, endDate.day);
      query = query.lte('date', _dateKey(cappedEndDate));

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

  Future<AttendanceSummary?> getStudentAttendanceSummary({
    required String studentId,
  }) async {
    try {
      final userResponse = await _supabase
          .from('users')
          .select('id, email, reg_no, name, team_id, batch')
          .eq('id', studentId)
          .maybeSingle();

      if (userResponse == null) return null;

      final records = await _supabase
          .from('attendance_records')
          .select('status, date')
          .eq('user_id', studentId)
          .lte('date', _dateKey(_today));

      int present = 0;
      int absent = 0;

      for (final record in (records as List)) {
        final status = (record['status'] ?? '').toString().toUpperCase();
        if (status == 'PRESENT') present++;
        if (status == 'ABSENT') absent++;
      }

      final total = present + absent;
      final percentage = total == 0 ? 0.0 : (present / total) * 100;

      return AttendanceSummary(
        studentId: userResponse['id'],
        email: userResponse['email'] ?? '',
        regNo: userResponse['reg_no'] ?? '',
        name: userResponse['name'] ?? '',
        teamId: userResponse['team_id'],
        batch: userResponse['batch'] ?? 'G1',
        presentCount: present,
        absentCount: absent,
        totalWorkingDays: total,
        attendancePercentage: double.parse(percentage.toStringAsFixed(1)),
      );
    } catch (e) {
      throw Exception('Failed to get attendance summary: ${e.toString()}');
    }
  }

  Future<List<AttendanceSummary>> getAllStudentsAttendanceSummary() async {
    try {
      final users = await _supabase
          .from('users')
          .select('id, email, reg_no, name, team_id, batch')
          .order('name');

      return _buildSummariesFromUsers(users as List);
    } catch (e) {
      throw Exception('Failed to get all students summary: ${e.toString()}');
    }
  }

  Future<List<AttendanceSummary>> getTeamAttendanceSummary({
    required String teamId,
  }) async {
    try {
      final users = await _supabase
          .from('users')
          .select('id, email, reg_no, name, team_id, batch')
          .eq('team_id', teamId)
          .order('name');

      return _buildSummariesFromUsers(users as List);
    } catch (e) {
      throw Exception('Failed to get team summary: ${e.toString()}');
    }
  }

  /// Get all teams attendance summary with ranking
  Future<List<Map<String, dynamic>>> getAllTeamsAttendanceSummary() async {
    try {
      final summaries = await getAllStudentsAttendanceSummary();

      // Group by team_id
      final Map<String, List<AttendanceSummary>> teamGroups = {};
      for (final item in summaries) {
        final teamId = item.teamId;
        if (teamId != null) {
          teamGroups.putIfAbsent(teamId, () => []);
          teamGroups[teamId]!.add(item);
        }
      }

      // Calculate team averages
      final List<Map<String, dynamic>> teamSummaries = [];
      for (var entry in teamGroups.entries) {
        final members = entry.value;
        final avgPercentage = members.fold<double>(
              0,
              (sum, member) => sum + member.attendancePercentage,
            ) /
            members.length;

        teamSummaries.add({
          'team_id': entry.key,
          'team_name': 'Team ${entry.key}',
          'average_percentage': avgPercentage,
          'member_count': members.length,
          'members': members,
        });
      }

      // Sort by average percentage (highest first)
      teamSummaries.sort((a, b) => (b['average_percentage'] as double)
          .compareTo(a['average_percentage'] as double));

      return teamSummaries;
    } catch (e) {
      throw Exception('Failed to get all teams summary: ${e.toString()}');
    }
  }

  Future<Map<String, double>> getBatchAttendanceSummary() async {
    try {
      final data = await getAllStudentsAttendanceSummary();

      final g1Students = data.where((s) => s.batch == 'G1');
      final g2Students = data.where((s) => s.batch == 'G2');

      final g1Avg = g1Students.isEmpty
          ? 0.0
          : g1Students
                  .map((s) => s.attendancePercentage)
                  .reduce((a, b) => a + b) /
              g1Students.length;

      final g2Avg = g2Students.isEmpty
          ? 0.0
          : g2Students
                  .map((s) => s.attendancePercentage)
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
          .from('attendance_records')
          .select()
          .eq('id', attendanceId)
          .single();

      final oldStatus = existing['status'];

      // Update attendance
      await _supabase.from('attendance_records').update({
        'status': newStatus.displayName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', attendanceId);

      // Create audit log
      final auditLog = AuditLog.createAttendanceOverride(
        actorId: overriddenBy,
        attendanceId: attendanceId,
        studentId: existing['user_id'] ?? existing['student_id'],
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
      debugPrint('Failed to create audit log: $e');
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
            'user_id': studentId,
            'team_id': studentTeamMap[studentId] ?? '',
            'status': status,
            'marked_by': 'system',
          });
        }
      }

      if (records.isNotEmpty) {
        await _supabase.from('attendance_records').upsert(records);
      }
    } catch (e) {
      throw Exception('Failed to initialize attendance: ${e.toString()}');
    }
  }

  Future<double> getStudentAttendancePercentage(String studentId) async {
    try {
      // 1. Get all attendance records for the student
      final response = await _supabase
          .from('attendance_records')
          .select('date, status')
          .eq('user_id', studentId);

      final records = response as List;
      int totalWorkingDays = 0;
      int presentDays = 0;

      for (final rec in records) {
        final dateStr = rec['date'] as String;
        final date = DateTime.parse(dateStr);
        final status = rec['status'] as String;

        // Verify if it is/was a working day (honoring overrides)
        if (await isWorkingDay(date)) {
          totalWorkingDays++;
          if (status == 'PRESENT') {
            presentDays++;
          }
        }
      }

      if (totalWorkingDays == 0) return 0.0;
      return (presentDays / totalWorkingDays) * 100;
    } catch (e) {
      debugPrint("Error calculating attendance: $e");
      return 0.0;
    }
  }

  // ========================================
  // BULK ATTENDANCE FOR PLACEMENT REP
  // ========================================

  /// Get all attendance records for a specific date
  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('date', dateString);

      return (response as List)
          .map((data) => Attendance.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Failed to get attendance for date: $e');
      return [];
    }
  }

  /// Bulk upsert attendance records (insert or update)
  Future<void> bulkUpsertAttendance(List<Map<String, dynamic>> records) async {
    try {
      if (records.isEmpty) return;

      final validRecords = <Map<String, dynamic>>[];
      for (final record in records) {
        final userId = record['user_id']?.toString();
        final dateRaw = record['date']?.toString() ?? '';
        final parsedDate = DateTime.tryParse(dateRaw);
        if (userId == null || !_uuidRegex.hasMatch(userId)) {
          continue;
        }
        if (parsedDate != null) {
          final normalized =
              DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
          if (normalized.isAfter(_today)) {
            continue;
          }
        }
        validRecords.add(record);
      }

      if (validRecords.isEmpty) {
        throw Exception(
            'No valid registered students found in attendance selection.');
      }

      // Use upsert to insert or update based on user_id + date
      await _supabase.from('attendance_records').upsert(
            validRecords,
            onConflict: 'user_id,date',
          );
    } catch (e) {
      throw Exception('Failed to save bulk attendance: ${e.toString()}');
    }
  }

  Future<AttendanceMarkingResult> markAttendanceForIndividuals({
    required List<String> studentIds,
    required List<DateTime> dates,
    required AttendanceStatus status,
    required String markedBy,
    required Map<String, String?> studentTeamMap,
  }) async {
    final uniqueStudents = studentIds.toSet().toList();
    final uniqueDates = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .where((date) => !date.isAfter(_today))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (uniqueStudents.isEmpty) {
      throw Exception('Select at least one student');
    }
    if (uniqueDates.isEmpty) {
      throw Exception('Select at least one present or past working day');
    }

    final totalRequests = uniqueStudents.length * uniqueDates.length;
    final validStudents =
        uniqueStudents.where((id) => _uuidRegex.hasMatch(id)).toList();
    final skippedInvalidCount =
        (uniqueStudents.length - validStudents.length) * uniqueDates.length;

    if (validStudents.isEmpty) {
      throw Exception('No valid registered students selected.');
    }

    final dateStrings = uniqueDates.map(_dateKey).toList();

    final existingResponse = await _supabase
        .from('attendance_records')
        .select('user_id, date, status')
        .inFilter('user_id', validStudents)
        .inFilter('date', dateStrings);

    final existingMap = <String, String>{};
    for (final record in existingResponse as List) {
      final key = '${record['user_id']}-${record['date']}';
      existingMap[key] = record['status'] as String? ?? '';
    }

    final candidates = <_AttendanceWriteCandidate>[];
    var skippedCount = 0;

    for (final studentId in validStudents) {
      final teamId = studentTeamMap[studentId] ?? '';
      for (final date in uniqueDates) {
        final dateKey = _dateKey(date);
        final compoundKey = '$studentId-$dateKey';
        final existingStatus = existingMap[compoundKey];

        if (existingStatus != null &&
            existingStatus.toUpperCase() == status.displayName) {
          skippedCount += 1;
          continue;
        }

        final previousStatus =
            existingStatus != null && existingStatus.isNotEmpty
                ? AttendanceStatus.fromString(existingStatus)
                : null;

        final record = {
          'user_id': studentId,
          'team_id': teamId,
          'date': dateKey,
          'status': status.displayName,
          'marked_by': markedBy,
          'updated_at': DateTime.now().toIso8601String(),
        };

        candidates.add(
          _AttendanceWriteCandidate(
            payload: record,
            snapshot: AttendanceAppliedRecord(
              studentId: studentId,
              teamId: teamId,
              date: date,
              newStatus: status,
              previousStatus: previousStatus,
            ),
          ),
        );
      }
    }

    final appliedRecords = <AttendanceAppliedRecord>[];
    final failures = <AttendanceFailure>[];

    for (final chunk in _chunkCandidates(candidates, 50)) {
      final payload = chunk.map((c) => c.payload).toList();
      try {
        await _supabase.from('attendance_records').upsert(
              payload,
              onConflict: 'user_id,date',
            );
        appliedRecords.addAll(chunk.map((c) => c.snapshot));
      } catch (e) {
        for (final candidate in chunk) {
          failures.add(
            AttendanceFailure(
              studentId: candidate.snapshot.studentId,
              date: candidate.snapshot.date,
              reason: e.toString(),
            ),
          );
        }
      }
    }

    return AttendanceMarkingResult(
      totalRequests: totalRequests,
      savedCount: appliedRecords.length,
      skippedCount: skippedCount,
      skippedInvalidCount: skippedInvalidCount,
      failures: failures,
      appliedRecords: appliedRecords,
    );
  }

  Future<void> revertAttendanceChanges({
    required List<AttendanceAppliedRecord> records,
    required String undoActor,
  }) async {
    if (records.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final upsertPayload = <Map<String, dynamic>>[];
    final deletes = <Map<String, String>>[];

    for (final record in records) {
      final dateKey = _dateKey(record.date);
      if (record.previousStatus == null) {
        deletes.add({'user_id': record.studentId, 'date': dateKey});
      } else {
        upsertPayload.add({
          'user_id': record.studentId,
          'team_id': record.teamId ?? '',
          'date': dateKey,
          'status': record.previousStatus!.displayName,
          'marked_by': undoActor,
          'updated_at': now,
        });
      }
    }

    if (upsertPayload.isNotEmpty) {
      await _supabase.from('attendance_records').upsert(
            upsertPayload,
            onConflict: 'user_id,date',
          );
    }

    for (final delete in deletes) {
      await _supabase
          .from('attendance_records')
          .delete()
          .eq('user_id', delete['user_id']!)
          .eq('date', delete['date']!);
    }
  }

  Future<List<AttendanceSummary>> _buildSummariesFromUsers(List users) async {
    if (users.isEmpty) return [];

    final userIds = users
        .map((u) => u['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (userIds.isEmpty) return [];

    final records = await _supabase
        .from('attendance_records')
        .select('user_id, status, date')
        .inFilter('user_id', userIds)
        .lte('date', _dateKey(_today));

    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final raw in records as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final userId = map['user_id']?.toString() ?? '';
      if (userId.isEmpty) continue;
      byUser.putIfAbsent(userId, () => []).add(map);
    }

    final result = <AttendanceSummary>[];
    for (final rawUser in users) {
      final user = Map<String, dynamic>.from(rawUser as Map);
      final id = user['id']?.toString() ?? '';
      final userRecords = byUser[id] ?? const [];

      int present = 0;
      int absent = 0;
      for (final rec in userRecords) {
        final status = (rec['status'] ?? '').toString().toUpperCase();
        if (status == 'PRESENT') present++;
        if (status == 'ABSENT') absent++;
      }

      final total = present + absent;
      final percentage = total == 0 ? 0.0 : (present / total) * 100;

      result.add(
        AttendanceSummary(
          studentId: id,
          email: user['email']?.toString() ?? '',
          regNo: user['reg_no']?.toString() ?? '',
          name: user['name']?.toString() ?? '',
          teamId: user['team_id']?.toString(),
          batch: user['batch']?.toString() ?? 'G1',
          presentCount: present,
          absentCount: absent,
          totalWorkingDays: total,
          attendancePercentage: double.parse(percentage.toStringAsFixed(1)),
        ),
      );
    }

    result.sort(
      (a, b) => b.attendancePercentage.compareTo(a.attendancePercentage),
    );
    return result;
  }
}

Iterable<List<_AttendanceWriteCandidate>> _chunkCandidates(
  List<_AttendanceWriteCandidate> source,
  int size,
) sync* {
  if (source.isEmpty) return;
  for (var i = 0; i < source.length; i += size) {
    final end = (i + size) > source.length ? source.length : i + size;
    yield source.sublist(i, end);
  }
}

class _AttendanceWriteCandidate {
  final Map<String, dynamic> payload;
  final AttendanceAppliedRecord snapshot;

  _AttendanceWriteCandidate({
    required this.payload,
    required this.snapshot,
  });
}

class AttendanceMarkingResult {
  final int totalRequests;
  final int savedCount;
  final int skippedCount;
  final int skippedInvalidCount;
  final List<AttendanceFailure> failures;
  final List<AttendanceAppliedRecord> appliedRecords;

  AttendanceMarkingResult({
    required this.totalRequests,
    required this.savedCount,
    required this.skippedCount,
    this.skippedInvalidCount = 0,
    required this.failures,
    required this.appliedRecords,
  });

  bool get hasFailures => failures.isNotEmpty;

  int get attemptedWrites => savedCount + failures.length;
}

class AttendanceFailure {
  final String studentId;
  final DateTime date;
  final String reason;

  AttendanceFailure({
    required this.studentId,
    required this.date,
    required this.reason,
  });
}

class AttendanceAppliedRecord {
  final String studentId;
  final String? teamId;
  final DateTime date;
  final AttendanceStatus newStatus;
  final AttendanceStatus? previousStatus;

  AttendanceAppliedRecord({
    required this.studentId,
    required this.teamId,
    required this.date,
    required this.newStatus,
    required this.previousStatus,
  });
}
