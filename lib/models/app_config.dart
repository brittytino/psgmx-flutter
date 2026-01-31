/// App Configuration Model
/// Represents the remote configuration for version control and updates
library;

class AppConfig {
  /// Minimum version required to use the app
  /// Users below this version are FORCED to update
  final String minRequiredVersion;

  /// Latest available version
  final String latestVersion;

  /// If true, enforce min_required_version strictly
  final bool forceUpdate;

  /// Message to show users when update is available
  final String updateMessage;

  /// GitHub releases URL for downloading updates
  final String githubReleaseUrl;

  /// Direct Android APK download URL (optional)
  final String? androidDownloadUrl;

  /// Direct iOS download URL (optional)
  final String? iosDownloadUrl;

  /// If true, BLOCK all app access immediately
  final bool emergencyBlock;

  /// Message to show during emergency block
  final String emergencyMessage;

  /// When this config was last updated
  final DateTime? updatedAt;

  const AppConfig({
    required this.minRequiredVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.githubReleaseUrl,
    this.androidDownloadUrl,
    this.iosDownloadUrl,
    required this.emergencyBlock,
    required this.emergencyMessage,
    this.updatedAt,
  });

  /// Default configuration (used when fetch fails)
  factory AppConfig.defaultConfig() {
    return const AppConfig(
      minRequiredVersion: '1.0.0',
      latestVersion: '1.0.0',
      forceUpdate: false,
      updateMessage: 'A new version is available.',
      githubReleaseUrl: 'https://github.com/psgmx/psgmx-flutter/releases/latest',
      emergencyBlock: false,
      emergencyMessage: 'App temporarily unavailable.',
    );
  }

  /// Parse from Supabase response
  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      minRequiredVersion: map['min_required_version'] as String? ?? '1.0.0',
      latestVersion: map['latest_version'] as String? ?? '1.0.0',
      forceUpdate: map['force_update'] as bool? ?? false,
      updateMessage: map['update_message'] as String? ?? 'A new version is available.',
      githubReleaseUrl: map['github_release_url'] as String? ?? 
          'https://github.com/psgmx/psgmx-flutter/releases/latest',
      androidDownloadUrl: map['android_download_url'] as String?,
      iosDownloadUrl: map['ios_download_url'] as String?,
      emergencyBlock: map['emergency_block'] as bool? ?? false,
      emergencyMessage: map['emergency_message'] as String? ?? 
          'App temporarily unavailable.',
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to map (for debugging/logging)
  Map<String, dynamic> toMap() {
    return {
      'min_required_version': minRequiredVersion,
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'update_message': updateMessage,
      'github_release_url': githubReleaseUrl,
      'android_download_url': androidDownloadUrl,
      'ios_download_url': iosDownloadUrl,
      'emergency_block': emergencyBlock,
      'emergency_message': emergencyMessage,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppConfig(min: $minRequiredVersion, latest: $latestVersion, '
        'force: $forceUpdate, emergency: $emergencyBlock)';
  }
}
