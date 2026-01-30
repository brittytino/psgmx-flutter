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

class ComprehensiveAttendanceScreen extends StatelessWidget {
  const ComprehensiveAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isPlacementRep = userProvider.isPlacementRep || userProvider.isActualPlacementRep;

    return DefaultTabController(
      length: isPlacementRep ? 3 : 2,
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
                    isScrollable: false,
                    tabAlignment: TabAlignment.fill,
                    tabs: [
                      const Tab(text: 'My Attendance'),
                      const Tab(text: 'My Team'),
                      if (isPlacementRep) const Tab(text: 'Overall'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              const _MyAttendanceTab(),
              const _MyTeamAttendanceTab(),
              if (isPlacementRep) const _OverallAttendanceTab(),
            ],
          ),
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
          _buildOverallStatsCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildStudentsList(),
        ],
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
