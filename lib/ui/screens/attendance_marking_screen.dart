import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/attendance_service.dart';
import '../../services/enhanced_auth_service.dart';
import '../../models/attendance.dart';
import '../../models/app_user.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  const AttendanceMarkingScreen({super.key});

  @override
  State<AttendanceMarkingScreen> createState() =>
      _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  final Map<String, AttendanceStatus> _attendanceMap = {};
  bool _isLoading = false;
  bool _hasMarked = false;
  DateTime _selectedDate = DateTime.now();
  List<AppUser> _teamMembers = [];

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
      final authService = context.read<EnhancedAuthService>();
      final attendanceService = context.read<AttendanceService>();
      final user = authService.effectiveUser!;

      // Load team members
      _teamMembers = await authService.getUsersByTeam(user.teamId!);

      // Check if attendance already marked
      final existingAttendance =
          await attendanceService.getTeamAttendanceForDate(
        teamId: user.teamId!,
        date: _selectedDate,
      );

      if (existingAttendance.isNotEmpty) {
        setState(() {
          _hasMarked = true;
          for (final record in existingAttendance) {
            _attendanceMap[record.studentId] = record.status;
          }
        });
      } else {
        // Initialize all as present by default
        for (final member in _teamMembers) {
          _attendanceMap[member.uid] = AttendanceStatus.present;
        }
      }
    } catch (e) {
      _showError('Failed to load data: $e');
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

    if (user == null || !user.isTeamLeader) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: const Center(
          child: Text('Only Team Leaders can mark attendance'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildAttendanceList(),
                ),
                _buildActionBar(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_hasMarked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Attendance already marked'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: _teamMembers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final member = _teamMembers[index];
        final status = _attendanceMap[member.uid] ?? AttendanceStatus.present;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(status),
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(member.name),
            subtitle: Text(member.regNo),
            trailing: _hasMarked
                ? Chip(
                    label: Text(status.displayName),
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  )
                : SegmentedButton<AttendanceStatus>(
                    segments: const [
                      ButtonSegment(
                        value: AttendanceStatus.present,
                        label: Text('P'),
                      ),
                      ButtonSegment(
                        value: AttendanceStatus.absent,
                        label: Text('A'),
                      ),
                    ],
                    selected: {status},
                    onSelectionChanged: (Set<AttendanceStatus> newSelection) {
                      setState(() {
                        _attendanceMap[member.uid] = newSelection.first;
                      });
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar() {
    if (_hasMarked) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Present: ${_getPresentCount()} / ${_teamMembers.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _submitAttendance,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.na:
        return Colors.grey;
    }
  }

  int _getPresentCount() {
    return _attendanceMap.values
        .where((s) => s == AttendanceStatus.present)
        .length;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _attendanceMap.clear();
        _hasMarked = false;
      });
      _loadData();
    }
  }

  Future<void> _submitAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: const Text(
          'Once submitted, attendance cannot be edited. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<EnhancedAuthService>();
      final attendanceService = context.read<AttendanceService>();
      final user = authService.effectiveUser!;

      final studentStatuses = _attendanceMap.entries.map((entry) {
        return {
          'student_id': entry.key,
          'team_id': user.teamId!,
          'status': entry.value.displayName,
        };
      }).toList();

      await attendanceService.markAttendance(
        date: _selectedDate,
        studentStatuses: studentStatuses,
        markedBy: user.uid,
      );

      setState(() {
        _hasMarked = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to submit attendance: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
