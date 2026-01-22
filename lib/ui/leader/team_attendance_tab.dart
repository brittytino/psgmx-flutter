import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';
import '../../models/task_attendance.dart';

class TeamAttendanceTab extends StatefulWidget {
  const TeamAttendanceTab({super.key});

  @override
  State<TeamAttendanceTab> createState() => _TeamAttendanceTabState();
}

class _TeamAttendanceTabState extends State<TeamAttendanceTab> {
  bool _isLoading = true;
  bool _isSubmitted = false;
  List<AppUser> _members = [];
  final Map<String, bool> _attendanceMap = {}; // uid -> isPresent

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    final firestore = Provider.of<SupabaseDbService>(context, listen: false);
    
    if (user?.teamId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Check if locked time passed (8 PM IST)
    // IST is +5:30. 20:00.
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final lockTime = DateTime(now.year, now.month, now.day, 20, 0);
    
    final alreadySubmitted = await firestore.isAttendanceSubmitted(user!.teamId!, today);

    if (now.isAfter(lockTime) || alreadySubmitted) {
      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isLoading = false;
        });
      }
      return;
    }

    final members = await firestore.getTeamMembers(user.teamId!);
    if (mounted) {
      setState(() {
        _members = members;
        for (var m in members) {
          _attendanceMap[m.uid] = true; // Default to present
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    final firestore = Provider.of<SupabaseDbService>(context, listen: false);
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      setState(() => _isLoading = true);

      // Construct records
      List<AttendanceRecord> records = _members.map((m) {
        return AttendanceRecord(
          id: 'temp', 
          date: today,
          studentUid: m.uid,
          regNo: m.regNo,
          teamId: user!.teamId!,
          isPresent: _attendanceMap[m.uid] ?? false,
          timestamp: DateTime.now(),
          markedBy: user.uid,
        );
      }).toList();

      await firestore.submitTeamAttendance(user!.teamId!, today, user.uid, records);
      
      if (mounted) {
        setState(() {
           _isSubmitted = true;
           _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Submitted!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    final user = Provider.of<UserProvider>(context).currentUser;
    if (user?.teamId == null) return const Center(child: Text("You are not assigned to a team."));

    if (_isSubmitted) {
      // Show summary or simple "Locked" message
      // Ideally show what was submitted if we fetched it, but for now:
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Attendance Locked or Already Submitted for today.", style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Mark Attendance - Team ${user!.teamId}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return CheckboxListTile(
                title: Text(member.name),
                subtitle: Text(member.regNo),
                value: _attendanceMap[member.uid],
                onChanged: (val) {
                  setState(() {
                    _attendanceMap[member.uid] = val ?? false;
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text("Final Submit (Cannot Undo)"),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
          child: Text(
            "WARNING: Once submitted, you CANNOT edit this. The list is final for the day. Ensure all absentees are marked correctly before clicking.", 
            style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }
}
