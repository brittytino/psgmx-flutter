import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/leetcode_provider.dart';
import '../../../providers/user_provider.dart';
import 'dart:math' as math;

class LeetCodeCard extends StatefulWidget {
  const LeetCodeCard({super.key});

  @override
  State<LeetCodeCard> createState() => _LeetCodeCardState();
}

class _LeetCodeCardState extends State<LeetCodeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final leetCodeProvider =
          Provider.of<LeetCodeProvider>(context, listen: false);

      final username = userProvider.currentUser?.leetcodeUsername;
      if (username != null && username.isNotEmpty) {
        await leetCodeProvider.fetchStats(username);
        if (mounted) {
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('[LeetCodeCard] Init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final leetCodeProvider = Provider.of<LeetCodeProvider>(context);
    final user = userProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    final hasUsername =
        user.leetcodeUsername != null && user.leetcodeUsername!.isNotEmpty;

    // Theme-aware colors
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerBg = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFF8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA116), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA116).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.code_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LeetCode Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        hasUsername ? 'Your coding journey' : 'Connect account',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (leetCodeProvider.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.orangeAccent : const Color(0xFFFFA116),
                      ),
                    ),
                  )
                else if (hasUsername)
                  IconButton(
                    onPressed: () => leetCodeProvider
                        .fetchStats(user.leetcodeUsername!)
                        .then((_) {
                      if (mounted) {
                        _animationController.reset();
                        _animationController.forward();
                      }
                    }),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Refresh stats',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: !hasUsername
                ? _buildConnectView(context, isDark)
                : _buildStatsView(
                    context, leetCodeProvider, user.leetcodeUsername!, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectView(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.link_rounded,
          size: 48,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Connect Your LeetCode',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your progress, compete on leaderboards,\nand showcase your coding skills!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: textColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Go to Profile to add LeetCode username'),
                    ],
                  ),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: const Text('Connect Account'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView(BuildContext context, LeetCodeProvider provider,
      String username, bool isDark) {
    final stats = provider.getCachedStats(username);
    final user = context.read<UserProvider>().currentUser;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    // Loading state
    if (stats == null && provider.isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.orangeAccent : const Color(0xFFFFA116),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your stats...',
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Stats available
    if (stats != null) {
      return AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Column(
            children: [
              // Profile Row
              Row(
                children: [
                  // Profile Picture
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: stats.profilePicture != null &&
                              stats.profilePicture!.isNotEmpty
                          ? Image.network(
                              stats.profilePicture!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDefaultAvatar(user, isDark),
                            )
                          : _buildDefaultAvatar(user, isDark),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Username and Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.name != null)
                          Text(
                            user!.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Ranking Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.grey[800]!, Colors.grey[850]!]
                            : [Colors.grey[100]!, Colors.grey[200]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.leaderboard_rounded,
                          size: 14,
                          color: Color(0xFFFFA116),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${stats.ranking}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Main Content: Circle + Stats
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Progress Ring
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(130, 130),
                          painter: _AnimatedCircularProgressPainter(
                            easy: stats.easySolved,
                            medium: stats.mediumSolved,
                            hard: stats.hardSolved,
                            progress: _progressAnimation.value,
                            isDark: isDark,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(stats.totalSolved * _progressAnimation.value).round()}',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Solved',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Stats Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Easy',
                          stats.easySolved,
                          const Color(0xFF00B8A3),
                          isDark,
                          _progressAnimation.value,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Medium',
                          stats.mediumSolved,
                          const Color(0xFFFFC01E),
                          isDark,
                          _progressAnimation.value,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Hard',
                          stats.hardSolved,
                          const Color(0xFFEF4743),
                          isDark,
                          _progressAnimation.value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    // Error/No data state
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load stats',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => provider.fetchStats(username),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFA116),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, int value, Color color, bool isDark, double progress) {
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${(value * progress).round()}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(dynamic user, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 28,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }
}

class _AnimatedCircularProgressPainter extends CustomPainter {
  final int easy;
  final int medium;
  final int hard;
  final double progress;
  final bool isDark;

  _AnimatedCircularProgressPainter({
    required this.easy,
    required this.medium,
    required this.hard,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 10.0;

    // Background circle
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final totalSolved = easy + medium + hard;
    if (totalSolved == 0) return;

    final easyAngle = (easy / totalSolved) * 2 * math.pi * progress;
    final mediumAngle = (medium / totalSolved) * 2 * math.pi * progress;
    final hardAngle = (hard / totalSolved) * 2 * math.pi * progress;

    var startAngle = -math.pi / 2;

    // Draw Easy (Teal)
    if (easy > 0) {
      final easyPaint = Paint()
        ..color = const Color(0xFF00B8A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        easyAngle,
        false,
        easyPaint,
      );
      startAngle += easyAngle;
    }

    // Draw Medium (Yellow)
    if (medium > 0) {
      final mediumPaint = Paint()
        ..color = const Color(0xFFFFC01E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        mediumAngle,
        false,
        mediumPaint,
      );
      startAngle += mediumAngle;
    }

    // Draw Hard (Red)
    if (hard > 0) {
      final hardPaint = Paint()
        ..color = const Color(0xFFEF4743)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        hardAngle,
        false,
        hardPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedCircularProgressPainter oldDelegate) {
    return easy != oldDelegate.easy ||
        medium != oldDelegate.medium ||
        hard != oldDelegate.hard ||
        progress != oldDelegate.progress ||
        isDark != oldDelegate.isDark;
  }
}
