class ScheduledDate {
  final String id;
  final DateTime date;
  final String? scheduledBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduledDate({
    required this.id,
    required this.date,
    this.scheduledBy,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ScheduledDate.fromMap(Map<String, dynamic> data) {
    return ScheduledDate(
      id: data['id'] ?? '',
      date: DateTime.parse(data['date']),
      scheduledBy: data['scheduled_by'],
      notes: data['notes'],
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
      'scheduled_by': scheduledBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScheduledDate copyWith({
    String? id,
    DateTime? date,
    String? scheduledBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduledDate(
      id: id ?? this.id,
      date: date ?? this.date,
      scheduledBy: scheduledBy ?? this.scheduledBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
