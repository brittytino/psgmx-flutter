import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../core/utils/version_comparator.dart';
import '../../services/update_service.dart';
import 'force_update_screen.dart';
import 'optional_update_sheet.dart';

/// Update Gate Widget
///
/// Wraps the main app content and enforces update policies.
/// Should be placed high in the widget tree, after authentication.
///
/// Flow:
/// 1. If emergency_block or force_update required → Show ForceUpdateScreen
/// 2. If optional_update available → Show bottom sheet once per session
/// 3. Otherwise → Show child (normal app)
class UpdateGate extends StatefulWidget {
  final Widget child;

  /// Called when update check completes
  final VoidCallback? onUpdateCheckComplete;

  const UpdateGate({
    super.key,
    required this.child,
    this.onUpdateCheckComplete,
  });

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _hasShownOptionalUpdate = false;
  bool _initialCheckDone = false;

  static bool _isAndroidNativeUpdatesEnabled() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    if (!_isAndroidNativeUpdatesEnabled()) {
      _initialCheckDone = true;
      widget.onUpdateCheckComplete?.call();
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _performInitialCheck();
  }

  @override
  void dispose() {
    if (_isAndroidNativeUpdatesEnabled()) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  /// Check for updates on app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_isAndroidNativeUpdatesEnabled()) return;
    if (state == AppLifecycleState.resumed) {
      // Recheck on resume (but respects cache)
      _recheckOnResume();
    }
  }

  Future<void> _performInitialCheck() async {
    final updateService = context.read<UpdateService>();

    // Wait for update service to initialize if not already
    if (!updateService.isInitialized) {
      await updateService.initialize();
    }

    if (mounted) {
      setState(() => _initialCheckDone = true);
      widget.onUpdateCheckComplete?.call();

      // Show optional update if applicable (delayed to avoid blocking)
      _maybeShowOptionalUpdate();
    }
  }

  Future<void> _recheckOnResume() async {
    final updateService = context.read<UpdateService>();
    await updateService.checkForUpdates();

    if (mounted) {
      setState(() {});
    }
  }

  void _maybeShowOptionalUpdate() {
    if (_hasShownOptionalUpdate) return;

    final updateService = context.read<UpdateService>();
    if (updateService.shouldShowOptionalUpdate) {
      _hasShownOptionalUpdate = true;

      // Delay slightly to ensure smooth UI and Navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && updateService.shouldShowOptionalUpdate) {
          // Check if Navigator is available before showing
          if (Navigator.maybeOf(context) != null) {
            OptionalUpdateSheet.show(context);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroidNativeUpdatesEnabled()) {
      return widget.child;
    }

    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        // Still initializing - show loading or child
        if (!updateService.isInitialized || !_initialCheckDone) {
          return widget.child; // Or a loading indicator
        }

        final status = updateService.updateStatus;

        // Priority 1: Blocking update required
        if (status == UpdateStatus.emergencyBlocked ||
            status == UpdateStatus.forceUpdateRequired) {
          return const ForceUpdateScreen();
        }

        // Priority 2: Optional Update (handled via bottom sheet, not blocking)
        // Show the normal app
        return widget.child;
      },
    );
  }
}

/// Mixin for screens that should trigger update check
/// Use this on main screens that might be entry points
mixin UpdateCheckMixin<T extends StatefulWidget> on State<T> {
  bool _hasCheckedForUpdate = false;

  bool _isAndroidNativeUpdatesEnabled() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    if (!_isAndroidNativeUpdatesEnabled()) return;
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_hasCheckedForUpdate) return;
    _hasCheckedForUpdate = true;

    final updateService = context.read<UpdateService>();
    await updateService.checkForUpdates();

    if (mounted && updateService.shouldShowOptionalUpdate) {
      OptionalUpdateSheet.show(context);
    }
  }
}

/// Simple function to check and show update dialog
/// Can be called from anywhere
Future<void> checkAndShowUpdate(BuildContext context) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final updateService = context.read<UpdateService>();
  await updateService.checkForUpdates(forceCheck: true);

  if (!context.mounted) return;

  final status = updateService.updateStatus;

  if (status == UpdateStatus.emergencyBlocked ||
      status == UpdateStatus.forceUpdateRequired) {
    // Navigate to blocking update screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ForceUpdateScreen()),
      (_) => false,
    );
  } else if (status == UpdateStatus.optionalUpdateAvailable) {
    OptionalUpdateSheet.show(context);
  }
}
