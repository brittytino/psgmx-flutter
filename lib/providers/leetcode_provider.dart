import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/leetcode_stats.dart';
import '../services/supabase_service.dart';

class LeetCodeProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  final Map<String, LeetCodeStats> _statsCache = {};
  final Set<String> _pendingRequests = {}; // Request deduplication
  
  LeetCodeProvider(this._supabaseService);
  
  // Clean username helper
  String _cleanUsername(String username) {
    if (username.contains('/')) {
      final parts = username.split('/');
      return parts.lastWhere((element) => element.isNotEmpty);
    }
    return username.trim();
  }

  Future<LeetCodeStats?> fetchStats(String rawUsername) async {
    final username = _cleanUsername(rawUsername);
    if (username.isEmpty) return null;

    // 1. Return memory cache immediately if available
    if (_statsCache.containsKey(username)) {
      final stats = _statsCache[username]!;
      // If data is fresh (< 1 hour), don't refetch
      if (DateTime.now().difference(stats.lastUpdated).inHours < 1) {
        return stats;
      }
    }
    
    // 2. Prevent duplicate in-flight requests
    if (_pendingRequests.contains(username)) {
      return _statsCache[username]; // Return what we have, or null
    }
    _pendingRequests.add(username);
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 3. Try to fetch from Supabase (Offline Support)
      final dbData = await _supabaseService.client
          .from('leetcode_stats')
          .select()
          .eq('username', username)
          .maybeSingle();
          
      if (dbData != null) {
        final stats = LeetCodeStats.fromMap(dbData);
        _statsCache[username] = stats;
        
        // If Supabase data is fresh (< 4 hours), stop here
        if (DateTime.now().difference(stats.lastUpdated).inHours < 4) {
          _pendingRequests.remove(username);
          _isLoading = false;
          notifyListeners();
          return stats;
        }
      }

      // 4. Fetch from LeetCode API (Network)
      final stats = await _fetchFromLeetCodeApi(username);
      
      // 5. Update Supabase & Cache
      if (stats != null) {
        await _supabaseService.client.from('leetcode_stats').upsert(stats.toMap());
        _statsCache[username] = stats;
      }
      
      _pendingRequests.remove(username);
      _isLoading = false;
      notifyListeners();
      return stats ?? _statsCache[username];
      
    } catch (e) {
      debugPrint('Error fetching LeetCode stats: $e');
      _pendingRequests.remove(username);
      _isLoading = false;
      notifyListeners();
      return _statsCache[username]; // Return stale/offline data
    }
  }

  Future<List<LeetCodeStats>> fetchLeaderboard({int limit = 3}) async {
    try {
      final response = await _supabaseService.client
          .from('leetcode_stats')
          .select()
          .order('weekly_score', ascending: false) // Weekly first as per request
          .limit(limit);
      
      return (response as List).map((e) => LeetCodeStats.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<List<LeetCodeStats>> fetchTopSolvers() async {
     return fetchLeaderboard();
  }


  Future<LeetCodeStats?> _fetchFromLeetCodeApi(String username) async {
    const String url = 'https://leetcode.com/graphql';
    
    // Calculate current year dynamically
    final year = DateTime.now().year;

    const String query = r'''
      query getUserProfile($username: String!, $year: Int) {
        matchedUser(username: $username) {
          username
          profile {
            ranking
          }
          submitStats: submitStatsGlobal {
            acSubmissionNum {
              difficulty
              count
            }
          }
          userCalendar(year: $year) {
            submissionCalendar
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (compatible; PSGMX/1.0)',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username, 'year': year}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['data']?['matchedUser'];
        
        if (user == null) return null;

        // Parse Solved Counts
        final stats = user['submitStats']['acSubmissionNum'] as List;
        int total = 0, easy = 0, medium = 0, hard = 0;
        
        for (var item in stats) {
          final count = item['count'] as int;
          switch (item['difficulty']) {
            case 'All': total = count; break;
            case 'Easy': easy = count; break;
            case 'Medium': medium = count; break;
            case 'Hard': hard = count; break;
          }
        }

        // Parse Ranking
        final ranking = user['profile']?['ranking'] ?? 0;

        // Calculate Weekly Score (Last 7 Days)
        int weeklyScore = 0;
        final calendarJson = user['userCalendar']?['submissionCalendar'];
        if (calendarJson != null && calendarJson is String) {
          try {
            final Map<String, dynamic> calendar = jsonDecode(calendarJson);
            final now = DateTime.now();
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            
            calendar.forEach((timestampStr, count) {
              final ts = int.tryParse(timestampStr);
              if (ts != null) {
                final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                if (date.isAfter(sevenDaysAgo)) {
                   weeklyScore += (count as int);
                }
              }
            });
          } catch (e) {
            debugPrint("Error parsing calendar: $e");
          }
        }

        return LeetCodeStats(
          username: username,
          totalSolved: total,
          easySolved: easy,
          mediumSolved: medium,
          hardSolved: hard,
          ranking: ranking,
          weeklyScore: weeklyScore,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('LeetCode API Exception: $e');
    }
    return null;
  }
}
