import 'package:tapture/core/constants/app_constants.dart';

import 'setting_key.dart';

/// Every app-wide preference, typed, with its default.
///
/// Limits and durations come from [AppConstants]. Secrets never appear here.
abstract final class SettingKeys {
  /// GPS at capture. Off until a person turns it on (FE-SEC-07).
  static const SettingKey<bool> gpsEnabled = SettingKey<bool>(
    'capture.gps',
    false,
  );

  /// Stamp dates and times without asking.
  static const SettingKey<bool> autoFillDates = SettingKey<bool>(
    'capture.autoFillDates',
    true,
  );

  /// JPEG quality for a captured photo.
  ///
  /// Record getters are not const-evaluable, so AppConstants-backed keys
  /// are final rather than const.
  static final SettingKey<int> photoQuality = SettingKey<int>(
    'capture.photoQuality',
    AppConstants.images.quality,
  );

  /// How new photo folders are grouped. Existing files stay put.
  static final SettingKey<String> folderStrategy = SettingKey<String>(
    'capture.folderStrategy',
    AppConstants.folders.defaultStrategy,
  );

  /// Token pattern for a new photo file name.
  static const SettingKey<String> namingPattern = SettingKey<String>(
    'capture.namingPattern',
    '{date}_{time}_{type}',
  );

  /// Rear or front camera at the start of a session.
  static const SettingKey<String> cameraMode = SettingKey<String>(
    'capture.cameraMode',
    'photo',
  );

  /// Flash mode for a still capture.
  static const SettingKey<String> flash = SettingKey<String>(
    'capture.flash',
    'off',
  );

  /// Composition grid overlay.
  static const SettingKey<bool> grid = SettingKey<bool>('capture.grid', false);

  /// Recycle-bin and tombstone retention, in days.
  static final SettingKey<int> retentionDays = SettingKey<int>(
    'storage.retentionDays',
    AppConstants.retention.days,
  );

  /// Operator forced every outbound call off.
  static const SettingKey<bool> offlineByChoice = SettingKey<bool>(
    'network.offlineByChoice',
    false,
  );

  /// Last opened project. Null when none is open or the id no longer resolves.
  static const SettingKey<String?> openProjectId = SettingKey<String?>(
    'projects.openId',
    null,
  );

  /// Chosen storage-root folder. Null or empty keeps the Documents fallback.
  static const SettingKey<String?> storageRootPath = SettingKey<String?>(
    'storage.rootPath',
    null,
  );

  /// Last committed internal route, path and query. Empty on first launch.
  static const SettingKey<String> lastLocation = SettingKey<String>(
    'navigation.lastLocation',
    '',
  );

  /// Default for new exports. The key itself is never stored here.
  static const SettingKey<bool> encryptExports = SettingKey<bool>(
    'security.encryptExports',
    false,
  );

  /// Whether a PIN or biometric lock is armed. The PIN lives in secure storage.
  static const SettingKey<bool> appLockEnabled = SettingKey<bool>(
    'security.appLock',
    false,
  );

  /// Do not send originals to a provider.
  static const SettingKey<bool> aiDoNotSendImages = SettingKey<bool>(
    'ai.doNotSendImages',
    false,
  );

  /// Queue processing when a network appears.
  static const SettingKey<bool> aiAutoProcess = SettingKey<bool>(
    'ai.autoProcessWhenConnected',
    false,
  );

  /// Provider calls only on unmetered networks.
  static const SettingKey<bool> aiWifiOnly = SettingKey<bool>(
    'ai.wifiOnly',
    true,
  );

  /// Propose a refined caption without being asked.
  static const SettingKey<bool> aiRefineCaptions = SettingKey<bool>(
    'ai.refineCaptions',
    false,
  );

  /// High-confidence band copied from [AppConstants.confidence].
  static final SettingKey<double> confidenceHigh = SettingKey<double>(
    'ai.confidenceHigh',
    AppConstants.confidence.high,
  );

  /// Medium-confidence band copied from [AppConstants.confidence].
  static final SettingKey<double> confidenceMedium = SettingKey<double>(
    'ai.confidenceMedium',
    AppConstants.confidence.medium,
  );

  /// UI language.
  static const SettingKey<String> appLanguage = SettingKey<String>(
    'language.app',
    'en',
  );

  /// Speech-to-text language.
  static const SettingKey<String> voiceLanguage = SettingKey<String>(
    'language.voice',
    'en',
  );

  /// Chosen appearance. Survives a restart and a cache clear.
  static const SettingKey<String> themeMode = SettingKey<String>(
    'appearance.themeMode',
    'system',
  );

  /// Wire names of every declared key, so a raw string cannot sneak in.
  static List<String> get names => <String>[
    gpsEnabled.name,
    autoFillDates.name,
    photoQuality.name,
    folderStrategy.name,
    namingPattern.name,
    cameraMode.name,
    flash.name,
    grid.name,
    retentionDays.name,
    offlineByChoice.name,
    openProjectId.name,
    storageRootPath.name,
    lastLocation.name,
    encryptExports.name,
    appLockEnabled.name,
    aiDoNotSendImages.name,
    aiAutoProcess.name,
    aiWifiOnly.name,
    aiRefineCaptions.name,
    confidenceHigh.name,
    confidenceMedium.name,
    appLanguage.name,
    voiceLanguage.name,
    themeMode.name,
  ];
}
