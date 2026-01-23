class AttendanceDay {
  final DateTime date;
  final bool isWorkingDay;
  final String? decidedBy;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceDay({
    required this.date,
    required this.isWorkingDay,
    this.decidedBy,
    this.reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AttendanceDay.fromMap(Map<String, dynamic> data) {
    return AttendanceDay(
      date: DateTime.parse(data['date']),
      isWorkingDay: data['is_working_day'] ?? true,
      decidedBy: data['decided_by'],
      reason: data['reason'],
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
      'date': date.toIso8601String().split('T')[0],
      'is_working_day': isWorkingDay,
      'decided_by': decidedBy,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AttendanceDay copyWith({
    DateTime? date,
    bool? isWorkingDay,
    String? decidedBy,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceDay(
      date: date ?? this.date,
      isWorkingDay: isWorkingDay ?? this.isWorkingDay,
      decidedBy: decidedBy ?? this.decidedBy,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
