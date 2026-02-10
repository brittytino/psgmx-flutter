import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/app_user.dart';
import '../../services/attendance_schedule_service.dart';
import '../../core/theme/app_dimens.dart';

class DailyAttendanceSheet extends StatefulWidget {
  const DailyAttendanceSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent, // Allow custom styling
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = context.read<UserProvider>().currentUser;
    final provider = context.read<AttendanceProvider>();

    if (_showAllStudents) {
      provider.loadAllUsers();
    } else if (user?.teamId != null) {
      provider.loadTeamMembers(user!.teamId!);
    }
  }

  // Helper to initialize status map when data arrives
  void _ensureStatusMapInitialized(List<AppUser> members) {
    if (_statusMap.isEmpty && members.isNotEmpty) {
      final provider = context.read<AttendanceProvider>();

      for (var m in members) {
        // Use preloaded data if available (for updates), otherwise default to ABSENT
        if (provider.statusMap.containsKey(m.uid)) {
          _statusMap[m.uid] = provider.statusMap[m.uid]!;
        } else {
          _statusMap[m.uid] = 'ABSENT';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg, 
        right: AppSpacing.lg, 
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar (Purely Visual)
          Center(
            child: Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(
                color: theme.dividerColor, 
                borderRadius: BorderRadius.circular(2)
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Attendance",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.pop(), 
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),

          // Rep View Toggle
          if (context.watch<UserProvider>().isPlacementRep) ...[
            Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                 color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min, // Keep compact
                 children: [
                   _buildToggleOption("My Team", !_showAllStudents, () {
                      setState(() {
                        _showAllStudents = false;
                        _statusMap.clear();
                      });
                      _loadData();
                   }),
                   _buildToggleOption("All Students", _showAllStudents, () {
                      setState(() {
                         _showAllStudents = true;
                         _statusMap.clear();
                      });
                      _loadData();
                   }),
                 ],
               ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mark Status",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Consumer<AttendanceProvider>(
                builder: (context, provider, _) { 
                  if (provider.hasSubmittedToday) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () {
                         setState(() {
                             for (var m in provider.teamMembers) {
                                _statusMap[m.uid] = 'PRESENT';
                             }
                         });
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text("Mark All Present"),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }
              )
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // List
          Expanded(
            child: Consumer<AttendanceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.teamMembers.isEmpty) {
                  return Center(
                    child: Text(
                      "No students found.", 
                      style: TextStyle(color: theme.colorScheme.secondary)
                    ),
                  );
                }

                // ALLOW Team Leaders to edit: Removed the return _buildSubmittedView() block
                // which prevented editing if already submitted.
                // Logic: Team Leaders can now see the list and toggle switches even if hasSubmittedToday is true.
                
                // Initialize checks
                _ensureStatusMapInitialized(provider.teamMembers);

                return ListView.builder(
                  itemCount: provider.teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = provider.teamMembers[index];
                    final isPresent = _statusMap[member.uid] == 'PRESENT';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPresent 
                              ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                              : theme.colorScheme.error.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isPresent 
                              ? theme.colorScheme.primaryContainer 
                              : theme.colorScheme.errorContainer,
                          child: Text(
                            member.name.isNotEmpty ? member.name[0] : '?',
                            style: TextStyle(
                              color: isPresent 
                                  ? theme.colorScheme.onPrimaryContainer 
                                  : theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        title: Text(
                          member.name, 
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              member.regNo,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)
                            ),
                            if (member.uid.contains('@')) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "UNREGISTERED",
                                  style: TextStyle(
                                    color: Colors.amber, 
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Transform.scale(
                          scale: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isPresent 
                                      ? theme.colorScheme.primary 
                                      : theme.colorScheme.error).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Switch(
                              value: isPresent,
                              activeTrackColor: theme.colorScheme.primaryContainer,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: theme.colorScheme.error,
                              thumbIcon: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  );
                                }
                                return Icon(
                                  Icons.close_rounded,
                                  color: theme.colorScheme.error,
                                  size: 16,
                                );
                              }),
                              onChanged: (val) {
                                setState(() {
                                  _statusMap[member.uid] = val ? 'PRESENT' : 'ABSENT';
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Submit / Update Button
          Consumer<AttendanceProvider>(
            builder: (context, provider, _) {
              final isSubmitting = provider.isLoading; // Use isLoading or add dedicated flag

              return FilledButton(
                onPressed: isSubmitting ? null : () => _submit(context, provider),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  provider.hasSubmittedToday ? "UPDATE ATTENDANCE" : "SUBMIT ATTENDANCE",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10), // Taller touch target
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, AttendanceProvider provider) async {
    final user = context.read<UserProvider>().currentUser;
    final isRep = context.read<UserProvider>().isPlacementRep;
    
    if (!isRep && user?.teamId == null) return;

    // Check if today is scheduled for team leaders
    if (!isRep) {
      final scheduleService = AttendanceScheduleService();
      final isTodayScheduled = await scheduleService.isDateScheduled(DateTime.now());
      
      if (!isTodayScheduled) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("No Class Today"),
              content: const Text(
                "Attendance marking is only available on scheduled class dates. "
                "Please contact the placement rep if you believe this is an error."
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    // Validation checks
    final absentCount = _statusMap.values.where((s) => s == 'ABSENT').length;
    final total = provider.teamMembers.length;

    if (!context.mounted) return;

    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Submission"),
        content: Text("Marking $absentCount out of $total students as ABSENT.\n\nThis cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Confirm")
          ),
        ],
      )
    );

    if (confirm != true) return;
    
    try {
      await provider.submitAttendance(
        user?.teamId, // Can be null for Reps
        _statusMap,
        isRep: isRep
      );
      if (context.mounted) {
        if (!isRep) {
          context.pop(); // Close for TLs
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance Submitted ✅")));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes Saved ✅")));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
