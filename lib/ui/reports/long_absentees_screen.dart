import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_dimens.dart';

class LongAbsenteesScreen extends StatefulWidget {
  const LongAbsenteesScreen({super.key});

  @override
  State<LongAbsenteesScreen> createState() => _LongAbsenteesScreenState();
}

class _LongAbsenteesScreenState extends State<LongAbsenteesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _absentees = [];
  bool _isLoading = true;
  int _absentDaysFilter = 5;

  @override
  void initState() {
    super.initState();
    _loadAbsentees();
  }

  Future<void> _loadAbsentees() async {
    setState(() => _isLoading = true);
    try {
      // Query attendance records to find students with consecutive absences
      final response = await _supabase
          .from('attendance_records')
          .select('user_id, date, status')
          .eq('status', 'ABSENT')
          .order('date', ascending: false);

      final absenceRecords = response as List;
      
      // Group by user_id and calculate consecutive absences
      final Map<String, int> consecutiveAbsences = {};
      final Map<String, Map<String, dynamic>> studentInfo = {};

      // First, get all student info
      final studentResponse = await _supabase
          .from('users')
          .select('id, name, reg_no, team_id')
          .eq('roles->>isStudent', 'true');

      for (var student in studentResponse as List) {
        studentInfo[student['id']] = student;
      }

      // Calculate consecutive absences for each student
      for (var record in absenceRecords) {
        final userId = record['user_id'];
        consecutiveAbsences[userId] = (consecutiveAbsences[userId] ?? 0) + 1;
      }

      // Build final list
      final absenteesList = <Map<String, dynamic>>[];
      for (var entry in consecutiveAbsences.entries) {
        if (entry.value >= _absentDaysFilter && studentInfo.containsKey(entry.key)) {
          final student = studentInfo[entry.key]!;
          absenteesList.add({
            ...student,
            'absence_count': entry.value,
          });
        }
      }

      // Sort by absence count descending
      absenteesList.sort((a, b) => b['absence_count'].compareTo(a['absence_count']));

      if (mounted) {
        setState(() {
          _absentees = absenteesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading absentees: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Long Absentees',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _absentees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.green.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No long absentees',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All students have good attendance!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter Section
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Absent for at least:',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            DropdownButton<int>(
                              value: _absentDaysFilter,
                              underline: const SizedBox(),
                              items: [3, 5, 7, 10, 14].map((days) {
                                return DropdownMenuItem(
                                  value: days,
                                  child: Text('$days days'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _absentDaysFilter = value);
                                  _loadAbsentees();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: _absentees.length,
                        itemBuilder: (context, index) {
                          final student = _absentees[index];
                          final absenceCount = student['absence_count'] as int;
                          final severity = absenceCount > 10
                              ? 'Critical'
                              : (absenceCount > 7 ? 'High' : 'Moderate');
                          final color = absenceCount > 10
                              ? Colors.red
                              : (absenceCount > 7 ? Colors.orange : Colors.amber);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(AppSpacing.md),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                student['name'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${student['reg_no']} • Team ${student['team_id'] ?? "N/A"}',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$absenceCount days',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      severity,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
