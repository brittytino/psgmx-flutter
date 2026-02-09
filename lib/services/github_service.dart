import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for fetching GitHub repository statistics
class GitHubService {
  static const String _repoOwner = 'brittytino';
  static const String _repoName = 'psgmx-flutter';
  static const String _apiBaseUrl = 'https://api.github.com';
  
  // Cache to prevent excessive API calls
  static GitHubRepoStats? _cachedStats;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Fetch repository statistics (stars and forks)
  static Future<GitHubRepoStats> fetchRepoStats() async {
    // Return cached data if still valid
    if (_cachedStats != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedStats!;
    }

    try {
      final url = Uri.parse('$_apiBaseUrl/repos/$_repoOwner/$_repoName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedStats = GitHubRepoStats(
          stars: data['stargazers_count'] ?? 0,
          forks: data['forks_count'] ?? 0,
        );
        _lastFetchTime = DateTime.now();
        return _cachedStats!;
      } else {
        debugPrint('GitHub API error: ${response.statusCode}');
        return const GitHubRepoStats(stars: 0, forks: 0);
      }
    } catch (e) {
      debugPrint('Error fetching GitHub stats: $e');
      // Return cached data if available, otherwise return zeros
      return _cachedStats ?? const GitHubRepoStats(stars: 0, forks: 0);
    }
  }

  /// Clear the cache (useful for manual refresh)
  static void clearCache() {
    _cachedStats = null;
    _lastFetchTime = null;
  }
}

/// Model for GitHub repository statistics
class GitHubRepoStats {
  final int stars;
  final int forks;

  const GitHubRepoStats({
    required this.stars,
    required this.forks,
  });

  String get formattedStars => _formatCount(stars);
  String get formattedForks => _formatCount(forks);

  static String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
