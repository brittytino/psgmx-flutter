import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/leetcode_provider.dart';
import '../../../models/leetcode_stats.dart';
import '../../../services/connectivity_service.dart';
import '../../../core/theme/app_dimens.dart';
import '../../widgets/offline_error_view.dart';

class ModernLeaderboard extends StatefulWidget {
  const ModernLeaderboard({super.key});

  @override
  State<ModernLeaderboard> createState() => _ModernLeaderboardState();
}

class _ModernLeaderboardState extends State<ModernLeaderboard> {
  bool _isWeekly = true;
  late Future<List<LeetCodeStats>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    _leaderboardFuture = context.read<LeetCodeProvider>().fetchLeaderboard(
      limit: 100,
      isWeekly: _isWeekly,
    );
  }

  void _refreshLeaderboard() {
    setState(() {
      _loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 8),
              Text(
                "Top 3 ${_isWeekly ? 'Weekly' : 'Overall'} Leaders",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Leaderboard
        FutureBuilder<List<LeetCodeStats>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              final isOffline = !ConnectivityService().hasConnection;
              if (isOffline) {
                return const CompactOfflineView();
              }
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return const Center(child: Text("No data available"));
            }

            final top3 = list.take(3).toList();
            final rest = list.skip(3).toList();

            return Column(
              children: [
                // Top 3 Podium
                if (top3.isNotEmpty) _buildTop3Podium(top3),
                const SizedBox(height: AppSpacing.xxl),

                // Toggle
                _buildToggle(),
                const SizedBox(height: AppSpacing.lg),

                // Rest of leaderboard
                if (rest.isNotEmpty) _buildRestLeaderboard(rest, 4),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTop3Podium(List<LeetCodeStats> top3) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Left)
          if (top3.length > 1)
            Expanded(
              child: _buildPodiumCard(top3[1], 2, 150),
            ),
          const SizedBox(width: 12),

          // 1st Place (Center - Tallest)
          if (top3.isNotEmpty)
            Expanded(
              child: _buildPodiumCard(top3[0], 1, 190),
            ),
          const SizedBox(width: 12),

          // 3rd Place (Right)
          if (top3.length > 2)
            Expanded(
              child: _buildPodiumCard(top3[2], 3, 150),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(LeetCodeStats user, int rank, double height) {
    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Medal Icon
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: medalColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // User Avatar
        Center(
          child: CircleAvatar(
            radius: 35,
            backgroundColor: medalColor.withValues(alpha: 30/255),
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: medalColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // User Info Card
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: medalColor.withValues(alpha: 100/255), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Column(
                children: [
                  Text(
                    "${_isWeekly ? user.weeklyScore : user.totalSolved}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: medalColor,
                    ),
                  ),
                  Text(
                    _isWeekly ? "Weekly" : "Total",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 25/255),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleBtn("Weekly Rank", _isWeekly),
            _buildToggleBtn("Overall Rank", !_isWeekly),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekly = label.contains("Weekly");
          _refreshLeaderboard();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRestLeaderboard(List<LeetCodeStats> users, int startRank) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: users.length,
      itemBuilder: (ctx, idx) {
        final user = users[idx];
        final rank = startRank + idx;
        return _buildLeaderboardCard(user, rank);
      },
    );
  }

  Widget _buildLeaderboardCard(LeetCodeStats user, int rank) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 50/255),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 30/255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "#$rank",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 30/255),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Text(
              user.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      "${user.totalSolved}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "${user.weeklyScore}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      "Week",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: _refreshLeaderboard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 14, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    "Refresh Stats",
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
