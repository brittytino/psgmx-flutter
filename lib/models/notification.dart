enum NotificationType {
  motivation,
  reminder,
  alert,
  announcement;

  String get displayName {
    switch (this) {
      case NotificationType.motivation:
        return 'Motivation';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.announcement:
        return 'Announcement';
    }
  }

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'motivation':
        return NotificationType.motivation;
      case 'reminder':
        return NotificationType.reminder;
      case 'alert':
        return NotificationType.alert;
      case 'announcement':
        return NotificationType.announcement;
      default:
        return NotificationType.announcement;
    }
  }
}

enum NotificationTone {
  serious,
  friendly,
  humorous;

  String get displayName {
    switch (this) {
      case NotificationTone.serious:
        return 'Serious';
      case NotificationTone.friendly:
        return 'Friendly';
      case NotificationTone.humorous:
        return 'Light & Fun';
    }
  }

  static NotificationTone fromString(String tone) {
    switch (tone.toLowerCase()) {
      case 'serious':
        return NotificationTone.serious;
      case 'friendly':
        return NotificationTone.friendly;
      case 'humorous':
        return NotificationTone.humorous;
      default:
        return NotificationTone.friendly;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType notificationType;
  final NotificationTone? tone;
  final String targetAudience;
  final DateTime generatedAt;
  final DateTime? validUntil;
  final String? createdBy;
  final bool isActive;
  final bool? isRead;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    this.tone,
    required this.targetAudience,
    DateTime? generatedAt,
    this.validUntil,
    this.createdBy,
    this.isActive = true,
    this.isRead,
    this.readAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AppNotification.fromMap(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      notificationType: NotificationType.fromString(
        data['notification_type'] ?? 'announcement',
      ),
      tone: data['tone'] != null
          ? NotificationTone.fromString(data['tone'])
          : null,
      targetAudience: data['target_audience'] ?? 'all',
      generatedAt: data['generated_at'] != null
          ? DateTime.parse(data['generated_at'])
          : DateTime.now(),
      validUntil: data['valid_until'] != null
          ? DateTime.parse(data['valid_until'])
          : null,
      createdBy: data['created_by'],
      isActive: data['is_active'] ?? true,
      isRead: data['is_read'],
      readAt: data['read_at'] != null ? DateTime.parse(data['read_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'notification_type': notificationType.name,
      'tone': tone?.name,
      'target_audience': targetAudience,
      'generated_at': generatedAt.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'created_by': createdBy,
      'is_active': isActive,
    };
  }

  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  // Convenience getters for compatibility
  NotificationType get type => notificationType;
  DateTime get createdAt => generatedAt;
  String get body => message;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? notificationType,
    NotificationTone? tone,
    String? targetAudience,
    DateTime? generatedAt,
    DateTime? validUntil,
    String? createdBy,
    bool? isActive,
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      tone: tone ?? this.tone,
      targetAudience: targetAudience ?? this.targetAudience,
      generatedAt: generatedAt ?? this.generatedAt,
      validUntil: validUntil ?? this.validUntil,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}
