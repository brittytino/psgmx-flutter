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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Analytics & Reports'),
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
                    _buildStatsOverview(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildExportSection(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalStudents = _stats['total_students'] ?? 0;
    final todayPresent = _stats['today_present'] ?? 0;
    final avgPercentage = _stats['avg_percentage'] ?? 0.0;
    final scheduledClasses = _stats['scheduled_classes'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERVIEW',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Students',
                totalStudents.toString(),
                Icons.group,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Scheduled Classes',
                scheduledClasses.toString(),
                Icons.event,
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
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Avg Attendance',
                '${avgPercentage.toStringAsFixed(1)}%',
                Icons.trending_up,
                avgPercentage >= 75 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
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
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActionTile(
                'View All Students',
                'See complete attendance records',
                Icons.people_alt_outlined,
                Colors.blue,
                () => _showAllStudents(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'View by Team',
                'Team-wise attendance analysis',
                Icons.groups_outlined,
                Colors.green,
                () => _showTeamAnalysis(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'Scheduled Classes',
                'View all scheduled dates',
                Icons.event_note_outlined,
                Colors.purple,
                () => _showScheduledClasses(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATA EXPORT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActionTile(
                'Export Attendance CSV',
                'Download complete attendance data',
                Icons.table_chart_outlined,
                Colors.orange,
                () => _exportAttendanceCSV(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                'Copy Attendance Summary',
                'Copy formatted text to clipboard',
                Icons.copy_outlined,
                Colors.teal,
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

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
        builder: (context) => AlertDialog(
          title: Text('All Students (${summaries.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final student = summaries[index];
                final color =
                    student.attendancePercentage >= 75 ? Colors.green : Colors.red;

                return ListTile(
                  title: Text(student.name),
                  subtitle: Text('${student.regNo} - ${student.teamId ?? "No Team"}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${student.attendancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${student.presentCount}/${student.totalWorkingDays}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showTeamAnalysis() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _supabase.from('team_attendance_summary').select();
      if (!mounted) return;
      Navigator.pop(context);

      final teams = response as List<dynamic>;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Team Analysis (${teams.length} teams)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final percentage = (team['team_attendance_percentage'] ?? 0.0).toDouble();
                final color = percentage >= 75 ? Colors.green : Colors.red;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(
                      team['team_id']?.toString().substring(4) ?? '?',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(team['team_id'] ?? 'Unknown'),
                  subtitle: Text('${team['team_size']} students - ${team['batch']}'),
                  trailing: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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
        builder: (context) => AlertDialog(
          title: Text('Scheduled Classes (${scheduled.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: scheduled.length,
              itemBuilder: (context, index) {
                final date = scheduled[index];
                final dateStr = DateFormat('MMM dd, yyyy').format(date.date);
                final isPast = date.date.isBefore(DateTime.now());

                return ListTile(
                  leading: Icon(
                    isPast ? Icons.check_circle : Icons.event,
                    color: isPast ? Colors.green : Colors.blue,
                  ),
                  title: Text(dateStr),
                  subtitle: Text(date.notes ?? 'No notes'),
                  trailing: Text(
                    isPast ? 'Completed' : 'Upcoming',
                    style: TextStyle(
                      color: isPast ? Colors.green : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: csv.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV data copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

      // Generate formatted text
      final text = StringBuffer();
      text.writeln('=== ATTENDANCE SUMMARY ===');
      text.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      text.writeln('Total Students: ${summaries.length}\n');

      final avgPercentage = summaries.fold<double>(
              0, (sum, s) => sum + s.attendancePercentage) /
          summaries.length;
      text.writeln('Overall Average: ${avgPercentage.toStringAsFixed(2)}%\n');

      text.writeln('--- INDIVIDUAL RECORDS ---');
      for (final student in summaries) {
        text.writeln(
          '${student.regNo} | ${student.name} | ${student.teamId ?? "No Team"} | ${student.presentCount}/${student.totalWorkingDays} (${student.attendancePercentage.toStringAsFixed(1)}%)',
        );
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: text.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
