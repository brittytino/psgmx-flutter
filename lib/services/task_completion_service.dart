import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_completion.dart';

/// Service for managing task completion tracking
/// Handles marking tasks as complete, fetching completion status,
/// and providing team/global completion statistics
class TaskCompletionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // STUDENT TASK COMPLETION
  // ========================================

  /// Get the current user's task completion status for a specific date
  Future<TaskCompletion?> getMyTaskCompletion(DateTime date) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('task_completions')
          .select()
          .eq('user_id', user.id)
          .eq('task_date', dateString)
          .maybeSingle();

      if (response == null) return null;
      return TaskCompletion.fromMap(response);
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting completion: $e');
      return null;
    }
  }

  /// Mark today's task as completed for the current user
  Future<bool> markTaskCompleted({
    required DateTime date,
    required bool completed,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('[TaskCompletionService] No authenticated user');
        return false;
      }

      final dateString = date.toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      await _supabase.from('task_completions').upsert({
        'user_id': user.id,
        'task_date': dateString,
        'completed': completed,
        'completed_at': completed ? now : null,
        'updated_at': now,
      }, onConflict: 'user_id, task_date');

      debugPrint(
          '[TaskCompletionService] Task marked as ${completed ? "completed" : "incomplete"} for $dateString');
      return true;
    } catch (e) {
      debugPrint('[TaskCompletionService] Error marking task: $e');
      return false;
    }
  }

  /// Check if the current user has completed today's task
  Future<bool> hasCompletedTodayTask() async {
    final completion = await getMyTaskCompletion(DateTime.now());
    return completion?.completed ?? false;
  }

  /// Stream the current user's task completion status for today
  Stream<bool> watchTodayTaskCompletion() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(false);

    final today = DateTime.now().toIso8601String().split('T')[0];

    return _supabase
        .from('task_completions')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((rows) {
          final todayRow =
              rows.where((r) => r['task_date'] == today).firstOrNull;
          return todayRow?['completed'] == true;
        });
  }

  // ========================================
  // TEAM LEADER VIEWS
  // ========================================

  /// Get task completion summary for a team on a specific date
  Future<TaskCompletionSummary> getTeamCompletionStats({
    required String teamId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];

      // Call the database function
      final response =
          await _supabase.rpc('get_team_task_completion_stats', params: {
        'p_team_id': teamId,
        'p_date': dateString,
      });

      if (response == null || (response as List).isEmpty) {
        return TaskCompletionSummary.empty();
      }

      return TaskCompletionSummary.fromMap(response[0]);
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting team stats: $e');
      return TaskCompletionSummary.empty();
    }
  }

  /// Get detailed completion status for each team member
  Future<List<UserTaskStatus>> getTeamMemberCompletions({
    required String teamId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];

      // Get all team members with their completion status
      final response = await _supabase.from('users').select('''
            id,
            name,
            reg_no,
            team_id,
            task_completions!task_completions_user_id_fkey!left(
              id,
              completed, 
              completed_at, 
              task_date, 
              verified_by, 
              verified_at
            )
          ''').eq('team_id', teamId).order('reg_no');

      final results = <UserTaskStatus>[];
      for (var row in response as List) {
        final completions = row['task_completions'] as List? ?? [];
        // Filter for the specific date
        final todayCompletion = completions.firstWhere(
          (c) => c['task_date'] == dateString,
          orElse: () => null,
        );

        // Get verified by name if exists
        String? verifiedByName;
        if (todayCompletion?['verified_by'] != null) {
          try {
            final verifierResponse = await _supabase
                .from('users')
                .select('name')
                .eq('id', todayCompletion['verified_by'])
                .single();
            verifiedByName = verifierResponse['name'];
          } catch (e) {
            debugPrint('[TaskCompletionService] Error getting verifier name: $e');
          }
        }

        results.add(UserTaskStatus(
          odId: row['id'] ?? '',
          name: row['name'] ?? '',
          regNo: row['reg_no'] ?? '',
          teamId: row['team_id'],
          completed: todayCompletion?['completed'] ?? false,
          completedAt: todayCompletion?['completed_at'] != null
              ? DateTime.parse(todayCompletion['completed_at'])
              : null,
          verifiedByName: verifiedByName,
          verifiedAt: todayCompletion?['verified_at'] != null
              ? DateTime.parse(todayCompletion['verified_at'])
              : null,
        ));
      }

      return results;
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting team members: $e');
      return [];
    }
  }

  // ========================================
  // PLACEMENT REP / ADMIN VIEWS
  // ========================================

  /// Get global completion statistics for a date
  Future<TaskCompletionSummary> getGlobalCompletionStats(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];

      // Count total students
      final totalResponse = await _supabase
          .from('users')
          .select()
          .eq('roles->>isStudent', 'true');
      final totalCount = (totalResponse as List).length;

      // Count completed
      final completedResponse = await _supabase
          .from('task_completions')
          .select()
          .eq('task_date', dateString)
          .eq('completed', true);
      final completedCount = (completedResponse as List).length;

      final percentage =
          totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;

      return TaskCompletionSummary(
        totalMembers: totalCount,
        completedCount: completedCount,
        completionPercentage: percentage,
      );
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting global stats: $e');
      return TaskCompletionSummary.empty();
    }
  }

  /// Get all students' completion status for a date
  Future<List<UserTaskStatus>> getAllStudentCompletions(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];

      // Get all students with their task completions for today
      final response = await _supabase
          .from('users')
          .select('''
            id,
            name,
            reg_no,
            team_id,
            task_completions!task_completions_user_id_fkey!left(
              id,
              completed, 
              completed_at, 
              task_date, 
              verified_by, 
              verified_at
            )
          ''')
          .contains('roles', {'isStudent': true})
          .order('team_id')
          .order('reg_no');

      final results = <UserTaskStatus>[];
      for (var row in response as List) {
        final completions = row['task_completions'] as List? ?? [];
        final todayCompletion = completions.firstWhere(
          (c) => c['task_date'] == dateString,
          orElse: () => null,
        );

        // Get verified by name if exists
        String? verifiedByName;
        if (todayCompletion?['verified_by'] != null) {
          try {
            final verifierResponse = await _supabase
                .from('users')
                .select('name')
                .eq('id', todayCompletion['verified_by'])
                .single();
            verifiedByName = verifierResponse['name'];
          } catch (e) {
            debugPrint('[TaskCompletionService] Error getting verifier name: $e');
          }
        }

        results.add(UserTaskStatus(
          odId: row['id'] ?? '',
          name: row['name'] ?? '',
          regNo: row['reg_no'] ?? '',
          teamId: row['team_id'],
          completed: todayCompletion?['completed'] ?? false,
          completedAt: todayCompletion?['completed_at'] != null
              ? DateTime.parse(todayCompletion['completed_at'])
              : null,
          verifiedByName: verifiedByName,
          verifiedAt: todayCompletion?['verified_at'] != null
              ? DateTime.parse(todayCompletion['verified_at'])
              : null,
        ));
      }

      return results;
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting all completions: $e');
      return [];
    }
  }

  /// Get completion stats grouped by team
  Future<Map<String, TaskCompletionSummary>> getCompletionStatsByTeam(
      DateTime date) async {
    try {
      // Get all teams
      final teamsResponse = await _supabase
          .from('users')
          .select('team_id')
          .not('team_id', 'is', null);

      final teamIds = (teamsResponse as List)
          .map((r) => r['team_id'] as String?)
          .where((id) => id != null)
          .toSet();

      final results = <String, TaskCompletionSummary>{};

      for (var teamId in teamIds) {
        if (teamId != null) {
          results[teamId] = await getTeamCompletionStats(
            teamId: teamId,
            date: date,
          );
        }
      }

      return results;
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting stats by team: $e');
      return {};
    }
  }

  // ========================================
  // HISTORY & ANALYTICS
  // ========================================

  /// Get completion history for a student
  Future<List<TaskCompletion>> getStudentCompletionHistory({
    required String studentId,
    int limit = 30,
  }) async {
    try {
      final response = await _supabase
          .from('task_completions')
          .select()
          .eq('user_id', studentId)
          .order('task_date', ascending: false)
          .limit(limit);

      return (response as List).map((r) => TaskCompletion.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting history: $e');
      return [];
    }
  }

  /// Get my completion rate (percentage of days completed out of days with tasks)
  Future<double> getMyCompletionRate() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

      // Get count of days with tasks
      final tasksResponse = await _supabase
          .from('daily_tasks')
          .select('date')
          .order('date', ascending: false);
      final taskDates =
          (tasksResponse as List).map((r) => r['date'] as String).toSet();

      if (taskDates.isEmpty) return 100.0;

      // Get completed count
      final completedResponse = await _supabase
          .from('task_completions')
          .select('task_date')
          .eq('user_id', user.id)
          .eq('completed', true);
      final completedDates = (completedResponse as List)
          .map((r) => r['task_date'] as String)
          .toSet();

      // Calculate intersection (only count dates that had tasks)
      final relevantCompleted = completedDates.intersection(taskDates);

      return (relevantCompleted.length / taskDates.length) * 100;
    } catch (e) {
      debugPrint('[TaskCompletionService] Error getting completion rate: $e');
      return 0.0;
    }
  }
}
