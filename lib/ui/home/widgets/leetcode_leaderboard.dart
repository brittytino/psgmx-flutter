import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/leetcode_provider.dart';
import '../../../models/leetcode_stats.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../services/supabase_service.dart';

/// Modern LeetCode Leaderboard with proper theme support
/// Features: Top 3 podium, paginated grid, weekly/overall toggle, refresh for placement reps
class LeetCodeLeaderboard extends StatefulWidget {
  const LeetCodeLeaderboard({super.key});

  @override
  State<LeetCodeLeaderboard> createState() => _LeetCodeLeaderboardState();
}

class _LeetCodeLeaderboardState extends State<LeetCodeLeaderboard>
    with TickerProviderStateMixin {
  bool _isWeekly = true;
  bool _isRefreshing = false;
  int _currentPage = 0;
  static const int _usersPerPage = 14;

  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeLeaderboard();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLeaderboard() async {
    final provider = context.read<LeetCodeProvider>();
    await provider.loadAllUsersFromDatabase();
  }

  Future<void> _refreshLeaderboard() async {
    // Capture all context-dependent values BEFORE any await
    final supabaseService = context.read<SupabaseService>();
    final user = supabaseService.client.auth.currentUser;
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leetCodeProvider = context.read<LeetCodeProvider>();

    final userData = await supabaseService
        .client
        .from('users')
        .select('roles')
        .eq('email', user.email!)
        .single();

    final roles = userData['roles'] as Map<String, dynamic>?;
    final isPlacementRep = roles?['isPlacementRep'] ?? false;

    if (!isPlacementRep) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text(
                '⚠️ Only Placement Representatives can refresh data'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _isRefreshing = true);
    _refreshAnimationController.repeat();

    try {
      if (!mounted) return;
      final shouldRefresh = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildRefreshDialog(isDark),
      );

      if (shouldRefresh == true && mounted) {
        // Show progress modal
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _RefreshProgressModal(
            leetCodeProvider: leetCodeProvider,
            onComplete: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('✅ Refresh complete! All stats updated.'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      }
    }
  }

  Widget _buildRefreshDialog(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6600).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.refresh, color: Color(0xFFFF6600), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Refresh All Students?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will fetch fresh LeetCode data for all 123 students.',
            style: GoogleFonts.inter(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This may take 1-2 minutes',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.amber.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6600),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Refresh All',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: AppSpacing.lg),
          Consumer<LeetCodeProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.allUsers.isEmpty) {
                return _buildLoadingState(isDark, provider.loadingMessage);
              }

              final users = _getSortedUsers(provider.allUsers);

              if (users.isEmpty) {
                return _buildEmptyState(isDark);
              }

              final top3 = users.take(3).toList();
              final rest = users.skip(3).toList();

              final totalPages = (rest.length / _usersPerPage).ceil();
              final startIndex = _currentPage * _usersPerPage;
              final endIndex =
                  (startIndex + _usersPerPage).clamp(0, rest.length);
              final paginatedUsers = rest.sublist(startIndex, endIndex);

              return Column(
                children: [
                  if (top3.isNotEmpty) _buildTop3Podium(top3, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  _buildToggle(isDark),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatsSummary(users.length, isDark),
                  const SizedBox(height: AppSpacing.lg),
                  if (paginatedUsers.isNotEmpty)
                    _buildUserGrid(paginatedUsers, 4 + startIndex, isDark),
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

  Widget _buildLoadingState(bool isDark, String message) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
              backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ],
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
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.2),
                const Color(0xFFFFA500).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFD700),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LeetCode Leaderboard",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                "${_isWeekly ? 'Weekly' : 'All-Time'} Top Performers",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<bool>(
          future: _checkIsPlacementRep(),
          builder: (context, snapshot) {
            final isPlacementRep = snapshot.data ?? false;

            if (!isPlacementRep) {
              return IconButton(
                onPressed: () => _showAutoRefreshInfo(isDark),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: textSecondary,
                ),
                tooltip: "Auto-refreshed daily",
              );
            }

            return AnimatedBuilder(
              animation: _refreshAnimationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshAnimationController.value * 2 * 3.14159,
                  child: IconButton(
                    onPressed: _isRefreshing ? null : _refreshLeaderboard,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF6600)),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded,
                            color: Color(0xFFFF6600)),
                    tooltip: "Refresh All Stats",
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAutoRefreshInfo(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_mode_rounded,
                  color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Auto-Refresh',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'LeetCode stats are refreshed daily automatically.\n\n'
          'Only Placement Representatives can manually refresh all student data.',
          style: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Got it',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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
      height: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1)
            Expanded(child: _buildPodiumCard(top3[1], 2, 140, isDark)),
          const SizedBox(width: 8),
          if (top3.isNotEmpty)
            Expanded(child: _buildPodiumCard(top3[0], 1, 165, isDark)),
          const SizedBox(width: 8),
          if (top3.length > 2)
            Expanded(child: _buildPodiumCard(top3[2], 3, 130, isDark)),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
      LeetCodeStats user, int rank, double height, bool isDark) {
    final medalColors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };
    final medalColor = medalColors[rank] ?? Colors.grey;

    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown/Star Badge
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor,
                medalColor.withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            rank == 1 ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.white,
            size: rank == 1 ? 20 : 16,
          ),
        ),
        const SizedBox(height: 6),

        // Avatar
        Container(
          width: rank == 1 ? 54 : 46,
          height: rank == 1 ? 54 : 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: rank == 1 ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child:
                user.profilePicture != null && user.profilePicture!.isNotEmpty
                    ? Image.network(
                        user.profilePicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildDefaultAvatar(user, isDark, medalColor),
                      )
                    : _buildDefaultAvatar(user, isDark, medalColor),
          ),
        ),
        const SizedBox(height: 6),

        // Card
        Container(
          height: height,
          decoration: BoxDecoration(
            color: cardBg,
            border:
                Border.all(color: medalColor.withValues(alpha: 0.5), width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Name
              Text(
                user.name ?? user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: textPrimary,
                ),
              ),

              // Score
              Text(
                "${_isWeekly ? user.weeklyScore : user.totalSolved}",
                style: GoogleFonts.poppins(
                  fontSize: rank == 1 ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
              Text(
                _isWeekly ? "Weekly" : "Total",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: textSecondary,
                ),
              ),

              // Difficulty Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat("E", user.easySolved, const Color(0xFF4CAF50)),
                  _buildMiniStat(
                      "M", user.mediumSolved, const Color(0xFFFF9800)),
                  _buildMiniStat("H", user.hardSolved, const Color(0xFFF44336)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "$value",
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(bool isDark) {
    final toggleBg = isDark ? const Color(0xFF262626) : Colors.grey.shade200;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: toggleBg,
          borderRadius: BorderRadius.circular(28),
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
    const selectedBg = Color(0xFFFF6600);
    final unselectedText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekly = label.contains("Weekly");
          _currentPage = 0; // Reset pagination on toggle
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : unselectedText,
            fontWeight: FontWeight.w600,
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
        childAspectRatio: 0.78,
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
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6600).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.code_rounded,
              size: 48,
              color: Color(0xFFFF6600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No LeetCode Data Available",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your LeetCode username in Profile to get started",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshLeaderboard,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              "Refresh Data",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernUserCard(LeetCodeStats user, int rank, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade200;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final isTopPerformer = rank <= 10;
    const accentColor = Color(0xFFFF6600);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isTopPerformer ? accentColor.withValues(alpha: 0.4) : borderColor,
          width: isTopPerformer ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Rank Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isTopPerformer
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          )
                        : LinearGradient(
                            colors: isDark
                                ? [Colors.grey.shade700, Colors.grey.shade800]
                                : [Colors.grey.shade300, Colors.grey.shade400],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isTopPerformer
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    "#$rank",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: isTopPerformer
                          ? Colors.white
                          : (isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700),
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isTopPerformer)
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFD700), size: 20),
              ],
            ),

            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: user.profilePicture != null &&
                          user.profilePicture!.isNotEmpty
                      ? Image.network(
                          user.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultAvatar(user, isDark, accentColor),
                        )
                      : _buildDefaultAvatar(user, isDark, accentColor),
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
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textPrimary,
                  ),
                ),
                if (user.name != null)
                  Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "${_isWeekly ? user.weeklyScore : user.totalSolved}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: accentColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isWeekly ? "Weekly" : "Total",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty Stats
            Row(
              children: [
                _buildDifficultyChip(
                    "E", user.easySolved, const Color(0xFF4CAF50), isDark),
                const SizedBox(width: 6),
                _buildDifficultyChip(
                    "M", user.mediumSolved, const Color(0xFFFF9800), isDark),
                const SizedBox(width: 6),
                _buildDifficultyChip(
                    "H", user.hardSolved, const Color(0xFFF44336), isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(
      String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$value",
              style: GoogleFonts.poppins(
                fontSize: 13,
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
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade200;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    const accentColor = Color(0xFFFF6600);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            Icons.people_rounded,
            "$totalUsers",
            "Students",
            accentColor,
            textPrimary,
            textSecondary,
          ),
          Container(
            width: 1,
            height: 44,
            color: borderColor,
          ),
          _buildSummaryItem(
            Icons.code_rounded,
            "LeetCode",
            "Rankings",
            Colors.green,
            textPrimary,
            textSecondary,
          ),
          Container(
            width: 1,
            height: 44,
            color: borderColor,
          ),
          _buildSummaryItem(
            Icons.trending_up_rounded,
            _isWeekly ? "Weekly" : "Overall",
            "Mode",
            Colors.blue,
            textPrimary,
            textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade200;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: _currentPage > 0 ? const Color(0xFFFF6600) : iconColor,
            ),
            tooltip: "Previous Page",
          ),
          ...List.generate(
            totalPages.clamp(0, 5),
            (index) {
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
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _currentPage < totalPages - 1
                  ? const Color(0xFFFF6600)
                  : iconColor,
            ),
            tooltip: "Next Page",
          ),
        ],
      ),
    );
  }

  Widget _buildPageDot(int page, bool isDark) {
    final isActive = page == _currentPage;
    final inactiveColor =
        isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade200;
    final inactiveTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => setState(() => _currentPage = page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 36 : 32,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6600) : inactiveColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6600).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            "${page + 1}",
            style: GoogleFonts.poppins(
              color: isActive ? Colors.white : inactiveTextColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(LeetCodeStats user, bool isDark,
      [Color? accentColor]) {
    final color = accentColor ?? const Color(0xFFFF6600);
    final bgColor = isDark ? const Color(0xFF262626) : Colors.grey.shade100;

    return Container(
      color: bgColor,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 26,
          color: color,
        ),
      ),
    );
  }
}

/// Modal dialog that shows real-time progress while refreshing LeetCode stats
class _RefreshProgressModal extends StatefulWidget {
  final LeetCodeProvider leetCodeProvider;
  final VoidCallback onComplete;

  const _RefreshProgressModal({
    required this.leetCodeProvider,
    required this.onComplete,
  });

  @override
  State<_RefreshProgressModal> createState() => _RefreshProgressModalState();
}

class _RefreshProgressModalState extends State<_RefreshProgressModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isComplete = false;
  String _statusMessage = 'Starting refresh...';
  int _currentUser = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _startRefresh();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRefresh() async {
    try {
      // Listen to provider updates
      widget.leetCodeProvider.addListener(_onProviderUpdate);
      
      await widget.leetCodeProvider.refreshAllUsersFromAPI();
      
      if (mounted) {
        setState(() {
          _isComplete = true;
          _statusMessage = 'Refresh complete!';
        });
        
        // Wait a moment to show completion, then close
        await Future.delayed(const Duration(seconds: 2));
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isComplete = true;
          _statusMessage = 'Error: $e';
        });
        await Future.delayed(const Duration(seconds: 3));
        widget.onComplete();
      }
    } finally {
      widget.leetCodeProvider.removeListener(_onProviderUpdate);
    }
  }

  void _onProviderUpdate() {
    if (!mounted) return;
    final message = widget.leetCodeProvider.loadingMessage;
    
    // Parse progress from message like "Fetching 45/123 users..."
    final match = RegExp(r'(\d+)/(\d+)').firstMatch(message);
    if (match != null) {
      setState(() {
        _currentUser = int.tryParse(match.group(1) ?? '0') ?? 0;
        _totalUsers = int.tryParse(match.group(2) ?? '0') ?? 0;
        _statusMessage = message;
      });
    } else {
      setState(() => _statusMessage = message);
    }
  }

  double get _progress {
    if (_totalUsers == 0) return 0.0;
    return _currentUser / _totalUsers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return PopScope(
      canPop: _isComplete,
      child: Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isComplete
                            ? Colors.green.withValues(alpha: 0.15)
                            : const Color(0xFFFF6600).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isComplete ? Icons.check_circle : Icons.sync,
                        color: _isComplete ? Colors.green : const Color(0xFFFF6600),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                _isComplete ? 'All Done!' : 'Refreshing LeetCode Data',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Status Message
              Text(
                _statusMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Progress Bar
              if (!_isComplete && _totalUsers > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 12,
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_currentUser / $_totalUsers users',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6600),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Loading indicator when no progress yet
              if (!_isComplete && _totalUsers == 0) ...[
                const SizedBox(height: 8),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
                ),
                const SizedBox(height: 16),
              ],
              
              // Warning message
              if (!_isComplete)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please wait until the process completes. Do not close this dialog.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Success summary
              if (_isComplete) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Leaderboard updated successfully!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
