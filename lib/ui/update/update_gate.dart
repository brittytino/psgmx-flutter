import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/version_comparator.dart';
import '../../services/update_service.dart';
import 'emergency_block_screen.dart';
import 'force_update_screen.dart';
import 'optional_update_sheet.dart';

/// Update Gate Widget
/// 
/// Wraps the main app content and enforces update policies.
/// Should be placed high in the widget tree, after authentication.
/// 
/// Flow:
/// 1. If emergency_block → Show EmergencyBlockScreen (full block)
/// 2. If force_update required → Show ForceUpdateScreen (cannot proceed)
/// 3. If optional_update available → Show bottom sheet once per session
/// 4. Otherwise → Show child (normal app)
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _performInitialCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Check for updates on app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
      
      // Delay slightly to ensure smooth UI
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && updateService.shouldShowOptionalUpdate) {
          OptionalUpdateSheet.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        // Still initializing - show loading or child
        if (!updateService.isInitialized || !_initialCheckDone) {
          return widget.child; // Or a loading indicator
        }

        final status = updateService.updateStatus;

        // Priority 1: Emergency Block
        if (status == UpdateStatus.emergencyBlocked) {
          return const EmergencyBlockScreen();
        }

        // Priority 2: Force Update Required
        if (status == UpdateStatus.forceUpdateRequired) {
          return const ForceUpdateScreen();
        }

        // Priority 3: Optional Update (handled via bottom sheet, not blocking)
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

  @override
  void initState() {
    super.initState();
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
  final updateService = context.read<UpdateService>();
  await updateService.checkForUpdates(forceCheck: true);

  if (!context.mounted) return;

  final status = updateService.updateStatus;

  if (status == UpdateStatus.emergencyBlocked) {
    // Navigate to emergency screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmergencyBlockScreen()),
      (_) => false,
    );
  } else if (status == UpdateStatus.forceUpdateRequired) {
    // Navigate to force update screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ForceUpdateScreen()),
      (_) => false,
    );
  } else if (status == UpdateStatus.optionalUpdateAvailable) {
    OptionalUpdateSheet.show(context);
  }
}
