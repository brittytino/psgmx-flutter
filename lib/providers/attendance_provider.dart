import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/supabase_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  List<AppUser> _teamMembers = [];
  List<AppUser> get teamMembers => _teamMembers;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _hasSubmittedToday = false;
  bool get hasSubmittedToday => _hasSubmittedToday;

  AttendanceProvider(this._supabaseService);

  String? _cachedTeamId;

  Future<void> loadTeamMembers(String teamId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Cache: Only fetch members if team changed or list empty
      if (_cachedTeamId != teamId || _teamMembers.isEmpty) {
        // Fetch from whitelist to get ALL 123 students (not just those who signed up)
        final response = await _supabaseService.client
            .from('whitelist')
            .select()
            .eq('team_id', teamId)
            .order('reg_no');
            
        _teamMembers = (response as List).map((e) {
          // Convert whitelist row to AppUser format
          return AppUser(
            uid: e['email'], // Use email as ID since they haven't signed up yet
            email: e['email'],
            regNo: e['reg_no'],
            name: e['name'],
            teamId: e['team_id'],
            batch: e['batch'],
            roles: e['roles'] != null ? UserRoles.fromJson(Map<String, dynamic>.from(e['roles'])) : const UserRoles(),
            leetcodeUsername: e['leetcode_username'],
            dob: e['dob'] != null ? DateTime.parse(e['dob']) : null,
          );
        }).toList();
        _cachedTeamId = teamId;
      }
      
      // Check if already submitted today
      await _checkSubmissionStatus(teamId);
      
    } catch (e) {
      debugPrint('Error loading team: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch ALL 123 students from whitelist (not just those who signed up)
      final response = await _supabaseService.client
          .from('whitelist')
          .select()
          .order('reg_no');
          
      _teamMembers = (response as List).map((e) {
        // Convert whitelist row to AppUser format
        return AppUser(
          uid: e['email'], // Use email as ID
          email: e['email'],
          regNo: e['reg_no'],
          name: e['name'],
          teamId: e['team_id'],
          batch: e['batch'],
          roles: e['roles'] != null ? UserRoles.fromJson(Map<String, dynamic>.from(e['roles'])) : const UserRoles(),
          leetcodeUsername: e['leetcode_username'],
          dob: e['dob'] != null ? DateTime.parse(e['dob']) : null,
        );
      }).toList();
      _hasSubmittedToday = false; // Reps can always edit/submit in this mode
      
    } catch (e) {
      debugPrint('Error loading all users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkSubmissionStatus(String teamId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final count = await _supabaseService.client
        .from('attendance')
        .count()
        .eq('team_id', teamId)
        .eq('date', today);
        
    _hasSubmittedToday = count > 0;
  }

  Future<void> submitAttendance(String? teamId, Map<String, String> statusMap, {bool isRep = false}) async {
    if (!isRep && _hasSubmittedToday) throw Exception("Already submitted for today");
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    final user = _supabaseService.client.auth.currentUser;
    
    final List<Map<String, dynamic>> rows = [];
    
    for (var entry in statusMap.entries) {
      final studentIdentifier = entry.key; // This is email from whitelist
      final status = entry.value;
      
      // Try to find actual user ID from users table, otherwise use email as identifier
      String? actualUserId;
      try {
        final userRecord = await _supabaseService.client
            .from('users')
            .select('id')
            .eq('email', studentIdentifier)
            .maybeSingle();
        actualUserId = userRecord?['id'];
      } catch (e) {
        // User hasn't signed up yet, use email as identifier
        actualUserId = null;
      }
      
      rows.add({
        'date': today,
        'student_id': actualUserId ?? studentIdentifier, // Use actual ID or email
        'student_email': studentIdentifier, // Store email for reference
        'team_id': teamId,
        'status': status,
        'marked_by': user!.id,
      });
    }

    if (rows.isNotEmpty) {
      if (isRep) {
        // Upsert for Reps
        await _supabaseService.client.from('attendance_records').upsert(rows);
      } else {
        await _supabaseService.client.from('attendance_records').insert(rows);
      }
      
      if (!isRep && teamId != null) {
        _hasSubmittedToday = true; 
      }
      notifyListeners();
    }
  }
}
