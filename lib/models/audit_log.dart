class AuditLog {
  final String id;
  final String actorId;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLog.fromMap(Map<String, dynamic> data) {
    return AuditLog(
      id: data['id'] ?? '',
      actorId: data['actor_id'] ?? '',
      action: data['action'] ?? '',
      entityType: data['entity_type'] ?? '',
      entityId: data['entity_id'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actor_id': actorId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static AuditLog createAttendanceOverride({
    required String actorId,
    required String attendanceId,
    required String studentId,
    required String oldStatus,
    required String newStatus,
    required DateTime date,
  }) {
    return AuditLog(
      id: '',
      actorId: actorId,
      action: 'attendance_override',
      entityType: 'attendance',
      entityId: attendanceId,
      metadata: {
        'student_id': studentId,
        'date': date.toIso8601String(),
        'old_status': oldStatus,
        'new_status': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static AuditLog createWorkingDayChange({
    required String actorId,
    required DateTime date,
    required bool isWorkingDay,
    String? reason,
  }) {
    return AuditLog(
      id: '',
      actorId: actorId,
      action: 'working_day_change',
      entityType: 'attendance_days',
      metadata: {
        'date': date.toIso8601String(),
        'is_working_day': isWorkingDay,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static AuditLog createBulkTaskUpload({
    required String actorId,
    required int taskCount,
    required String fileName,
  }) {
    return AuditLog(
      id: '',
      actorId: actorId,
      action: 'bulk_task_upload',
      entityType: 'daily_tasks',
      metadata: {
        'task_count': taskCount,
        'file_name': fileName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
