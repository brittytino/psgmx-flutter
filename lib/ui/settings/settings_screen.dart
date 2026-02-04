import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_dimens.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../widgets/premium_card.dart';
import '../widgets/notification_bell_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSaving = false;
  bool _isLoggingOut = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    // A2: Read preferences from DB-backed user model
    final taskReminders = user?.taskRemindersEnabled ?? true;
    final attendanceAlerts = user?.attendanceAlertsEnabled ?? true;
    final announcements = user?.announcementsEnabled ?? true;
    final leetcodeNotifications = user?.leetcodeNotificationsEnabled ?? true;

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
                builder: (context, notifService, _) =>
                    FutureBuilder<List<dynamic>>(
                  future: notifService.getNotifications(),
                  builder: (context, snapshot) {
                    final unreadCount =
                        snapshot.data?.where((n) => n.isRead != true).length ??
                            0;
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
                _buildSectionHeader(
                    context, 'Notifications', Icons.notifications_active),
                const SizedBox(height: AppSpacing.sm),
                PremiumCard(
                  child: Column(
                    children: [
                      _buildModernToggle(
                        context,
                        title: 'Task Reminders',
                        subtitle: 'Daily coding problem reminders at 9 PM',
                        icon: Icons.task_alt,
                        value: taskReminders,
                        isLoading: _isSaving,
                        onChanged: (val) => _updatePreference(
                          () => userProvider.updateTaskRemindersEnabled(val),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildModernToggle(
                        context,
                        title: 'Attendance Alerts',
                        subtitle: 'Get notified about attendance updates',
                        icon: Icons.calendar_today,
                        value: attendanceAlerts,
                        isLoading: _isSaving,
                        onChanged: (val) => _updatePreference(
                          () => userProvider.updateAttendanceAlertsEnabled(val),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildModernToggle(
                        context,
                        title: 'Announcements',
                        subtitle: 'Important updates from placement team',
                        icon: Icons.campaign_outlined,
                        value: announcements,
                        isLoading: _isSaving,
                        onChanged: (val) => _updatePreference(
                          () => userProvider.updateAnnouncementsEnabled(val),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildModernToggle(
                        context,
                        title: 'LeetCode Reminders',
                        subtitle: 'Daily problem & weekly leaderboard updates',
                        icon: Icons.code,
                        value: leetcodeNotifications,
                        isLoading: _isSaving,
                        onChanged: (val) => _updatePreference(
                          () => userProvider.updateLeetCodeNotification(val),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Appearance Section
                _buildSectionHeader(context, 'Appearance', Icons.palette),
                const SizedBox(height: AppSpacing.sm),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return PremiumCard(
                      child: Column(
                        children: [
                          _buildThemeSelector(context, themeProvider),
                        ],
                      ),
                    );
                  },
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
                        title: 'About',
                        subtitle: 'Version $_appVersion',
                        icon: Icons.info,
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'PSGMX Flutter',
                            applicationVersion: _appVersion,
                            applicationLegalese:
                                '© ${DateTime.now().year} PSGMX. All rights reserved.',
                          );
                        },
                      ),
                    ],
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

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
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

  // A2: Helper to update preferences with loading state
  Future<void> _updatePreference(Future<void> Function() update) async {
    setState(() => _isSaving = true);
    try {
      await update();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preference saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preference: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmSignOut(BuildContext context, UserProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoggingOut = true);
      try {
        await provider.signOut();
        // Navigation will be handled by the auth state listener
      } catch (e) {
        if (mounted) {
          setState(() => _isLoggingOut = false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error signing out: $e')),
            );
          }
        }
      }
    }
  }

  Widget _buildModernToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLoading = false,
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
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
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

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isSystem = themeProvider.themeMode == ThemeMode.system;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Sun Icon (Light Mode)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: !isDark && !isSystem
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.light_mode,
              color: !isDark && !isSystem
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          // Toggle Switch
          Expanded(
            child: Center(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // System Option
                    _buildThemeToggleOption(
                      context,
                      label: 'System',
                      isSelected: isSystem,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                    // Light Option
                    _buildThemeToggleOption(
                      context,
                      label: 'Light',
                      isSelected: !isDark && !isSystem,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    // Dark Option
                    _buildThemeToggleOption(
                      context,
                      label: 'Dark',
                      isSelected: isDark && !isSystem,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          // Moon Icon (Dark Mode)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark && !isSystem
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.dark_mode,
              color: isDark && !isSystem
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption_OLD(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
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
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
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
