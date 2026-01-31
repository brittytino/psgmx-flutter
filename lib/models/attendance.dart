enum AttendanceStatus {
  present,
  absent,
  na;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.na:
        return 'NA';
    }
  }

  static AttendanceStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'NA':
        return AttendanceStatus.na;
      default:
        return AttendanceStatus.na;
    }
  }
}

class Attendance {
  final String id;
  final DateTime date;
  final String studentId;
  final String? userId; // Alternative field name in DB
  final String teamId;
  final AttendanceStatus status;
  final String markedBy;
  final DateTime markedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.date,
    required this.studentId,
    this.userId,
    required this.teamId,
    required this.status,
    required this.markedBy,
    DateTime? markedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : markedAt = markedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Attendance.fromMap(Map<String, dynamic> data) {
    // Support both student_id and user_id columns
    final studentIdValue = data['student_id'] ?? data['user_id'] ?? '';
    return Attendance(
      id: data['id'] ?? '',
      date: DateTime.parse(data['date']),
      studentId: studentIdValue,
      userId: data['user_id'],
      teamId: data['team_id'] ?? '',
      status: AttendanceStatus.fromString(data['status'] ?? 'NA'),
      markedBy: data['marked_by'] ?? '',
      markedAt: data['marked_at'] != null
          ? DateTime.parse(data['marked_at'])
          : DateTime.now(),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'user_id': studentId,
      'team_id': teamId,
      'status': status.displayName,
      'marked_by': markedBy,
      'marked_at': markedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Attendance copyWith({
    String? id,
    DateTime? date,
    String? studentId,
    String? teamId,
    AttendanceStatus? status,
    String? markedBy,
    DateTime? markedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      date: date ?? this.date,
      studentId: studentId ?? this.studentId,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AttendanceSummary {
  final String studentId;
  final String email;
  final String regNo;
  final String name;
  final String? teamId;
  final String batch;
  final int presentCount;
  final int absentCount;
  final int totalWorkingDays;
  final double attendancePercentage;

  AttendanceSummary({
    required this.studentId,
    required this.email,
    required this.regNo,
    required this.name,
    this.teamId,
    required this.batch,
    required this.presentCount,
    required this.absentCount,
    required this.totalWorkingDays,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromMap(Map<String, dynamic> data) {
    // Support both student_id and user_id columns
    final studentIdValue = data['student_id'] ?? data['user_id'] ?? '';
    return AttendanceSummary(
      studentId: studentIdValue,
      email: data['email'] ?? '',
      regNo: data['reg_no'] ?? '',
      name: data['name'] ?? '',
      teamId: data['team_id'],
      batch: data['batch'] ?? 'G1',
      presentCount: data['present_count'] ?? 0,
      absentCount: data['absent_count'] ?? 0,
      totalWorkingDays: data['total_working_days'] ?? 0,
      attendancePercentage:
          (data['attendance_percentage'] ?? 0.0).toDouble(),
    );
  }

  AttendanceColor get colorIndicator {
    if (attendancePercentage >= 90) return AttendanceColor.green;
    if (attendancePercentage >= 75) return AttendanceColor.yellow;
    return AttendanceColor.red;
  }
}

enum AttendanceColor {
  green,
  yellow,
  red;

  String get displayName {
    switch (this) {
      case AttendanceColor.green:
        return '≥ 90%';
      case AttendanceColor.yellow:
        return '75-89%';
      case AttendanceColor.red:
        return '< 75%';
    }
  }
}
