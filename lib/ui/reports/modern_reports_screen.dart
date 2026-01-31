import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/attendance_service.dart';
import '../../services/attendance_schedule_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';

class ModernReportsScreen extends StatefulWidget {
  const ModernReportsScreen({super.key});

  @override
  State<ModernReportsScreen> createState() => _ModernReportsScreenState();
}

class _ModernReportsScreenState extends State<ModernReportsScreen> {
  final _supabase = Supabase.instance.client;
  late AttendanceService _attendanceService;
  late AttendanceScheduleService _scheduleService;

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _scheduleService = AttendanceScheduleService();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      // Get whitelist count (source of truth - all 123 students)
      final whitelistCount = await _supabase.from('whitelist').count();

      // Get today's attendance
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayPresentCount = await _supabase
          .from('attendance_records')
          .count()
          .eq('date', today)
          .eq('status', 'PRESENT');

      // Get overall average
      final summaries = await _attendanceService.getAllStudentsAttendanceSummary();
      final avgPercentage = summaries.isEmpty
          ? 0.0
          : summaries.fold<double>(0, (sum, s) => sum + s.attendancePercentage) /
              summaries.length;

      // Get scheduled dates count
      final scheduledDates = await _scheduleService.getScheduledDates();

      if (mounted) {
        setState(() {
          _stats = {
            'total_students': whitelistCount,
            'today_present': todayPresentCount,
            'avg_percentage': avgPercentage,
            'scheduled_classes': scheduledDates.length,
            'total_with_attendance': summaries.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(
                'Analytics & Reports',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              pinned: true,
              floating: true,
              forceElevated: true,
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsOverview(colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuickActions(colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildExportSection(colorScheme),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(ColorScheme colorScheme) {
    final totalStudents = _stats['total_students'] ?? 0;
    final todayPresent = _stats['today_present'] ?? 0;
    final avgPercentage = _stats['avg_percentage'] ?? 0.0;
    final scheduledClasses = _stats['scheduled_classes'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OVERVIEW', colorScheme),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Students',
                totalStudents.toString(),
                Icons.group_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Scheduled Classes',
                scheduledClasses.toString(),
                Icons.event_rounded,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Today Present',
                todayPresent.toString(),
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Avg Attendance',
                '${avgPercentage.toStringAsFixed(1)}%',
                Icons.trending_up_rounded,
                avgPercentage >= 75 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 26,
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
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('QUICK ACTIONS', colorScheme),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActionTile(
                'Long Absentees',
                'Find students with consecutive absences',
                Icons.warning_amber_rounded,
                Colors.orange,
                () => _showLongAbsenteesDialog(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'View by Team',
                'Team-wise attendance analysis',
                Icons.groups_rounded,
                Colors.green,
                () => _showTeamAnalysis(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'View All Students',
                'See complete attendance records',
                Icons.people_alt_rounded,
                Colors.blue,
                () => _showAllStudents(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'Scheduled Classes',
                'View all scheduled dates',
                Icons.event_note_rounded,
                Colors.purple,
                () => _showScheduledClasses(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DATA EXPORT', colorScheme),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActionTile(
                'Export Attendance CSV',
                'Download complete attendance data',
                Icons.table_chart_rounded,
                Colors.teal,
                () => _exportAttendanceCSV(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'Copy Attendance Summary',
                'Copy formatted text to clipboard',
                Icons.copy_rounded,
                Colors.indigo,
                () => _copyAttendanceSummary(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // LONG ABSENTEES DIALOG
  // ========================================
  Future<void> _showLongAbsenteesDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => const _LongAbsenteesDialog(),
    );
  }

  // ========================================
  // TEAM ANALYSIS DIALOG
  // ========================================
  Future<void> _showTeamAnalysis() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Query team data from student_attendance_summary grouped by team
      final response = await _supabase
          .from('student_attendance_summary')
          .select('team_id, batch, attendance_percentage, present_count, absent_count')
          .not('team_id', 'is', null);

      if (!mounted) return;
      Navigator.pop(context);

      final students = response as List<dynamic>;

      // Group by team
      final Map<String, Map<String, dynamic>> teamData = {};
      for (final student in students) {
        final teamId = student['team_id'] as String?;
        if (teamId == null) continue;

        if (!teamData.containsKey(teamId)) {
          teamData[teamId] = {
            'team_id': teamId,
            'batch': student['batch'] ?? 'Unknown',
            'students': <Map<String, dynamic>>[],
            'total_percentage': 0.0,
          };
        }
        
        teamData[teamId]!['students'].add(student);
        teamData[teamId]!['total_percentage'] += 
            (student['attendance_percentage'] ?? 0.0).toDouble();
      }

      // Calculate averages
      final teams = teamData.values.map((team) {
        final studentCount = (team['students'] as List).length;
        return {
          'team_id': team['team_id'],
          'batch': team['batch'],
          'team_size': studentCount,
          'team_attendance_percentage': studentCount > 0
              ? team['total_percentage'] / studentCount
              : 0.0,
        };
      }).toList();

      // Sort by team_id
      teams.sort((a, b) => (a['team_id'] as String).compareTo(b['team_id'] as String));

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _TeamAnalysisDialog(teams: teams),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading team data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================
  // ALL STUDENTS DIALOG
  // ========================================
  Future<void> _showAllStudents() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final summaries = await _attendanceService.getAllStudentsAttendanceSummary();
      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => _AllStudentsDialog(summaries: summaries),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================
  // SCHEDULED CLASSES DIALOG
  // ========================================
  Future<void> _showScheduledClasses() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final scheduled = await _scheduleService.getScheduledDates();
      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => _ScheduledClassesDialog(scheduled: scheduled),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================
  // EXPORT FUNCTIONS
  // ========================================
  Future<void> _exportAttendanceCSV() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final summaries = await _attendanceService.getAllStudentsAttendanceSummary();
      if (!mounted) return;
      Navigator.pop(context);

      if (summaries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      // Generate CSV
      final csv = StringBuffer();
      csv.writeln(
          'Reg No,Name,Email,Team,Batch,Present,Absent,Total Days,Percentage');

      for (final student in summaries) {
        csv.writeln(
          '${student.regNo},${student.name},${student.email},${student.teamId ?? ""},${student.batch},${student.presentCount},${student.absentCount},${student.totalWorkingDays},${student.attendancePercentage}',
        );
      }

      await Clipboard.setData(ClipboardData(text: csv.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('CSV data copied (${summaries.length} students)'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _copyAttendanceSummary() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final summaries = await _attendanceService.getAllStudentsAttendanceSummary();
      if (!mounted) return;
      Navigator.pop(context);

      if (summaries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available')),
        );
        return;
      }

      final text = StringBuffer();
      text.writeln('═══════════════════════════════════════════');
      text.writeln('         ATTENDANCE SUMMARY REPORT          ');
      text.writeln('═══════════════════════════════════════════');
      text.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      text.writeln('Total Students: ${summaries.length}');

      final avgPercentage = summaries.fold<double>(
              0, (sum, s) => sum + s.attendancePercentage) /
          summaries.length;
      text.writeln('Overall Average: ${avgPercentage.toStringAsFixed(2)}%');
      text.writeln('───────────────────────────────────────────\n');

      for (var i = 0; i < summaries.length; i++) {
        final student = summaries[i];
        text.writeln('${i + 1}. ${student.name} (${student.regNo})');
        text.writeln('   Team: ${student.teamId ?? "No Team"} | ${student.batch}');
        text.writeln('   Present: ${student.presentCount} | Absent: ${student.absentCount}');
        text.writeln('   Attendance: ${student.attendancePercentage.toStringAsFixed(1)}%');
        text.writeln('');
      }

      await Clipboard.setData(ClipboardData(text: text.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Summary copied (${summaries.length} students)'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}


// ========================================
// LONG ABSENTEES DIALOG
// ========================================
class _LongAbsenteesDialog extends StatefulWidget {
  const _LongAbsenteesDialog();

  @override
  State<_LongAbsenteesDialog> createState() => _LongAbsenteesDialogState();
}

class _LongAbsenteesDialogState extends State<_LongAbsenteesDialog> {
  int _consecutiveDays = 3;
  bool _isLoading = false;
  List<Map<String, dynamic>> _absentees = [];
  bool _hasSearched = false;

  Future<void> _findLongAbsentees() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Get all students
      final students = await supabase
          .from('users')
          .select('id, name, reg_no, email, team_id')
          .eq('roles->>isStudent', 'true')
          .order('reg_no');

      // Get scheduled dates for accurate tracking
      final scheduledDatesResponse = await supabase
          .from('scheduled_attendance_dates')
          .select('date')
          .order('date', ascending: false);

      final scheduledDates = (scheduledDatesResponse as List<dynamic>)
          .map((e) => e['date'] as String)
          .toList();

      if (scheduledDates.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _absentees = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No scheduled attendance dates found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get attendance records for scheduled dates
      final attendanceRecords = await supabase
          .from('attendance_records')
          .select('user_id, date, status')
          .inFilter('date', scheduledDates);

      // Group attendance by user
      final Map<String, Map<String, String>> userAttendance = {};
      for (var record in attendanceRecords) {
        final userId = record['user_id'] as String;
        final date = record['date'] as String;
        final status = record['status'] as String;
        
        userAttendance.putIfAbsent(userId, () => {});
        userAttendance[userId]![date] = status;
      }

      List<Map<String, dynamic>> longAbsentees = [];

      // Check each student for consecutive absences
      for (var student in students) {
        final userId = student['id'] as String;
        final userRecords = userAttendance[userId] ?? {};

        // Count consecutive absences from most recent date
        int currentStreak = 0;
        DateTime? lastAbsentDate;

        for (final dateStr in scheduledDates) {
          final status = userRecords[dateStr];
          
          // If no record or ABSENT, count as absent
          if (status == null || status == 'ABSENT') {
            currentStreak++;
            lastAbsentDate ??= DateTime.parse(dateStr);
          } else if (status == 'PRESENT') {
            // Stop counting when we hit a PRESENT
            break;
          }
        }

        if (currentStreak >= _consecutiveDays) {
          longAbsentees.add({
            'name': student['name'],
            'reg_no': student['reg_no'],
            'email': student['email'],
            'team_id': student['team_id'],
            'consecutive_days': currentStreak,
            'last_absent_date': lastAbsentDate,
          });
        }
      }

      // Sort by consecutive days descending
      longAbsentees.sort((a, b) => 
        (b['consecutive_days'] as int).compareTo(a['consecutive_days'] as int));

      if (mounted) {
        setState(() {
          _absentees = longAbsentees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyAbsenteesData() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('         LONG ABSENTEES REPORT              ');
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('Consecutive Days: $_consecutiveDays+');
    buffer.writeln('Total Found: ${_absentees.length}');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('───────────────────────────────────────────\n');

    for (var i = 0; i < _absentees.length; i++) {
      final absentee = _absentees[i];
      buffer.writeln('${i + 1}. ${absentee['name']} (${absentee['reg_no']})');
      buffer.writeln('   Email: ${absentee['email']}');
      buffer.writeln('   Team: ${absentee['team_id'] ?? 'No Team'}');
      buffer.writeln('   Consecutive Absences: ${absentee['consecutive_days']} days');
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${_absentees.length} absentees copied'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Long Absentees Finder',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Find students with consecutive absences',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Days selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Consecutive Days',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _consecutiveDays > 1
                                ? () => setState(() => _consecutiveDays--)
                                : null,
                            color: colorScheme.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_consecutiveDays',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _consecutiveDays < 30
                                ? () => setState(() => _consecutiveDays++)
                                : null,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _findLongAbsentees,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isLoading ? 'Searching...' : 'Find Long Absentees',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    if (_hasSearched) ...[
                      const SizedBox(height: 20),

                      // Results header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Results (${_absentees.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_absentees.isNotEmpty)
                            TextButton.icon(
                              onPressed: _copyAbsenteesData,
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Results list
                      if (_absentees.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle, size: 48, color: Colors.green[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No Long Absentees Found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No students with $_consecutiveDays+ consecutive absences',
                                style: GoogleFonts.inter(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _absentees.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final absentee = _absentees[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  absentee['name'],
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${absentee['reg_no']} • ${absentee['team_id'] ?? 'No Team'}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${absentee['consecutive_days']} days',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ========================================
// TEAM ANALYSIS DIALOG
// ========================================
class _TeamAnalysisDialog extends StatefulWidget {
  final List<Map<String, dynamic>> teams;
  const _TeamAnalysisDialog({required this.teams});

  @override
  State<_TeamAnalysisDialog> createState() => _TeamAnalysisDialogState();
}

class _TeamAnalysisDialogState extends State<_TeamAnalysisDialog> {
  String _sortBy = 'name'; // 'name', 'percentage', 'size'
  bool _ascending = true;

  List<Map<String, dynamic>> get _sortedTeams {
    final sorted = List<Map<String, dynamic>>.from(widget.teams);
    sorted.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'percentage':
          result = (a['team_attendance_percentage'] as double)
              .compareTo(b['team_attendance_percentage'] as double);
          break;
        case 'size':
          result = (a['team_size'] as int).compareTo(b['team_size'] as int);
          break;
        default:
          result = (a['team_id'] as String).compareTo(b['team_id'] as String);
      }
      return _ascending ? result : -result;
    });
    return sorted;
  }

  void _copyTeamData() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('         TEAM ATTENDANCE ANALYSIS           ');
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('Total Teams: ${widget.teams.length}');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('───────────────────────────────────────────\n');

    for (var i = 0; i < _sortedTeams.length; i++) {
      final team = _sortedTeams[i];
      final percentage = (team['team_attendance_percentage'] as double).toStringAsFixed(1);
      buffer.writeln('${i + 1}. ${team['team_id']}');
      buffer.writeln('   Batch: ${team['batch']}');
      buffer.writeln('   Members: ${team['team_size']}');
      buffer.writeln('   Average Attendance: $percentage%');
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${widget.teams.length} teams copied'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Analysis',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.teams.length} teams',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyTeamData,
                    tooltip: 'Copy Data',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Sort options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  Text(
                    'Sort by:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'name', label: Text('Name')),
                      ButtonSegment(value: 'percentage', label: Text('%')),
                      ButtonSegment(value: 'size', label: Text('Size')),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (value) => setState(() => _sortBy = value.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                    onPressed: () => setState(() => _ascending = !_ascending),
                    tooltip: _ascending ? 'Ascending' : 'Descending',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Team list
            Flexible(
              child: widget.teams.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No Teams Found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'No team data available yet',
                              style: GoogleFonts.inter(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _sortedTeams.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final team = _sortedTeams[index];
                        final percentage = (team['team_attendance_percentage'] as double);
                        final isGood = percentage >= 75;
                        final color = isGood ? Colors.green : Colors.red;

                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                team['team_id'].toString().replaceAll('Team', '').trim(),
                                style: GoogleFonts.inter(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            team['team_id'] ?? 'Unknown',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${team['team_size']} members • ${team['batch']}',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


// ========================================
// ALL STUDENTS DIALOG
// ========================================
class _AllStudentsDialog extends StatefulWidget {
  final List<dynamic> summaries;
  const _AllStudentsDialog({required this.summaries});

  @override
  State<_AllStudentsDialog> createState() => _AllStudentsDialogState();
}

class _AllStudentsDialogState extends State<_AllStudentsDialog> {
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'percentage', 'reg_no'
  bool _ascending = true;

  List<dynamic> get _filteredSortedStudents {
    var list = widget.summaries.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
          s.regNo.toLowerCase().contains(query) ||
          (s.teamId?.toLowerCase().contains(query) ?? false);
    }).toList();

    list.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'percentage':
          result = a.attendancePercentage.compareTo(b.attendancePercentage);
          break;
        case 'reg_no':
          result = a.regNo.compareTo(b.regNo);
          break;
        default:
          result = a.name.compareTo(b.name);
      }
      return _ascending ? result : -result;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final students = _filteredSortedStudents;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Students',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.summaries.length} students',
                          style: GoogleFonts.inter(
                            fontSize: 13,
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
            ),

            // Search and Sort
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, reg no, or team...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Sort by:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'name', label: Text('Name')),
                            ButtonSegment(value: 'percentage', label: Text('Attendance')),
                            ButtonSegment(value: 'reg_no', label: Text('Reg No')),
                          ],
                          selected: {_sortBy},
                          onSelectionChanged: (v) => setState(() => _sortBy = v.first),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 11)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                        onPressed: () => setState(() => _ascending = !_ascending),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Student list
            Flexible(
              child: students.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No students found',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Try a different search term',
                              style: GoogleFonts.inter(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final percentage = student.attendancePercentage;
                        final isGood = percentage >= 75;
                        final color = isGood ? Colors.green : Colors.red;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${student.presentCount}/${student.totalWorkingDays}',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


// ========================================
// SCHEDULED CLASSES DIALOG
// ========================================
class _ScheduledClassesDialog extends StatelessWidget {
  final List<dynamic> scheduled;
  const _ScheduledClassesDialog({required this.scheduled});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = scheduled.where((s) => s.date.isAfter(now)).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_note_rounded, color: Colors.purple, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled Classes',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${scheduled.length} total • ${upcoming.length} upcoming',
                          style: GoogleFonts.inter(
                            fontSize: 13,
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
            ),

            // Content
            Flexible(
              child: scheduled.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No Scheduled Classes',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Add scheduled dates in the Attendance screen',
                              style: GoogleFonts.inter(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: scheduled.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final date = scheduled[index];
                        final dateStr = DateFormat('EEE, MMM dd, yyyy').format(date.date);
                        final isPast = date.date.isBefore(now);

                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (isPast ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPast ? Icons.check_circle : Icons.event,
                              color: isPast ? Colors.green : Colors.blue,
                            ),
                          ),
                          title: Text(
                            dateStr,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            date.notes ?? 'No notes',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isPast ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPast ? 'Completed' : 'Upcoming',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPast ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
