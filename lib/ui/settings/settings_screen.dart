import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_dimens.dart';
import '../../services/notification_service.dart';
import '../widgets/premium_card.dart';
import '../widgets/notification_bell_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _taskReminders = true;
  bool _attendanceAlerts = true;
  bool _reportUpdates = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
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
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Notifications Section
                _buildSectionHeader(context, 'Notifications', Icons.notifications_active),
                const SizedBox(height: AppSpacing.sm),
                PremiumCard(
                  child: Column(
                    children: [
                      _buildModernToggle(
                        context,
                        title: 'Push Notifications',
                        subtitle: 'Enable notifications for all updates',
                        icon: Icons.notifications_outlined,
                        value: _notificationsEnabled,
                        onChanged: (val) => setState(() => _notificationsEnabled = val),
                      ),
                      const Divider(height: 1),
                      _buildModernToggle(
                        context,
                        title: 'Task Reminders',
                        subtitle: 'Daily coding problem reminders',
                        icon: Icons.task_alt,
                        value: _taskReminders,
                        onChanged: (val) => setState(() => _taskReminders = val),
                      ),
                      const Divider(height: 1),
                      _buildModernToggle(
                        context,
                        title: 'Attendance Alerts',
                        subtitle: 'Get notified about attendance updates',
                        icon: Icons.calendar_today,
                        value: _attendanceAlerts,
                        onChanged: (val) => setState(() => _attendanceAlerts = val),
                      ),
                      const Divider(height: 1),
                      _buildModernToggle(
                        context,
                        title: 'Report Updates',
                        subtitle: 'Weekly analytics and reports',
                        icon: Icons.bar_chart,
                        value: _reportUpdates,
                        onChanged: (val) => setState(() => _reportUpdates = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Appearance Section
                _buildSectionHeader(context, 'Appearance', Icons.palette),
                const SizedBox(height: AppSpacing.sm),
                PremiumCard(
                  child: Column(
                    children: [
                      _buildModernToggle(
                        context,
                        title: 'Dark Mode',
                        subtitle: 'Toggle dark theme',
                        icon: Icons.dark_mode,
                        value: _darkMode,
                        onChanged: (val) => setState(() => _darkMode = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Account Section
                _buildSectionHeader(context, 'Account', Icons.person),
                const SizedBox(height: AppSpacing.sm),
                PremiumCard(
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        title: 'Edit Profile',
                        subtitle: 'Update your profile information',
                        icon: Icons.edit,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile edit coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        title: 'Change Password',
                        subtitle: 'Update your security credentials',
                        icon: Icons.lock,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password change coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        title: 'Privacy Policy',
                        subtitle: 'View our privacy policy',
                        icon: Icons.privacy_tip,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy policy coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Support Section
                _buildSectionHeader(context, 'Support', Icons.help),
                const SizedBox(height: AppSpacing.sm),
                PremiumCard(
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        title: 'Help Center',
                        subtitle: 'Get help and support',
                        icon: Icons.help_outline,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help center coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        title: 'Contact Us',
                        subtitle: 'Reach out to our team',
                        icon: Icons.email,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact form coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        icon: Icons.info,
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'PSGMX Flutter',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2024 PSGMX. All rights reserved.',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Logout Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Logout coming soon!')),
                                );
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        thumbIcon: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(Icons.check, color: Colors.white, size: 16);
          }
          return const Icon(Icons.close, color: Colors.white, size: 16);
        }),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}


