import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/attendance_service.dart';
import '../../services/enhanced_auth_service.dart';
import '../../models/attendance.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  bool _isLoading = false;
  List<AttendanceSummary> _allStudents = [];
  Map<String, double> _batchSummary = {};
  String _filterBatch = 'ALL';
  String _filterTeam = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = context.read<AttendanceService>();

      final students = await attendanceService.getAllStudentsAttendanceSummary();
      final batchSummary = await attendanceService.getBatchAttendanceSummary();

      setState(() {
        _allStudents = students;
        _batchSummary = batchSummary;
      });
    } catch (e) {
      _showError('Failed to load analytics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<EnhancedAuthService>();
    final user = authService.effectiveUser;

    if (user == null || !user.isPlacementRep) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(
          child: Text('Only Placement Reps can view analytics'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _buildStudentList(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final totalStudents = _allStudents.length;
    final avgAttendance = totalStudents > 0
        ? _allStudents
                .map((s) => s.attendancePercentage)
                .reduce((a, b) => a + b) /
            totalStudents
        : 0.0;

    final criticalStudents =
        _allStudents.where((s) => s.attendancePercentage < 75).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Avg Attendance',
                value: '${avgAttendance.toStringAsFixed(1)}%',
                icon: Icons.analytics,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Critical (<75%)',
                value: criticalStudents.toString(),
                icon: Icons.warning,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'G1 Average',
                value: '${(_batchSummary['G1'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.group,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'G2 Average',
                value: '${(_batchSummary['G2'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.group,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Batch',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: _filterBatch,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Batches')),
                      DropdownMenuItem(value: 'G1', child: Text('G1')),
                      DropdownMenuItem(value: 'G2', child: Text('G2')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterBatch = value ?? 'ALL';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Team',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: _filterTeam,
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Teams')),
                      ...List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          value: 'Team${i + 1}',
                          child: Text('Team${i + 1}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterTeam = value ?? 'ALL';
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filteredStudents = _allStudents.where((s) {
      if (_filterBatch != 'ALL' && s.batch != _filterBatch) return false;
      if (_filterTeam != 'ALL' && s.teamId != _filterTeam) return false;
      return true;
    }).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Student Attendance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${filteredStudents.length} students',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredStudents.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return _buildStudentTile(student);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(AttendanceSummary student) {
    final color = _getColorForPercentage(student.attendancePercentage);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          student.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(student.name),
      subtitle: Text('${student.regNo} • ${student.teamId ?? "No Team"}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${student.attendancePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            '${student.presentCount}/${student.totalWorkingDays}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      onTap: () => _showStudentDetails(student),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  void _showStudentDetails(AttendanceSummary student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Reg No:', student.regNo),
            _buildDetailRow('Email:', student.email),
            _buildDetailRow('Team:', student.teamId ?? 'No Team'),
            _buildDetailRow('Batch:', student.batch),
            const Divider(),
            _buildDetailRow('Present:', student.presentCount.toString()),
            _buildDetailRow('Absent:', student.absentCount.toString()),
            _buildDetailRow('Total Days:', student.totalWorkingDays.toString()),
            _buildDetailRow(
              'Percentage:',
              '${student.attendancePercentage.toStringAsFixed(2)}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to detailed attendance history
            },
            child: const Text('View History'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
