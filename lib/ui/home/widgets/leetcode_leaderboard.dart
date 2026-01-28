import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/leetcode_provider.dart';
import '../../../models/leetcode_stats.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../services/supabase_service.dart';

class LeetCodeLeaderboard extends StatefulWidget {
  const LeetCodeLeaderboard({super.key});

  @override
  State<LeetCodeLeaderboard> createState() => _LeetCodeLeaderboardState();
}

class _LeetCodeLeaderboardState extends State<LeetCodeLeaderboard> {
  bool _isWeekly = true;
  bool _isRefreshing = false;
  int _currentPage = 0;
  static const int _usersPerPage = 20;

  @override
  void initState() {
    super.initState();
    _initializeLeaderboard();
  }

  Future<void> _initializeLeaderboard() async {
    final provider = context.read<LeetCodeProvider>();
    // Just load from database - fast, no network calls
    await provider.loadAllUsersFromDatabase();
  }

  Future<void> _refreshLeaderboard() async {
    // Check if user is placement rep
    final user = context.read<SupabaseService>().client.auth.currentUser;
    if (user == null) return;

    // Get user role from database
    final userData = await context
        .read<SupabaseService>()
        .client
        .from('users')
        .select('roles')
        .eq('email', user.email!)
        .single();

    final roles = userData['roles'] as Map<String, dynamic>?;
    final isPlacementRep = roles?['isPlacementRep'] ?? false;

    if (!isPlacementRep) {
      // Show error for non-placement reps
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Only Placement Representatives can refresh data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      // Show confirmation dialog
      final shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Refresh All Students?'),
          content: const Text(
            'This will fetch fresh LeetCode data for all 123 students.\n\n'
            'It may take 1-2 minutes.\n\nContinue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Refresh All'),
            ),
          ],
        ),
      );

      if (shouldRefresh == true) {
        await context.read<LeetCodeProvider>().refreshAllUsersFromAPI();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Refresh complete! All stats updated.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(isDark),
          const SizedBox(height: AppSpacing.lg),

          // Leaderboard Content
          Consumer<LeetCodeProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.allUsers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        if (provider.loadingMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            provider.loadingMessage,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              final users = _getSortedUsers(provider.allUsers);

              if (users.isEmpty) {
                return _buildEmptyState(isDark);
              }

              final top3 = users.take(3).toList();
              final rest = users.skip(3).toList();

              // Calculate pagination
              final totalPages = (rest.length / _usersPerPage).ceil();
              final startIndex = _currentPage * _usersPerPage;
              final endIndex =
                  (startIndex + _usersPerPage).clamp(0, rest.length);
              final paginatedUsers = rest.sublist(startIndex, endIndex);

              return Column(
                children: [
                  // Top 3 Podium
                  if (top3.isNotEmpty) _buildTop3Podium(top3, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Toggle
                  _buildToggle(isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats Summary
                  _buildStatsSummary(users.length, isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // Rest of users in grid with pagination
                  if (paginatedUsers.isNotEmpty)
                    _buildUserGrid(paginatedUsers, 4 + startIndex, isDark),

                  // Pagination Controls
                  if (totalPages > 1) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildPaginationControls(totalPages, isDark),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<LeetCodeStats> _getSortedUsers(List<LeetCodeStats> users) {
    final sorted = List<LeetCodeStats>.from(users);
    if (_isWeekly) {
      sorted.sort((a, b) => b.weeklyScore.compareTo(a.weeklyScore));
    } else {
      sorted.sort((a, b) => b.totalSolved.compareTo(a.totalSolved));
    }
    return sorted;
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Color(0xFFFFD700),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LeetCode Leaderboard",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                "${_isWeekly ? 'Weekly' : 'All-Time'} Top Performers",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
        // Refresh Button - Only show for Placement Reps
        FutureBuilder<bool>(
          future: _checkIsPlacementRep(),
          builder: (context, snapshot) {
            final isPlacementRep = snapshot.data ?? false;

            if (!isPlacementRep) {
              // Show info icon instead
              return IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('📊 Auto-Refresh'),
                      content: const Text(
                        'LeetCode stats are refreshed daily automatically.\n\n'
                        'Only Placement Representatives can manually refresh.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                tooltip: "Auto-refreshed daily",
              );
            }

            // Show refresh button for placement reps
            return IconButton(
              onPressed: _isRefreshing ? null : _refreshLeaderboard,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: "Refresh All Stats (Placement Rep)",
            );
          },
        ),
      ],
    );
  }

  Future<bool> _checkIsPlacementRep() async {
    try {
      final user = context.read<SupabaseService>().client.auth.currentUser;
      if (user == null) return false;

      final userData = await context
          .read<SupabaseService>()
          .client
          .from('users')
          .select('roles')
          .eq('email', user.email!)
          .single();

      final roles = userData['roles'] as Map<String, dynamic>?;
      return roles?['isPlacementRep'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Widget _buildTop3Podium(List<LeetCodeStats> top3, bool isDark) {
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          // 2nd Place
          if (top3.length > 1)
            Expanded(child: _buildPodiumCard(top3[1], 2, 180, isDark)),
          const SizedBox(width: 8),

          // 1st Place (Taller)
          if (top3.isNotEmpty)
            Expanded(child: _buildPodiumCard(top3[0], 1, 210, isDark)),
          const SizedBox(width: 8),

          // 3rd Place
          if (top3.length > 2)
            Expanded(child: _buildPodiumCard(top3[2], 3, 180, isDark)),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
      LeetCodeStats user, int rank, double height, bool isDark) {
    final medalColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

    final bgColor = isDark ? Colors.grey[900] : Colors.white;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Medal Badge
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: medalColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: medalColor.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            rank == 1 ? Icons.star : Icons.star_border,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),

        // Avatar
        CircleAvatar(
          radius: 30,
          backgroundColor: medalColor.withAlpha(30),
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: medalColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Card
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: medalColor.withAlpha(100), width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Name & Username
              Column(
                children: [
                   Text(
                    user.name ?? user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (user.name != null)
                    Text(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),

              // Stats
              Column(
                children: [
                  Text(
                    "${_isWeekly ? user.weeklyScore : user.totalSolved}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: medalColor,
                    ),
                  ),
                  Text(
                    _isWeekly ? "Weekly" : "Total",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Mini stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat("E", user.easySolved, Colors.green, 10),
                  _buildMiniStat("M", user.mediumSolved, Colors.orange, 10),
                  _buildMiniStat("H", user.hardSolved, Colors.red, 10),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, int value, Color color, double size) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: size,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "$value",
          style: TextStyle(
            fontSize: size + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton("Weekly Rank", _isWeekly, isDark),
            _buildToggleButton("Overall Rank", !_isWeekly, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekly = label.contains("Weekly");
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.grey[700] : Colors.grey[800])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrid(List<LeetCodeStats> users, int startRank, bool isDark) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78, // Adjusted for better fit on smaller screens
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: users.length,
      itemBuilder: (ctx, idx) {
        final user = users[idx];
        final rank = startRank + idx;
        return _buildModernUserCard(user, rank, isDark);
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.code, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No LeetCode Data Available",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your LeetCode username in Profile to get started",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshLeaderboard,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  // Modern card design with better visuals
  Widget _buildModernUserCard(LeetCodeStats user, int rank, bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[200];

    // Gradient for top performers
    final isTopPerformer = rank <= 10;
    final gradientColors = isTopPerformer
        ? [
            Theme.of(context).primaryColor.withAlpha(40),
            Theme.of(context).primaryColor.withAlpha(10),
          ]
        : [bgColor!, bgColor];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopPerformer
              ? Theme.of(context).primaryColor.withAlpha(100)
              : borderColor!,
          width: isTopPerformer ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10), // Reduced from 12 to prevent overflow
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            // Header: Rank Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTopPerformer
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                          : [Colors.grey[300]!, Colors.grey[400]!],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isTopPerformer
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withAlpha(60),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    "#$rank",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTopPerformer ? Colors.white : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isTopPerformer)
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
              ],
            ),

            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withAlpha(80),
                    Theme.of(context).primaryColor.withAlpha(40),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.transparent,
                child: Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : "?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Name & Username
            Column(
              children: [
                Text(
                  user.name ?? user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (user.name != null)
                  Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),

            // Main Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "${_isWeekly ? user.weeklyScore : user.totalSolved}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: Theme.of(context).primaryColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isWeekly ? "Weekly" : "Total",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty Stats
            Row(
              children: [
                _buildDifficultyChip(
                    "E", user.easySolved, const Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                _buildDifficultyChip(
                    "M", user.mediumSolved, const Color(0xFFFF9800)),
                const SizedBox(width: 6),
                _buildDifficultyChip(
                    "H", user.hardSolved, const Color(0xFFF44336)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(int totalUsers, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withAlpha(20),
            Theme.of(context).primaryColor.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(40),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            Icons.people,
            "$totalUsers",
            "Total Students",
            isDark,
          ),
          Container(width: 1, height: 40, color: Colors.grey[400]),
          _buildSummaryItem(
            Icons.code,
            "LeetCode",
            "Live Rankings",
            isDark,
          ),
          Container(width: 1, height: 40, color: Colors.grey[400]),
          _buildSummaryItem(
            Icons.trending_up,
            _isWeekly ? "Weekly" : "Overall",
            "Competition",
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: "Previous Page",
          ),

          // Page Indicators
          ...List.generate(
            totalPages.clamp(0, 5),
            (index) {
              // Show first page, current page, and last page
              int pageToShow;
              if (totalPages <= 5) {
                pageToShow = index;
              } else if (_currentPage < 2) {
                pageToShow = index;
              } else if (_currentPage > totalPages - 3) {
                pageToShow = totalPages - 5 + index;
              } else {
                if (index == 0) return _buildPageDot(0, isDark);
                if (index == 4) return _buildPageDot(totalPages - 1, isDark);
                pageToShow = _currentPage - 2 + index;
              }

              return _buildPageDot(pageToShow, isDark);
            },
          ),

          // Next Button
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: "Next Page",
          ),
        ],
      ),
    );
  }

  Widget _buildPageDot(int page, bool isDark) {
    final isActive = page == _currentPage;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = page;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 32 : 28,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.grey[700] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            "${page + 1}",
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
