import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/supabase_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final Map<String, String> _emailToUid = {};

  List<AppUser> _teamMembers = [];
  List<AppUser> get teamMembers => _teamMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasSubmittedToday = false;
  bool get hasSubmittedToday => _hasSubmittedToday;

  final Map<String, String> _statusMap = {};
  Map<String, String> get statusMap => _statusMap;

  AttendanceProvider(this._supabaseService);

  Future<void> _preloadStatuses(String? teamId, String dateStr) async {
    try {
      var query = _supabaseService.client
          .from('attendance_records')
          .select('user_id, status')
          .eq('date', dateStr);

      if (teamId != null) {
        query = query.eq('team_id', teamId);
      }

      final response = await query;

      _statusMap.clear();
      for (var record in response as List) {
        final key = record['user_id'];
        if (key != null) {
          _statusMap[key] = record['status'];
        }
      }
    } catch (e) {
      debugPrint('Error preloading status: $e');
    }
  }

  Future<void> loadTeamMembers(String teamId, {DateTime? forDate}) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = (forDate ?? DateTime.now()).toIso8601String().split('T')[0];

    try {
      // 1. Fetch from whitelist
      final whiteListResponse = await _supabaseService.client
          .from('whitelist')
          .select()
          .eq('team_id', teamId)
          .order('reg_no');

      final List<dynamic> whitelistStudents = whiteListResponse as List;
      final List<String> emails =
          whitelistStudents.map((e) => e['email'] as String).toList();

      // 2. Fetch actual user IDs from users table (who have signed up)
      final usersResponse = await _supabaseService.client
          .from('users')
          .select('id, email')
          .inFilter('email', emails);

      final Map<String, String> emailToUid = {
        for (var u in usersResponse as List)
          u['email'] as String: u['id'] as String
      };
      _emailToUid
        ..clear()
        ..addAll(emailToUid);

      // 3. Merge
      _teamMembers = whitelistStudents.map((e) {
        final email = e['email'] as String;
        return AppUser(
          uid: emailToUid[email] ?? email, // Real UID or fallback to email
          email: email,
          regNo: e['reg_no'],
          name: e['name'],
          teamId: e['team_id'],
          batch: e['batch'],
          roles: e['roles'] != null
              ? UserRoles.fromJson(Map<String, dynamic>.from(e['roles']))
              : const UserRoles(),
          leetcodeUsername: e['leetcode_username'],
          dob: e['dob'] != null ? DateTime.parse(e['dob']) : null,
        );
      }).toList();

      // Check if already submitted for the selected date
      await _checkSubmissionStatus(teamId, dateStr);

      // Always preload existing statuses for the selected date so the UI
      // pre-fills any previously-saved records (whether or not fully submitted).
      await _preloadStatuses(teamId, dateStr);
    } catch (e) {
      debugPrint('Error loading team: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers({DateTime? forDate}) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = (forDate ?? DateTime.now()).toIso8601String().split('T')[0];

    try {
      // 1. Fetch from whitelist
      final whiteListResponse = await _supabaseService.client
          .from('whitelist')
          .select()
          .order('reg_no');

      final List<dynamic> whitelistStudents = whiteListResponse as List;
      final List<String> emails =
          whitelistStudents.map((e) => e['email'] as String).toList();

      // 2. Fetch actual user IDs from users table
      final usersResponse = await _supabaseService.client
          .from('users')
          .select('id, email')
          .inFilter('email', emails);

      final Map<String, String> emailToUid = {
        for (var u in usersResponse as List)
          u['email'] as String: u['id'] as String
      };
      _emailToUid
        ..clear()
        ..addAll(emailToUid);

      // 3. Merge
      _teamMembers = whitelistStudents.map((e) {
        final email = e['email'] as String;
        return AppUser(
          uid: emailToUid[email] ?? email,
          email: email,
          regNo: e['reg_no'],
          name: e['name'],
          teamId: e['team_id'],
          batch: e['batch'],
          roles: e['roles'] != null
              ? UserRoles.fromJson(Map<String, dynamic>.from(e['roles']))
              : const UserRoles(),
          leetcodeUsername: e['leetcode_username'],
          dob: e['dob'] != null ? DateTime.parse(e['dob']) : null,
        );
      }).toList();

      // Always preload existing records for the selected date (Reps can always edit)
      await _preloadStatuses(null, dateStr);

      _hasSubmittedToday = false; // Reps can always edit/submit in this mode
    } catch (e) {
      debugPrint('Error loading all users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkSubmissionStatus(String teamId, String dateStr) async {
    try {
      final count = await _supabaseService.client
          .from('attendance_records')
          .count()
          .eq('team_id', teamId)
          .eq('date', dateStr);

      _hasSubmittedToday = count > 0;
    } catch (e) {
      debugPrint('Error checking submission status: $e');
      _hasSubmittedToday = false;
    }
  }

  Future<void> submitAttendance(
    String? teamId,
    Map<String, String> statusMap, {
    DateTime? forDate,
    bool isRep = false,
  }) async {
    final selectedDate = forDate ?? DateTime.now();
    final normalizedSelected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (normalizedSelected.isAfter(today)) {
      throw Exception('Attendance cannot be marked for future dates.');
    }

    final dateStr = normalizedSelected.toIso8601String().split('T')[0];
    final user = _supabaseService.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final List<Map<String, dynamic>> rows = [];
    final List<String> skippedUnregistered = [];

    // UUID regex pattern
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    for (var entry in statusMap.entries) {
      final studentIdOrEmail = entry.key;
      final status = entry.value;

      // Find student in team members (works for both registered and unregistered)
      final student = _teamMembers.firstWhere(
        (m) => m.uid == studentIdOrEmail,
        orElse: () => AppUser(
          uid: studentIdOrEmail,
          email: studentIdOrEmail,
          regNo: '',
          name: '',
          teamId: teamId,
          batch: '',
          roles: const UserRoles(),
        ),
      );
      final studentTeamId = student.teamId ?? teamId ?? 'ALL';

      String? resolvedUserId;
      if (uuidRegex.hasMatch(studentIdOrEmail)) {
        resolvedUserId = studentIdOrEmail;
      } else {
        resolvedUserId = _emailToUid[student.email];
      }

      // Skip whitelist-only members who have not completed registration yet.
      if (resolvedUserId == null) {
        skippedUnregistered.add(
          student.name.isNotEmpty ? student.name : student.email,
        );
        continue;
      }

      rows.add({
        'date': dateStr,
        'user_id': resolvedUserId,
        'team_id': studentTeamId,
        'status': status,
        'marked_by': user.id,
      });
    }

    if (rows.isEmpty) {
      if (skippedUnregistered.isNotEmpty) {
        throw Exception(
          'No registered students available to mark attendance. ${skippedUnregistered.length} selected students are not registered yet.',
        );
      }
      throw Exception('No valid students to mark attendance for.');
    }

    // Upsert on (date, user_id) conflict — safe for both first-mark and updates
    await _supabaseService.client
        .from('attendance_records')
        .upsert(rows, onConflict: 'date,user_id');

    if (!isRep && teamId != null) {
      _hasSubmittedToday = true;
    }
    notifyListeners();

    debugPrint(
        '[Attendance] Successfully marked attendance for ${rows.length} students');
    if (skippedUnregistered.isNotEmpty) {
      debugPrint(
        '[Attendance] Skipped ${skippedUnregistered.length} unregistered students during submission',
      );
    }
  }
}
