import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leetcode_stats.dart';
import '../../providers/user_provider.dart';
import '../../providers/leetcode_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../services/supabase_db_service.dart';
import '../../services/quote_service.dart';
import '../../services/notification_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';
import 'widgets/leetcode_card.dart';
import 'widgets/leaderboard_card.dart';
import 'widgets/attendance_action_card.dart';
import '../../core/ui/skeletons.dart';
import 'widgets/announcements_list.dart';
import 'widgets/create_announcement_dialog.dart';
import '../attendance/daily_attendance_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<LeetCodeStats>>? _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = context.read<LeetCodeProvider>().fetchTopSolvers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Fetch Announcements
      context.read<AnnouncementProvider>().fetchAnnouncements();
      
      // 2. Refresh My LeetCode Stats
      final user = context.read<UserProvider>().currentUser;
      if (user?.leetcodeUsername != null) {
        context.read<LeetCodeProvider>().fetchStats(user!.leetcodeUsername!);
      }
    });

    NotificationService().init(); // Ensure notification init
    NotificationService().requestPermissions();
    _checkAttendancePopup();
  }

  void _checkAttendancePopup() async {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isTeamLeader) return;

    final now = DateTime.now();
    // After 5 PM
    if (now.hour >= 17) {
       // Ideally check if already submitted today
       if (!mounted) return;
       await Future.delayed(const Duration(seconds: 1)); // Small delay for enter animation
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DailyAttendanceSheet(),
    );
  }

  void _showCreateAnnouncement(BuildContext context) {
    showDialog(
      context: context, 
      builder: (ctx) => const CreateAnnouncementDialog()
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
    final isStudentView = !userProvider.isCoordinator && !userProvider.isPlacementRep;
    // Show TL Actions if Lead AND (Time > 10AM for demo, > 17PM for prod)
    final showTLActions = userProvider.isTeamLeader; 
    final canPost = userProvider.isCoordinator || userProvider.isPlacementRep;

    return Scaffold(
      floatingActionButton: canPost ? FloatingActionButton.extended(
        onPressed: () => _showCreateAnnouncement(context),
        icon: const Icon(Icons.campaign),
        label: const Text("Announce"),
      ) : null,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, userProvider),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Welcome Header
                _buildWelcomeHeader(context, user.name),
                const SizedBox(height: AppSpacing.xl),

                // 2. Hero Component: Daily Quote
                _QuoteCard(service: quoteService),
                const SizedBox(height: AppSpacing.xxl),
                
                // 3. Announcements (Global)
                const AnnouncementsList(),
                const SizedBox(height: AppSpacing.xxl),

                // Gamified Leaderboard
                FutureBuilder<List<LeetCodeStats>>(
                  future: _leaderboardFuture,
                  builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                          child: SkeletonCard(height: 200),
                        );
                     }
                     if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                     return Column(
                       children: [
                         LeaderboardCard(topSolvers: snapshot.data!),
                         const SizedBox(height: AppSpacing.xxl),
                       ],
                     );
                  }
                ),

                // 4. TL Actions
                if (showTLActions) ...[
                  AttendanceActionCard(onTap: () => _showAttendanceSheet(context)),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // 5. Dashboard
                if (isStudentView)
                  _StudentDashboard(db: dbService, provider: userProvider)
                else
                  _AdminDashboard(db: dbService),
                  
                // Bottom padding
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
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
        titlePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.md),
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
                Text(
                  'Placement 2026',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
             ),
             const Spacer(),
             _RoleBadge(userProvider: userProvider),
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
}

class _RoleBadge extends StatelessWidget {
  final UserProvider userProvider;
  const _RoleBadge({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = Theme.of(context).colorScheme.secondary;
    String roleLabel = 'Guest';

    if (userProvider.isPlacementRep) {
      badgeColor = const Color(0xFF9333EA); 
      roleLabel = 'Rep';
    } else if (userProvider.isCoordinator) {
      badgeColor = const Color(0xFFEA580C); 
      roleLabel = 'Coord';
    } else if (userProvider.isTeamLeader) {
      badgeColor = const Color(0xFF2563EB); 
      roleLabel = 'Lead';
    } else {
      badgeColor = const Color(0xFF16A34A); 
      roleLabel = 'Student';
    }

    if (userProvider.isSimulating) {
      roleLabel = 'SIM: $roleLabel';
      badgeColor = Theme.of(context).colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        roleLabel.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
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
        final quote = data?['text'] ?? 'Loading your daily insight...';
        final author = data?['author'] ?? '';

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
                    child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'DAILY MOTIVATION',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                quote,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              if (author.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '- $author',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  final SupabaseDbService db;
  final UserProvider provider;
  
  const _StudentDashboard({required this.db, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         _SectionHeader(title: 'Your Progress', action: 'History', onTap: () {}),
         const SizedBox(height: AppSpacing.md),
         Row(
           children: [
              Expanded(
                child: _buildAttendanceStat(context, '92%', 'Attendance', Colors.green),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildAttendanceStat(context, '14', 'Days Streak', Colors.orange),
              ),
           ],
         ),
         const SizedBox(height: AppSpacing.xxl),
         
         const LeetCodeCard(),
      ],
    );
  }
  
  Widget _buildAttendanceStat(BuildContext context, String value, String label, Color color) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
        if (!snapshot.hasData) return const SizedBox(height: 100);

        final data = snapshot.data!;
        final total = data['total_students'] as int? ?? 123;
        final present = data['today_present'] as int? ?? 0;
        final percent = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Overview', action: 'Reports', onTap: () {}),
            const SizedBox(height: AppSpacing.md),
             Row(
               children: [
                  Expanded(
                    child: PremiumCard(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
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
                           Text(
                             '$present / $total', 
                             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                           ),
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

  const _SectionHeader({required this.title, required this.action, required this.onTap});

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
