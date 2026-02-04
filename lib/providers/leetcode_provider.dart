import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/leetcode_stats.dart';
import '../services/supabase_service.dart';

class LeetCodeProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _loadingMessage = '';
  String get loadingMessage => _loadingMessage;
  
  final Map<String, LeetCodeStats> _statsCache = {};
  Map<String, LeetCodeStats> get statsCache => _statsCache;

  final Set<String> _pendingRequests = {}; // Request deduplication
  
  List<LeetCodeStats> _allUsers = [];
  List<LeetCodeStats> get allUsers => _allUsers;
  
  DateTime? _lastBatchUpdate;
  
  LeetCodeProvider(this._supabaseService);
  
  // Check if we need to refresh (every 12 hours)
  bool get needsRefresh {
    if (_lastBatchUpdate == null) return true;
    return DateTime.now().difference(_lastBatchUpdate!).inHours >= 12;
  }
  
  // Clean username helper
  String _cleanUsername(String username) {
    if (username.contains('/')) {
      final parts = username.split('/');
      return parts.lastWhere((element) => element.isNotEmpty);
    }
    return username.trim();
  }
  
  LeetCodeStats? getCachedStats(String username) {
    final clean = _cleanUsername(username);
    return _statsCache[clean];
  }

  Future<LeetCodeStats?> fetchStats(String rawUsername) async {
    final username = _cleanUsername(rawUsername);
    if (username.isEmpty) return null;

    // 1. Return memory cache immediately if available
    if (_statsCache.containsKey(username)) {
      final stats = _statsCache[username]!;
      // If data is fresh (< 12 hour), don't refetch
      if (DateTime.now().difference(stats.lastUpdated).inHours < 12) {
        return stats;
      }
    }
    
    // 2. Prevent duplicate in-flight requests
    if (_pendingRequests.contains(username)) {
      return _statsCache[username]; // Return what we have, or null
    }
    _pendingRequests.add(username);
    
    // Only set loading if we don't have cache to show
    if (!_statsCache.containsKey(username)) {
       _isLoading = true;
       notifyListeners();
    }
    
    try {
      // 3. Try to fetch from Supabase (Offline Support)
      if (!_statsCache.containsKey(username)) {
         final dbData = await _supabaseService.client
            .from('leetcode_stats')
            .select()
            .eq('username', username)
            .maybeSingle();
            
        if (dbData != null) {
          final stats = LeetCodeStats.fromMap(dbData);
          _statsCache[username] = stats;
          
          // If Supabase data is fresh (<12 hours), stop here
          if (DateTime.now().difference(stats.lastUpdated).inHours < 12) {
            _pendingRequests.remove(username);
            _isLoading = false;
            notifyListeners();
            return stats;
          }
          // We got stale data from DB, show it while we fetch fresh
          notifyListeners(); 
        }
      }

      // 4. Fetch from LeetCode API (Network) - it will save to DB internally
      final stats = await _fetchFromLeetCodeApi(username);
      
      // 5. Update Cache
      if (stats != null) {
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

  Future<List<LeetCodeStats>> fetchLeaderboard({
    int limit = 10, 
    int offset = 0,
    bool isWeekly = false,
  }) async {
    try {
      final orderBy = isWeekly ? 'weekly_score' : 'total_solved';

      final response = await _supabaseService.client
          .from('leetcode_stats')
          .select()
          .order(orderBy, ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List).map((e) => LeetCodeStats.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      // Return empty list on error instead of crashing
      return [];
    }
  }

  Future<List<LeetCodeStats>> fetchAllUsers() async {
    try {
      // 1. Fetch ALL whitelisted students (Source of Truth for Names)
      final whitelistResponse = await _supabaseService.client
          .from('whitelist')
          .select('leetcode_username, name');
          
      final nameMap = <String, String>{};
      final whitelistUsernames = <String>{};
      
      for (var entry in whitelistResponse as List) {
        final username = entry['leetcode_username'] as String?;
        final name = entry['name'] as String?;
        if (username != null && username.isNotEmpty) {
           final cleanUser = _cleanUsername(username);
           whitelistUsernames.add(cleanUser);
           if (name != null) {
             nameMap[cleanUser] = name;
           }
        }
      }

      // 2. Fetch ALL stats from database
      final statsResponse = await _supabaseService.client
          .from('leetcode_stats')
          .select()
          .order('total_solved', ascending: false)
          .limit(200); 
      
      final dbStatsList = (statsResponse as List).map((e) => LeetCodeStats.fromMap(e)).toList();
      
      // 3. Merge: Add names to stats AND include users with no stats (yet)
      final mergedUsers = <LeetCodeStats>[];
      final seenUsernames = <String>{};
      
      // First, add existing stats and attach names
      for (var stat in dbStatsList) {
        final cleanUser = _cleanUsername(stat.username);
        seenUsernames.add(cleanUser);
        
        // Attach name if available
        if (nameMap.containsKey(cleanUser)) {
           mergedUsers.add(stat.copyWith(name: nameMap[cleanUser]));
        } else {
           mergedUsers.add(stat);
        }
      }
      
      // Second, add students from whitelist who have no stats entry yet (create empty placeholder)
      // This ensures they appear in the list (at bottom) until fetched
      for (var username in whitelistUsernames) {
        if (!seenUsernames.contains(username)) {
           mergedUsers.add(
             LeetCodeStats.empty(username).copyWith(name: nameMap[username])
           );
        }
      }
      
      // Sort again just to be safe (Total solved desc)
      mergedUsers.sort((a, b) => b.totalSolved.compareTo(a.totalSolved));

      _allUsers = mergedUsers;
      
      // Update cache
      for (var user in mergedUsers) {
        _statsCache[user.username] = user;
      }
      
      notifyListeners();
      return mergedUsers;
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return _allUsers; // Return cached data
    }
  }

  /// Load all users from database (no API calls)
  /// This is called on app startup for all users
  Future<void> loadAllUsersFromDatabase() async {
    _isLoading = true;
    _loadingMessage = 'Loading user stats...';
    notifyListeners();
    
    try {
      // Just fetch from database - fast and no network calls
      await fetchAllUsers();
    } catch (e) {
      debugPrint('Error loading users from database: $e');
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  /// Refresh all users from LeetCode API (Placement Rep Only)
  /// This should only be called by authorized users
  Future<void> refreshAllUsersFromAPI() async {
    _isLoading = true;
    _loadingMessage = 'Preparing refresh...';
    notifyListeners();
    
    try {
      // 1. Get all leetcode usernames from WHITELIST (Source of Truth)
      // This checks EVERY student, not just those who signed up
      _loadingMessage = 'Loading user list...';
      notifyListeners();
      final usersResponse = await _supabaseService.client
          .from('whitelist')
          .select('leetcode_username')
          .not('leetcode_username', 'is', null);
      
      final usernames = <String>{};
      for (var user in usersResponse as List) {
        final username = user['leetcode_username'] as String?;
        if (username != null && username.isNotEmpty && username != 'NULL') {
          usernames.add(_cleanUsername(username));
        }
      }
      
      debugPrint('[LeetCode] Found ${usernames.length} students to refresh');

      // 2. Show current database data first (with names attached)
      _loadingMessage = 'Loading cached data...';
      notifyListeners();
      await fetchAllUsers();

      // 3. Fetch fresh data from LeetCode API
      if (usernames.isNotEmpty) {
        await _refreshInBackground(usernames.toList());
      }
    } catch (e) {
      debugPrint('Error refreshing from API: $e');
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }
  
  /// Check if data needs daily refresh (for auto-refresh)
  bool get needsDailyRefresh {
    if (_lastBatchUpdate == null) return true;
    return DateTime.now().difference(_lastBatchUpdate!).inHours >= 24;
  }

  /// Background refresh from LeetCode API (non-blocking)
  Future<void> _refreshInBackground(List<String> usernames) async {
    debugPrint('[LeetCode] 🔄 Starting background refresh for ${usernames.length} users...');
    
    int successCount = 0;
    int failCount = 0;
    
    for (var i = 0; i < usernames.length; i++) {
      final username = usernames[i];
      try {
        // Update progress message
        _loadingMessage = 'Fetching ${i + 1}/${usernames.length} users...';
        notifyListeners();
        
        await Future.delayed(const Duration(milliseconds: 800)); // Rate limiting (slightly longer)
        final stats = await _fetchFromLeetCodeApi(username); // This saves to DB internally
        if (stats != null) {
          _statsCache[username] = stats;
          successCount++;
          
          // Notify UI every 10 users for progressive loading
          if (successCount % 10 == 0) {
            debugPrint('[LeetCode] 📊 Progress: $successCount/${usernames.length} users synced');
            await fetchAllUsers();
          }
        } else {
          failCount++;
          debugPrint('[LeetCode] ⚠️  Failed to fetch: $username');
        }
      } catch (e) {
        debugPrint('[LeetCode] ❌ Error fetching $username: $e');
        failCount++;
      }
    }
    
    debugPrint('[LeetCode] ✅ Batch refresh complete: $successCount success, $failCount failed');
    _lastBatchUpdate = DateTime.now();
    _loadingMessage = '';
    notifyListeners();
    
    // Save timestamp to database for tracking
    await _saveLastRefreshTimestamp();
    
    // Final UI refresh with all new data
    await fetchAllUsers();
  }
  
  /// Save last refresh timestamp to database
  Future<void> _saveLastRefreshTimestamp() async {
    try {
      // You could store this in a settings table or metadata table
      // For now, we'll just keep it in memory
      debugPrint('[LeetCode] Last refresh: ${_lastBatchUpdate.toString()}');
    } catch (e) {
      debugPrint('[LeetCode] Error saving timestamp: $e');
    }
  }

  Future<List<LeetCodeStats>> fetchTopSolvers() async {
     return fetchLeaderboard(limit: 150, isWeekly: false); // Fetch all users, sort by total
  }


  Future<LeetCodeStats?> _fetchFromLeetCodeApi(String username) async {
    // Try official LeetCode GraphQL API first
    final stats = await _fetchFromOfficialApi(username);
    if (stats != null) return stats;
    
    // Fallback to Alpha API if official fails
    return await _fetchFromAlphaApi(username);
  }

  Future<LeetCodeStats?> _fetchFromOfficialApi(String username) async {
    try {
      // Use official LeetCode GraphQL API (same as Kotlin implementation)
      const url = 'https://leetcode.com/graphql';
      
      // GraphQL query matching the Kotlin implementation
      const query = '''
        query getUserProfile(\$username: String!) {
          matchedUser(username: \$username) {
            username
            profile {
              realName
              userAvatar
              ranking
            }
            submitStats: submitStatsGlobal {
              acSubmissionNum {
                difficulty
                count
                submissions
              }
            }
            submissionCalendar
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://leetcode.com',
          'Origin': 'https://leetcode.com',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username}
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        // Check for GraphQL errors
        if (body['errors'] != null) {
          debugPrint('[LeetCode] ⚠️  GraphQL Error for $username, trying Alpha API');
          return null;
        }

        final matchedUser = body['data']?['matchedUser'];
        if (matchedUser == null) {
          debugPrint('[LeetCode] ⚠️  User not found in official API: $username');
          return null;
        }

        // Parse submission stats
        final submitStats = matchedUser['submitStats']['acSubmissionNum'] as List;
        int totalSolved = 0;
        int easySolved = 0;
        int mediumSolved = 0;
        int hardSolved = 0;

        for (var stat in submitStats) {
          final difficulty = stat['difficulty'] as String;
          final count = stat['count'] as int;
          
          switch (difficulty) {
            case 'All':
              totalSolved = count;
              break;
            case 'Easy':
              easySolved = count;
              break;
            case 'Medium':
              mediumSolved = count;
              break;
            case 'Hard':
              hardSolved = count;
              break;
          }
        }

        final ranking = matchedUser['profile']['ranking'] as int? ?? 0;
        final profilePicture = matchedUser['profile']['userAvatar'] as String?;

        // Calculate weekly score from submission calendar
        int weeklyScore = 0;
        final submissionCalendarStr = matchedUser['submissionCalendar'] as String?;
        if (submissionCalendarStr != null && submissionCalendarStr.isNotEmpty) {
          try {
            final submissionCalendar = jsonDecode(submissionCalendarStr) as Map<String, dynamic>;
            final now = DateTime.now();
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            
            submissionCalendar.forEach((timestampStr, count) {
              try {
                final timestamp = int.tryParse(timestampStr);
                if (timestamp != null) {
                  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                  if (date.isAfter(sevenDaysAgo)) {
                    weeklyScore += (count as int? ?? 0);
                  }
                }
              } catch (e) {
                // Skip invalid entries
              }
            });
          } catch (e) {
            debugPrint('[LeetCode] ⚠️  Calendar parse error for $username');
          }
        }

        debugPrint('[LeetCode] ✅ [Official API] $username: $totalSolved problems (E:$easySolved M:$mediumSolved H:$hardSolved) ${profilePicture != null ? '🖼️' : ''}');
        
        final stats = LeetCodeStats(
          username: username,
          profilePicture: profilePicture,
          totalSolved: totalSolved,
          easySolved: easySolved,
          mediumSolved: mediumSolved,
          hardSolved: hardSolved,
          ranking: ranking,
          weeklyScore: weeklyScore,
          lastUpdated: DateTime.now(),
        );

        // Save to database immediately
        await _saveToDatabase(stats);
        return stats;
      } else {
        debugPrint('[LeetCode] ⚠️  Official API returned ${response.statusCode} for $username');
        return null;
      }
    } catch (e) {
      debugPrint('[LeetCode] ⚠️  Official API Exception for $username: $e');
      return null;
    }
  }

  Future<LeetCodeStats?> _fetchFromAlphaApi(String username) async {
    try {
      // Fallback to Alpha API
      final alphaUrl = 'https://alfa-leetcode-api.onrender.com/userProfile/$username';
      
      final response = await http.get(
        Uri.parse(alphaUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['errors'] != null || data['status'] == 'error') {
          debugPrint('[LeetCode] ❌ User not found: $username');
          return null;
        }

        final totalSolved = data['totalSolved'] as int? ?? 0;
        final easySolved = data['easySolved'] as int? ?? 0;
        final mediumSolved = data['mediumSolved'] as int? ?? 0;
        final hardSolved = data['hardSolved'] as int? ?? 0;
        final ranking = data['ranking'] as int? ?? 0;

        // Calculate weekly score
        int weeklyScore = 0;
        final submissionCalendar = data['submissionCalendar'];
        if (submissionCalendar != null && submissionCalendar is Map) {
          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          
          submissionCalendar.forEach((timestampStr, count) {
            try {
              final timestamp = int.tryParse(timestampStr.toString());
              if (timestamp != null) {
                final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                if (date.isAfter(sevenDaysAgo)) {
                  weeklyScore += (count as int? ?? 0);
                }
              }
            } catch (e) {
              // Skip
            }
          });
        }

        debugPrint('[LeetCode] ✅ [Alpha API] $username: $totalSolved problems');
        
        final stats = LeetCodeStats(
          username: username,
          totalSolved: totalSolved,
          easySolved: easySolved,
          mediumSolved: mediumSolved,
          hardSolved: hardSolved,
          ranking: ranking,
          weeklyScore: weeklyScore,
          lastUpdated: DateTime.now(),
        );

        // Save to database
        await _saveToDatabase(stats);
        return stats;
      } else {
        debugPrint('[LeetCode] ❌ Alpha API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[LeetCode] ❌ Alpha API Exception: $e');
      return null;
    }
  }

  Future<void> _saveToDatabase(LeetCodeStats stats) async {
    try {
      await _supabaseService.client
          .from('leetcode_stats')
          .upsert(stats.toMap());
      debugPrint('[LeetCode] 💾 Saved ${stats.username} to database');
    } catch (e) {
      debugPrint('[LeetCode] ❌ Failed to save ${stats.username} to DB: $e');
      rethrow; // Let caller handle
    }
  }
}
