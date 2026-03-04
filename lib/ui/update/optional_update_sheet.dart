import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/update_service.dart';

/// Optional Update Bottom Sheet
/// 
/// Dismissible UI for optional updates with engaging Tamil cinema meme images.
/// User can choose to update now or later.
/// Only shown once per session.
class OptionalUpdateSheet extends StatefulWidget {
  const OptionalUpdateSheet({super.key});

  /// Show the optional update bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => const OptionalUpdateSheet(),
    );
  }

  @override
  State<OptionalUpdateSheet> createState() => _OptionalUpdateSheetState();
}

class _OptionalUpdateSheetState extends State<OptionalUpdateSheet> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _updateCancelled = false;
  bool _preparingDownload = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    setState(() => _updateCancelled = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        final updateService = context.read<UpdateService>();
        updateService.dismissOptionalUpdate();
      }
    });
  }

  void _handleUpdate() async {
    setState(() => _preparingDownload = true);
    
    final updateService = context.read<UpdateService>();
    
    // Show "update done" state for 1.5 seconds before opening URL
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    Navigator.pop(context);
    updateService.dismissOptionalUpdate();
    await updateService.openUpdateUrl();
  }

  @override
  Widget build(BuildContext context) {
    final updateService = Provider.of<UpdateService>(context);
    final config = updateService.config;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),

              // Animated Image based on state
              ScaleTransition(
                scale: _scaleAnimation,
                child: Hero(
                  tag: 'update_available',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        _preparingDownload
                            ? 'assets/images/app_update_done.png'
                            : _updateCancelled
                                ? 'assets/images/app_update_cancelled.png'
                                : 'assets/images/app_update_available.png',
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Title based on state
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _preparingDownload
                      ? 'Ready to Download! 🎉'
                      : _updateCancelled
                          ? 'Maybe Later! 👍'
                          : 'Hi Chellom! 👋',
                  key: ValueKey(_preparingDownload ? 'ready' : _updateCancelled ? 'cancel' : 'default'),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _preparingDownload 
                        ? Colors.green 
                        : _updateCancelled
                            ? Colors.orange
                            : Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _preparingDownload
                      ? 'Opening download link...'
                      : _updateCancelled
                          ? 'You can update anytime from settings'
                          : 'New update is here!',
                  key: ValueKey(_preparingDownload ? 'ready_sub' : _updateCancelled ? 'cancel_sub' : 'default_sub'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              if (!_updateCancelled && !_preparingDownload) ...[
                const SizedBox(height: 16),
                
                // Version badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.blue.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.celebration, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Version ${config?.latestVersion ?? "?"} Available',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Current version
                Text(
                  'You\'re on v${updateService.currentVersion ?? "?"}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Action Buttons (only show if not cancelled or preparing)
              if (!_updateCancelled && !_preparingDownload) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // Update Now Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _handleUpdate,
                          icon: const Icon(Icons.download_rounded, size: 22),
                          label: Text(
                            'Update Now',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Later Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _handleCancel,
                          icon: const Icon(Icons.schedule_rounded, size: 20),
                          label: Text(
                            'Maybe Later',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                            side: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_preparingDownload) ...[
                // Loading indicator
                const SizedBox(
                  height: 56,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog variant for optional update (alternative to bottom sheet)
class OptionalUpdateDialog extends StatelessWidget {
  const OptionalUpdateDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const OptionalUpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updateService = Provider.of<UpdateService>(context);
    final config = updateService.config;
    final message = config?.updateMessage ?? 
        'A new version of PSGMX is available!';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              size: 40,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Update Available',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v${config?.latestVersion ?? "?"}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            updateService.dismissOptionalUpdate();
          },
          child: Text(
            'Later',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            updateService.dismissOptionalUpdate();
            await updateService.openUpdateUrl();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
