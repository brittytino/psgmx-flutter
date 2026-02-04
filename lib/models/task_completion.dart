/// Model for tracking task completion status
class TaskCompletion {
  final String id;
  final String userId;
  final DateTime taskDate;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskCompletion({
    required this.id,
    required this.userId,
    required this.taskDate,
    required this.completed,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TaskCompletion.fromMap(Map<String, dynamic> data) {
    return TaskCompletion(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      taskDate: DateTime.parse(data['task_date']),
      completed: data['completed'] ?? false,
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'])
          : null,
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
      'user_id': userId,
      'task_date': taskDate.toIso8601String().split('T')[0],
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskCompletion copyWith({
    String? id,
    String? userId,
    DateTime? taskDate,
    bool? completed,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskCompletion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskDate: taskDate ?? this.taskDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Summary of task completions for display purposes
class TaskCompletionSummary {
  final int totalMembers;
  final int completedCount;
  final double completionPercentage;

  const TaskCompletionSummary({
    required this.totalMembers,
    required this.completedCount,
    required this.completionPercentage,
  });

  factory TaskCompletionSummary.fromMap(Map<String, dynamic> data) {
    return TaskCompletionSummary(
      totalMembers: data['total_members'] ?? 0,
      completedCount: data['completed_count'] ?? 0,
      completionPercentage: (data['completion_percentage'] ?? 0.0).toDouble(),
    );
  }

  factory TaskCompletionSummary.empty() {
    return const TaskCompletionSummary(
      totalMembers: 0,
      completedCount: 0,
      completionPercentage: 0.0,
    );
  }
}

/// User's task completion status for a specific day
class UserTaskStatus {
  final String odId;
  final String name;
  final String regNo;
  final String? teamId;
  final bool completed;
  final DateTime? completedAt;
  final String? verifiedByName;
  final DateTime? verifiedAt;

  const UserTaskStatus({
    required this.odId,
    required this.name,
    required this.regNo,
    this.teamId,
    required this.completed,
    this.completedAt,
    this.verifiedByName,
    this.verifiedAt,
  });

  factory UserTaskStatus.fromMap(Map<String, dynamic> data) {
    return UserTaskStatus(
      odId: data['user_id'] ?? data['id'] ?? '',
      name: data['name'] ?? '',
      regNo: data['reg_no'] ?? '',
      teamId: data['team_id'],
      completed: data['completed'] ?? false,
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'])
          : null,
      verifiedByName: data['verified_by_name'],
      verifiedAt: data['verified_at'] != null
          ? DateTime.parse(data['verified_at'])
          : null,
    );
  }
}
