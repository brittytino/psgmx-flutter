import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';
import './notification_service.dart';
import '../models/notification.dart';

/// Service for tracking and announcing top performers (C1 & C2)
///
/// C1: Weekly Top Performer Announcement
/// C2: LeetCode Milestones (50 / 100 / 200)
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // Milestone thresholds
  static const List<int> milestones = [50, 100, 200, 300, 400, 500];

  // ========================================
  // C1: WEEKLY TOP PERFORMER
  // ========================================

  /// Get the weekly top performer based on weekly_score
  Future<WeeklyTopPerformer?> getWeeklyTopPerformer() async {
    try {
      final response = await _supabase
          .from('leetcode_stats')
          .select('username, weekly_score')
          .order('weekly_score', ascending: false)
          .limit(1) as List;

      if (response.isEmpty) {
        return null;
      }

      final data = response[0];
      final username = data['username'] as String;
      final weeklyScore = data['weekly_score'] as int? ?? 0;

      // Get the user's name from whitelist
      final nameResponse = await _supabase
          .from('whitelist')
          .select('name')
          .eq('leetcode_username', username)
          .maybeSingle();

      final name = nameResponse?['name'] as String? ?? username;

      return WeeklyTopPerformer(
        username: username,
        name: name,
        weeklyScore: weeklyScore,
      );
    } catch (e) {
      debugPrint('[PerformanceService] Error getting weekly top performer: $e');
      return null;
    }
  }

  /// Check if we should announce this week's top performer
  /// Returns true if it's Monday and we haven't announced yet this week
  Future<bool> shouldAnnounceWeeklyTopPerformer() async {
    final now = DateTime.now();

    // Only announce on Monday
    if (now.weekday != DateTime.monday) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastAnnouncedWeek = prefs.getInt('last_top_performer_week') ?? 0;
    final currentWeek = _getWeekNumber(now);

    return lastAnnouncedWeek < currentWeek;
  }

  /// Announce weekly top performer via push notification
  Future<void> announceWeeklyTopPerformer() async {
    try {
      final topPerformer = await getWeeklyTopPerformer();
      if (topPerformer == null || topPerformer.weeklyScore == 0) {
        debugPrint('[PerformanceService] No top performer to announce');
        return;
      }

      // Send notification
      await _notificationService.showNotification(
        id: 901,
        title: '🏆 Weekly Champion!',
        body:
            'This week\'s top solver: ${topPerformer.name} with ${topPerformer.weeklyScore} problems solved! Keep pushing! 💪',
        type: NotificationType.motivation,
        channel: 'psgmx_channel_main',
      );

      // Store in database as announcement for in-app banner
      await _createWeeklyAnnouncementInDb(topPerformer);

      // Mark as announced
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_top_performer_week', _getWeekNumber(DateTime.now()));

      debugPrint(
          '[PerformanceService] Weekly top performer announced: ${topPerformer.name}');
    } catch (e) {
      debugPrint('[PerformanceService] Error announcing top performer: $e');
    }
  }

  /// Create an announcement in database for in-app display
  Future<void> _createWeeklyAnnouncementInDb(
      WeeklyTopPerformer performer) async {
    try {
      // Check if announcement already exists this week
      final weekStart = _getWeekStartDate(DateTime.now());
      final existingResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('type', 'motivation')
          .gte('created_at', weekStart.toIso8601String())
          .ilike('title', '%Weekly Champion%')
          .maybeSingle();

      if (existingResponse != null) {
        debugPrint('[PerformanceService] Weekly announcement already exists');
        return;
      }

      // Create new announcement
      await _supabase.from('notifications').insert({
        'title': '🏆 Weekly Champion!',
        'body':
            'Congratulations to ${performer.name} for being this week\'s top solver with ${performer.weeklyScore} problems solved! Keep up the great work everyone! 💪',
        'type': 'motivation',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[PerformanceService] Error creating announcement in DB: $e');
    }
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  DateTime _getWeekStartDate(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // ========================================
  // C2: LEETCODE MILESTONES
  // ========================================

  /// Check if user has reached a new milestone
  Future<MilestoneAchievement?> checkMilestoneAchieved(String userId) async {
    try {
      // Get user's LeetCode username
      final userResponse = await _supabase
          .from('users')
          .select('leetcode_username, name')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return null;

      final leetcodeUsername = userResponse['leetcode_username'] as String?;
      final userName = userResponse['name'] as String? ?? 'User';

      if (leetcodeUsername == null || leetcodeUsername.isEmpty) {
        return null;
      }

      // Get current stats
      final statsResponse = await _supabase
          .from('leetcode_stats')
          .select('total_solved')
          .eq('username', leetcodeUsername)
          .maybeSingle();

      if (statsResponse == null) return null;

      final totalSolved = statsResponse['total_solved'] as int? ?? 0;

      // Check against stored milestones
      final prefs = await SharedPreferences.getInstance();
      final lastMilestone = prefs.getInt('milestone_$userId') ?? 0;

      // Find the highest milestone reached
      int? newMilestone;
      for (final milestone in milestones) {
        if (totalSolved >= milestone && milestone > lastMilestone) {
          newMilestone = milestone;
        }
      }

      if (newMilestone != null) {
        // Store new milestone
        await prefs.setInt('milestone_$userId', newMilestone);

        return MilestoneAchievement(
          userId: userId,
          userName: userName,
          milestone: newMilestone,
          totalSolved: totalSolved,
        );
      }

      return null;
    } catch (e) {
      debugPrint('[PerformanceService] Error checking milestone: $e');
      return null;
    }
  }

  /// Announce milestone achievement via notification
  Future<void> announceMilestone(MilestoneAchievement achievement) async {
    try {
      // Local notification for the user
      await _notificationService.showNotification(
        id: 902 + achievement.milestone,
        title: '🎉 Milestone Reached!',
        body:
            'Congratulations! You\'ve solved ${achievement.milestone} problems on LeetCode! Keep going! 🚀',
        type: NotificationType.motivation,
        channel: 'psgmx_channel_main',
      );

      // Create announcement in database for everyone to see
      await _supabase.from('notifications').insert({
        'title': '🎉 Milestone Achievement!',
        'body':
            '${achievement.userName} just crossed ${achievement.milestone} problems on LeetCode! 🌟',
        'type': 'motivation',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint(
          '[PerformanceService] Milestone announced: ${achievement.userName} - ${achievement.milestone}');
    } catch (e) {
      debugPrint('[PerformanceService] Error announcing milestone: $e');
    }
  }

  /// Check and announce milestone for current user
  Future<void> checkAndAnnounceMilestone() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final achievement = await checkMilestoneAchieved(userId);
    if (achievement != null) {
      await announceMilestone(achievement);
    }
  }

  // ========================================
  // GET TOP PERFORMERS FOR UI
  // ========================================

  /// Get top N performers for display
  Future<List<LeetCodeStats>> getTopPerformers(
      {int limit = 3, bool weekly = true}) async {
    try {
      final orderBy = weekly ? 'weekly_score' : 'total_solved';

      final response = await _supabase
          .from('leetcode_stats')
          .select()
          .order(orderBy, ascending: false)
          .limit(limit);

      return (response as List).map((e) => LeetCodeStats.fromMap(e)).toList();
    } catch (e) {
      debugPrint('[PerformanceService] Error getting top performers: $e');
      return [];
    }
  }

  /// Get current user's rank
  Future<int?> getCurrentUserRank({bool weekly = true}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Get user's LeetCode username
      final userResponse = await _supabase
          .from('users')
          .select('leetcode_username')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return null;

      final username = userResponse['leetcode_username'] as String?;
      if (username == null) return null;

      // Get all stats ordered
      final orderBy = weekly ? 'weekly_score' : 'total_solved';
      final allStats = await _supabase
          .from('leetcode_stats')
          .select('username')
          .order(orderBy, ascending: false);

      // Find user's position
      int rank = 1;
      for (var stat in allStats as List) {
        if (stat['username'] == username) {
          return rank;
        }
        rank++;
      }

      return null;
    } catch (e) {
      debugPrint('[PerformanceService] Error getting user rank: $e');
      return null;
    }
  }
}

// ========================================
// MODELS
// ========================================

class WeeklyTopPerformer {
  final String username;
  final String name;
  final int weeklyScore;

  WeeklyTopPerformer({
    required this.username,
    required this.name,
    required this.weeklyScore,
  });
}

class MilestoneAchievement {
  final String userId;
  final String userName;
  final int milestone;
  final int totalSolved;

  MilestoneAchievement({
    required this.userId,
    required this.userName,
    required this.milestone,
    required this.totalSolved,
  });
}
