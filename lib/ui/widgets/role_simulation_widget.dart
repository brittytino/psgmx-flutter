import 'package:flutter/material.dart';
import '../../services/enhanced_auth_service.dart';
import '../../models/app_user.dart';

class RoleSimulationWidget extends StatefulWidget {
  final EnhancedAuthService authService;
  final VoidCallback? onRoleChanged;

  const RoleSimulationWidget({
    super.key,
    required this.authService,
    this.onRoleChanged,
  });

  @override
  State<RoleSimulationWidget> createState() => _RoleSimulationWidgetState();
}

class _RoleSimulationWidgetState extends State<RoleSimulationWidget> {
  String? _selectedTeamId;
  SimulationMode _mode = SimulationMode.none;

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    
    if (user == null || !user.isPlacementRep) {
      return const SizedBox.shrink();
    }

    final isSimulating = widget.authService.roleSimulation.isActive;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: isSimulating ? 4 : 2,
      color: isSimulating ? Colors.amber.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSimulating ? Icons.visibility : Icons.person_outline,
                  color: isSimulating ? Colors.amber.shade900 : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Role Simulation Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSimulating ? Colors.amber.shade900 : null,
                      ),
                ),
                const Spacer(),
                if (isSimulating)
                  Chip(
                    label: const Text('SIMULATING'),
                    backgroundColor: Colors.amber.shade700,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'View the app as different roles without logging out',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRoleChip(
                  context,
                  label: 'Placement Rep (Real)',
                  mode: SimulationMode.none,
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                ),
                _buildRoleChip(
                  context,
                  label: 'Coordinator',
                  mode: SimulationMode.coordinator,
                  icon: Icons.school,
                  color: const Color(0xFFEA580C),
                  needsTeam: true,
                ),
                _buildRoleChip(
                  context,
                  label: 'Team Leader',
                  mode: SimulationMode.teamLeader,
                  icon: Icons.group,
                  color: Colors.green,
                  needsTeam: true,
                ),
                _buildRoleChip(
                  context,
                  label: 'Student',
                  mode: SimulationMode.student,
                  icon: Icons.person,
                  color: Colors.orange,
                  needsTeam: true,
                ),
              ],
            ),
            if (_mode == SimulationMode.coordinator || 
                _mode == SimulationMode.teamLeader || 
                _mode == SimulationMode.student)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildTeamSelector(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(
    BuildContext context, {
    required String label,
    required SimulationMode mode,
    required IconData icon,
    required Color color,
    bool needsTeam = false,
  }) {
    final isActive = _mode == mode;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isActive,
      onSelected: (_) => _selectMode(mode, needsTeam),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
    );
  }

  Widget _buildTeamSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Team',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      initialValue: _selectedTeamId,
      items: _getTeamOptions(),
      onChanged: (value) {
        setState(() {
          _selectedTeamId = value;
        });
        _applySimulation();
      },
    );
  }

  List<DropdownMenuItem<String>> _getTeamOptions() {
    // Generate team options (Team1 to Team10)
    return List.generate(10, (index) {
      final teamId = 'Team${index + 1}';
      return DropdownMenuItem(
        value: teamId,
        child: Text(teamId),
      );
    });
  }

  void _selectMode(SimulationMode mode, bool needsTeam) {
    setState(() {
      _mode = mode;
      if (!needsTeam) {
        _selectedTeamId = null;
      }
    });

    if (!needsTeam) {
      _applySimulation();
    }
  }

  Future<void> _applySimulation() async {
    try {
      switch (_mode) {
        case SimulationMode.none:
          await widget.authService.disableRoleSimulation();
          break;
        case SimulationMode.coordinator:
          if (_selectedTeamId != null) {
            await widget.authService.simulateCoordinator(teamId: _selectedTeamId);
          } else {
            return; // Wait for team selection
          }
          break;
        case SimulationMode.teamLeader:
          if (_selectedTeamId != null) {
            await widget.authService.simulateTeamLeader(_selectedTeamId!);
          } else {
            return; // Wait for team selection
          }
          break;
        case SimulationMode.student:
          await widget.authService.simulateStudent(teamId: _selectedTeamId);
          break;
      }

      widget.onRoleChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSimulationMessage()),
            backgroundColor: _mode == SimulationMode.none
                ? Colors.green
                : Colors.amber.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change simulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSimulationMessage() {
    switch (_mode) {
      case SimulationMode.none:
        return 'Back to Placement Rep view';
      case SimulationMode.coordinator:
        return _selectedTeamId != null
            ? 'Now viewing as Coordinator ($_selectedTeamId)'
            : 'Now viewing as Coordinator';
      case SimulationMode.teamLeader:
        return 'Now viewing as Team Leader ($_selectedTeamId)';
      case SimulationMode.student:
        return _selectedTeamId != null
            ? 'Now viewing as Student ($_selectedTeamId)'
            : 'Now viewing as Student';
    }
  }
}

enum SimulationMode {
  none,
  coordinator,
  teamLeader,
  student,
}

// Role indicator badge for app bar
class RoleIndicatorBadge extends StatelessWidget {
  final EnhancedAuthService authService;

  const RoleIndicatorBadge({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUser = authService.effectiveUser;
    final isSimulating = authService.roleSimulation.isActive;

    if (effectiveUser == null) return const SizedBox.shrink();

    final roleText = _getRoleText(effectiveUser);
    final roleColor = _getRoleColor(effectiveUser);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSimulating ? Colors.amber.shade100 : roleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSimulating ? Colors.amber.shade700 : roleColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSimulating)
            Icon(
              Icons.visibility,
              size: 16,
              color: Colors.amber.shade900,
            ),
          if (isSimulating) const SizedBox(width: 4),
          Text(
            roleText,
            style: TextStyle(
              color: isSimulating ? Colors.amber.shade900 : roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(AppUser user) {
    if (user.isPlacementRep) return 'PLACEMENT REP';
    if (user.isCoordinator) return 'COORDINATOR';
    if (user.isTeamLeader) return 'TEAM LEADER';
    return 'STUDENT';
  }

  Color _getRoleColor(AppUser user) {
    if (user.isPlacementRep) return Colors.purple;
    if (user.isCoordinator) return Colors.blue;
    if (user.isTeamLeader) return Colors.green;
    return Colors.orange;
  }
}
