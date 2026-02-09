import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/version_comparator.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../services/update_service.dart';
import '../widgets/premium_card.dart';
import '../widgets/notification_bell_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSaving = false;
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
                        title: 'Check for Updates',
                        subtitle: 'Manually check for new app updates',
                        icon: Icons.system_update_alt,
                        onTap: () => _showUpdateCheckModal(context),
                      ),
                      const Divider(height: 1),
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

  // Check for Updates Modal
  Future<void> _showUpdateCheckModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _UpdateCheckModal(),
    );
  }
}

// Modern Update Check Modal Widget
class _UpdateCheckModal extends StatefulWidget {
  const _UpdateCheckModal();

  @override
  State<_UpdateCheckModal> createState() => _UpdateCheckModalState();
}

class _UpdateCheckModalState extends State<_UpdateCheckModal> {
  bool _isChecking = true;
  UpdateStatus? _updateStatus;
  String? _latestVersion;
  String? _currentVersion;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateService = UpdateService();
      
      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // Force check for updates
      final status = await updateService.checkForUpdates(forceCheck: true);
      
      if (mounted) {
        setState(() {
          _updateStatus = status;
          _latestVersion = updateService.config?.latestVersion;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Failed to check for updates. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: _isChecking
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ],
                      )
                    : (_updateStatus == UpdateStatus.optionalUpdateAvailable ||
                            _updateStatus == UpdateStatus.forceUpdateRequired)
                        ? const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                          )
                        : LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                shape: BoxShape.circle,
              ),
              child: _buildIcon(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              _getTitle(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              _getDescription(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_isChecking) {
      return SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Icon(
        Icons.error_outline,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      );
    }

    if (_updateStatus == UpdateStatus.optionalUpdateAvailable ||
        _updateStatus == UpdateStatus.forceUpdateRequired) {
      return const Icon(
        Icons.system_update_alt,
        size: 48,
        color: Colors.white,
      );
    }

    return Icon(
      Icons.check_circle,
      size: 48,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  String _getTitle() {
    if (_isChecking) return 'Checking for Updates';
    if (_errorMessage != null) return 'Check Failed';
    
    if (_updateStatus == UpdateStatus.optionalUpdateAvailable ||
        _updateStatus == UpdateStatus.forceUpdateRequired) {
      return 'Update Available';
    }
    
    return 'You\'re Up to Date';
  }

  String _getDescription() {
    if (_isChecking) {
      return 'Please wait while we check for the latest version...';
    }

    if (_errorMessage != null) {
      return _errorMessage!;
    }

    if (_updateStatus == UpdateStatus.optionalUpdateAvailable ||
        _updateStatus == UpdateStatus.forceUpdateRequired) {
      return 'Version $_latestVersion is now available!\nYou\'re currently running v$_currentVersion';
    }

    return 'You have the latest version ($_currentVersion) installed';
  }

  Widget _buildActionButtons() {
    if (_isChecking) {
      return const SizedBox.shrink();
    }

    if (_errorMessage != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isChecking = true;
                  _errorMessage = null;
                });
                _checkForUpdates();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_updateStatus == UpdateStatus.optionalUpdateAvailable ||
        _updateStatus == UpdateStatus.forceUpdateRequired) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Later',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () async {
                final updateService = UpdateService();
                final launched = await updateService.openUpdateUrl();
                
                if (!launched && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to open download link'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.download, size: 20),
              label: Text(
                'Download',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Up to date - just close button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(
          'Close',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
