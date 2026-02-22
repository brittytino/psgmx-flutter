// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/scheduled_date.dart';
import '../../services/attendance_schedule_service.dart';
import '../../core/theme/app_dimens.dart';

// ============================================================
// Widget
// ============================================================

class DailyAttendanceSheet extends StatefulWidget {
  const DailyAttendanceSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DailyAttendanceSheet(),
    );
  }

  @override
  State<DailyAttendanceSheet> createState() => _DailyAttendanceSheetState();
}

// ============================================================
// State
// ============================================================

class _DailyAttendanceSheetState extends State<DailyAttendanceSheet> {
  // â”€â”€ Local state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Attendance choices the TL has made in the current session.
  /// Keyed by student UUID. Values: 'PRESENT' | 'ABSENT'
  final Map<String, String> _statusMap = {};

  /// Whether the Placement Rep toggle is showing all students.
  bool _showAllStudents = false;

  /// Normalised (midnight) date currently being viewed / marked.
  DateTime _selectedDate = _todayMidnight();

  /// Past + today scheduled dates (newest first).
  /// Future dates are never included so TLs cannot pre-mark attendance.
  List<ScheduledDate> _scheduledDates = [];

  /// Separate submit flag so the button has its own spinner
  /// and is not affected by the list-load indicator.
  bool _isSubmitting = false;

  /// True while the scheduled-date list is being fetched on first open.
  bool _isLoadingDates = true;

  // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().addListener(_onProviderChanged);
      _initialise();
    });
  }

  @override
  void dispose() {
    // Safe remove: provider outlives the bottom sheet.
    context.read<AttendanceProvider>().removeListener(_onProviderChanged);
    super.dispose();
  }

  // â”€â”€ Provider listener â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool _providerWasLoading = false;

  /// Called on every notifyListeners() from AttendanceProvider.
  /// Syncs _statusMap from the provider exactly once, when a load cycle ends.
  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<AttendanceProvider>();
    if (provider.isLoading) {
      _providerWasLoading = true;
    } else if (_providerWasLoading) {
      _providerWasLoading = false;
      _syncStatusMapFromProvider(provider);
    }
  }

  /// Copies provider.statusMap â†’ _statusMap.
  /// Students not yet in the DB default to 'ABSENT'.
  void _syncStatusMapFromProvider(AttendanceProvider provider) {
    if (!mounted) return;
    setState(() {
      _statusMap.clear();
      for (final member in provider.teamMembers) {
        _statusMap[member.uid] = provider.statusMap[member.uid] ?? 'ABSENT';
      }
    });
  }

  // â”€â”€ Initialisation sequence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _initialise() async {
    await _loadScheduledDates(); // must complete first to set _selectedDate
    _loadAttendanceData();       // then load members + preloaded statuses
  }

  /// Fetches all scheduled dates from the past 90 days up to and including
  /// today. Never fetches future dates â€” TLs cannot pre-mark sessions.
  Future<void> _loadScheduledDates() async {
    if (!mounted) return;
    setState(() => _isLoadingDates = true);
    try {
      final today = _todayMidnight();
      final start = today.subtract(const Duration(days: 90));
      final dates = await AttendanceScheduleService().getScheduledDatesInRange(
        startDate: start,
        endDate: today,
      );
      if (!mounted) return;

      // Sort newest â†’ oldest.
      final sorted = [...dates]..sort((a, b) => b.date.compareTo(a.date));

      // Land on today if scheduled, otherwise the most recent past date.
      DateTime landing = _selectedDate;
      if (sorted.isNotEmpty) {
        final todayScheduled =
            sorted.any((sd) => _isSameDay(sd.date, today));
        if (!todayScheduled) {
          landing = _normalise(sorted.first.date);
        }
      }

      setState(() {
        _scheduledDates = sorted;
        _selectedDate = landing;
        _isLoadingDates = false;
      });
    } catch (e) {
      debugPrint('[DailyAttendanceSheet] Could not load scheduled dates: $e');
      if (mounted) setState(() => _isLoadingDates = false);
    }
  }

  /// Asks the provider to (re)load team members and preloaded statuses
  /// for the currently selected date.
  void _loadAttendanceData() {
    if (!mounted) return;
    final user = context.read<UserProvider>().currentUser;
    final provider = context.read<AttendanceProvider>();

    if (_showAllStudents) {
      provider.loadAllUsers(forDate: _selectedDate);
    } else if (user?.teamId != null) {
      provider.loadTeamMembers(user!.teamId!, forDate: _selectedDate);
    }
  }

  // â”€â”€ Date helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static DateTime _todayMidnight() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isToday(DateTime date) => _isSameDay(date, _todayMidnight());

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDateSelected(DateTime date) {
    final normalised = _normalise(date);
    if (_isSameDay(normalised, _selectedDate)) return; // no-op

    setState(() {
      _selectedDate = normalised;
      // Clear local choices â€” the provider listener will re-populate them
      // from the DB once the new load cycle completes.
      _statusMap.clear();
    });
    _loadAttendanceData();
  }

  // â”€â”€ Date picker dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showDatePicker() {
    if (_scheduledDates.isEmpty) return;
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Select Date',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _scheduledDates.length,
              itemBuilder: (_, index) {
                final sd = _scheduledDates[index];
                final isSel = _isSameDay(sd.date, _selectedDate);
                final isToday = _isToday(sd.date);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isSel
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isSel ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    isToday
                        ? 'Today Â· ${DateFormat('MMM d, yyyy').format(sd.date)}'
                        : DateFormat('EEE, MMM d, yyyy').format(sd.date),
                    style: GoogleFonts.inter(
                      fontWeight:
                          isSel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: (sd.notes != null && sd.notes!.isNotEmpty)
                      ? Text(sd.notes!,
                          style: GoogleFonts.inter(fontSize: 12))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _onDateSelected(sd.date);
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Submit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _submit(
      BuildContext context, AttendanceProvider provider) async {
    final user = context.read<UserProvider>().currentUser;
    final isRep = context.read<UserProvider>().isPlacementRep;

    if (!isRep && user?.teamId == null) return;

    // â”€â”€ Validate: TLs can only mark scheduled dates â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (!isRep) {
      // Fast path: check local cache first (no round-trip needed usually).
      bool isScheduled =
          _scheduledDates.any((sd) => _isSameDay(sd.date, _selectedDate));

      // Network fallback when cache is empty (e.g. offline load failed).
      if (!isScheduled) {
        try {
          isScheduled = await AttendanceScheduleService()
              .isDateScheduled(_selectedDate);
        } catch (_) {
          // Network unavailable â€” honour the local negative result.
        }
      }

      if (!isScheduled && context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Not a Scheduled Date'),
            content: Text(
              '${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)} is not '
              'a scheduled class date.\n\n'
              'Use the date picker to choose a valid session, or ask the '
              'Placement Rep to schedule this date.',
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
        return;
      }
    }

    if (_statusMap.isEmpty) return;

    final presentCount =
        _statusMap.values.where((s) => s == 'PRESENT').length;
    final absentCount =
        _statusMap.values.where((s) => s == 'ABSENT').length;
    final absentees = provider.teamMembers
        .where((m) => _statusMap[m.uid] == 'ABSENT')
        .toList();

    if (!context.mounted) return;

    // â”€â”€ Confirmation sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: t.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: t.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Verify Attendance',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _isToday(_selectedDate)
                    ? "Please review today's attendance before submitting."
                    : 'Updating record for '
                        '${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: t.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _statItem(
                            ctx, 'Present', presentCount, Colors.green)),
                    Container(
                        width: 1, height: 36, color: t.dividerColor),
                    Expanded(
                        child: _statItem(ctx, 'Absent', absentCount,
                            t.colorScheme.error)),
                  ],
                ),
              ),

              if (absentees.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Marked as Absent:',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.2,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: absentees.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final s = absentees[idx];
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: t.colorScheme.errorContainer,
                            child: Text(
                              s.name.isNotEmpty ? s.name[0] : '?',
                              style: TextStyle(
                                fontSize: 11,
                                color: t.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.name,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: t.dividerColor),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: t.colorScheme.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        provider.hasSubmittedToday ? 'Update' : 'Confirm',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    // â”€â”€ Persist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    setState(() => _isSubmitting = true);
    try {
      await provider.submitAttendance(
        user?.teamId,
        Map<String, String>.from(_statusMap),
        forDate: _selectedDate,
        isRep: isRep,
      );
      if (!context.mounted) return;

      if (isRep) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes Saved âœ…')),
        );
      } else {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Attendance Submitted Successfully âœ…')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRep = context.watch<UserProvider>().isPlacementRep;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Handle bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Attendance',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _isToday(_selectedDate)
                              ? DateFormat('EEEE, MMM d')
                                  .format(_selectedDate)
                              : DateFormat('EEE, MMM d, yyyy')
                                  .format(_selectedDate),
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        if (!_isToday(_selectedDate)) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Past',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme
                                    .colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // â”€â”€ Date selector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_isLoadingDates)
            const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_scheduledDates.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No scheduled class dates found in the last 90 days.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _showDatePicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 15, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      _isToday(_selectedDate)
                          ? 'Today'
                          : DateFormat('EEE, MMM d').format(_selectedDate),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // â”€â”€ Rep view toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (isRep) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggleOption('My Team', !_showAllStudents, () {
                    setState(() {
                      _showAllStudents = false;
                      _statusMap.clear();
                    });
                    _loadAttendanceData();
                  }),
                  _buildToggleOption('All Students', _showAllStudents, () {
                    setState(() {
                      _showAllStudents = true;
                      _statusMap.clear();
                    });
                    _loadAttendanceData();
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // â”€â”€ Action bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<AttendanceProvider>(
                builder: (_, provider, __) => Text(
                  provider.hasSubmittedToday
                      ? 'Update attendance'
                      : 'Mark attendance',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Consumer<AttendanceProvider>(
                builder: (_, provider, __) => TextButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => setState(() {
                            for (final m in provider.teamMembers) {
                              _statusMap[m.uid] = 'PRESENT';
                            }
                          }),
                  icon: const Icon(Icons.done_all_rounded, size: 17),
                  label: const Text('Mark All Present'),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // â”€â”€ Student list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: Consumer<AttendanceProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.teamMembers.isEmpty) {
                  return Center(
                    child: Text(
                      'No students found.',
                      style:
                          TextStyle(color: theme.colorScheme.secondary),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.teamMembers.length,
                  itemBuilder: (ctx, index) {
                    final member = provider.teamMembers[index];
                    final isPresent =
                        _statusMap[member.uid] == 'PRESENT';
                    final isUnregistered = member.uid.contains('@');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPresent
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.15)
                              : theme.colorScheme.error
                                  .withValues(alpha: 0.15),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isPresent
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0]
                                : '?',
                            style: TextStyle(
                              color: isPresent
                                  ? theme
                                      .colorScheme.onPrimaryContainer
                                  : theme
                                      .colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              member.regNo,
                              style: TextStyle(
                                  color: theme
                                      .colorScheme.onSurfaceVariant),
                            ),
                            if (isUnregistered) ...[
                              const SizedBox(width: 8),
                              _badge(
                                  'UNREGISTERED',
                                  Colors.amber.withValues(alpha: 0.15),
                                  Colors.amber),
                            ],
                          ],
                        ),
                        trailing: Switch(
                          value: isPresent,
                          activeTrackColor:
                              theme.colorScheme.primaryContainer,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: theme.colorScheme.error,
                          thumbIcon: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16);
                              }
                              return Icon(Icons.close_rounded,
                                  color: theme.colorScheme.error,
                                  size: 16);
                            },
                          ),
                          onChanged: (val) {
                            setState(() {
                              _statusMap[member.uid] =
                                  val ? 'PRESENT' : 'ABSENT';
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // â”€â”€ Submit / Update button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Consumer<AttendanceProvider>(
            builder: (_, provider, __) {
              final busy = _isSubmitting;
              final canSubmit =
                  !busy && !provider.isLoading && _statusMap.isNotEmpty;

              return FilledButton(
                onPressed: canSubmit ? () => _submit(context, provider) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        provider.hasSubmittedToday
                            ? 'UPDATE ATTENDANCE'
                            : 'SUBMIT ATTENDANCE',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  // â”€â”€ Small helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildToggleOption(
      String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(
          text,
          style: TextStyle(
              color: fg, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      );

  Widget _statItem(
      BuildContext ctx, String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString().padLeft(2, '0'),
          style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
