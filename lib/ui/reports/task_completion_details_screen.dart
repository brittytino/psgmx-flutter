import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/task_completion.dart';
import '../../services/task_completion_service.dart';

class TaskCompletionDetailsScreen extends StatefulWidget {
  const TaskCompletionDetailsScreen({super.key});

  @override
  State<TaskCompletionDetailsScreen> createState() =>
      _TaskCompletionDetailsScreenState();
}

class _TaskCompletionDetailsScreenState
    extends State<TaskCompletionDetailsScreen> {
  late TaskCompletionService _taskService;
  List<UserTaskStatus> _allTasks = [];
  List<UserTaskStatus> _filteredTasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, completed, verified, pending

  @override
  void initState() {
    super.initState();
    _taskService = TaskCompletionService();
    _loadTaskCompletions();
  }

  Future<void> _loadTaskCompletions() async {
    setState(() => _isLoading = true);
    try {
      final completions = await _taskService.getAllStudentCompletions(DateTime.now());
      
      if (mounted) {
        setState(() {
          _allTasks = completions;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task completions: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    _filteredTasks = _allTasks.where((task) {
      switch (_selectedFilter) {
        case 'completed':
          return task.completed;
        case 'verified':
          return task.verifiedByName != null;
        case 'pending':
          return !task.completed;
        default:
          return true; // all
      }
    }).toList();

    // Sort by date descending - use verifiedAt if available, else current date
    _filteredTasks.sort((a, b) {
      final dateA = a.verifiedAt ?? DateTime.now();
      final dateB = b.verifiedAt ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Completions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ('all', 'All', Icons.all_inclusive),
                  ('completed', 'Completed', Icons.check_circle),
                  ('verified', 'Verified', Icons.verified),
                  ('pending', 'Pending', Icons.pending_actions),
                ]
                    .map((filter) {
                      final isSelected = _selectedFilter == filter.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          avatar: Icon(
                            filter.$3,
                            size: 18,
                          ),
                          label: Text(
                            filter.$2,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter.$1;
                              _applyFilter();
                            });
                          },
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),

          // Tasks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 80,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'for this filter',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTaskCompletions,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          final isCompleted = task.completed;
                          final isVerified = task.verifiedByName != null;

                          Color statusColor;
                          IconData statusIcon;

                          if (isVerified) {
                            statusColor = Colors.green;
                            statusIcon = Icons.verified;
                          } else if (isCompleted) {
                            statusColor = Colors.blue;
                            statusIcon = Icons.check_circle;
                          } else {
                            statusColor = Colors.orange;
                            statusIcon = Icons.pending_actions;
                          }

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Today',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          statusIcon,
                                          color: statusColor,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Verification info if verified
                                  if (isVerified) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.05),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.md),
                                        border: Border.all(
                                          color: Colors.green.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.verified_user,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              'Verified by ${task.verifiedByName}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
