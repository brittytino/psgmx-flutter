import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/ecampus_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ecampus_attendance.dart';
import '../../models/ecampus_cgpa.dart';
import '../../services/ecampus_service.dart';
import 'widgets/subject_attendance_card.dart';

/// Main "Academic Insights" screen – shows PSG eCampus attendance (tab 1) and
/// CGPA (tab 2) with a pull-to-sync trigger.
class BunkerScreen extends StatefulWidget {
  const BunkerScreen({super.key});

  @override
  State<BunkerScreen> createState() => _BunkerScreenState();
}

class _BunkerScreenState extends State<BunkerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _syncAllInProgress = false;
  bool _dobDialogShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user == null) return;

      if (user.dob == null) {
        _showDobRequiredDialog(userProvider);
        return;
      }

      final rollno = user.regNo;
      if (rollno.isNotEmpty) {
        context.read<EcampusProvider>().init(rollno);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null) return;

    if (user.dob == null) {
      _showDobRequiredDialog(userProvider);
      return;
    }

    if (user.regNo.isNotEmpty) {
      await context.read<EcampusProvider>().sync();
    }
  }

  Future<void> _showDobRequiredDialog(UserProvider userProvider) async {
    if (_dobDialogShown || !mounted) return;
    _dobDialogShown = true;

    final theme = Theme.of(context);
    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cake_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Add your DOB'),
          ],
        ),
        content: Text(
          'To view attendance insights, set your date of birth. This is used to '
          'securely generate your eCampus password in the required format '
          '(e.g. 08jul04).',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Not now'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final initial = userProvider.currentUser?.dob ??
                  DateTime(now.year - 20, now.month, now.day);
              final pickedDate = await showDatePicker(
                context: ctx,
                initialDate: initial,
                firstDate: DateTime(1990),
                lastDate: DateTime(now.year - 10),
                helpText: 'Select your date of birth',
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(pickedDate);
            },
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Pick date'),
          ),
        ],
      ),
    );

    if (picked != null) {
      try {
        await userProvider.updateDob(picked);
        final rollno = userProvider.currentUser?.regNo;
        if (rollno != null && rollno.isNotEmpty && mounted) {
          context.read<EcampusProvider>().init(rollno);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save DOB: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    _dobDialogShown = false;
  }

  Future<void> _syncAllStudents() async {
    if (_syncAllInProgress) return;

    final userProvider = context.read<UserProvider>();
    if (!userProvider.isActualPlacementRep) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refresh all students?'),
        content: const Text(
          'This will sync attendance and CGPA for all students and can take several minutes. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start sync'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _syncAllInProgress = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing all students...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final result = await EcampusService().syncAllUsers();
      final total = result['total'] ?? 0;
      final success = result['success_count'] ?? 0;
      final failed = result['failed_count'] ?? 0;
      final failedList = (result['failed'] as List?) ?? [];

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sync results'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total: $total'),
                  Text('Succeeded: $success'),
                  Text('Failed: $failed'),
                  if (failedList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Failed roll numbers',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...failedList.map((item) {
                      final rollno = item['rollno'] ?? 'Unknown';
                      final error = item['error'] ?? 'Unknown error';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('- $rollno: $error'),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncAllInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<UserProvider>().currentUser;

    if (user != null && user.dob == null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cake_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  'Set your date of birth to access attendance insights.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showDobRequiredDialog(context.read<UserProvider>()),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Set DOB'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor:
                isDark ? const Color(0xFF0F0F1A) : Colors.white,
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 56),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Insights',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer<EcampusProvider>(
                    builder: (_, prov, __) {
                      final ts = prov.lastSyncedAt;
                      final label = ts != null
                          ? 'Last synced ${DateFormat('dd MMM, hh:mm a').format(ts.toLocal())}'
                          : 'Not synced yet – pull to refresh';
                      return Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : Colors.black45,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              Consumer<EcampusProvider>(
                builder: (_, prov, __) => IconButton(
                  icon: prov.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  tooltip: 'Sync from eCampus',
                  onPressed: prov.isSyncing ? null : _onRefresh,
                ),
              ),
              Consumer<UserProvider>(
                builder: (_, userProv, __) {
                  if (!userProv.isActualPlacementRep) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: _syncAllInProgress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_alt_rounded),
                    tooltip: 'Sync all students',
                    onPressed: _syncAllInProgress ? null : _syncAllStudents,
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  isDark ? Colors.white54 : Colors.black45,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Attendance'),
                Tab(text: 'CGPA'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AttendanceTab(onRefresh: _onRefresh),
            _CgpaTab(onRefresh: _onRefresh),
          ],
        ),
      ),
    );
  }
}

// ─── Attendance Tab ──────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _AttendanceTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<EcampusProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prov.status == EcampusStatus.error) {
          return _ErrorView(
            message: prov.errorMessage ?? 'Something went wrong',
            onRetry: () => context
                .read<EcampusProvider>()
                .sync(),
          );
        }

        if (prov.attendance == null) {
          return _EmptyView(
            message: 'No attendance data yet.\nTap sync to fetch from eCampus.',
            onSync: onRefresh,
            isSyncing: prov.isSyncing,
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _AttendanceSummaryCard(
                    summary: prov.attendance!.summary),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Subject-wise Breakdown',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => SubjectAttendanceCard(
                    subject: prov.attendance!.subjects[i],
                  ),
                  childCount: prov.attendance!.subjects.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final AttendanceSummary summary;
  const _AttendanceSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final Color accent = summary.isSafe
        ? const Color(0xFF4CAF50)
        : const Color(0xFFEF5350);

    final String bunkMsg = summary.isSafe
        ? '🎉 You can bunk ${summary.overallCanBunk} more class${summary.overallCanBunk == 1 ? '' : 'es'}'
        : '⚠️ Attend ${summary.overallNeedAttend} more class${summary.overallNeedAttend == 1 ? '' : 'es'} to reach 75%';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.isSafe
              ? const [Color(0xFF1B5E20), Color(0xFF004D40)]
              : const [Color(0xFFB71C1C), Color(0xFFBF360C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: label + fraction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL ATTENDANCE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.overallPercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                // Circular indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: (summary.overallPercentage / 100).clamp(0, 1),
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      summary.isSafe ? '✓' : '!',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (summary.overallPercentage / 100).clamp(0.0, 1.0),
                minHeight: 9,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white38)),
                Text('▲ 75% min',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white54)),
                Text('100%',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white38)),
              ],
            ),

            const SizedBox(height: 18),

            // Bunk message
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bunkMsg,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Stats chips
            Row(
              children: [
                _SummaryChip(
                    icon: Icons.timer_outlined,
                    label: 'Total',
                    value: '${summary.totalHours}h'),
                const SizedBox(width: 8),
                _SummaryChip(
                    icon: Icons.check_rounded,
                    label: 'Attended',
                    value: '${summary.totalPresent}h'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CGPA Tab ─────────────────────────────────────────────────────────────────

class _CgpaTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CgpaTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<EcampusProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prov.status == EcampusStatus.error) {
          return _ErrorView(
            message: prov.errorMessage ?? 'Something went wrong',
            onRetry: () =>
                context.read<EcampusProvider>().sync(),
          );
        }

        if (prov.cgpa == null) {
          return _EmptyView(
            message:
                'No CGPA data yet.\nTap sync to fetch from eCampus.',
            onSync: onRefresh,
            isSyncing: prov.isSyncing,
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _CgpaSummaryCard(cgpa: prov.cgpa!),
              ),
              SliverToBoxAdapter(
                child: _SemesterSgpaSection(cgpa: prov.cgpa!),
              ),
              SliverToBoxAdapter(
                child: _CourseResultsSection(cgpa: prov.cgpa!),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _CgpaSummaryCard extends StatelessWidget {
  final EcampusCgpa cgpa;
  const _CgpaSummaryCard({required this.cgpa});

  Color _cgpaColor(double c) {
    if (c >= 9) return Colors.amber.shade300;
    if (c >= 8) return Colors.green.shade400;
    if (c >= 7) return Colors.blue.shade400;
    if (c >= 6) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final c = _cgpaColor(cgpa.cgpa);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A3E),
            Color(0xFF2D2B55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: c.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cumulative GPA',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white60)),
                const SizedBox(height: 4),
                Text(
                  cgpa.cgpa.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: c,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Latest semester: ${cgpa.latestSemester}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cgpa.totalSemesters} semester${cgpa.totalSemesters == 1 ? '' : 's'} • ${cgpa.totalCredits} credits',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: (cgpa.cgpa / 10).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(c),
                ),
              ),
              Text(
                '${((cgpa.cgpa / 10) * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemesterSgpaSection extends StatelessWidget {
  final EcampusCgpa cgpa;
  const _SemesterSgpaSection({required this.cgpa});

  Color _sgpaColor(double v) {
    if (v >= 8.5) return const Color(0xFF4CAF50);
    if (v >= 7) return const Color(0xFF2196F3);
    if (v >= 5.5) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (cgpa.semesterSgpa.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SGPA TREND',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          ...cgpa.semesterSgpa.map((s) {
            final color = _sgpaColor(s.sgpa);
            final fraction = (s.sgpa / 10).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      s.semester,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 10,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.07),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.sgpa.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CourseResultsSection extends StatelessWidget {
  final EcampusCgpa cgpa;
  const _CourseResultsSection({required this.cgpa});

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'O':
        return const Color(0xFFFFB300);
      case 'A+':
        return const Color(0xFF43A047);
      case 'A':
        return const Color(0xFF7CB342);
      case 'B+':
        return const Color(0xFF1E88E5);
      case 'B':
        return const Color(0xFF00ACC1);
      case 'C+':
      case 'C':
        return const Color(0xFFFF7043);
      case 'RA':
      case 'SA':
      case 'W':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grouped = cgpa.coursesBySemester;

    if (grouped.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COURSE RESULTS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Semester header
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Course cards
                ...entry.value.map((course) {
                  final gradeColor = _gradeColor(course.grade);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Grade badge on left
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                gradeColor.withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              course.grade.isEmpty ? '–' : course.grade,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: gradeColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Course info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${course.code}  •  ${course.credits} credits',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Shared empty / error views ───────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  final Future<void> Function() onSync;
  final bool isSyncing;

  const _EmptyView(
      {required this.message, required this.onSync, required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSyncing ? null : onSync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(isSyncing ? 'Syncing…' : 'Sync Now',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
