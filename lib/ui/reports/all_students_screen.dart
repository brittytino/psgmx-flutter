import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  late AttendanceService _attendanceService;
  List<AttendanceSummary> _students = [];
  List<AttendanceSummary> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _attendanceFilter = 0;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _attendanceService.getAllStudentsAttendanceSummary();

      if (mounted) {
        setState(() {
          _students = stats;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredStudents = _students.where((student) {
      final name = student.name.toLowerCase();
      final attendance = student.attendancePercentage;
      
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesAttendance = attendance >= _attendanceFilter;

      return matchesSearch && matchesAttendance;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Students',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    hintStyle: GoogleFonts.inter(fontSize: 14),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Attendance filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [0, 50, 75, 90, 100].map((threshold) {
                      final isSelected = _attendanceFilter == threshold.toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(
                            threshold == 0 ? 'All' : '${threshold}%+',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _attendanceFilter = selected ? threshold.toDouble() : 0;
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Student list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No students found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final attendance = student.attendancePercentage;
                            final name = student.name;
                            final regNo = student.regNo;

                            Color attendanceColor;
                            if (attendance >= 75) {
                              attendanceColor = Colors.green;
                            } else if (attendance >= 60) {
                              attendanceColor = Colors.orange;
                            } else {
                              attendanceColor = Colors.red;
                            }

                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.all(AppSpacing.md),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      attendanceColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: attendanceColor,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  regNo,
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: attendanceColor.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Text(
                                    '${attendance.toStringAsFixed(1)}%',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: attendanceColor,
                                    ),
                                  ),
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
