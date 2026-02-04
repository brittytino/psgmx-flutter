enum UserRole { student, teamLeader, coordinator, placementRep }

class UserRoles {
  final bool isStudent;
  final bool isTeamLeader;
  final bool isCoordinator;
  final bool isPlacementRep;

  const UserRoles({
    this.isStudent = true,
    this.isTeamLeader = false,
    this.isCoordinator = false,
    this.isPlacementRep = false,
  });

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      isStudent: json['isStudent'] as bool? ?? true,
      isTeamLeader: json['isTeamLeader'] as bool? ?? false,
      isCoordinator: json['isCoordinator'] as bool? ?? false,
      isPlacementRep: json['isPlacementRep'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isStudent': isStudent,
      'isTeamLeader': isTeamLeader,
      'isCoordinator': isCoordinator,
      'isPlacementRep': isPlacementRep,
    };
  }

  UserRoles copyWith({
    bool? isStudent,
    bool? isTeamLeader,
    bool? isCoordinator,
    bool? isPlacementRep,
  }) {
    return UserRoles(
      isStudent: isStudent ?? this.isStudent,
      isTeamLeader: isTeamLeader ?? this.isTeamLeader,
      isCoordinator: isCoordinator ?? this.isCoordinator,
      isPlacementRep: isPlacementRep ?? this.isPlacementRep,
    );
  }

  bool hasAnyAdminRole() {
    return isPlacementRep || isCoordinator || isTeamLeader;
  }
}

class AppUser {
  final String uid;
  final String email;
  final String regNo;
  final String name;
  final String? teamId;
  final String batch;
  final UserRoles roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New Fields
  final String? leetcodeUsername;
  final DateTime? dob;
  final bool birthdayNotificationsEnabled;
  final bool leetcodeNotificationsEnabled;

  // A2: Additional notification preferences (persisted to DB)
  final bool taskRemindersEnabled;
  final bool attendanceAlertsEnabled;
  final bool announcementsEnabled;

  AppUser({
    required this.uid,
    required this.email,
    required this.regNo,
    required this.name,
    this.teamId,
    required this.batch,
    required this.roles,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.leetcodeUsername,
    this.dob,
    this.birthdayNotificationsEnabled = true,
    this.leetcodeNotificationsEnabled = true,
    this.taskRemindersEnabled = true,
    this.attendanceAlertsEnabled = true,
    this.announcementsEnabled = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convenience getters
  bool get isStudent => roles.isStudent;
  bool get isTeamLeader => roles.isTeamLeader;
  bool get isCoordinator => roles.isCoordinator;
  bool get isPlacementRep => roles.isPlacementRep;
  bool get hasAdminAccess => roles.hasAnyAdminRole();

  factory AppUser.fromMap(Map<String, dynamic> data) {
    var rolesData = data['roles'];
    rolesData ??= const UserRoles().toJson();

    final roles = rolesData is Map<String, dynamic>
        ? UserRoles.fromJson(rolesData)
        : const UserRoles();

    return AppUser(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      regNo: data['reg_no'] ?? '',
      name: data['name'] ?? '',
      teamId: data['team_id'],
      batch: data['batch'] ?? 'G1',
      roles: roles,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
      leetcodeUsername: data['leetcode_username'],
      dob: data['dob'] != null
          ? DateTime.tryParse(data['dob'].toString())
          : null,
      birthdayNotificationsEnabled:
          data['birthday_notifications_enabled'] ?? true,
      leetcodeNotificationsEnabled:
          data['leetcode_notifications_enabled'] ?? true,
      taskRemindersEnabled: data['task_reminders_enabled'] ?? true,
      attendanceAlertsEnabled: data['attendance_alerts_enabled'] ?? true,
      announcementsEnabled: data['announcements_enabled'] ?? true,
    );
  }

  // Alias for fromMap
  factory AppUser.fromJson(Map<String, dynamic> data) => AppUser.fromMap(data);

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'reg_no': regNo,
      'name': name,
      'team_id': teamId,
      'batch': batch,
      'roles': roles.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'leetcode_username': leetcodeUsername,
      'dob': dob?.toIso8601String().split('T')[0],
      'birthday_notifications_enabled': birthdayNotificationsEnabled,
      'leetcode_notifications_enabled': leetcodeNotificationsEnabled,
      'task_reminders_enabled': taskRemindersEnabled,
      'attendance_alerts_enabled': attendanceAlertsEnabled,
      'announcements_enabled': announcementsEnabled,
    };
  }

  AppUser copyWith({
    String? name,
    UserRoles? roles,
    String? leetcodeUsername,
    DateTime? dob,
    bool? birthdayNotificationsEnabled,
    bool? leetcodeNotificationsEnabled,
    bool? taskRemindersEnabled,
    bool? attendanceAlertsEnabled,
    bool? announcementsEnabled,
    String? teamId,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      regNo: regNo,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      batch: batch,
      roles: roles ?? this.roles,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      leetcodeUsername: leetcodeUsername ?? this.leetcodeUsername,
      dob: dob ?? this.dob,
      birthdayNotificationsEnabled:
          birthdayNotificationsEnabled ?? this.birthdayNotificationsEnabled,
      leetcodeNotificationsEnabled:
          leetcodeNotificationsEnabled ?? this.leetcodeNotificationsEnabled,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      attendanceAlertsEnabled:
          attendanceAlertsEnabled ?? this.attendanceAlertsEnabled,
      announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
    );
  }
}
