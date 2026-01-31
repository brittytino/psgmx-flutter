import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../core/utils/version_comparator.dart';

/// Update Service for PSGMX App
/// 
/// Handles:
/// - Fetching remote app configuration
/// - Version comparison
/// - Update enforcement logic
/// - Session-based caching to prevent popup spam
class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // ========================================
  // STATE
  // ========================================
  
  AppConfig? _config;
  String? _currentVersion;
  UpdateStatus? _updateStatus;
  bool _hasCheckedThisSession = false;
  bool _hasShownOptionalUpdateThisSession = false;
  bool _isInitialized = false;
  DateTime? _lastCheckTime;

  // Cache key for emergency block state
  static const String _emergencyBlockCacheKey = 'psgmx_emergency_block_cached';

  // ========================================
  // GETTERS
  // ========================================

  AppConfig? get config => _config;
  String? get currentVersion => _currentVersion;
  UpdateStatus? get updateStatus => _updateStatus;
  bool get isInitialized => _isInitialized;
  
  /// Whether we should show the optional update dialog
  bool get shouldShowOptionalUpdate => 
      _updateStatus == UpdateStatus.optionalUpdateAvailable && 
      !_hasShownOptionalUpdateThisSession;

  /// Whether we should show force update screen
  bool get shouldShowForceUpdate => 
      _updateStatus == UpdateStatus.forceUpdateRequired;

  /// Whether we should show emergency block screen
  bool get shouldShowEmergencyBlock => 
      _updateStatus == UpdateStatus.emergencyBlocked;

  /// Check if app needs any update intervention
  bool get needsUpdateIntervention =>
      shouldShowEmergencyBlock || shouldShowForceUpdate;

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize the update service
  /// Should be called early in app startup, after Supabase init
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      debugPrint('📱 [UpdateService] Current app version: $_currentVersion');

      // Check for updates
      await checkForUpdates();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ [UpdateService] Initialization error: $e');
      // On error, allow app to continue (fail-open)
      _updateStatus = UpdateStatus.upToDate;
      _isInitialized = true;
    }

    notifyListeners();
  }

  // ========================================
  // UPDATE CHECK LOGIC
  // ========================================

  /// Check for updates from Supabase
  /// 
  /// This fetches the app_config and determines update status
  Future<UpdateStatus> checkForUpdates({bool forceCheck = false}) async {
    // Prevent excessive checks (minimum 5 minutes between checks)
    if (!forceCheck && 
        _hasCheckedThisSession && 
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < const Duration(minutes: 5)) {
      return _updateStatus ?? UpdateStatus.upToDate;
    }

    try {
      debugPrint('🔍 [UpdateService] Checking for updates...');

      // Fetch config from Supabase
      final response = await _supabase
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _config = AppConfig.fromMap(response);
        debugPrint('📦 [UpdateService] Config loaded: $_config');

        // Cache emergency block state
        if (_config!.emergencyBlock) {
          await _cacheEmergencyBlockState(true);
        }
      } else {
        // No config in DB, use defaults
        _config = AppConfig.defaultConfig();
        debugPrint('⚠️ [UpdateService] No config found, using defaults');
      }

      // Determine update status
      _updateStatus = _determineUpdateStatus();
      _hasCheckedThisSession = true;
      _lastCheckTime = DateTime.now();

      debugPrint('📊 [UpdateService] Update status: $_updateStatus');

    } catch (e) {
      debugPrint('❌ [UpdateService] Error fetching config: $e');
      
      // Check if we have cached emergency block
      final cachedEmergency = await _getCachedEmergencyBlockState();
      if (cachedEmergency) {
        _updateStatus = UpdateStatus.emergencyBlocked;
        _config = AppConfig.defaultConfig();
      } else {
        // Fail-open: allow app to continue if fetch fails
        _updateStatus = UpdateStatus.upToDate;
        _config = AppConfig.defaultConfig();
      }
    }

    notifyListeners();
    return _updateStatus ?? UpdateStatus.upToDate;
  }

  /// Determine update status based on config and current version
  UpdateStatus _determineUpdateStatus() {
    if (_config == null || _currentVersion == null) {
      return UpdateStatus.upToDate;
    }

    return VersionComparator.getUpdateStatus(
      currentVersion: _currentVersion!,
      minRequiredVersion: _config!.minRequiredVersion,
      latestVersion: _config!.latestVersion,
      forceUpdate: _config!.forceUpdate,
      emergencyBlock: _config!.emergencyBlock,
    );
  }

  // ========================================
  // USER ACTIONS
  // ========================================

  /// Mark optional update as dismissed for this session
  void dismissOptionalUpdate() {
    _hasShownOptionalUpdateThisSession = true;
    notifyListeners();
  }

  /// Open the GitHub releases page for update
  Future<bool> openUpdateUrl() async {
    if (_config == null) return false;

    String? url;
    
    // Platform-specific URLs if available
    if (Platform.isAndroid && _config!.androidDownloadUrl != null) {
      url = _config!.androidDownloadUrl;
    } else if (Platform.isIOS && _config!.iosDownloadUrl != null) {
      url = _config!.iosDownloadUrl;
    } else {
      url = _config!.githubReleaseUrl;
    }

    if (url == null || url.isEmpty) {
      url = 'https://github.com/psgmx/psgmx-flutter/releases/latest';
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('❌ [UpdateService] Error opening URL: $e');
    }

    return false;
  }

  // ========================================
  // CACHING (for emergency block persistence)
  // ========================================

  Future<void> _cacheEmergencyBlockState(bool blocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emergencyBlockCacheKey, blocked);
    } catch (e) {
      debugPrint('⚠️ [UpdateService] Error caching emergency state: $e');
    }
  }

  Future<bool> _getCachedEmergencyBlockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_emergencyBlockCacheKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Clear emergency block cache (call when block is lifted)
  Future<void> clearEmergencyBlockCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergencyBlockCacheKey);
    } catch (e) {
      debugPrint('⚠️ [UpdateService] Error clearing emergency cache: $e');
    }
  }

  // ========================================
  // RESET (for testing/development)
  // ========================================

  /// Reset session state (for testing)
  void resetSession() {
    _hasCheckedThisSession = false;
    _hasShownOptionalUpdateThisSession = false;
    _lastCheckTime = null;
    notifyListeners();
  }

  /// Force refresh (ignore cache)
  Future<void> forceRefresh() async {
    _hasCheckedThisSession = false;
    await checkForUpdates(forceCheck: true);
  }
}
