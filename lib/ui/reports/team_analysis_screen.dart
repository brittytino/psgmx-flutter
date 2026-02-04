import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_dimens.dart';
import '../../services/attendance_service.dart';
import 'team_details_screen.dart';

class TeamAnalysisScreen extends StatefulWidget {
  const TeamAnalysisScreen({super.key});

  @override
  State<TeamAnalysisScreen> createState() => _TeamAnalysisScreenState();
}

class _TeamAnalysisScreenState extends State<TeamAnalysisScreen> {
  late AttendanceService _attendanceService;
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  String _sortBy = 'attendance'; // 'attendance', 'members', 'name'
  
  bool get _showMedals => _sortBy == 'attendance';

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      // Get all unique teams from users table
      final response = await _supabase
          .from('users')
          .select('team_id')
          .eq('roles->>isStudent', 'true')
          .not('team_id', 'is', null);

      final userList = response as List;
      
      // Get unique team IDs
      final Set<String> teamIds = {};
      for (var user in userList) {
        final teamId = user['team_id'];
        if (teamId != null) {
          teamIds.add(teamId.toString());
        }
      }

      // Fetch attendance summary for each team
      final List<Map<String, dynamic>> teams = [];
      for (var teamId in teamIds) {
        try {
          final teamMembers = await _attendanceService.getTeamAttendanceSummary(
            teamId: teamId,
          );

          if (teamMembers.isNotEmpty) {
            final avgAttendance = teamMembers.fold<double>(
                  0,
                  (sum, member) => sum + member.attendancePercentage,
                ) /
                teamMembers.length;

            teams.add({
              'team_id': teamId,
              'name': 'Team $teamId',
              'member_count': teamMembers.length,
              'attendance_percentage': avgAttendance,
              'members': teamMembers,
            });
          }
        } catch (e) {
          debugPrint('Error loading team $teamId: $e');
        }
      }

      _sortTeams(teams);

      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
      }
    }
  }

  void _sortTeams(List<Map<String, dynamic>> teams) {
    switch (_sortBy) {
      case 'attendance':
        teams.sort((a, b) {
          final percentA = (a['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
          final percentB = (b['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
          return percentB.compareTo(percentA);
        });
        break;
      case 'members':
        teams.sort((a, b) {
          final countA = (a['member_count'] as num?)?.toInt() ?? 0;
          final countB = (b['member_count'] as num?)?.toInt() ?? 0;
          return countB.compareTo(countA);
        });
        break;
      case 'name':
        teams.sort((a, b) => 
            (a['name'] as String).compareTo(b['name'] as String));
        break;
    }
  }

  String _getRankDisplay(int rank) {
    if (_showMedals) {
      switch (rank) {
        case 0:
          return '🥇';
        case 1:
          return '🥈';
        case 2:
          return '🥉';
        default:
          return '${rank + 1}';
      }
    }
    return '${rank + 1}';
  }

  Color _getRankColor(int rank, BuildContext context) {
    if (!_showMedals) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
    
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Team Rankings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.sort_rounded, color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              offset: const Offset(0, 48),
              itemBuilder: (context) => [
                _buildSortMenuItem('attendance', 'Attendance', Icons.trending_up_rounded),
                _buildSortMenuItem('members', 'Team Size', Icons.people_rounded),
                _buildSortMenuItem('name', 'Team Name', Icons.sort_by_alpha_rounded),
              ],
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                  _sortTeams(_teams);
                });
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading teams...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 64,
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No teams found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: _loadTeams,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getSortIcon(),
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sorted by ${_getSortLabel()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_teams.length} teams',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final team = _teams[index];
                              final rankDisplay = _getRankDisplay(index);
                              final rankColor = _getRankColor(index, context);
                              final attendance =
                                  (team['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
                              final memberCount =
                                  (team['member_count'] as num?)?.toInt() ?? 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTeamCard(
                                  context,
                                  team,
                                  index,
                                  rankDisplay,
                                  rankColor,
                                  attendance,
                                  memberCount,
                                  isDark,
                                ),
                              );
                            },
                            childCount: _teams.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getSortIcon() {
    switch (_sortBy) {
      case 'attendance':
        return Icons.trending_up_rounded;
      case 'members':
        return Icons.people_rounded;
      case 'name':
        return Icons.sort_by_alpha_rounded;
      default:
        return Icons.sort_rounded;
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'attendance':
        return 'Attendance';
      case 'members':
        return 'Team Size';
      case 'name':
        return 'Team Name';
      default:
        return 'Default';
    }
  }

  Widget _buildTeamCard(
    BuildContext context,
    Map<String, dynamic> team,
    int index,
    String rankDisplay,
    Color rankColor,
    double attendance,
    int memberCount,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final attendanceColor = _getAttendanceColor(attendance);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TeamDetailsScreen(
              teamId: team['team_id'],
              teamName: team['name'] ?? 'Team ${team['team_id']}',
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showMedals && index < 3
                  ? rankColor.withOpacity(0.3)
                  : colorScheme.outlineVariant.withOpacity(0.5),
              width: _showMedals && index < 3 ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(_showMedals && index < 3 ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rankColor.withOpacity(_showMedals && index < 3 ? 0.4 : 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      rankDisplay,
                      style: TextStyle(
                        fontSize: _showMedals && index < 3 ? 24 : 18,
                        fontWeight: FontWeight.w700,
                        color: _showMedals && index < 3
                            ? rankColor
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Team Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team['name'] ?? 'Team ${team['team_id']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Attendance Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: attendanceColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: attendanceColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${attendance.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: attendanceColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981); // Green
    if (percentage >= 60) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }
}
