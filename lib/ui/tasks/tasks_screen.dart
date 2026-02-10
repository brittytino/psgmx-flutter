import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_db_service.dart';
import '../../services/task_upload_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/task_completion_service.dart';
import '../../models/daily_task.dart';
import '../../models/task_completion.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/offline_error_view.dart';
import 'bulk_upload_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Determine view based on role
    final canPublish = userProvider.isCoordinator ||
        (userProvider.isActualPlacementRep && !userProvider.isSimulating);
    
    final isTeamLeader = userProvider.isTeamLeader && !canPublish;

    // Reps/Coordinators see management interface
    if (canPublish) {
      return const _RepTasksView();
    }
    
    // Team Leaders see verification interface
    if (isTeamLeader) {
      return const _TeamLeaderTasksView();
    }
    
    // Students see task list
    return const _StudentTasksView();
  }
}

// ==========================================
// STUDENT VIEW
// ==========================================

class _StudentTasksView extends StatefulWidget {
  const _StudentTasksView();

  @override
  State<_StudentTasksView> createState() => _StudentTasksViewState();
}

class _StudentTasksViewState extends State<_StudentTasksView> {
  DateTime _selectedDate = DateTime.now();
  final TaskCompletionService _completionService = TaskCompletionService();
  bool _isMarkingComplete = false;

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<SupabaseDbService>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: const Text("Daily Roadmap"),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _pickDate,
                tooltip: "Jump to Date",
              )
            ],
          ),

          // Date Navigator Sticky Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md),
              child: _DateNavigator(
                date: _selectedDate,
                onNext: () => setState(() =>
                    _selectedDate = _selectedDate.add(const Duration(days: 1))),
                onPrev: () => setState(() => _selectedDate =
                    _selectedDate.subtract(const Duration(days: 1))),
                onTitleTap: null,
              ),
            ),
          ),

          // A1: Task Completion Status Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: _TaskCompletionCard(
                date: _selectedDate,
                isToday: isToday,
                completionService: _completionService,
                isLoading: _isMarkingComplete,
                onMarkComplete: (isToday || _selectedDate.isBefore(DateTime.now())) 
                    ? () => _markTaskComplete(true) 
                    : null,
                onMarkIncomplete:
                    (isToday || _selectedDate.isBefore(DateTime.now())) 
                        ? () => _markTaskComplete(false) 
                        : null,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Content Stream
          StreamBuilder<CompositeTask?>(
            stream: dbService.getDailyTask(dateStr),
            builder: (context, snapshot) {
              // 1. Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final task = snapshot.data;

              // 2. Empty State
              if (task == null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: PremiumEmptyState(
                    icon: Icons.coffee_outlined,
                    message: "Rest Day",
                    subMessage:
                        "No tasks assigned for ${DateFormat('MMMM d').format(_selectedDate)}",
                  ),
                );
              }

              // 3. Tasks List
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (task.leetcodeUrl.isNotEmpty)
                      _TaskPremiumCard(
                          type: "LeetCode Challenge",
                          icon: Icons.code,
                          color: Colors.orange,
                          title: "Daily Coding Problem",
                          content: task.leetcodeUrl,
                          isLink: true),
                    const SizedBox(height: AppSpacing.md),
                    if (task.csTopic.isNotEmpty)
                      _TaskPremiumCard(
                          type: "Core CS Concept",
                          icon: Icons.menu_book_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          title: task.csTopic,
                          content: task.csTopicDescription,
                          isLink: false),
                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markTaskComplete(bool completed) async {
    setState(() => _isMarkingComplete = true);
    try {
      final success = await _completionService.markTaskCompleted(
        date: _selectedDate,
        completed: completed,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(completed
                  ? '✓ Task marked as completed!'
                  : 'Task marked as incomplete'),
              backgroundColor: completed ? Colors.green : null,
            ),
          );
          setState(() {}); // Refresh the UI
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update task status')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

/// A1: Task Completion Card - Shows completion status and allows marking
class _TaskCompletionCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final TaskCompletionService completionService;
  final bool isLoading;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onMarkIncomplete;

  const _TaskCompletionCard({
    required this.date,
    required this.isToday,
    required this.completionService,
    required this.isLoading,
    this.onMarkComplete,
    this.onMarkIncomplete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskCompletion?>(
      future: completionService.getMyTaskCompletion(date),
      builder: (context, snapshot) {
        final completion = snapshot.data;
        final isCompleted = completion?.completed ?? false;
        final isPastDate = date.isBefore(DateTime.now()) && !isToday;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted
                  ? [
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green.withValues(alpha: 0.05)
                    ]
                  : [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Status Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? 'Today\'s Task'
                            : DateFormat('MMM d').format(date),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted ? '✓ Completed' : 'Mark as Completed',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      if (isCompleted && completion?.completedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'at ${DateFormat('MMM d, h:mm a').format(completion!.completedAt!)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              if (!DateUtils.isSameDay(completion.completedAt, date) && 
                                  completion.completedAt!.isAfter(date))
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'TURNED IN LATE',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action Button
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  isCompleted
                      ? IconButton(
                          icon: const Icon(Icons.undo, size: 20),
                          tooltip: 'Mark as incomplete',
                          onPressed: onMarkIncomplete,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : FilledButton.icon(
                          onPressed: onMarkComplete,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(isPastDate ? 'Complete Late' : 'Done'),
                          style: FilledButton.styleFrom(
                            backgroundColor: isPastDate ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onTitleTap;

  const _DateNavigator({
    required this.date,
    required this.onPrev,
    required this.onNext,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            splashRadius: 24,
          ),
          InkWell(
            onTap: onTitleTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE').format(date).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('MMMM d, yyyy').format(date),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (onTitleTap != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _TaskPremiumCard extends StatelessWidget {
  final String type;
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  final bool isLink;

  const _TaskPremiumCard(
      {required this.type,
      required this.icon,
      required this.color,
      required this.title,
      required this.content,
      required this.isLink});

  Future<void> _shareLink(BuildContext context) async {
    try {
      // Share the problem link with a nice message
      final shareText = '🎯 Today\'s Coding Challenge!\n\n'
          '📌 $title\n\n'
          '🔗 $content\n\n'
          '💪 Practice makes perfect! #PSGMX #CodingPractice';
      
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'PSGMX - Daily Coding Problem',
        ),
      );
      
      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Link shared successfully!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to clipboard if share fails
      try {
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📋 Link copied to clipboard!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (clipError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: PremiumCard(
        backgroundColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Text(type.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.8)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    )),

            const SizedBox(height: AppSpacing.md),
            Divider(color: color.withValues(alpha: 0.2), thickness: 1.5),
            const SizedBox(height: AppSpacing.md),

            // Content Area
            if (isLink)
              Column(
                children: [
                  InkWell(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(content);
                        if (!await launchUrl(uri,
                            mode: LaunchMode.externalApplication)) {
                          throw 'Could not launch $content';
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Could not open link: $e')),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.link_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Open Challenge',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  content,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareLink(context),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Link'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                        foregroundColor: color,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                        )),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// REP/COORD VIEW
// ==========================================

class _RepTasksView extends StatelessWidget {
  const _RepTasksView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 4, // Changed from 3 to 4
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: const Text("Manage Tasks"),
                pinned: true,
                floating: true,
                centerTitle: false,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: TabBar(
                      isScrollable: true, // Changed to true for 4 tabs
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: "MY TASKS"), // NEW: Personal tasks
                        Tab(text: "TASKS"),
                        Tab(text: "NEW ENTRY"),
                        Tab(text: "BULK UPLOAD"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: const TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                _StudentTasksView(), // NEW: Rep's personal tasks
                _RepTaskManagementView(),
                _SingleEntryForm(),
                _BulkUploadForm(),
              ],
            ),
          ),
        ));
  }
}

// ==========================================
// REP TASK MANAGEMENT VIEW
// ==========================================

class _RepTaskManagementView extends StatefulWidget {
  const _RepTaskManagementView();

  @override
  State<_RepTaskManagementView> createState() => _RepTaskManagementViewState();
}

class _RepTaskManagementViewState extends State<_RepTaskManagementView> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final taskUploadService = TaskUploadService();

    return Column(
      children: [
        // Date Range Selector
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text('Change'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        // Tasks List
        Expanded(
          child: FutureBuilder<List<DailyTask>>(
            future: taskUploadService.getTasksInRange(
              startDate: _startDate,
              endDate: _endDate,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                // Check if it's a connection error
                final isOffline = !ConnectivityService().hasConnection;
                if (isOffline) {
                  return Center(
                    child: CompactOfflineView(
                      onRetry: () {
                        setState(() {});
                      },
                    ),
                  );
                }

                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final tasks = snapshot.data ?? [];

              if (tasks.isEmpty) {
                return const PremiumEmptyState(
                  icon: Icons.task_outlined,
                  message: 'No Tasks Found',
                  subMessage: 'No tasks in selected date range',
                );
              }

              // Group tasks by date
              final groupedTasks = <String, List<DailyTask>>{};
              for (final task in tasks) {
                final dateKey = DateFormat('yyyy-MM-dd').format(task.date);
                groupedTasks.putIfAbsent(dateKey, () => []);
                groupedTasks[dateKey]!.add(task);
              }

              final sortedDates = groupedTasks.keys.toList()
                ..sort((a, b) => b.compareTo(a)); // Newest first

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedDates[index];
                  final dateTasks = groupedTasks[dateKey]!;
                  final date = DateTime.parse(dateKey);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: 8, top: index == 0 ? 0 : 16),
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(date),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),

                      // Task Cards for this date
                      ...dateTasks.map((task) => _TaskManagementCard(
                            task: task,
                            onDelete: () =>
                                _deleteTask(task, taskUploadService),
                            onEdit: () => _editTask(task),
                          )),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _deleteTask(DailyTask task, TaskUploadService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await service.deleteTask(task.id);
        setState(() {}); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete task: $e')),
          );
        }
      }
    }
  }

  void _editTask(DailyTask task) {
    showDialog(
      context: context,
      builder: (ctx) => _EditTaskDialog(task: task),
    ).then((edited) {
      if (edited == true) {
        setState(() {}); // Refresh the list
      }
    });
  }
}

class _TaskManagementCard extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskManagementCard({
    required this.task,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLeetCode = task.topicType == TopicType.leetcode;
    final color = isLeetCode ? Colors.orange : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: PremiumCard(
        backgroundColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and actions
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLeetCode ? Icons.code : Icons.menu_book_outlined,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.topicType.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Task',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete Task',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),

            // Subject (for core tasks)
            if (task.subject != null && task.subject!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.subject!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],

            // Reference Link (for leetcode tasks)
            if (task.referenceLink != null &&
                task.referenceLink!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  try {
                    final uri = Uri.parse(task.referenceLink!);
                    if (!await launchUrl(uri,
                        mode: LaunchMode.externalApplication)) {
                      throw 'Could not launch ${task.referenceLink}';
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open link: $e')),
                      );
                    }
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.referenceLink!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  final DailyTask task;

  const _EditTaskDialog({required this.task});

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _subjectCtrl;
  late DateTime _date;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _linkCtrl = TextEditingController(text: widget.task.referenceLink ?? '');
    _subjectCtrl = TextEditingController(text: widget.task.subject ?? '');
    _date = widget.task.date;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isLeetCode = widget.task.topicType == TopicType.leetcode;

    return AlertDialog(
      title: Text('Edit ${widget.task.topicType.displayName} Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2027),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy-MM-dd').format(_date)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: isLeetCode ? 'Problem Title' : 'Topic',
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Link or Subject
            if (isLeetCode)
              TextField(
                controller: _linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'LeetCode URL',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              )
            else
              TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject / Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () => _saveTask(userProvider.currentUser!.uid),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveTask(String userId) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskUploadService = TaskUploadService();
      await taskUploadService.createTask(
        date: _date,
        topicType: widget.task.topicType,
        title: _titleCtrl.text.trim(),
        referenceLink:
            _linkCtrl.text.trim().isNotEmpty ? _linkCtrl.text.trim() : null,
        subject: _subjectCtrl.text.trim().isNotEmpty
            ? _subjectCtrl.text.trim()
            : null,
        uploadedBy: userId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SingleEntryForm extends StatefulWidget {
  const _SingleEntryForm();

  @override
  State<_SingleEntryForm> createState() => _SingleEntryFormState();
}

class _SingleEntryFormState extends State<_SingleEntryForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  final _leetCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormSectionHeader(title: "Target Date"),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2027));
                        if (d != null) setState(() => _date = d);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: AppSpacing.md),
                            Text(DateFormat('yyyy-MM-dd').format(_date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Icon(Icons.edit,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormSectionHeader(title: "LeetCode Challenge"),
                    TextFormField(
                      controller: _leetCtrl,
                      decoration: const InputDecoration(
                          labelText: "Challenge URL",
                          hintText: "https://leetcode.com/problems/..."),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormSectionHeader(title: "Core CS Topic"),
                    TextFormField(
                      controller: _topicCtrl,
                      decoration: const InputDecoration(
                          labelText: "Topic Title",
                          hintText: "e.g. Operating Systems"),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                          labelText: "Description / Instructions",
                          alignLabelWithHint: true),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: const Text("PUBLISH TASK"),
                ),
              )
            ],
          )),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final task = CompositeTask(
        date: DateFormat('yyyy-MM-dd').format(_date),
        leetcodeUrl: _leetCtrl.text.trim(),
        csTopic: _topicCtrl.text.trim(),
        csTopicDescription: _descCtrl.text.trim(),
        motivationQuote: '',
      );

      await Provider.of<SupabaseDbService>(context, listen: false)
          .publishDailyTask(task);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task published successfully!")));
        _leetCtrl.clear();
        _topicCtrl.clear();
        _descCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _FormSectionHeader extends StatelessWidget {
  final String title;
  const _FormSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.0,
              )),
    );
  }
}

// ==========================================
// TEAM LEADER VIEW - Task Verification
// ==========================================

class _TeamLeaderTasksView extends StatefulWidget {
  const _TeamLeaderTasksView();

  @override
  State<_TeamLeaderTasksView> createState() => _TeamLeaderTasksViewState();
}

class _TeamLeaderTasksViewState extends State<_TeamLeaderTasksView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: const Text("Tasks"),
            centerTitle: false,
            forceElevated: innerBoxIsScrolled,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'My Tasks'),
                Tab(text: 'Team Verification'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const _StudentTasksView(),
            _TeamVerificationView(date: _selectedDate),
          ],
        ),
      ),
    );
  }
}

class _TeamVerificationView extends StatefulWidget {
  final DateTime date;
  const _TeamVerificationView({required this.date});

  @override
  State<_TeamVerificationView> createState() => _TeamVerificationViewState();
}

class _TeamVerificationViewState extends State<_TeamVerificationView> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final teamId = userProvider.currentUser?.teamId;
      
      if (teamId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final supabase = Supabase.instance.client;

      // Get team members with their task completion status
      final response = await supabase
          .from('users')
          .select('id, email, name, reg_no')
          .eq('team_id', teamId)
          .order('name');

      final members = response as List;
      
      // Get task completions for this date
      final completionsResponse = await supabase
          .from('task_completions')
          .select('user_id, completed, completed_at, verified_by, verified_at')
          .eq('task_date', dateStr)
          .inFilter('user_id', members.map((m) => m['id']).toList());

      final completions = completionsResponse as List;
      final completionMap = {for (var c in completions) c['user_id']: c};

      // Combine data
      final teamData = members.map((member) {
        final completion = completionMap[member['id']];
        return {
          'id': member['id'],
          'email': member['email'],
          'name': member['name'],
          'reg_no': member['reg_no'],
          'is_completed': completion?['completed'] ?? false,
          'completed_at': completion?['completed_at'],
          'verified_by': completion?['verified_by'],
          'verified_at': completion?['verified_at'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _teamMembers = teamData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[TeamVerification] Error loading team data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team data: $e')),
        );
      }
    }
  }

  Future<void> _verifyTask(String studentId, bool isCompleted) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final verifierId = userProvider.currentUser?.uid;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final supabase = Supabase.instance.client;

      // Find if there's an existing completion to preserve the student's completion time
      final existing = _teamMembers.firstWhere((m) => m['id'] == studentId);
      final existingCompletedAt = existing['completed_at'];

      // Upsert task completion with verification
      await supabase.from('task_completions').upsert({
        'user_id': studentId,
        'task_date': dateStr,
        'completed': isCompleted,
        // Preserve original completion time if it exists and we're marking as completed
        'completed_at': isCompleted 
            ? (existingCompletedAt ?? DateTime.now().toIso8601String())
            : null,
        'verified_by': verifierId,
        'verified_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,task_date');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCompleted
                ? 'Task verified as completed'
                : 'Task marked as incomplete'),
            backgroundColor: isCompleted ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadTeamData();
      }
    } catch (e) {
      debugPrint('[TeamVerification] Error verifying task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Navigator
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: _DateNavigator(
            date: _selectedDate,
            onNext: () => setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
              _loadTeamData();
            }),
            onPrev: () => setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              _loadTeamData();
            }),
            onTitleTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && mounted) {
                setState(() {
                  _selectedDate = picked;
                  _loadTeamData();
                });
              }
            },
          ),
        ),

        // Team Members List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _teamMembers.isEmpty
                  ? const Center(child: Text('No team members found'))
                  : RefreshIndicator(
                      onRefresh: _loadTeamData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          final isCompleted = member['is_completed'] as bool;
                          final isVerified = member['verified_by'] != null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isCompleted
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.1),
                                        child: Text(
                                          (member['name'] as String)[0].toUpperCase(),
                                          style: TextStyle(
                                            color: isCompleted ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  member['reg_no'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                if (member['completed_at'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  _buildLateBadge(member['completed_at'], _selectedDate),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified,
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _verifyTask(member['id'], true),
                                          icon: Icon(
                                            isCompleted
                                                ? Icons.check_circle
                                                : Icons.check_circle_outline,
                                            size: 18,
                                          ),
                                          label: const Text('Completed'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            side: BorderSide(
                                              color: isCompleted
                                                  ? Colors.green
                                                  : Colors.grey.shade300,
                                              width: isCompleted ? 2 : 1,
                                            ),
                                            backgroundColor: isCompleted
                                                ? Colors.green.withValues(alpha: 0.1)
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _verifyTask(member['id'], false),
                                          icon: Icon(
                                            !isCompleted && isVerified
                                                ? Icons.cancel
                                                : Icons.cancel_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Incomplete'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: BorderSide(
                                              color: !isCompleted && isVerified
                                                  ? Colors.orange
                                                  : Colors.grey.shade300,
                                              width: !isCompleted && isVerified ? 2 : 1,
                                            ),
                                            backgroundColor: !isCompleted && isVerified
                                                ? Colors.orange.withValues(alpha: 0.1)
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildLateBadge(String? completedAtStr, DateTime taskDate) {
    if (completedAtStr == null) return const SizedBox.shrink();
    
    final completedAt = DateTime.parse(completedAtStr);
    // If completed on a different day and AFTER the task date
    if (!DateUtils.isSameDay(completedAt, taskDate) && 
        completedAt.isAfter(taskDate)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'LATE',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _BulkUploadForm extends StatelessWidget {
  const _BulkUploadForm();

  @override
  Widget build(BuildContext context) {
    return const BulkUploadScreen();
  }
}
