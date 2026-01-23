enum UserRole {
  student,
  teamLeader,
  coordinator,
  placementRep
}

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
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convenience getters
  bool get isStudent => roles.isStudent;
  bool get isTeamLeader => roles.isTeamLeader;
  bool get isCoordinator => roles.isCoordinator;
  bool get isPlacementRep => roles.isPlacementRep;
  bool get hasAdminAccess => roles.hasAnyAdminRole();

  factory AppUser.fromMap(Map<String, dynamic> data) {
    final rolesData = data['roles'];
    final roles = rolesData is Map<String, dynamic>
        ? UserRoles.fromJson(rolesData)
        : const UserRoles();

    return AppUser(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      regNo: data['reg_no'] ?? data['reg_number'] ?? data['regNo'] ?? '',
      name: data['name'] ?? data['full_name'] ?? '',
      teamId: data['team_id'] ?? data['teamId'],
      batch: data['batch'] ?? 'G1',
      roles: roles,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
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
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? regNo,
    String? name,
    String? teamId,
    String? batch,
    UserRoles? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      regNo: regNo ?? this.regNo,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      batch: batch ?? this.batch,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

