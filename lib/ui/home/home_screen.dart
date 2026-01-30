import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/leetcode_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../services/supabase_db_service.dart';
import '../../services/quote_service.dart';
import '../../services/notification_service.dart';
import '../../services/attendance_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';
import '../widgets/notification_bell_icon.dart';
import 'widgets/leetcode_card.dart';
import 'widgets/leetcode_leaderboard.dart';
import 'widgets/attendance_action_card.dart';
import 'widgets/announcements_list.dart';
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
    _refreshAll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      await context.read<LeetCodeProvider>().fetchStats(user!.leetcodeUsername!);
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
    if (!_isClassDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Today is marked as a NON-CLASS day. Attendance not required.")),
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
    // Show TL Actions if Lead AND Class Day
    final showTLActions = userProvider.isTeamLeader && _isClassDay; 
    final canPost = userProvider.isCoordinator || userProvider.isPlacementRep;

    return Scaffold(
      floatingActionButton: canPost ? FloatingActionButton.extended(
        onPressed: () => _showCreateAnnouncement(context),
        icon: const Icon(Icons.campaign),
        label: const Text("Announce"),
      ) : null,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Allow pull to refresh even if content short
          slivers: [
            _buildSliverAppBar(context, userProvider),
            
            // Non-Class Day Warning
            if (!_isClassDay && !_isLoadingClassStatus)
               SliverToBoxAdapter(
                 child: Container(
                   margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                   padding: const EdgeInsets.all(AppSpacing.md),
                   decoration: BoxDecoration(
                     color: Colors.amber.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(AppRadius.lg),
                     border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
                  
                  // 3. Announcements (Global)
                  const AnnouncementsList(),
                  const SizedBox(height: AppSpacing.xxl),
  
                  // 4. TL Actions
                  if (showTLActions) ...[
                    AttendanceActionCard(onTap: () => _showAttendanceSheet(context)),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
  
                  // 5. Dashboard (Overview Section)
                  if (isStudentView)
                    _StudentDashboard(db: dbService, provider: userProvider)
                  else
                    _AdminDashboard(db: dbService),
                    
                  const SizedBox(height: AppSpacing.xxl),

                  // 6. Personal LeetCode Stats (For Everyone with Username) - MOVED UP
                  if (user.leetcodeUsername != null && user.leetcodeUsername!.isNotEmpty)
                     const LeetCodeCard(),
                  
                  if (user.leetcodeUsername != null && user.leetcodeUsername!.isNotEmpty)
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
          final unreadCount = snapshot.data?.where((n) => n.isRead != true).length ?? 0;
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(height: 100, child: Center(child: Text('Unable to load stats')));
        }

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
