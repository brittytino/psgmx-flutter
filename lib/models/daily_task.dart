enum TopicType {
  leetcode,
  core;

  String get displayName {
    switch (this) {
      case TopicType.leetcode:
        return 'LeetCode';
      case TopicType.core:
        return 'Core Subject';
    }
  }

  static TopicType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'leetcode':
        return TopicType.leetcode;
      case 'core':
        return TopicType.core;
      default:
        return TopicType.core;
    }
  }
}

class DailyTask {
  final String id;
  final DateTime date;
  final TopicType topicType;
  final String title;
  final String? referenceLink;
  final String? subject;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyTask({
    required this.id,
    required this.date,
    required this.topicType,
    required this.title,
    this.referenceLink,
    this.subject,
    required this.uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory DailyTask.fromMap(Map<String, dynamic> data) {
    return DailyTask(
      id: data['id'] ?? '',
      date: DateTime.parse(data['date']),
      topicType: TopicType.fromString(data['topic_type'] ?? 'core'),
      title: data['title'] ?? '',
      referenceLink: data['reference_link'],
      subject: data['subject'],
      uploadedBy: data['uploaded_by'] ?? '',
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
      'topic_type': topicType.name,
      'title': title,
      'reference_link': referenceLink,
      'subject': subject,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyTask copyWith({
    String? id,
    DateTime? date,
    TopicType? topicType,
    String? title,
    String? referenceLink,
    String? subject,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      date: date ?? this.date,
      topicType: topicType ?? this.topicType,
      title: title ?? this.title,
      referenceLink: referenceLink ?? this.referenceLink,
      subject: subject ?? this.subject,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model for bulk task upload
class TaskUploadRow {
  final DateTime date;
  final String title;
  final String? referenceLink;
  final String? subject;
  final TopicType topicType;
  final String? error;

  TaskUploadRow({
    required this.date,
    required this.title,
    this.referenceLink,
    this.subject,
    required this.topicType,
    this.error,
  });

  bool get isValid => error == null;
}

class TaskUploadSheet {
  final String sheetName;
  final TopicType topicType;
  final List<TaskUploadRow> rows;

  TaskUploadSheet({
    required this.sheetName,
    required this.topicType,
    required this.rows,
  });

  int get validRowCount => rows.where((r) => r.isValid).length;
  int get errorRowCount => rows.where((r) => !r.isValid).length;
}
