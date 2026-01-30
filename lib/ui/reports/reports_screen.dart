import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_db_service.dart';
import '../../services/notification_service.dart';
import '../../services/connectivity_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/notification_bell_icon.dart';
import '../widgets/offline_error_view.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<SupabaseDbService>(context, listen: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text("Analytics & Reports"),
            pinned: true,
            floating: true,
            actions: [
              Consumer<NotificationService>(
                builder: (context, notifService, _) => FutureBuilder<List<dynamic>>(
                  future: notifService.getNotifications(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data?.where((n) => n.isRead != true).length ?? 0;
                    return NotificationBellIcon(unreadCount: unreadCount);
                  },
                ),
              ),
            ],
          ),
          
          SliverPadding(
             padding: const EdgeInsets.all(AppSpacing.screenPadding),
             sliver: SliverToBoxAdapter(
               child: FutureBuilder<Map<String, dynamic>>(
                  future: db.getPlacementStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: Padding(
                         padding: EdgeInsets.all(AppSpacing.xl),
                         child: CircularProgressIndicator(),
                       ));
                    }
                    if (snapshot.hasError) {
                       // Check if it's a connection error
                       final isOffline = !ConnectivityService().hasConnection;
                       if (isOffline) {
                         return OfflineErrorView(
                           title: 'Unable to Load Reports',
                           message: 'Connect to the internet to view analytics and reports',
                           onRetry: () {
                             // Trigger rebuild
                             (context as Element).markNeedsBuild();
                           },
                         );
                       }
                       
                       return PremiumEmptyState(
                         icon: Icons.error_outline, 
                         message: "Data Error",
                         subMessage: snapshot.error.toString()
                       );
                    }
                    
                    final data = snapshot.data!;
                    final total = data['total_students'] as int;
                    final present = data['today_present'] as int;
                    final percent = total > 0 ? (present / total) : 0.0;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Summary Section
                         _SummaryPremiumCard(total: total, present: present, percent: percent),
                         
                         const SizedBox(height: AppSpacing.xxl),
                         
                         // Actions Section
                         Text(
                           "QUICK ACTIONS", 
                           style: Theme.of(context).textTheme.labelSmall?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: Theme.of(context).colorScheme.primary,
                             letterSpacing: 1.2
                           )
                         ),
                         const SizedBox(height: AppSpacing.md),
                         
                         PremiumCard(
                           padding: EdgeInsets.zero,
                           child: Column(
                             children: [
                               _ActionListTile(
                                 icon: Icons.warning_amber_rounded,
                                 title: "Long Absentees",
                                 subtitle: "Find students with consecutive absences",
                                 onTap: () => _showLongAbsenteesDialog(context),
                               ),
                               const Divider(height: 1),
                               _ActionListTile(
                                 icon: Icons.table_chart_outlined,
                                 title: "Attendance Report",
                                 subtitle: "View detailed summary",
                                 onTap: () => _viewAttendanceReport(context),
                               ),

                             ],
                           ),
                         )
                      ],
                    );
                  }
                ),
             ),
          )
        ],
      ),
    );
  }
}

Future<void> _showLongAbsenteesDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (ctx) => _LongAbsenteesDialog(),
  );
}

Future<void> _viewAttendanceReport(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('student_attendance_summary')
        .select()
        .order('attendance_percentage', ascending: false);
    final data = res as List<dynamic>;

    if (!context.mounted) return;
    Navigator.pop(context);

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records found.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _AttendanceReportDialog(data: data),
    );
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

class _AttendanceReportDialog extends StatefulWidget {
  final List<dynamic> data;

  const _AttendanceReportDialog({required this.data});

  @override
  State<_AttendanceReportDialog> createState() => _AttendanceReportDialogState();
}

class _AttendanceReportDialogState extends State<_AttendanceReportDialog> {
  String _exportFormat = 'csv'; // 'csv' or 'text'

  String _generateCSV() {
    const header = "Name,Register No,Batch,Present,Absent,Total Working,Percentage\n";
    final rows = widget.data.map((e) {
      final present = e['present_count'] ?? 0;
      final absent = e['absent_count'] ?? 0;
      return "${e['name']},${e['reg_no']},${e['batch']},$present,$absent,${present + absent},${e['attendance_percentage']}%";
    }).join("\n");
    return "$header$rows";
  }

  String _generateText() {
    final buffer = StringBuffer();
    buffer.writeln("ATTENDANCE SUMMARY REPORT");
    buffer.writeln("=" * 80);
    buffer.writeln("");

    for (var i = 0; i < widget.data.length; i++) {
      final e = widget.data[i];
      final present = e['present_count'] ?? 0;
      final absent = e['absent_count'] ?? 0;
      final total = present + absent;
      final percentage = e['attendance_percentage'];

      buffer.writeln("${i + 1}. ${e['name']} (${e['reg_no']})");
      buffer.writeln("   Batch: ${e['batch']}");
      buffer.writeln("   Present: $present | Absent: $absent | Total: $total");
      buffer.writeln("   Percentage: $percentage%");
      buffer.writeln("");
    }

    return buffer.toString();
  }

  void _copyToClipboard() {
    final content = _exportFormat == 'csv' ? _generateCSV() : _generateText();
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${_exportFormat.toUpperCase()} copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_chart, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Attendance Summary",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${widget.data.length} students",
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

            const SizedBox(height: AppSpacing.lg),

            // Export format selector
            Row(
              children: [
                Text(
                  'Export Format:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'csv',
                      label: Text('CSV'),
                      icon: Icon(Icons.table_chart, size: 16),
                    ),
                    ButtonSegment(
                      value: 'text',
                      label: Text('Text'),
                      icon: Icon(Icons.text_snippet, size: 16),
                    ),
                  ],
                  selected: {_exportFormat},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _exportFormat = newSelection.first;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Content preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SelectableText(
                    _exportFormat == 'csv' ? _generateCSV() : _generateText(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text('Copy ${_exportFormat.toUpperCase()}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPremiumCard extends StatelessWidget {
  final int total;
  final int present;
  final double percent;

  const _SummaryPremiumCard({required this.total, required this.present, required this.percent});

  @override
  Widget build(BuildContext context) {
     return PremiumCard(
       color: Theme.of(context).colorScheme.primary, // Dark blue background
       padding: const EdgeInsets.all(AppSpacing.lg),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm)
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.white, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "Today's Overview", 
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9), 
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5
                  )
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Expanded(child: _Metric(label: "Total Students", value: total.toString())),
                 Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                 Expanded(child: _Metric(label: "Present", value: present.toString())),
                 Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                 Expanded(child: _Metric(label: "Attendance", value: "${(percent * 100).toStringAsFixed(0)}%")),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                color: Colors.white,
              ),
            )
         ],
       ),
     );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
     return Column(
       children: [
          Text(
            value, 
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            )
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10, 
              color: Colors.white.withValues(alpha: 0.7)
            )
          ),
       ],
     );
  }
}

class _ActionListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionListTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.outline),
      onTap: onTap,
    );
  }
}

// ========================================
// LONG ABSENTEES DIALOG
// ========================================
class _LongAbsenteesDialog extends StatefulWidget {
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
      
      // Get all students with their attendance records
      final students = await supabase
          .from('users')
          .select('id, name, reg_no, email')
          .eq('roles->>isStudent', 'true')
          .order('reg_no');

      List<Map<String, dynamic>> longAbsentees = [];

      // Get attendance records for the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final attendanceRecords = await supabase
          .from('attendance_records')
          .select('user_id, date, status')
          .gte('date', thirtyDaysAgo.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      // Group attendance by user
      Map<String, List<Map<String, dynamic>>> userAttendance = {};
      for (var record in attendanceRecords) {
        final userId = record['user_id'];
        if (!userAttendance.containsKey(userId)) {
          userAttendance[userId] = [];
        }
        userAttendance[userId]!.add(record);
      }

      // Check each student for consecutive absences
      for (var student in students) {
        final userId = student['id'];
        final records = userAttendance[userId] ?? [];
        
        if (records.isEmpty) continue;

        // Sort by date descending
        records.sort((a, b) => b['date'].compareTo(a['date']));

        int consecutiveAbsent = 0;
        int maxConsecutive = 0;
        DateTime? lastAbsentDate;

        for (var record in records) {
          if (record['status'] == 'ABSENT') {
            consecutiveAbsent++;
            if (consecutiveAbsent > maxConsecutive) {
              maxConsecutive = consecutiveAbsent;
              lastAbsentDate = DateTime.parse(record['date']);
            }
          } else if (record['status'] == 'PRESENT') {
            consecutiveAbsent = 0;
          }
        }

        if (maxConsecutive >= _consecutiveDays) {
          longAbsentees.add({
            'name': student['name'],
            'reg_no': student['reg_no'],
            'email': student['email'],
            'consecutive_days': maxConsecutive,
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Long Absentees Finder",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Find students with consecutive absences",
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

            const SizedBox(height: AppSpacing.lg),

            // Days selector
            Row(
              children: [
                Text(
                  'Consecutive Days:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _consecutiveDays > 1
                            ? () => setState(() => _consecutiveDays--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_consecutiveDays',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _consecutiveDays < 30
                            ? () => setState(() => _consecutiveDays++)
                            : null,
                      ),
                      Text(
                        'days',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _findLongAbsentees,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Searching...' : 'Find Long Absentees'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Results
            if (_hasSearched) ...[
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
                      onPressed: () => _copyAbsenteesData(),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy List'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Results list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasSearched
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Select days and click search',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _absentees.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No students found!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No students with $_consecutiveDays+ consecutive absences',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.separated(
                                itemCount: _absentees.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final absentee = _absentees[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                                      child: Text(
                                        absentee['name'][0].toUpperCase(),
                                        style: const TextStyle(
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
                                      '${absentee['reg_no']} • ${absentee['email']}',
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
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
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAbsenteesData() {
    final buffer = StringBuffer();
    buffer.writeln('LONG ABSENTEES REPORT');
    buffer.writeln('Consecutive Days: $_consecutiveDays+');
    buffer.writeln('Total Found: ${_absentees.length}');
    buffer.writeln('=' * 80);
    buffer.writeln();

    for (var i = 0; i < _absentees.length; i++) {
      final absentee = _absentees[i];
      buffer.writeln('${i + 1}. ${absentee['name']} (${absentee['reg_no']})');
      buffer.writeln('   Email: ${absentee['email']}');
      buffer.writeln('   Consecutive Absences: ${absentee['consecutive_days']} days');
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('List copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
