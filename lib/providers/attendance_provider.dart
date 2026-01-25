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
        final response = await _supabaseService.client
            .from('users')
            .select()
            .eq('team_id', teamId)
            .order('reg_no');
            
        _teamMembers = (response as List).map((e) => AppUser.fromMap(e)).toList();
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
      final response = await _supabaseService.client
          .from('users')
          .select()
          .order('reg_no');
          
      _teamMembers = (response as List).map((e) => AppUser.fromMap(e)).toList();
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
    statusMap.forEach((studentId, status) {
      rows.add({
        'date': today,
        'student_id': studentId,
        'team_id': teamId, // Can be null if marking for all
        'status': status,
        'marked_by': user!.id,
      });
    });

    if (rows.isNotEmpty) {
      if (isRep) {
        // Upsert for Reps
        await _supabaseService.client.from('attendance').upsert(rows);
      } else {
        await _supabaseService.client.from('attendance').insert(rows);
      }
      
      if (!isRep && teamId != null) {
        _hasSubmittedToday = true; 
      }
      notifyListeners();
    }
  }
}
