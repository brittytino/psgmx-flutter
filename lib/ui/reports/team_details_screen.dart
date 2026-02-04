import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  late AttendanceService _attendanceService;
  List<AttendanceSummary> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await _attendanceService.getTeamAttendanceSummary(
        teamId: widget.teamId,
      );

      if (mounted) {
        setState(() {
          _teamMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team members: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate team statistics
    final totalMembers = _teamMembers.length;
    final avgAttendance = _teamMembers.isEmpty
        ? 0.0
        : _teamMembers.fold<double>(0, (sum, m) => sum + m.attendancePercentage) /
            _teamMembers.length;
    final presentMembers =
        _teamMembers.where((m) => m.attendancePercentage >= 75).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.teamName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Team Summary Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Main stats card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withValues(alpha: 0.1),
                                Colors.blue.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              // Average Attendance
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Team Attendance',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${avgAttendance.toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: avgAttendance >= 75
                                              ? Colors.green
                                              : (avgAttendance >= 60
                                                  ? Colors.orange
                                                  : Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.groups,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatTile(
                                      'Members',
                                      '$totalMembers',
                                      Icons.people,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _buildStatTile(
                                      'Good Attendance',
                                      '$presentMembers',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _buildStatTile(
                                      'At Risk',
                                      '${totalMembers - presentMembers}',
                                      Icons.warning,
                                      Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Section header
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Team Members',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Members list
                _teamMembers.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
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
                                'No members in this team',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        sliver: SliverList.builder(
                          itemCount: _teamMembers.length,
                          itemBuilder: (context, index) {
                            final member = _teamMembers[index];
                            final attendance = member.attendancePercentage;

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
                                  child: Text(
                                    member.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: attendanceColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  member.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${member.regNo} • ${member.presentCount}/${member.totalWorkingDays} days',
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
              ],
            ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
