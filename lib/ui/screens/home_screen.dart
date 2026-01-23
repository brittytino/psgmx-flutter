import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';

/// Home Screen: Main authenticated screen
/// 
/// Features:
/// - Shows current user info
/// - Role-based UI (different views for different roles)
/// - Quick actions based on role
/// - Sign out button
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PSG MCA Placement Prep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user.name}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email}'),
                    Text('Reg No: ${user.regNo}'),
                    if (user.teamId != null) Text('Team: ${user.teamId}'),
                    Text('Batch: ${user.batch}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Roles:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (user.isStudent)
                          const Chip(
                            label: Text('Student'),
                            avatar: Icon(Icons.school, size: 16),
                          ),
                        if (user.isTeamLeader)
                          const Chip(
                            label: Text('Team Leader'),
                            avatar: Icon(Icons.group, size: 16),
                          ),
                        if (user.isCoordinator)
                          const Chip(
                            label: Text('Coordinator'),
                            avatar: Icon(Icons.admin_panel_settings, size: 16),
                          ),
                        if (user.isPlacementRep)
                          const Chip(
                            label: Text('Placement Rep'),
                            avatar: Icon(Icons.verified, size: 16),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions based on role
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Actions for Team Leaders
            if (user.isTeamLeader) ...[
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Mark Team Attendance'),
                subtitle: const Text('Record attendance for your team'),
                onTap: () {
                  // TODO: Navigate to attendance marking screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance Marking - Coming Soon')),
                  );
                },
              ),
            ],

            // Actions for Coordinators & Placement Rep
            if (user.isCoordinator || user.isPlacementRep) ...[
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload Tasks'),
                subtitle: const Text('Bulk upload daily tasks from CSV/Excel'),
                onTap: () {
                  // TODO: Navigate to task upload screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task Upload - Coming Soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics Dashboard'),
                subtitle: const Text('View attendance analytics and reports'),
                onTap: () {
                  // TODO: Navigate to analytics dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analytics - Coming Soon')),
                  );
                },
              ),
            ],

            // Actions for all users
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('View My Attendance'),
              subtitle: const Text('Check your attendance record'),
              onTap: () {
                // TODO: Navigate to my attendance screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('My Attendance - Coming Soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
