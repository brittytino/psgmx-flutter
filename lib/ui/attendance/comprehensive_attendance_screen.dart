import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/attendance_schedule_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/attendance.dart';
import '../../models/scheduled_date.dart';
import '../widgets/premium_card.dart';

/// Comprehensive Attendance Screen with Role-Based Access Control
/// 
/// ACCESS RULES:
/// - Students: Only "My Attendance" tab (personal attendance history)
/// - Team Leaders: "My Attendance" + "My Team" tabs
/// - Coordinators: "My Attendance" + "My Team" + "Schedule Classes" tabs
/// - Placement Rep: FULL ACCESS - All tabs including "Overall" and "Mark Attendance"
class ComprehensiveAttendanceScreen extends StatelessWidget {
  const ComprehensiveAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Role checks (considering simulation mode)
    final isStudent = !userProvider.isTeamLeader && !userProvider.isCoordinator && !userProvider.isPlacementRep;
    final isTeamLeader = userProvider.isTeamLeader;
    final isCoordinator = userProvider.isCoordinator;
    final isPlacementRep = userProvider.isPlacementRep || userProvider.isActualPlacementRep;
    
    // Determine which tabs to show based on role
    List<Widget> tabs = [];
    List<Widget> tabViews = [];
    
    // Everyone gets "My Attendance"
    tabs.add(const Tab(text: 'My Attendance'));
    tabViews.add(const _MyAttendanceTab());
    
    // Team Leaders and above get "My Team"
    if (isTeamLeader || isCoordinator || isPlacementRep) {
      tabs.add(const Tab(text: 'My Team'));
      tabViews.add(const _MyTeamAttendanceTab());
    }
    
    // Coordinators get "Schedule Classes" (read-only scheduling)
    if (isCoordinator && !isPlacementRep) {
      tabs.add(const Tab(text: 'Schedule'));
      tabViews.add(const _ScheduleClassesTab());
    }
    
    // Only Placement Rep gets full access including "Overall"
    if (isPlacementRep) {
      tabs.add(const Tab(text: 'Schedule'));
      tabViews.add(const _ScheduleClassesTab());
      tabs.add(const Tab(text: 'Overall'));
      tabViews.add(const _OverallAttendanceTab());
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const Text('Attendance'),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: TabBar(
                    isScrollable: tabs.length > 3,
                    tabAlignment: tabs.length > 3 ? TabAlignment.start : TabAlignment.fill,
                    tabs: tabs,
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(children: tabViews),
        ),
      ),
    );
  }
}

// ========================================
// MY ATTENDANCE TAB
// ========================================
class _MyAttendanceTab extends StatefulWidget {
  const _MyAttendanceTab();

  @override
  State<_MyAttendanceTab> createState() => _MyAttendanceTabState();
}

class _MyAttendanceTabState extends State<_MyAttendanceTab> {
  late AttendanceService _attendanceService;
  AttendanceSummary? _summary;
  List<Attendance> _recentAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.uid;

      if (userId != null) {
        final summary = await _attendanceService.getStudentAttendanceSummary(
          studentId: userId,
        );
        final recent = await _attendanceService.getStudentAttendanceHistory(
          studentId: userId,
          endDate: DateTime.now(),
          startDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        if (mounted) {
          setState(() {
            _summary = summary;
            _recentAttendance = recent;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summary == null) {
      return const Center(
        child: Text('No attendance data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentAttendanceList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _summary!;
    final percentage = summary.attendancePercentage;
    final color = percentage >= 75 ? Colors.green : Colors.red;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_month, color: color, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Present', summary.presentCount, Colors.green),
              _buildStatColumn('Absent', summary.absentCount, Colors.red),
              _buildStatColumn('Total', summary.totalWorkingDays, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAttendanceList() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Attendance',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_recentAttendance.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('No recent attendance records'),
              ),
            )
          else
            ..._recentAttendance.map((attendance) {
              final dateStr = DateFormat('MMM dd, yyyy').format(attendance.date);
              final isPresent = attendance.status == AttendanceStatus.present;
              final color = isPresent ? Colors.green : Colors.red;

              return ListTile(
                leading: Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  color: color,
                ),
                title: Text(dateStr),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.status.displayName,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ========================================
// MY TEAM ATTENDANCE TAB
// ========================================
class _MyTeamAttendanceTab extends StatefulWidget {
  const _MyTeamAttendanceTab();

  @override
  State<_MyTeamAttendanceTab> createState() => _MyTeamAttendanceTabState();
}

class _MyTeamAttendanceTabState extends State<_MyTeamAttendanceTab> {
  late AttendanceService _attendanceService;
  late AttendanceScheduleService _scheduleService;
  List<AttendanceSummary> _teamMembers = [];
  bool _isLoading = true;
  bool _isTodayScheduled = false;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _scheduleService = AttendanceScheduleService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final teamId = userProvider.currentUser?.teamId;

      // Check if today is scheduled
      final today = DateTime.now();
      _isTodayScheduled = await _scheduleService.isDateScheduled(today);

      if (teamId != null) {
        final members = await _attendanceService.getTeamAttendanceSummary(
          teamId: teamId,
        );

        if (mounted) {
          setState(() {
            _teamMembers = members;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team attendance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teamMembers.isEmpty) {
      return const Center(
        child: Text('No team members found'),
      );
    }

    final avgPercentage = _teamMembers.fold<double>(
          0,
          (sum, member) => sum + member.attendancePercentage,
        ) /
        _teamMembers.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildTeamSummaryCard(avgPercentage),
          const SizedBox(height: AppSpacing.lg),
          if (!_isTodayScheduled) _buildNoClassTodayCard(),
          if (!_isTodayScheduled) const SizedBox(height: AppSpacing.lg),
          ..._teamMembers.map((member) => _buildMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildNoClassTodayCard() {
    return PremiumCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Class Today',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attendance marking is only available on scheduled class dates.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSummaryCard(double avgPercentage) {
    final color = avgPercentage >= 75 ? Colors.green : Colors.red;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group, color: color, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Average',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${avgPercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(AttendanceSummary member) {
    final percentage = member.attendancePercentage;
    final color = percentage >= 75 ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
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
                        member.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        member.regNo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${member.presentCount}/${member.totalWorkingDays}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// SCHEDULE CLASSES TAB (Coordinators & Placement Rep)
// ========================================
class _ScheduleClassesTab extends StatefulWidget {
  const _ScheduleClassesTab();

  @override
  State<_ScheduleClassesTab> createState() => _ScheduleClassesTabState();
}

class _ScheduleClassesTabState extends State<_ScheduleClassesTab> {
  late AttendanceScheduleService _scheduleService;
  List<ScheduledDate> _scheduledDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scheduleService = AttendanceScheduleService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final scheduled = await _scheduleService.getUpcomingScheduledDates();
      if (mounted) {
        setState(() {
          _scheduledDates = scheduled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final isPlacementRep = userProvider.isPlacementRep || userProvider.isActualPlacementRep;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Header
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled Classes',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_scheduledDates.length} upcoming classes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Only Placement Rep can add new schedules
                    if (isPlacementRep)
                      IconButton(
                        onPressed: () => _showAddScheduleDialog(context),
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: 'Add Schedule',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Info for coordinators
          if (!isPlacementRep)
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only Placement Representatives can modify schedules',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isPlacementRep) const SizedBox(height: AppSpacing.lg),

          // Scheduled dates list
          if (_scheduledDates.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming classes scheduled',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_scheduledDates.length, (index) {
              final schedule = _scheduledDates[index];
              final isToday = DateUtils.isSameDay(schedule.date, DateTime.now());
              final isPast = schedule.date.isBefore(DateTime.now());
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  color: isToday 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                      : isPast 
                          ? (isDark ? Colors.grey[850] : Colors.grey[100])
                          : null,
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isToday 
                              ? Theme.of(context).primaryColor
                              : isPast 
                                  ? Colors.grey
                                  : Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('dd').format(schedule.date),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(schedule.date).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('EEEE').format(schedule.date),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isPast ? Colors.grey : null,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'TODAY',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isPast) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'PAST',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              schedule.notes ?? 'Placement Class',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPlacementRep && !isPast)
                        IconButton(
                          onPressed: () => _deleteSchedule(schedule.id),
                          icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
                          tooltip: 'Remove',
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

  Future<void> _showAddScheduleDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Class Date',
    );

    if (selectedDate != null && mounted) {
      try {
        await _scheduleService.addScheduledDate(
          date: selectedDate,
          scheduledBy: userProvider.currentUser?.uid ?? 'unknown',
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Class scheduled for ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error scheduling: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await _scheduleService.deleteScheduledDate(scheduleId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule removed'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ========================================
// OVERALL ATTENDANCE TAB (Placement Rep Only)
// ========================================
class _OverallAttendanceTab extends StatefulWidget {
  const _OverallAttendanceTab();

  @override
  State<_OverallAttendanceTab> createState() => _OverallAttendanceTabState();
}

class _OverallAttendanceTabState extends State<_OverallAttendanceTab> {
  late AttendanceService _attendanceService;
  late AttendanceScheduleService _scheduleService;
  List<AttendanceSummary> _allStudents = [];
  List<ScheduledDate> _scheduledDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _scheduleService = AttendanceScheduleService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final students = await _attendanceService.getAllStudentsAttendanceSummary();
      final scheduled = await _scheduleService.getUpcomingScheduledDates();

      if (mounted) {
        setState(() {
          _allStudents = students;
          _scheduledDates = scheduled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildScheduledDatesCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildMarkAttendanceCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildOverallStatsCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildStudentsList(),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceCard() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.how_to_reg, color: Colors.green, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark Attendance',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Mark attendance for all 123 students',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBulkAttendanceSheet(DateTime.now()),
                  icon: const Icon(Icons.today),
                  label: const Text('Today'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDateAndMarkAttendance(),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Select Date'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateAndMarkAttendance() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      _showBulkAttendanceSheet(date);
    }
  }

  void _showBulkAttendanceSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _BulkAttendanceSheet(
        date: date,
        allStudents: _allStudents,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  Widget _buildScheduledDatesCard() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduled Classes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showScheduleDatePicker(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Date'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_scheduledDates.isEmpty)
            const Text('No upcoming scheduled classes')
          else
            ..._scheduledDates.map((scheduled) {
              final dateStr = DateFormat('MMM dd, yyyy').format(scheduled.date);
              return ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(dateStr),
                subtitle: Text(scheduled.notes ?? 'No notes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editScheduledDate(scheduled),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteScheduledDate(scheduled.id),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard() {
    final avgPercentage = _allStudents.fold<double>(
          0,
          (sum, student) => sum + student.attendancePercentage,
        ) /
        (_allStudents.isEmpty ? 1 : _allStudents.length);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Students', _allStudents.length, Colors.blue),
              _buildStatColumn(
                'Avg %',
                avgPercentage.round(),
                avgPercentage >= 75 ? Colors.green : Colors.red,
              ),
              _buildStatColumn(
                'Scheduled',
                _scheduledDates.length,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Students',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._allStudents.map((student) {
            final percentage = student.attendancePercentage;
            final color = percentage >= 75 ? Colors.green : Colors.red;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Text(
                  student.name[0].toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(student.name),
              subtitle: Text('${student.regNo} - ${student.teamId ?? "No Team"}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${student.presentCount}/${student.totalWorkingDays}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
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

  Future<void> _showScheduleDatePicker() async {
    await showDialog(
      context: context,
      builder: (context) => _MultiDatePickerDialog(
        onDatesSelected: (dates, notes) async {
          try {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            
            // Add all selected dates
            for (final date in dates) {
              await _scheduleService.addScheduledDate(
                date: date,
                scheduledBy: userProvider.currentUser!.uid,
                notes: notes,
              );
            }
            
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${dates.length} date(s) scheduled successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _editScheduledDate(ScheduledDate scheduled) async {
    final controller = TextEditingController(text: scheduled.notes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (notes != null) {
      try {
        await _scheduleService.updateScheduledDate(
          id: scheduled.id,
          notes: notes,
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteScheduledDate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this scheduled date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _scheduleService.deleteScheduledDate(id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

// ========================================
// MULTI-DATE PICKER DIALOG
// ========================================
class _MultiDatePickerDialog extends StatefulWidget {
  final Function(List<DateTime> dates, String notes) onDatesSelected;

  const _MultiDatePickerDialog({required this.onDatesSelected});

  @override
  State<_MultiDatePickerDialog> createState() => _MultiDatePickerDialogState();
}

class _MultiDatePickerDialogState extends State<_MultiDatePickerDialog> {
  final Set<DateTime> _selectedDates = {};
  final TextEditingController _notesController = TextEditingController();
  DateTime _focusedDate = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final existingDate = _selectedDates.firstWhere(
        (d) => _isSameDay(d, date),
        orElse: () => DateTime(0),
      );

      if (existingDate.year != 0) {
        _selectedDates.remove(existingDate);
      } else {
        _selectedDates.add(DateTime(date.year, date.month, date.day));
      }
    });
  }

  bool _isSelected(DateTime date) {
    return _selectedDates.any((d) => _isSameDay(d, date));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Schedule Multiple Dates',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tap dates to select multiple class days',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Calendar view
            _buildCalendar(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Selected dates display
            if (_selectedDates.isNotEmpty) ...[
              Text(
                'Selected Dates (${_selectedDates.length}):',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedDates.map((date) {
                      return Chip(
                        label: Text(
                          DateFormat('MMM dd').format(date),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _toggleDate(date),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g., Data Structures classes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _selectedDates.isEmpty
                      ? null
                      : () {
                          final sortedDates = _selectedDates.toList()
                            ..sort((a, b) => a.compareTo(b));
                          widget.onDatesSelected(
                            sortedDates,
                            _notesController.text,
                          );
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.check),
                  label: Text('Schedule ${_selectedDates.length} Date(s)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Month navigation
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDate),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Weekday headers
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          
          // Calendar grid
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final today = DateTime.now();

    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final isToday = _isSameDay(date, today);
      final isSelected = _isSelected(date);
      final isPast = date.isBefore(today) && !isToday;

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _toggleDate(date),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue
                  : isToday
                      ? Colors.blue.withValues(alpha: 0.1)
                      : null,
              border: isToday && !isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Colors.white
                      : isPast
                          ? Colors.grey[400]
                          : Colors.black87,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: dayWidgets,
    );
  }
}

// ========================================
// BULK ATTENDANCE SHEET FOR PLACEMENT REP
// ========================================
class _BulkAttendanceSheet extends StatefulWidget {
  final DateTime date;
  final List<AttendanceSummary> allStudents;
  final VoidCallback onSaved;

  const _BulkAttendanceSheet({
    required this.date,
    required this.allStudents,
    required this.onSaved,
  });

  @override
  State<_BulkAttendanceSheet> createState() => _BulkAttendanceSheetState();
}

class _BulkAttendanceSheetState extends State<_BulkAttendanceSheet> {
  late Map<String, AttendanceStatus> _attendanceMap;
  late AttendanceService _attendanceService;
  bool _isSaving = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, present, absent

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _attendanceMap = {};
    
    // Initialize all students as present by default
    for (var student in widget.allStudents) {
      _attendanceMap[student.studentId] = AttendanceStatus.present;
    }
    
    _loadExistingAttendance();
  }

  Future<void> _loadExistingAttendance() async {
    try {
      // Load existing attendance for this date
      final existing = await _attendanceService.getAttendanceForDate(widget.date);
      
      if (mounted) {
        setState(() {
          for (var record in existing) {
            final id = record.userId ?? record.studentId;
            if (id.isNotEmpty) {
              _attendanceMap[id] = record.status;
            }
          }
        });
      }
    } catch (e) {
      // Ignore errors, just use defaults
    }
  }

  List<AttendanceSummary> get _filteredStudents {
    var students = widget.allStudents;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      students = students.where((s) {
        return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               s.regNo.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_filterStatus == 'present') {
      students = students.where((s) => 
        _attendanceMap[s.studentId] == AttendanceStatus.present
      ).toList();
    } else if (_filterStatus == 'absent') {
      students = students.where((s) => 
        _attendanceMap[s.studentId] == AttendanceStatus.absent
      ).toList();
    }
    
    return students;
  }

  int get _presentCount => _attendanceMap.values
      .where((s) => s == AttendanceStatus.present).length;
  
  int get _absentCount => _attendanceMap.values
      .where((s) => s == AttendanceStatus.absent).length;

  void _toggleStatus(String studentId) {
    setState(() {
      if (_attendanceMap[studentId] == AttendanceStatus.present) {
        _attendanceMap[studentId] = AttendanceStatus.absent;
      } else {
        _attendanceMap[studentId] = AttendanceStatus.present;
      }
    });
  }

  void _markAllPresent() {
    setState(() {
      for (var key in _attendanceMap.keys) {
        _attendanceMap[key] = AttendanceStatus.present;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var key in _attendanceMap.keys) {
        _attendanceMap[key] = AttendanceStatus.absent;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final markedBy = userProvider.currentUser!.uid;

      // Build attendance records with team_id from student data
      final records = _attendanceMap.entries.map((entry) {
        // Find the student to get their team_id
        final student = widget.allStudents.firstWhere(
          (s) => s.studentId == entry.key,
          orElse: () => widget.allStudents.first,
        );
        
        return {
          'user_id': entry.key,
          'date': widget.date.toIso8601String().split('T')[0],
          'status': entry.value == AttendanceStatus.present ? 'PRESENT' : 'ABSENT',
          'marked_by': markedBy,
          'team_id': student.teamId ?? 'G1', // Include team_id (required field)
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _attendanceService.bulkUpsertAttendance(records);

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Attendance saved for ${DateFormat('MMM dd, yyyy').format(widget.date)}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(widget.date);
    final isToday = DateFormat('yyyy-MM-dd').format(widget.date) == 
                    DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isToday 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isToday ? Icons.today : Icons.calendar_month,
                        color: isToday ? Colors.green : Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? "Today's Attendance" : 'Mark Attendance',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        'Present',
                        _presentCount,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildStatChip(
                        'Absent',
                        _absentCount,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildStatChip(
                        'Total',
                        widget.allStudents.length,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAllPresent,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('All Present'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAllAbsent,
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('All Absent'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Search and filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name or reg no...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.filter_list,
                        color: _filterStatus != 'all' ? Colors.blue : null,
                      ),
                      onSelected: (value) {
                        setState(() => _filterStatus = value);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'all', child: Text('All')),
                        const PopupMenuItem(value: 'present', child: Text('Present Only')),
                        const PopupMenuItem(value: 'absent', child: Text('Absent Only')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Student list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                final status = _attendanceMap[student.studentId] ?? AttendanceStatus.present;
                final isPresent = status == AttendanceStatus.present;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPresent 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.red.withValues(alpha: 0.1),
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: TextStyle(
                          color: isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${student.regNo} • ${student.teamId ?? "No Team"}',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: isPresent,
                      onChanged: (_) => _toggleStatus(student.studentId),
                      activeTrackColor: Colors.green.withValues(alpha: 0.5),
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green;
                        }
                        return Colors.red;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green.withValues(alpha: 0.5);
                        }
                        return Colors.red.withValues(alpha: 0.3);
                      }),
                    ),
                    onTap: () => _toggleStatus(student.studentId),
                  ),
                );
              },
            ),
          ),
          
          // Save button
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAttendance,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
