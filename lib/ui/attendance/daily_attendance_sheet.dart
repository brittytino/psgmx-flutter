import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_dimens.dart';

class DailyAttendanceSheet extends StatefulWidget {
  const DailyAttendanceSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const DailyAttendanceSheet(),
    );
  }

  @override
  State<DailyAttendanceSheet> createState() => _DailyAttendanceSheetState();
}

class _DailyAttendanceSheetState extends State<DailyAttendanceSheet> {
  final Map<String, String> _statusMap = {};
  bool _showAllStudents = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      final provider = context.read<AttendanceProvider>();
      
      if (_showAllStudents) {
         provider.loadAllUsers();
      } else if (user?.teamId != null) {
         provider.loadTeamMembers(user!.teamId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Attendance",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (context.watch<UserProvider>().isPlacementRep) ...[
            Row(
              children: [
                const Text("View: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text("My Team")),
                    ButtonSegment(value: true, label: Text("All Students")),
                  ],
                  selected: {_showAllStudents},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _showAllStudents = newSelection.first;
                      _statusMap.clear(); // Clear local changes when switching
                    });
                    _loadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            "Mark attendance for today. This can only be submitted once.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Expanded(
            child: Consumer<AttendanceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.hasSubmittedToday) return _buildSubmittedView();
                
                // Initialize map if empty
                if (_statusMap.isEmpty && provider.teamMembers.isNotEmpty) {
                  for (var m in provider.teamMembers) {
                    _statusMap[m.uid] = 'PRESENT';
                  }
                }

                return ListView.separated(
                  itemCount: provider.teamMembers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = provider.teamMembers[index];
                    final isPresent = _statusMap[member.uid] == 'PRESENT';
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        child: Text(member.name[0], style: TextStyle(color: isPresent ? Colors.green : Colors.red)),
                      ),
                      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(member.regNo),
                      trailing: Switch(
                        value: isPresent,
                        activeTrackColor: Colors.green,
                        activeThumbColor: Colors.white,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withValues(alpha: 0.2),
                        onChanged: (val) {
                          setState(() {
                            _statusMap[member.uid] = val ? 'PRESENT' : 'ABSENT';
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          Consumer<AttendanceProvider>(
            builder: (context, provider, _) {
              if (provider.hasSubmittedToday) return const SizedBox.shrink();
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submit(context, provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("SUBMIT ATTENDANCE"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text("All Caught Up!", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text("Attendance for today has been submitted."),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, AttendanceProvider provider) async {
    // Show confirmation dialog logic here
    final user = context.read<UserProvider>().currentUser;
    final isRep = context.read<UserProvider>().isPlacementRep;
    
    // Allow Rep to submit without teamId in All Students mode
    if (!isRep && user?.teamId == null) return;
    
    try {
      await provider.submitAttendance(
        user?.teamId, // Can be null for Reps
        _statusMap,
        isRep: isRep
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance Updated Successfully")));
        if (!isRep) {
          context.pop(); // Close for TLs
        } else {
           // For Reps, maybe refresh data or show success
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved. You can continue editing.")));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
