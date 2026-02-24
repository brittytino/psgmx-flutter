/// Model for a single subject's attendance data from PSG eCampus.
class SubjectAttendance {
  final String courseCode;
  final String courseTitle;
  final int totalHours;
  final int exceptionHour;
  final int totalPresent;
  final double percentage;
  final int canBunk;
  final int classesToAttend;
  final String attendanceFrom;
  final String attendanceTo;

  const SubjectAttendance({
    required this.courseCode,
    required this.courseTitle,
    required this.totalHours,
    required this.exceptionHour,
    required this.totalPresent,
    required this.percentage,
    required this.canBunk,
    required this.classesToAttend,
    required this.attendanceFrom,
    required this.attendanceTo,
  });

  bool get isSafe => percentage >= 75.0;
  bool get isCritical => percentage < 65.0;

  factory SubjectAttendance.fromJson(Map<String, dynamic> json) {
    return SubjectAttendance(
      courseCode: json['course_code'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      totalHours: (json['total_hours'] as num?)?.toInt() ?? 0,
      exceptionHour: (json['exception_hour'] as num?)?.toInt() ?? 0,
      totalPresent: (json['total_present'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      canBunk: (json['can_bunk'] as num?)?.toInt() ?? 0,
      classesToAttend: (json['classes_to_attend'] as num?)?.toInt() ?? 0,
      attendanceFrom: json['attendance_from'] as String? ?? '',
      attendanceTo: json['attendance_to'] as String? ?? '',
    );
  }
}

/// Summary statistics across all subjects.
class AttendanceSummary {
  final int totalHours;
  final int totalPresent;
  final double overallPercentage;
  final int overallCanBunk;
  final int overallNeedAttend;

  const AttendanceSummary({
    required this.totalHours,
    required this.totalPresent,
    required this.overallPercentage,
    required this.overallCanBunk,
    required this.overallNeedAttend,
  });

  bool get isSafe => overallPercentage >= 75.0;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalHours: (json['total_hours'] as num?)?.toInt() ?? 0,
      totalPresent: (json['total_present'] as num?)?.toInt() ?? 0,
      overallPercentage:
          (json['overall_percentage'] as num?)?.toDouble() ?? 0.0,
      overallCanBunk: (json['overall_can_bunk'] as num?)?.toInt() ?? 0,
      overallNeedAttend:
          (json['overall_need_attend'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Top-level model for the attendance payload stored in Supabase.
class EcampusAttendance {
  final String regNo;
  final List<SubjectAttendance> subjects;
  final AttendanceSummary summary;
  final DateTime syncedAt;

  const EcampusAttendance({
    required this.regNo,
    required this.subjects,
    required this.summary,
    required this.syncedAt,
  });

  factory EcampusAttendance.fromSupabase(Map<String, dynamic> row) {
    final data = row['data'] as Map<String, dynamic>;
    final syncedAtRaw = row['synced_at'] as String? ?? '';

    return EcampusAttendance(
      regNo: row['reg_no'] as String? ?? '',
      subjects: (data['subjects'] as List<dynamic>? ?? [])
          .map((e) => SubjectAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: AttendanceSummary.fromJson(
          data['summary'] as Map<String, dynamic>? ?? {}),
      syncedAt: syncedAtRaw.isNotEmpty
          ? DateTime.tryParse(syncedAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
