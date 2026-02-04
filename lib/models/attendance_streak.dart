/// Model for attendance streak data
class AttendanceStreak {
  final int currentStreak;
  final int longestStreak;
  final int totalClassDays;
  final int totalNonClassDays;

  const AttendanceStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalClassDays,
    required this.totalNonClassDays,
  });

  factory AttendanceStreak.fromMap(Map<String, dynamic> data) {
    return AttendanceStreak(
      currentStreak: data['current_streak'] ?? 0,
      longestStreak: data['longest_streak'] ?? 0,
      totalClassDays: data['total_class_days'] ?? 0,
      totalNonClassDays: data['total_non_class_days'] ?? 0,
    );
  }

  factory AttendanceStreak.empty() {
    return const AttendanceStreak(
      currentStreak: 0,
      longestStreak: 0,
      totalClassDays: 0,
      totalNonClassDays: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_class_days': totalClassDays,
      'total_non_class_days': totalNonClassDays,
    };
  }
}

/// Model for attendance calculation explanation (A4)
class AttendanceCalculation {
  final int presentCount;
  final int absentCount;
  final int totalClassDays;
  final int totalNonClassDays;
  final double attendancePercentage;
  final DateTime? startDate;
  final DateTime? endDate;

  const AttendanceCalculation({
    required this.presentCount,
    required this.absentCount,
    required this.totalClassDays,
    required this.totalNonClassDays,
    required this.attendancePercentage,
    this.startDate,
    this.endDate,
  });

  factory AttendanceCalculation.fromMap(Map<String, dynamic> data) {
    return AttendanceCalculation(
      presentCount: data['present_count'] ?? 0,
      absentCount: data['absent_count'] ?? 0,
      totalClassDays: data['total_class_days'] ?? 0,
      totalNonClassDays: data['total_non_class_days'] ?? 0,
      attendancePercentage: (data['attendance_percentage'] ?? 0.0).toDouble(),
      startDate: data['start_date'] != null
          ? DateTime.parse(data['start_date'])
          : null,
      endDate:
          data['end_date'] != null ? DateTime.parse(data['end_date']) : null,
    );
  }

  factory AttendanceCalculation.empty() {
    return const AttendanceCalculation(
      presentCount: 0,
      absentCount: 0,
      totalClassDays: 0,
      totalNonClassDays: 0,
      attendancePercentage: 0.0,
    );
  }

  /// Human-readable explanation of the calculation (A4)
  String get explanation {
    if (totalClassDays == 0) {
      return 'No class days recorded yet';
    }
    return 'Calculated from $totalClassDays class days'
        '${totalNonClassDays > 0 ? ' (Excluding $totalNonClassDays non-class days)' : ''}';
  }

  /// Short summary for cards
  String get shortSummary {
    return '$presentCount / $totalClassDays days present';
  }
}

/// Defaulter flag status model (B1)
class DefaulterFlag {
  final String id;
  final String userId;
  final bool defaulterStatus;
  final String defaulterReason;
  final int consecutiveAbsences;
  final double? attendancePercentage;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? notes;

  const DefaulterFlag({
    required this.id,
    required this.userId,
    required this.defaulterStatus,
    required this.defaulterReason,
    required this.consecutiveAbsences,
    this.attendancePercentage,
    required this.detectedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.notes,
  });

  factory DefaulterFlag.fromMap(Map<String, dynamic> data) {
    return DefaulterFlag(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      defaulterStatus: data['defaulter_status'] ?? false,
      defaulterReason: data['defaulter_reason'] ?? '',
      consecutiveAbsences: data['consecutive_absences'] ?? 0,
      attendancePercentage: data['attendance_percentage']?.toDouble(),
      detectedAt: data['detected_at'] != null
          ? DateTime.parse(data['detected_at'])
          : DateTime.now(),
      resolvedAt: data['resolved_at'] != null
          ? DateTime.parse(data['resolved_at'])
          : null,
      resolvedBy: data['resolved_by'],
      notes: data['notes'],
    );
  }
}
