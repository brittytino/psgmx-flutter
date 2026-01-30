import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Role simulation mode for Placement Rep
/// Allows UI-level role impersonation without auth changes
class RoleSimulation {
  final UserRoles simulatedRoles;
  final String? simulatedTeamId;
  final bool isActive;

  const RoleSimulation({
    required this.simulatedRoles,
    this.simulatedTeamId,
    this.isActive = false,
  });

  factory RoleSimulation.none() {
    return const RoleSimulation(
      simulatedRoles: UserRoles(),
      isActive: false,
    );
  }

  factory RoleSimulation.student({String? teamId}) {
    return RoleSimulation(
      simulatedRoles: const UserRoles(isStudent: true),
      simulatedTeamId: teamId,
      isActive: true,
    );
  }

  factory RoleSimulation.teamLeader(String teamId) {
    return RoleSimulation(
      simulatedRoles: const UserRoles(
        isStudent: true,
        isTeamLeader: true,
      ),
      simulatedTeamId: teamId,
      isActive: true,
    );
  }

  factory RoleSimulation.coordinator({String? teamId}) {
    return RoleSimulation(
      simulatedRoles: const UserRoles(
        isStudent: true,
        isCoordinator: true,
      ),
      simulatedTeamId: teamId,
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'simulatedRoles': simulatedRoles.toJson(),
      'simulatedTeamId': simulatedTeamId,
    };
  }

  factory RoleSimulation.fromJson(Map<String, dynamic> json) {
    return RoleSimulation(
      simulatedRoles: UserRoles.fromJson(json['simulatedRoles'] ?? {}),
      simulatedTeamId: json['simulatedTeamId'],
      isActive: json['isActive'] ?? false,
    );
  }
}

class EnhancedAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _simulationKey = 'role_simulation';

  // Current logged-in user
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Role simulation state
  RoleSimulation _roleSimulation = RoleSimulation.none();
  RoleSimulation get roleSimulation => _roleSimulation;

  // Effective user (with simulation applied)
  AppUser? get effectiveUser {
    if (_currentUser == null) return null;
    
    if (_roleSimulation.isActive && _currentUser!.isPlacementRep) {
      return _currentUser!.copyWith(
        roles: _roleSimulation.simulatedRoles,
        teamId: _roleSimulation.simulatedTeamId,
      );
    }
    
    return _currentUser;
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
  
  bool get canSimulateRoles => _currentUser?.isPlacementRep ?? false;

  Stream<AppUser?> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange.asyncMap((state) async {
      if (state.session?.user != null) {
        await _loadCurrentUser(state.session!.user.id);
        return effectiveUser;
      }
      _currentUser = null;
      _roleSimulation = RoleSimulation.none();
      return null;
    });
  }

  Future<void> initialize() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _loadCurrentUser(user.id);
      await _loadSimulationState();
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed');
      }

      await _loadCurrentUser(response.user!.id);
      
      if (_currentUser == null) {
        throw Exception('User profile not found');
      }

      return _currentUser!;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _roleSimulation = RoleSimulation.none();
    await _clearSimulationState();
  }

  Future<void> _loadCurrentUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = AppUser.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load user profile: ${e.toString()}');
    }
  }

  // ========================================
  // ROLE SIMULATION METHODS
  // ========================================

  Future<void> enableRoleSimulation(RoleSimulation simulation) async {
    if (!canSimulateRoles) {
      throw Exception('Only Placement Reps can simulate roles');
    }

    _roleSimulation = simulation;
    await _saveSimulationState();
  }

  Future<void> disableRoleSimulation() async {
    _roleSimulation = RoleSimulation.none();
    await _clearSimulationState();
  }

  Future<void> simulateStudent({String? teamId}) async {
    await enableRoleSimulation(RoleSimulation.student(teamId: teamId));
  }

  Future<void> simulateTeamLeader(String teamId) async {
    await enableRoleSimulation(RoleSimulation.teamLeader(teamId));
  }

  Future<void> simulateCoordinator({String? teamId}) async {
    await enableRoleSimulation(RoleSimulation.coordinator(teamId: teamId));
  }

  Future<void> _saveSimulationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _roleSimulation.toJson();
      await prefs.setString(
        _simulationKey,
        json.toString(),
      );
    } catch (e) {
      // Silent fail - simulation state is not critical
    }
  }

  Future<void> _loadSimulationState() async {
    try {
      if (!canSimulateRoles) return;
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_simulationKey);
      
      if (jsonString != null) {
        // Parse and restore simulation state
        // Implementation depends on JSON parsing
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _clearSimulationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_simulationKey);
    } catch (e) {
      // Silent fail
    }
  }

  // ========================================
  // USER MANAGEMENT (PLACEMENT REP ONLY)
  // ========================================

  Future<List<AppUser>> getAllUsers() async {
    if (!(_currentUser?.isPlacementRep ?? false)) {
      throw Exception('Unauthorized: Only Placement Reps can access all users');
    }

    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('name');

      return (response as List)
          .map((data) => AppUser.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  Future<List<AppUser>> getUsersByTeam(String teamId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('team_id', teamId)
          .order('name');

      return (response as List)
          .map((data) => AppUser.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to load team users: ${e.toString()}');
    }
  }

  Future<void> updateUserRoles(String userId, UserRoles roles) async {
    if (!(_currentUser?.isPlacementRep ?? false)) {
      throw Exception('Unauthorized: Only Placement Reps can update roles');
    }

    try {
      await _supabase
          .from('users')
          .update({'roles': roles.toJson()})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user roles: ${e.toString()}');
    }
  }
}
