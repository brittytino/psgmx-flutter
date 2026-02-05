import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/leetcode_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../services/supabase_db_service.dart';
import '../../services/quote_service.dart';
import '../../services/notification_service.dart';
import '../../services/attendance_service.dart';
import '../../services/task_completion_service.dart';
import '../../services/attendance_streak_service.dart';
import '../../services/performance_service.dart';
import '../../models/attendance_streak.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';
import '../widgets/notification_bell_icon.dart';
import 'widgets/leetcode_card.dart';
import 'widgets/leetcode_leaderboard.dart';
import 'widgets/attendance_action_card.dart';
import 'widgets/create_announcement_dialog.dart';
import 'widgets/birthday_greeting_card.dart';
import '../attendance/daily_attendance_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isClassDay = true;
  bool _isLoadingClassStatus = true;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
      NotificationService().init(); // Ensure notification init
      NotificationService().requestPermissions();
      _checkAttendancePopup();
    });
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    // 1. Refresh Leaderboard
    // 2. Fetch Announcements
    context.read<AnnouncementProvider>().fetchAnnouncements();

    // 3. Refresh My LeetCode Stats
    final user = context.read<UserProvider>().currentUser;
    if (user?.leetcodeUsername != null) {
      await context
          .read<LeetCodeProvider>()
          .fetchStats(user!.leetcodeUsername!);
    }

    // 4. Check Class Day Status
    await _checkClassDay();
  }

  Future<void> _checkClassDay() async {
    if (!mounted) return;
    setState(() => _isLoadingClassStatus = true);
    try {
      final attendanceService = AttendanceService();
      final isDay = await attendanceService.isWorkingDay(DateTime.now());
      if (mounted) setState(() => _isClassDay = isDay);
    } catch (e) {
      // Fail safe to TRUE so we don't accidentally block attendance if network fails
      if (mounted) setState(() => _isClassDay = true);
    } finally {
      if (mounted) setState(() => _isLoadingClassStatus = false);
    }
  }

  void _checkAttendancePopup() async {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isTeamLeader) return;

    // Only check on class days!
    if (!_isClassDay) return;

    final now = DateTime.now();
    // After 5 PM
    if (now.hour >= 17) {
      // Ideally check if already submitted today
      if (!mounted) return;
      await Future.delayed(
          const Duration(seconds: 1)); // Small delay for enter animation
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const DailyAttendanceSheet(),
      );
    }
  }

  void _showAttendanceSheet(BuildContext context) {
    if (!_isClassDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Today is marked as a NON-CLASS day. Attendance not required.")),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DailyAttendanceSheet(),
    );
  }

  void _showCreateAnnouncement(BuildContext context) {
    showDialog(
        context: context, builder: (ctx) => const CreateAnnouncementDialog());
  }

  void _showAnnouncementsSheet(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final canPost = userProvider.isPlacementRep || userProvider.isCoordinator;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Announcements',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (canPost)
                      IconButton(
                        icon: Icon(
                          Icons.add_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateAnnouncement(context);
                        },
                        tooltip: 'New Announcement',
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Announcements List
              Expanded(
                child: Consumer<AnnouncementProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.announcements.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (provider.announcements.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No announcements yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.announcements.length,
                      itemBuilder: (context, index) {
                        final item = provider.announcements[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: item.isPriority 
                              ? Colors.red.withValues(alpha: 0.05)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (item.isPriority)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(Icons.priority_high, 
                                          color: Colors.red, size: 20),
                                      ),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: item.isPriority ? Colors.red : null,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatAnnouncementDate(item.createdAt),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    if (canPost)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        onPressed: () => _confirmDeleteAnnouncement(
                                          context, provider, item.id, item.title),
                                        color: Theme.of(context).colorScheme.error,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.message,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAnnouncementDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _confirmDeleteAnnouncement(BuildContext context, AnnouncementProvider provider,
      String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteAnnouncement(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Announcement deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access Providers
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final dbService = Provider.of<SupabaseDbService>(context, listen: false);
    final quoteService = Provider.of<QuoteService>(context, listen: false);

    // Initial Loading State
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine Dashboard Type
    final isStudentView =
        !userProvider.isCoordinator && !userProvider.isPlacementRep;
    // Show TL Actions if Lead AND Class Day
    final showTLActions = userProvider.isTeamLeader && _isClassDay;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAnnouncementsSheet(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.campaign),
            Consumer<AnnouncementProvider>(
              builder: (context, provider, _) {
                if (provider.announcements.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${provider.announcements.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Allow pull to refresh even if content short
          slivers: [
            _buildSliverAppBar(context, userProvider),

            // Non-Class Day Warning
            if (!_isClassDay && !_isLoadingClassStatus)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.weekend, color: Colors.amber, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        "No Class Today - Relax & Upskill!",
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Welcome Header
                  _buildWelcomeHeader(context, user.name),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Birthday Greeting (if today is birthday)
                  if (_isBirthday(user.dob)) ...[
                    BirthdayGreetingCard(userName: user.name),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // 3. Hero Component: Daily Quote
                  _QuoteCard(service: quoteService),
                  const SizedBox(height: AppSpacing.xxl),

                  // 4. TL Actions
                  if (showTLActions) ...[
                    AttendanceActionCard(
                        onTap: () => _showAttendanceSheet(context)),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // 5. Dashboard (Overview Section)
                  if (isStudentView)
                    _StudentDashboard(db: dbService, provider: userProvider)
                  else
                    _AdminDashboard(db: dbService),

                  const SizedBox(height: AppSpacing.xxl),

                  // 6. Personal LeetCode Stats (For Everyone with Username) - MOVED UP
                  if (user.leetcodeUsername != null &&
                      user.leetcodeUsername!.isNotEmpty)
                    const LeetCodeCard(),

                  if (user.leetcodeUsername != null &&
                      user.leetcodeUsername!.isNotEmpty)
                    const SizedBox(height: AppSpacing.lg),

                  // 7. LeetCode Leaderboard
                  const LeetCodeLeaderboard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Bottom padding
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserProvider userProvider) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 70,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding, vertical: AppSpacing.md),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PSGMX',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
            const Spacer(),
            const _NotificationBell(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String name) {
    // Split name to get first name
    final firstName = name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let\'s achieve greatness,',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          firstName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -1,
              ),
        ),
      ],
    );
  }

  bool _isBirthday(DateTime? dob) {
    if (dob == null) return false;
    final now = DateTime.now();
    return dob.month == now.month && dob.day == now.day;
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notifService, _) => FutureBuilder<List<dynamic>>(
        future: notifService.getNotifications(),
        builder: (context, snapshot) {
          final unreadCount =
              snapshot.data?.where((n) => n.isRead != true).length ?? 0;
          return NotificationBellIcon(unreadCount: unreadCount);
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteService service;
  const _QuoteCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: service.getDailyQuote(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final quote = data?['text'] ?? 'Make today count...';

        return PremiumCard(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 14),
                  ),
                  const Spacer(),
                  Text(
                    '✨',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '"$quote"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentDashboard extends StatefulWidget {
  final SupabaseDbService db;
  final UserProvider provider;

  const _StudentDashboard({required this.db, required this.provider});

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // C1: Weekly Top Performer Banner
        const _WeeklyTopPerformerBanner(),
        const SizedBox(height: AppSpacing.md),

        // A1: Today's Task Status
        const _TodayTaskStatus(),
        const SizedBox(height: AppSpacing.xl),

        _SectionHeader(title: 'Your Progress', action: 'History', onTap: () {}),
        const SizedBox(height: AppSpacing.md),

        // A3 & A4: Real attendance stats
        const _RealAttendanceStats(),
      ],
    );
  }
}

/// A1: Widget to show today's task completion status
class _TodayTaskStatus extends StatelessWidget {
  const _TodayTaskStatus();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TaskCompletionService().hasCompletedTodayTask(),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return PremiumCard(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.1)
              : Theme.of(context)
                  .colorScheme
                  .errorContainer
                  .withValues(alpha: 0.3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.pending_actions,
                  color: isCompleted
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Task Status',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? '✓ Completed' : 'Pending',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                TextButton(
                  onPressed: () {
                    // Navigate to tasks screen
                    Navigator.of(context).pushNamed('/tasks');
                  },
                  child: const Text('Go to Task'),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A3 & A4: Widget showing real attendance statistics with explanation
class _RealAttendanceStats extends StatelessWidget {
  const _RealAttendanceStats();

  @override
  Widget build(BuildContext context) {
    final streakService = AttendanceStreakService();

    return FutureBuilder<AttendanceCalculation>(
      future: streakService.getMyAttendanceCalculation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final calculation = snapshot.data ?? AttendanceCalculation.empty();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: (calculation.attendancePercentage >= 75
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          calculation.attendancePercentage >= 75
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: calculation.attendancePercentage >= 75
                              ? Colors.green
                              : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${calculation.attendancePercentage.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: calculation.attendancePercentage >=
                                            75
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Present/Total Days
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${calculation.presentCount}/${calculation.totalClassDays}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Days Present',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Explanation
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            calculation.explanation,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final SupabaseDbService db;
  const _AdminDashboard({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: db.getPlacementStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
              height: 100, child: Center(child: Text('Unable to load stats')));
        }

        final data = snapshot.data!;
        final total = data['total_students'] as int? ?? 123;
        final present = data['today_present'] as int? ?? 0;
        final percent =
            total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Overview', action: 'Reports', onTap: () {}),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PremiumCard(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Text('Today\'s Attendance'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$present / $total',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Students Present'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionHeader(
      {required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(action),
        ),
      ],
    );
  }
}

// ========================================
// C1: WEEKLY TOP PERFORMER BANNER
// ========================================
class _WeeklyTopPerformerBanner extends StatelessWidget {
  const _WeeklyTopPerformerBanner();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeeklyTopPerformer?>(
      future: PerformanceService().getWeeklyTopPerformer(),
      builder: (context, snapshot) {
        // Don't show anything if loading or no data
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final performer = snapshot.data!;

        // Don't show if no weekly score
        if (performer.weeklyScore == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade300,
                Colors.orange.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Champion',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      performer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${performer.weeklyScore} solved',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
