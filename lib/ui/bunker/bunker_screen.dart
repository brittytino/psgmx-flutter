import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/ecampus_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ecampus_attendance.dart';
import '../../models/ecampus_cgpa.dart';
import '../../models/ecampus_ca_timetable.dart';
import '../../services/ecampus_service.dart';
import 'widgets/subject_attendance_card.dart';

/// Main "Academic Insights" screen – shows PSG eCampus attendance (tab 1) and
/// CGPA (tab 2) with a pull-to-sync trigger.
class AcademicInsightsScreen extends StatefulWidget {
  const AcademicInsightsScreen({super.key});

  @override
  State<AcademicInsightsScreen> createState() => _AcademicInsightsScreenState();
}

class _AcademicInsightsScreenState extends State<AcademicInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _syncAllInProgress = false;
  bool _dobDialogShown = false;
  /// Prevents double-showing the custom-password dialog when the provider
  /// emits multiple [isLoginFailed] notifications in quick succession.
  bool _pwDialogShown = false;
  bool _isPlacementRep = false;

  // ── Safe listener reference (avoids context.read in dispose) ──────────────
  EcampusProvider? _ecampusProv;

  // ── Inline credentials form state (no-credentials blocked screen) ─────────
  final TextEditingController _credPassCtrl = TextEditingController();
  bool _credObscure = true;
  bool _credSaving = false;
  bool _showPasswordSection = false;
  bool _isLoadingAllStudents = false;
  String? _allStudentsError;
  List<_StudentAcademicEntry> _allStudents = [];
  _SortMode _sortMode = _SortMode.rollNoAsc;
  _BatchFilter _batchFilter = _BatchFilter.all;
  DateTime? _lastAllStudentsSyncedAt;

  @override
  void initState() {
    super.initState();
    _isPlacementRep = context.read<UserProvider>().isActualPlacementRep;
    _tabController = TabController(length: _isPlacementRep ? 4 : 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user == null) return;

      final rollno = user.regNo;
      if (rollno.isNotEmpty) {
        context.read<EcampusProvider>().init(rollno);
      }

      if (_isPlacementRep) {
        _loadAllStudentsAcademicData();
        return;
      }

      // Only prompt for DOB if user also hasn't set a custom eCampus password.
      if (user.dob == null && !user.ecampusPasswordSet) {
        _showDobRequiredDialog(userProvider);
        return;
      }

    });

    // Watch EcampusProvider for login failures and surface the password dialog.
    // Store reference for safe removal in dispose() — never call context.read() in dispose.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ecampusProv = context.read<EcampusProvider>();
      _ecampusProv!.addListener(_onEcampusProviderUpdate);
    });
  }

  /// Called every time [EcampusProvider] notifies listeners.
  /// Detects login failures and auto-shows the custom-password dialog so
  /// students who changed their eCampus password don’t have to hunt for the
  /// option themselves.
  void _onEcampusProviderUpdate() {
    if (!mounted) return;
    final userProv = context.read<UserProvider>();
    final user = userProv.currentUser;
    // Don't auto-prompt while the blocked/onboarding screen is visible —
    // the user already sees the DOB and custom-password options there.
    if (!_isPlacementRep &&
        user != null &&
        user.dob == null &&
        !user.ecampusPasswordSet) return;
    final prov = context.read<EcampusProvider>();
    if (prov.isLoginFailed && !_pwDialogShown) {
      _showCustomPasswordDialog(userProv, isAutoPrompt: true);
    }
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatDob(dynamic value) {
    if (value == null) return 'Not set';
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(value);
    }
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateFormat('yyyy-MM-dd').format(parsed);
      }
      return value;
    }
    return 'Not set';
  }

  Future<void> _loadAllStudentsAcademicData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAllStudents = true;
      _allStudentsError = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final whitelistResponse = await supabase
          .from('whitelist')
          .select('reg_no, name, dob, batch')
          .order('reg_no');

        final usersResponse =
          await supabase.from('users').select('reg_no, dob');

      final attendanceResponse = await supabase
          .from('ecampus_attendance')
          .select('reg_no, data, synced_at');

      final cgpaResponse = await supabase
          .from('ecampus_cgpa')
          .select('reg_no, data, synced_at');

      final attendanceMap = <String, Map<String, dynamic>>{};
      for (final row in (attendanceResponse as List)) {
        final regNo = row['reg_no']?.toString();
        if (regNo == null) continue;
        attendanceMap[regNo] = (row['data'] as Map?)?.cast<String, dynamic>() ?? {};
      }

      final cgpaMap = <String, Map<String, dynamic>>{};
      DateTime? latestSynced;
      for (final row in (cgpaResponse as List)) {
        final regNo = row['reg_no']?.toString();
        if (regNo == null) continue;
        cgpaMap[regNo] = (row['data'] as Map?)?.cast<String, dynamic>() ?? {};
        final syncedAt = DateTime.tryParse(row['synced_at']?.toString() ?? '');
        if (syncedAt != null && (latestSynced == null || syncedAt.isAfter(latestSynced))) {
          latestSynced = syncedAt;
        }
      }

      for (final row in (attendanceResponse as List)) {
        final syncedAt = DateTime.tryParse(row['synced_at']?.toString() ?? '');
        if (syncedAt != null && (latestSynced == null || syncedAt.isAfter(latestSynced))) {
          latestSynced = syncedAt;
        }
      }

      final userDobMap = <String, dynamic>{};
      for (final row in (usersResponse as List)) {
        final regNo = row['reg_no']?.toString();
        if (regNo == null) continue;
        userDobMap[regNo] = row['dob'];
      }

      final items = (whitelistResponse as List).map((row) {
        final regNo = row['reg_no']?.toString() ?? '';
        final attendanceData = attendanceMap[regNo] ?? const <String, dynamic>{};
        final cgpaData = cgpaMap[regNo] ?? const <String, dynamic>{};
        final summary = (attendanceData['summary'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

        final dobValue = userDobMap[regNo] ?? row['dob'];
        // isSynced = true only if a row exists in ecampus_attendance OR ecampus_cgpa
        final isSynced = attendanceMap.containsKey(regNo) || cgpaMap.containsKey(regNo);

        return _StudentAcademicEntry(
          regNo: regNo,
          name: row['name']?.toString() ?? '-',
          batch: row['batch']?.toString() ?? 'Unknown',
          dobText: _formatDob(dobValue),
          attendancePercentage: _asDouble(summary['overall_percentage']),
          cgpa: _asDouble(cgpaData['cgpa']),
          isSynced: isSynced,
        );
      }).toList()
        ..sort((a, b) {
          const order = {'G1': 0, 'G2': 1};
          final aOrder = order[a.batch] ?? 99;
          final bOrder = order[b.batch] ?? 99;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          return a.regNo.compareTo(b.regNo);
        });

      if (!mounted) return;
      setState(() {
        _allStudents = items;
        _lastAllStudentsSyncedAt = latestSynced;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allStudentsError = 'Unable to load all students academic data right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAllStudents = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Use stored reference — context.read() is NOT safe inside dispose().
    _ecampusProv?.removeListener(_onEcampusProviderUpdate);
    _credPassCtrl.dispose();
    _tabController.dispose();
    super.dispose();
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
          '(e.g. 08jul04).\n\n'
          'If you changed your eCampus password, use the \'Custom Password\' '
          'option on the previous screen instead.',
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

  /// Handles the inline "Connect to eCampus" button on the credentials-blocked
  /// screen. Saves the entered password to the DB and immediately syncs.
  Future<void> _connectWithInlinePassword(UserProvider userProvider) async {
    final pw = _credPassCtrl.text.trim();
    if (pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your eCampus password.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _credSaving = true);
    try {
      await userProvider.updateEcampusPassword(pw);
      final rollno = userProvider.currentUser?.regNo;
      if (rollno != null && rollno.isNotEmpty && mounted) {
        _credPassCtrl.clear();
        context.read<EcampusProvider>().syncAfterCredentialUpdate(rollno);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password saved. Syncing your academic data…'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save password: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _credSaving = false);
    }
  }

  /// Quick-access dialog for students whose sync failed due to a wrong password.
  /// When [isAutoPrompt] is true the dialog was triggered automatically because
  /// a sync attempt failed with a login error — extra context is shown.
  Future<void> _showCustomPasswordDialog(
    UserProvider userProvider, {
    bool isAutoPrompt = false,
  }) async {
    if (_pwDialogShown || !mounted) return;
    _pwDialogShown = true;

    final theme = Theme.of(context);
    final controller = TextEditingController();
    bool obscure = true;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Update eCampus Password',
                    style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAutoPrompt) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your eCampus password has changed. '
                          'Enter your current portal password to load your data.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: controller,
                obscureText: obscure,
                autofillHints: const [],
                decoration: InputDecoration(
                  labelText: 'eCampus Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => obscure = !obscure),
                    tooltip: obscure ? 'Show' : 'Hide',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ── Trust-building statement ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\ud83d\udd12 Your password is stored securely on our server '
                        'and is only used to connect to the eCampus portal. '
                        'It is never exposed to other users or shown in the app.\n\n'
                        '\u2014 PSGMX Team',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade800,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Skip for now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Save & Load'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    _pwDialogShown = false;

    if (result == null || result.trim().isEmpty) return;

    try {
      await userProvider.updateEcampusPassword(result.trim());
      final rollno = userProvider.currentUser?.regNo;
      if (rollno != null && rollno.isNotEmpty && mounted) {
        // Use syncAfterCredentialUpdate so fresh data is fetched with the new password.
        context.read<EcampusProvider>().syncAfterCredentialUpdate(rollno);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password saved. Syncing your data\u2026'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save password: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncAllStudents() async {
    if (_syncAllInProgress) return;

    final userProvider = context.read<UserProvider>();
    if (!userProvider.isActualPlacementRep) return;

    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync all student data?'),
        content: const Text(
          'This will refresh attendance and CGPA for all students and store the latest values in Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (start != true || !mounted) return;

    setState(() => _syncAllInProgress = true);

    final syncState = ValueNotifier<_SyncAllDialogState>(
      const _SyncAllDialogState.loading(),
    );

    () async {
      try {
        final result = await EcampusService().syncAllUsers();
        // Support both old field name (total) and new (students_with_dob)
        final total = result['students_with_dob'] ?? result['total'] ?? 0;
        final success = result['success_count'] ?? 0;
        final failed = result['failed_count'] ?? 0;
        final failedList = (result['failed'] as List?) ?? [];
        final noDobSkipped = result['no_dob_skipped'] ?? 0;

        await _loadAllStudentsAcademicData();

        syncState.value = _SyncAllDialogState.success(
          total: total,
          success: success,
          failed: failed,
          failedList: failedList,
          noDobSkipped: noDobSkipped,
        );
      } catch (e) {
        final message = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('Bad state: ', '')
            .trim();
        syncState.value = _SyncAllDialogState.error(
          message.isEmpty
              ? 'Unable to complete sync right now. Please try again.'
              : message,
        );
      } finally {
        if (mounted) {
          setState(() => _syncAllInProgress = false);
        }
      }
    }();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return ValueListenableBuilder<_SyncAllDialogState>(
          valueListenable: syncState,
          builder: (_, state, __) {
            return Dialog(
              backgroundColor:
                  isDark ? const Color(0xFF171728) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.isLoading
                              ? Icons.sync
                              : state.isSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                          color: state.isLoading
                              ? Theme.of(ctx).colorScheme.primary
                              : state.isSuccess
                                  ? Colors.green
                                  : Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.isLoading
                              ? 'Sync in progress'
                              : state.isSuccess
                                  ? 'Sync completed'
                                  : 'Sync failed',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.isLoading) ...[
                      Text(
                        'Refreshing all student attendance and CGPA records. You can close this dialog and continue using the app.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(minHeight: 6),
                    ] else if (state.isSuccess) ...[
                      Text(
                        'Synced: ${state.total}  •  ✔ ${state.success}  •  ✗ ${state.failed}',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      if (state.failedList.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Failed – check DOB or eCampus login',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            itemCount: state.failedList.length,
                            itemBuilder: (_, index) {
                              final item = state.failedList[index] as Map;
                              final rollno = item['rollno'] ?? 'Unknown';
                              final errType = (item['error_type'] ?? '') as String;
                              final suffix = errType == 'login_failed'
                                  ? ' (wrong DOB?)'
                                  : errType == 'network_error'
                                      ? ' (timeout)'
                                      : '';
                              return Text(
                                '• $rollno$suffix',
                                style: GoogleFonts.inter(fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        state.errorMessage ??
                            'Unable to complete sync right now. Please try again.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                    if (!state.isLoading) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    syncState.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<UserProvider>().currentUser;

    if (!_isPlacementRep && user != null && user.dob == null && !user.ecampusPasswordSet) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hPad =
                  (constraints.maxWidth * 0.07).clamp(20.0, 44.0);
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: hPad, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                // ── Icon + heading ──────────────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school_rounded,
                        size: 48, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Connect to eCampus',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Link your account to view attendance,\n'
                  'CGPA, and CA exam schedules.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.60),
                  ),
                ),
                const SizedBox(height: 28),

                // ── OPTION A: DOB (recommended for most students) ──────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF15152A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FOR MOST STUDENTS',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit_calendar_outlined,
                              size: 18,
                              color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Use Date of Birth',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "If you haven't changed your eCampus password, "
                        'your login uses your date of birth '
                        '(e.g.\xA008jul04). Just set it below.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.60),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => _showDobRequiredDialog(
                            context.read<UserProvider>()),
                        icon: const Icon(
                            Icons.edit_calendar_rounded, size: 18),
                        label: const Text('Set My Date of Birth'),
                        style: FilledButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── OR divider ─────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.40)),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ]),

                const SizedBox(height: 16),

                // ── OPTION B: Custom password (changed it?) ────────────────
                if (!_showPasswordSection)
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showPasswordSection = true),
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: const Text(
                        'I changed my eCampus password'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF15152A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.vpn_key_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Custom Password',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(
                                  () => _showPasswordSection = false),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StatefulBuilder(
                          builder: (ctx, setLocal) => TextField(
                            controller: _credPassCtrl,
                            obscureText: _credObscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType:
                                TextInputType.visiblePassword,
                            autofillHints: const [],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                _connectWithInlinePassword(
                                    context.read<UserProvider>()),
                            decoration: InputDecoration(
                              hintText: 'Enter your eCampus password',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E1E2E)
                                  : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _credObscure
                                      ? Icons.visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _credObscure = !_credObscure),
                                tooltip:
                                    _credObscure ? 'Show' : 'Hide',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _credSaving
                                ? null
                                : () => _connectWithInlinePassword(
                                    context.read<UserProvider>()),
                            icon: _credSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.link_rounded,
                                    size: 18),
                            label: Text(
                              _credSaving ? 'Connecting\u2026' : 'Connect',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Security note ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: Colors.blue, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your credentials are stored securely and only '
                          'used to connect to the PSG eCampus portal. '
                          'They are never visible to other users.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.5,
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
          },
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
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            title: Text(
              'Academic Insights',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            actions: [
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
              // 4 tabs for placement rep can overflow on narrow phones
              isScrollable: _isPlacementRep,
              tabAlignment: _isPlacementRep
                  ? TabAlignment.start
                  : TabAlignment.fill,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  isDark ? Colors.white54 : Colors.black45,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: _isPlacementRep
                  ? const [
                      Tab(text: 'Attendance'),
                      Tab(text: 'CGPA'),
                      Tab(text: 'CA Timetable'),
                      Tab(text: 'All Students'),
                    ]
                  : const [
                      Tab(text: 'Attendance'),
                      Tab(text: 'CGPA'),
                      Tab(text: 'CA Timetable'),
                    ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _isPlacementRep
              ? [
                  _AttendanceTab(
                    onUpdatePassword: () => _showCustomPasswordDialog(
                        context.read<UserProvider>()),
                  ),
                  _CgpaTab(
                    onUpdatePassword: () => _showCustomPasswordDialog(
                        context.read<UserProvider>()),
                  ),
                  const _CaTestTab(),
                  _buildAllStudentsReportTab(context, isDark, theme),
                ]
              : [
                  _AttendanceTab(
                    onUpdatePassword: () => _showCustomPasswordDialog(
                        context.read<UserProvider>()),
                  ),
                  _CgpaTab(
                    onUpdatePassword: () => _showCustomPasswordDialog(
                        context.read<UserProvider>()),
                  ),
                  const _CaTestTab(),
                ],
        ),
      ),
    );
  }

  Widget _buildAllStudentsReportTab(
      BuildContext context, bool isDark, ThemeData theme) {
    if (_isLoadingAllStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allStudentsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _allStudentsError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
      );
    }

    final g1 = _applySort(_allStudents
      .where((item) => item.batch == 'G1')
      .toList());
    final g2 = _applySort(_allStudents
      .where((item) => item.batch == 'G2')
      .toList());
    final others = _applySort(_allStudents
      .where((item) => item.batch != 'G1' && item.batch != 'G2')
      .toList());

    final showG1 = _batchFilter == _BatchFilter.all || _batchFilter == _BatchFilter.g1;
    final showG2 = _batchFilter == _BatchFilter.all || _batchFilter == _BatchFilter.g2;
    final showOthers = _batchFilter == _BatchFilter.all;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Academic Report',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_lastAllStudentsSyncedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Last updated ${DateFormat('dd MMM, hh:mm a').format(_lastAllStudentsSyncedAt!.toLocal())}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload',
              onPressed: _isLoadingAllStudents ? null : _loadAllStudentsAcademicData,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReportControls(context, theme),
        const SizedBox(height: 12),
        if (showG1) ...[
          _buildBatchSection(
            title: 'G1',
            entries: g1,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 14),
        ],
        if (showG2) ...[
          _buildBatchSection(
            title: 'G2',
            entries: g2,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 14),
        ],
        if (showOthers && others.isNotEmpty)
          _buildBatchSection(
            title: 'Others',
            entries: others,
            isDark: isDark,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildReportControls(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showSortOptions(context),
            icon: const Icon(Icons.sort_rounded, size: 18),
            label: Text(
              _sortModeLabel,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showBatchOptions(context),
            icon: const Icon(Icons.filter_alt_rounded, size: 18),
            label: Text(
              _batchFilterLabel,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String get _sortModeLabel {
    switch (_sortMode) {
      case _SortMode.rollNoAsc:
        return 'Roll No A-Z';
      case _SortMode.rollNoDesc:
        return 'Roll No Z-A';
      case _SortMode.attendanceAsc:
        return 'Attendance Low-High';
      case _SortMode.attendanceDesc:
        return 'Attendance High-Low';
      case _SortMode.cgpaAsc:
        return 'CGPA Low-High';
      case _SortMode.cgpaDesc:
        return 'CGPA High-Low';
    }
  }

  String get _batchFilterLabel {
    switch (_batchFilter) {
      case _BatchFilter.all:
        return 'All batches';
      case _BatchFilter.g1:
        return 'G1 only';
      case _BatchFilter.g2:
        return 'G2 only';
    }
  }

  Future<void> _showSortOptions(BuildContext context) async {
    final selected = await showModalBottomSheet<_SortMode>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _SortSheet(selected: _sortMode),
    );

    if (selected != null && mounted) {
      setState(() => _sortMode = selected);
    }
  }

  Future<void> _showBatchOptions(BuildContext context) async {
    final selected = await showModalBottomSheet<_BatchFilter>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _BatchSheet(selected: _batchFilter),
    );

    if (selected != null && mounted) {
      setState(() => _batchFilter = selected);
    }
  }

  List<_StudentAcademicEntry> _applySort(List<_StudentAcademicEntry> entries) {
    int compareNullableDouble(double? a, double? b, {required bool ascending}) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return ascending ? a.compareTo(b) : b.compareTo(a);
    }

    entries.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.rollNoAsc:
          return a.regNo.compareTo(b.regNo);
        case _SortMode.rollNoDesc:
          return b.regNo.compareTo(a.regNo);
        case _SortMode.attendanceAsc:
          return compareNullableDouble(a.attendancePercentage, b.attendancePercentage, ascending: true);
        case _SortMode.attendanceDesc:
          return compareNullableDouble(a.attendancePercentage, b.attendancePercentage, ascending: false);
        case _SortMode.cgpaAsc:
          return compareNullableDouble(a.cgpa, b.cgpa, ascending: true);
        case _SortMode.cgpaDesc:
          return compareNullableDouble(a.cgpa, b.cgpa, ascending: false);
      }
    });

    return entries;
  }

  Widget _buildBatchSection({
    required String title,
    required List<_StudentAcademicEntry> entries,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171728) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${entries.length})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'No students available in this group.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          else
            ...entries.map((item) {
              final attendance = item.attendancePercentage == null
                  ? '—'
                  : '${item.attendancePercentage!.toStringAsFixed(1)}%';
              final cgpa =
                  item.cgpa == null ? '—' : item.cgpa!.toStringAsFixed(2);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10101C)
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: !item.isSynced
                        ? Border.all(
                            color: Colors.orange.withValues(alpha: 0.4),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!item.isSynced)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Not synced',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.regNo}  •  DOB: ${item.dobText}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Attendance $attendance',
                            style: GoogleFonts.inter(fontSize: 11.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'CGPA $cgpa',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SyncAllDialogState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final int total;
  final int success;
  final int failed;
  final List failedList;

  const _SyncAllDialogState._({
    required this.isLoading,
    required this.isSuccess,
    required this.errorMessage,
    required this.total,
    required this.success,
    required this.failed,
    required this.failedList,
  });

  const _SyncAllDialogState.loading()
      : this._(
          isLoading: true,
          isSuccess: false,
          errorMessage: null,
          total: 0,
          success: 0,
          failed: 0,
          failedList: const [],
        );

  const _SyncAllDialogState.success({
    required int total,
    required int success,
    required int failed,
    required List failedList,
    int noDobSkipped = 0,
  }) : this._(
          isLoading: false,
          isSuccess: true,
          errorMessage: null,
          total: total,
          success: success,
          failed: failed,
          failedList: failedList,
        );

  const _SyncAllDialogState.error(String message)
      : this._(
          isLoading: false,
          isSuccess: false,
          errorMessage: message,
          total: 0,
          success: 0,
          failed: 0,
          failedList: const [],
        );
}

class _StudentAcademicEntry {
  final String regNo;
  final String name;
  final String batch;
  final String dobText;
  final double? attendancePercentage;
  final double? cgpa;
  /// True only when this student has a row in ecampus_attendance or ecampus_cgpa.
  final bool isSynced;

  const _StudentAcademicEntry({
    required this.regNo,
    required this.name,
    required this.batch,
    required this.dobText,
    required this.attendancePercentage,
    required this.cgpa,
    this.isSynced = true,
  });
}

enum _SortMode {
  rollNoAsc,
  rollNoDesc,
  attendanceAsc,
  attendanceDesc,
  cgpaAsc,
  cgpaDesc,
}

enum _BatchFilter {
  all,
  g1,
  g2,
}

class _SortSheet extends StatelessWidget {
  final _SortMode selected;

  const _SortSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _SortTile(
            icon: Icons.sort_by_alpha_rounded,
            label: 'Roll number A-Z',
            value: _SortMode.rollNoAsc,
            groupValue: selected,
          ),
          _SortTile(
            icon: Icons.sort_by_alpha_rounded,
            label: 'Roll number Z-A',
            value: _SortMode.rollNoDesc,
            groupValue: selected,
          ),
          _SortTile(
            icon: Icons.trending_up_rounded,
            label: 'Attendance low to high',
            value: _SortMode.attendanceAsc,
            groupValue: selected,
          ),
          _SortTile(
            icon: Icons.trending_down_rounded,
            label: 'Attendance high to low',
            value: _SortMode.attendanceDesc,
            groupValue: selected,
          ),
          _SortTile(
            icon: Icons.insights_rounded,
            label: 'CGPA low to high',
            value: _SortMode.cgpaAsc,
            groupValue: selected,
          ),
          _SortTile(
            icon: Icons.insights_rounded,
            label: 'CGPA high to low',
            value: _SortMode.cgpaDesc,
            groupValue: selected,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: Text(
                'Close',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final _SortMode value;
  final _SortMode groupValue;

  const _SortTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13),
      ),
      trailing: groupValue == value
          ? Icon(Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked_rounded, size: 20),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

class _BatchSheet extends StatelessWidget {
  final _BatchFilter selected;

  const _BatchSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by batch',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _BatchTile(
            label: 'All batches',
            value: _BatchFilter.all,
            groupValue: selected,
          ),
          _BatchTile(
            label: 'G1 only',
            value: _BatchFilter.g1,
            groupValue: selected,
          ),
          _BatchTile(
            label: 'G2 only',
            value: _BatchFilter.g2,
            groupValue: selected,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: Text(
                'Close',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  final String label;
  final _BatchFilter value;
  final _BatchFilter groupValue;

  const _BatchTile({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.groups_rounded, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13),
      ),
      trailing: groupValue == value
          ? Icon(Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked_rounded, size: 20),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

// ─── Attendance Tab ──────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final VoidCallback? onUpdatePassword;
  const _AttendanceTab({this.onUpdatePassword});

  @override
  Widget build(BuildContext context) {
    return Consumer<EcampusProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prov.status == EcampusStatus.error) {
          final rollno =
              context.read<UserProvider>().currentUser?.regNo ?? '';
          if (prov.isLoginFailed) {
            return _PasswordErrorView(
              message: prov.errorMessage ?? 'eCampus login failed.',
              onUpdatePassword: onUpdatePassword,
              onRetry: () => context.read<EcampusProvider>().init(rollno),
            );
          }
          return _ErrorView(
            message: prov.errorMessage ?? 'Something went wrong',
            onRetry: () => context.read<EcampusProvider>().init(rollno),
          );
        }

        if (prov.attendance == null) {
          return const _EmptyView(
            message: 'No attendance data available yet.\nYour placement representative will refresh and publish updates.',
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _AttendanceSummaryCard(summary: prov.attendance!.summary),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

    final String complianceMsg = summary.isSafe
      ? '✅ Attendance is healthy. You can miss up to ${summary.overallCanBunk} class${summary.overallCanBunk == 1 ? '' : 'es'} and remain above 75%.'
      : '⚠️ Attend ${summary.overallNeedAttend} more class${summary.overallNeedAttend == 1 ? '' : 'es'} to meet the 75% requirement.';

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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${summary.overallPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
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

            // Attendance recommendation message
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                complianceMsg,
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
  final VoidCallback? onUpdatePassword;
  const _CgpaTab({this.onUpdatePassword});

  @override
  Widget build(BuildContext context) {
    return Consumer<EcampusProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prov.status == EcampusStatus.error) {
          final rollno =
              context.read<UserProvider>().currentUser?.regNo ?? '';
          if (prov.isLoginFailed) {
            return _PasswordErrorView(
              message: prov.errorMessage ?? 'eCampus login failed.',
              onUpdatePassword: onUpdatePassword,
              onRetry: () => context.read<EcampusProvider>().init(rollno),
            );
          }
          return _ErrorView(
            message: prov.errorMessage ?? 'Something went wrong',
            onRetry: () => context.read<EcampusProvider>().init(rollno),
          );
        }

        if (prov.cgpa == null) {
          return const _EmptyView(
            message: 'No CGPA data available yet.\nYour placement representative will refresh and publish updates.',
          );
        }

        return CustomScrollView(
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    cgpa.cgpa.toStringAsFixed(2),
                    style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: c,
                      height: 1,
                    ),
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
            // Format semester label: "1" becomes "Semester 1"
            final semesterLabel = entry.key.toLowerCase().contains('semester')
                ? entry.key
                : 'Semester ${entry.key}';
            final courseCount = entry.value.length;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern semester header with course count
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                            ]
                          : [
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                              theme.colorScheme.primary.withValues(alpha: 0.04),
                            ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Semester icon badge
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Semester label and count
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              semesterLabel,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$courseCount ${courseCount == 1 ? 'course' : 'courses'}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Course cards with improved spacing
                ...entry.value.map((course) {
                  final gradeColor = _gradeColor(course.grade);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: isDark ? 0.08 : 0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Modern grade badge with gradient
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                gradeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                gradeColor.withValues(alpha: isDark ? 0.15 : 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: gradeColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              course.grade.isEmpty ? '–' : course.grade,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: gradeColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Course info with improved hierarchy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.35,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Course code badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      course.code,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Credits indicator
                                  Icon(
                                    Icons.bookmark_outline_rounded,
                                    size: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${course.credits} ${course.credits == 1 ? 'credit' : 'credits'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
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
  final IconData? icon;

  const _EmptyView({required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.cloud_off_rounded,
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
          ],
        ),
      ),
    );
  }
}

/// Shown when the error is specifically a login failure (wrong / outdated
/// eCampus password).  Surfaces a prominent "Update Password" CTA so the
/// student can fix the issue inline without navigating to Profile.
class _PasswordErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onUpdatePassword;
  final VoidCallback onRetry;

  const _PasswordErrorView({
    required this.message,
    required this.onRetry,
    this.onUpdatePassword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Colors.orange.withValues(alpha: isDark ? 0.15 : 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Text(
              'eCampus Login Failed',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(height: 28),
            if (onUpdatePassword != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onUpdatePassword,
                  icon: const Icon(Icons.vpn_key_rounded, size: 18),
                  label: Text(
                    'Update eCampus Password',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
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

// ─────────────────────────────────────────────────────────────────────────────
// CA TESTS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _CaTestTab extends StatelessWidget {
  const _CaTestTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<EcampusProvider>(
      builder: (context, prov, _) {
        final tt = prov.caTimetable;

        // ── Always show the timetable when it's available ─────────────────
        // The CA schedule is global (same for all students) and must be
        // visible regardless of the user's eCampus login status or any
        // attendance-fetch error.
        if (tt != null && tt.hasData) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _CaTimetableSection(timetable: tt),
              ),
            ],
          );
        }

        // ── Loading the user's data ───────────────────────────────────────
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Attendance/CGPA error (but timetable also unavailable) ────────
        if (prov.status == EcampusStatus.error) {
          return const _EmptyView(
            icon: Icons.schedule_outlined,
            message:
                'CA exam timetable is not available yet.\nYour placement representative will publish the schedule soon.',
          );
        }

        // ── No timetable published yet ────────────────────────────────────
        if (tt == null) {
          return const _EmptyView(
            icon: Icons.schedule_outlined,
            message:
                'CA exam timetable is not available yet.\nYour placement representative will publish the schedule soon.',
          );
        }

        // tt.hasData == false (published but empty / has note)
        return _EmptyView(
          icon: Icons.schedule_outlined,
          message: tt.note?.isNotEmpty == true
              ? tt.note!
              : 'CA exam timetable has not been published yet.',
        );
      },
    );
  }
}

class _CaTimetableSection extends StatelessWidget {
  final EcampusCaTimetable timetable;
  const _CaTimetableSection({required this.timetable});

  // ── Date parsing ──────────────────────────────────────────────────────────
  // Handles formats: "06/MAR/26", "06/Mar/26", "06/03/2026", "06-03-26", etc.
  static final _monthAbbr = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  DateTime? _parseCaDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final s = raw.trim();
    // Try DD/MMM/YY(YY)  e.g. "06/Mar/26" or "06/MAR/2026"
    final alphaMatch = RegExp(
      r'^(\d{1,2})[/\-]([A-Za-z]{3,9})[/\-](\d{2,4})$',
    ).firstMatch(s);
    if (alphaMatch != null) {
      final day = int.tryParse(alphaMatch.group(1)!) ?? 0;
      final monthStr = alphaMatch.group(2)!.toLowerCase().substring(0, 3);
      final yearRaw = int.tryParse(alphaMatch.group(3)!) ?? 0;
      final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
      final month = _monthAbbr[monthStr];
      if (month != null && day > 0) {
        return DateTime(year, month, day);
      }
    }
    // Try DD/MM/YYYY or DD-MM-YYYY
    final numMatch = RegExp(
      r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})$',
    ).firstMatch(s);
    if (numMatch != null) {
      final day = int.tryParse(numMatch.group(1)!) ?? 0;
      final month = int.tryParse(numMatch.group(2)!) ?? 0;
      final yearRaw = int.tryParse(numMatch.group(3)!) ?? 0;
      final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
      if (day > 0 && month > 0) {
        return DateTime(year, month, day);
      }
    }
    // ISO fallback
    return DateTime.tryParse(s);
  }

  int? _daysLeft(DateTime? examDate) {
    if (examDate == null) return null;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final examOnly = DateTime(examDate.year, examDate.month, examDate.day);
    return examOnly.difference(todayOnly).inDays;
  }

  (Color, Color, String) _badgeStyle(int? days, bool isDark) {
    if (days == null) return (Colors.grey, Colors.grey.shade700, '');
    if (days < 0) return (Colors.grey, Colors.grey.shade700, 'Completed');
    if (days == 0) return (const Color(0xFFEF5350), const Color(0xFFB71C1C), 'Today!');
    if (days == 1) return (const Color(0xFFFF7043), const Color(0xFFBF360C), 'Tomorrow');
    if (days <= 3) return (const Color(0xFFFF9800), const Color(0xFFE65100), '$days Days Left');
    return (const Color(0xFF4CAF50), const Color(0xFF1B5E20), '$days Days Left');
  }

  String? _pickField(Map<String, String> row, List<String> candidates) {
    for (final k in candidates) {
      final v = row[k];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter and sort rows: hide completed exams, show upcoming first
    final sortedRows = timetable.rows
        .where((row) {
          final dateRaw = _pickField(row, const ['test_date', 'date', 'exam_date']) ?? '';
          final date = _parseCaDate(dateRaw);
          final days = _daysLeft(date);
          // Hide exams that are in the past (completed)
          return days == null || days >= 0;
        })
        .toList()
      ..sort((a, b) {
        final da = _parseCaDate(
          _pickField(a, const ['test_date', 'date', 'exam_date']) ?? '',
        );
        final db = _parseCaDate(
          _pickField(b, const ['test_date', 'date', 'exam_date']) ?? '',
        );
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    // If all exams are completed, show "CA 2 will be published soon" message
    if (sortedRows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      const Color(0xFF4CAF50).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 42,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'All CA 1 Exams Completed! 🎉',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'CA 2 will be published soon.\nStay tuned for updates!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'CA EXAM SCHEDULE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${sortedRows.length} ${sortedRows.length == 1 ? 'Exam' : 'Exams'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sortedRows.asMap().entries.map((entry) {
            final index = entry.key;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 80)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _CaExamCard(
                row: entry.value,
                parseCaDate: _parseCaDate,
                daysLeft: _daysLeft,
                badgeStyle: _badgeStyle,
                pickField: _pickField,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CaExamCard extends StatelessWidget {
  final Map<String, String> row;
  final DateTime? Function(String) parseCaDate;
  final int? Function(DateTime?) daysLeft;
  final (Color, Color, String) Function(int?, bool) badgeStyle;
  final String? Function(Map<String, String>, List<String>) pickField;
  final bool isDark;

  const _CaExamCard({
    required this.row,
    required this.parseCaDate,
    required this.daysLeft,
    required this.badgeStyle,
    required this.pickField,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final courseCode = pickField(row, const ['course_code', 'code', 'subject_code']) ?? '';
    final courseName = pickField(row, const [
          'course_name',
          'course_title',
          'subject',
          'title',
          'paper',
        ]) ??
        courseCode;
    final testDateRaw =
        pickField(row, const ['test_date', 'date', 'exam_date']) ?? '';
    final slotNo = pickField(row, const ['slot_no', 'slot', 'slot_number']) ?? '';
    final session = pickField(row, const ['session', 'time', 'timings']) ?? '';

    final examDate = parseCaDate(testDateRaw);
    final days = daysLeft(examDate);
    final (badgeColor, badgeDark, badgeText) = badgeStyle(days, isDark);
    final showBadge = badgeText.isNotEmpty;

    // Format display date: "06 Mar 2026"
    String displayDate = testDateRaw;
    if (examDate != null) {
      displayDate = DateFormat('dd MMM yyyy').format(examDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E1E2E),
                  const Color(0xFF1A1A28),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFAFAFA),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: showBadge
              ? badgeColor.withValues(alpha: isDark ? 0.3 : 0.2)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: showBadge ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: showBadge
                ? badgeColor.withValues(alpha: isDark ? 0.2 : 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: showBadge ? 16 : 12,
            offset: const Offset(0, 4),
            spreadRadius: showBadge ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Gradient accent line on left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      badgeColor,
                      badgeColor.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Course header ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (courseCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF9800).withValues(alpha: 0.18),
                                const Color(0xFFFF9800).withValues(alpha: 0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            courseCode,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF9800),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          courseName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : Colors.black.withValues(alpha: 0.87),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Date + Session row ──
                  Row(
                    children: [
                      // Date pill
                      if (displayDate.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  displayDate,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.87)
                                        : Colors.black.withValues(alpha: 0.87),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 10),
                      // Session / time pill
                      if (session.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    session,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (slotNo.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Slot $slotNo',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // ── Urgency badge ──
                  if (showBadge) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [badgeColor, badgeDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            days == 0
                                ? Icons.warning_rounded
                                : days == 1
                                    ? Icons.access_time_filled_rounded
                                    : Icons.event_available_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            badgeText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
