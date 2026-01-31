import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/app_user.dart';
import '../../core/theme/app_dimens.dart';
import '../../services/notification_service.dart';
import '../widgets/premium_card.dart';
import '../widgets/notification_bell_icon.dart';
import '../settings/settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final user = provider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSimulating = provider.isSimulating;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text("My Profile"),
            centerTitle: false,
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
               IconButton(
                 icon: const Icon(Icons.settings_outlined),
                 onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (context) => const SettingsScreen()),
                   );
                 },
               )
            ],
          ),
          
          SliverToBoxAdapter(
             child: Column(
               children: [
                 const SizedBox(height: AppSpacing.lg),
                 // Profile Header
                 Stack(
                   alignment: Alignment.center,
                   children: [
                     Container(
                       height: 120, width: 120,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         gradient: LinearGradient(
                           colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                           ],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         boxShadow: [
                           BoxShadow(
                             color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                             blurRadius: 15,
                             offset: const Offset(0, 8)
                           )
                         ]
                       ),
                       child: Center(
                         child: Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                         ),
                       ),
                     ),
                     Positioned(
                       bottom: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.all(6),
                         decoration: BoxDecoration(
                           color: Theme.of(context).scaffoldBackgroundColor,
                           shape: BoxShape.circle,
                         ),
                         child: Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration(
                             color: Theme.of(context).colorScheme.primary,
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.edit, size: 14, color: Colors.white),
                         ),
                       ),
                     )
                   ],
                 ),
                 
                 const SizedBox(height: AppSpacing.md),
                 Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 4),
                 Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                 
                 const SizedBox(height: AppSpacing.md),
                 _buildRoleChip(context, provider),
                 
                 const SizedBox(height: AppSpacing.xxl),
               ],
             ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // Simulation Control (Admin/Rep Only)
                if (provider.isActualPlacementRep) ...[
                   const _SectionLabel(label: "DEV TOOLS"),
                   PremiumCard(
                     backgroundColor: isSimulating ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3) : null,
                     padding: EdgeInsets.zero,
                     child: Column(
                       children: [
                          if (isSimulating)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              color: Theme.of(context).colorScheme.error,
                              child: const Text(
                                "SIMULATION ACTIVE", 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)
                              ),
                            ),
                          
                          SwitchListTile(
                            title: const Text("Simulate Student"),
                            subtitle: const Text("View app as access level: Student"),
                            secondary: Icon(Icons.person_outline, color: isSimulating ? Theme.of(context).colorScheme.error : null),
                            value: provider.simulatedRole == UserRole.student,
                            activeTrackColor: Theme.of(context).colorScheme.error,
                            onChanged: (v) => provider.setSimulationRole(v ? UserRole.student : null),
                          ),
                          Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                          SwitchListTile(
                            title: const Text("Simulate Team Leader"),
                            subtitle: const Text("View app as access level: Leader"),
                            secondary: Icon(Icons.badge_outlined, color: isSimulating ? Theme.of(context).colorScheme.error : null),
                            value: provider.simulatedRole == UserRole.teamLeader,
                            activeTrackColor: Theme.of(context).colorScheme.error,
                            onChanged: (v) => provider.setSimulationRole(v ? UserRole.teamLeader : null),
                        ),
                        Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                        SwitchListTile(
                          title: const Text("Simulate Coordinator"),
                          subtitle: const Text("View app as access level: Coordinator"),
                          secondary: Icon(Icons.school_outlined, color: isSimulating ? Theme.of(context).colorScheme.error : null),
                          value: provider.simulatedRole == UserRole.coordinator,
                          activeTrackColor: Theme.of(context).colorScheme.error,
                          onChanged: (v) => provider.setSimulationRole(v ? UserRole.coordinator : null),
                        ),
                     ],
                     ),
                   ),
                   const SizedBox(height: AppSpacing.xl),
                ],


                // Personal Details
                const _SectionLabel(label: "PERSONAL DETAILS"),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                       ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text("LeetCode Username"),
                        subtitle: Text(user.leetcodeUsername ?? "Not set"),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () => _editLeetCode(context, provider, user.leetcodeUsername),
                      ),
                      Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                      ListTile(
                        leading: const Icon(Icons.cake_outlined),
                        title: const Text("Date of Birth"),
                        subtitle: Text(user.dob != null ? user.dob!.toString().split(' ')[0] : "Not set"),
                        trailing: const Icon(Icons.edit_calendar, size: 18),
                        onTap: () => _editDob(context, provider, user.dob),
                      ),
                       Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                      SwitchListTile(
                        secondary: const Icon(Icons.celebration_outlined),
                        title: const Text("Birthday Notifications"),
                        subtitle: const Text("Show celebration on home screen"),
                        value: user.birthdayNotificationsEnabled,
                        onChanged: (v) => provider.updateBirthdayNotification(v),
                      ),
                      Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text("LeetCode Reminders"),
                        subtitle: const Text("Daily challenge & Weekly leaderboard"),
                        value: user.leetcodeNotificationsEnabled,
                        onChanged: (v) => provider.updateLeetCodeNotification(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Account
                const _SectionLabel(label: "ACCOUNT PREFERENCES"),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text("Notifications"),
                        trailing: Switch(value: true, onChanged: (v) {}), // Placeholder
                      ),
                      Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text("Help & Support"),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Danger Zone
                PremiumCard(
                  onTap: () => _confirmSignOut(context, provider),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                       const SizedBox(width: AppSpacing.md),
                       Text("Sign Out", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                const Center(
                   child: Text(
                     "PSGMX - Placement Excellence v1.2.0", 
                     style: TextStyle(color: Colors.grey, fontSize: 10)
                   )
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, UserProvider provider) {
    String label = "Student";
    Color color = Colors.green;
    
    if (provider.isActualPlacementRep) {
       label = "Placement Rep";
       color = Colors.purple;
    } else if (provider.isCoordinator) {
       label = "Coordinator";
       color = Colors.orange;
    } else if (provider.isTeamLeader) {
       label = "Team Leader";
       color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
      ),
    );
  }

  Future<void> _editLeetCode(BuildContext context, UserProvider provider, String? current) async {
    final ctrl = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("LeetCode Username"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Username", hintText: "e.g. user123"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateLeetCodeUsername(ctrl.text.trim());
            }, 
            child: const Text("Save")
          ),
        ],
      ),
    );
  }

  Future<void> _editDob(BuildContext context, UserProvider provider, DateTime? current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2003, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      await provider.updateDob(date);
    }
  }

  void _confirmSignOut(BuildContext context, UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              provider.signOut();
            }, 
            child: const Text("Sign Out")
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(
        label, 
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2
        )
      ),
    );
  }
}
