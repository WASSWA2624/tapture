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

  /// Clear the lowest context level after idle. Off by default.
  static const SettingKey<bool> contextAutoClearEnabled = SettingKey<bool>(
    'context.autoClearEnabled',
    false,
  );

  /// Idle seconds before auto-clear. Ignored while auto-clear is off.
  static final SettingKey<int> contextAutoClearSeconds = SettingKey<int>(
    'context.autoClearSeconds',
    AppConstants.context.idleSeconds,
  );

  /// Ask to confirm context after movement. Off by default.
  static const SettingKey<bool> contextMovementPromptEnabled = SettingKey<bool>(
    'context.movementPromptEnabled',
    false,
  );

  /// Metres travelled before the movement prompt. Ignored while off.
  static final SettingKey<int> contextMovementMetres = SettingKey<int>(
    'context.movementMetres',
    AppConstants.context.movementMetres,
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

  /// Last used photo type for rapid tagging.
  static const SettingKey<String> lastPhotoType = SettingKey<String>(
    'capture.lastPhotoType',
    'other',
  );

  /// Template pinned for the current capture session.
  static const SettingKey<String?> pinnedTemplateId = SettingKey<String?>(
    'capture.pinnedTemplateId',
    null,
  );

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

  /// How many jobs a runner may hold at once.
  static final SettingKey<int> aiConcurrency = SettingKey<int>(
    'ai.concurrency',
    AppConstants.processing.concurrency,
  );

  /// Online extraction requests allowed for a project today.
  static final SettingKey<int> aiDailyRequestCap = SettingKey<int>(
    'ai.dailyRequestCap',
    AppConstants.processing.dailyRequestCap,
  );

  /// On-device reading while charging and idle. Off until switched on.
  static const SettingKey<bool> aiOpportunisticOcr = SettingKey<bool>(
    'ai.opportunisticOcr',
    false,
  );

  /// Score a fuzzy row match must reach before it is accepted.
  static final SettingKey<double> aiRowMatchThreshold = SettingKey<double>(
    'ai.rowMatchThreshold',
    AppConstants.processing.fuzzyMatch,
  );

  /// Local detection score at which a template is chosen without asking.
  static final SettingKey<double> aiDetectionConfident = SettingKey<double>(
    'ai.detectionConfident',
    AppConstants.processing.detectionConfident,
  );

  /// Lead the best template needs over the next before detection decides.
  static final SettingKey<double> aiDetectionGap = SettingKey<double>(
    'ai.detectionGap',
    AppConstants.processing.detectionGap,
  );

  /// Provider and model per operation, as a JSON object keyed by
  /// `AiOperation.name`: `{"extractFields": {"provider": "…", "model": "…"}}`.
  /// An operation missing from the map falls back to [aiProvider] and
  /// [aiModel].
  static const SettingKey<String> aiProviderSelection = SettingKey<String>(
    'ai.providerSelection',
    '{}',
  );

  /// Selected provider id. `backend` is the keyless organisation proxy.
  static const SettingKey<String> aiProvider = SettingKey<String>(
    'ai.provider',
    'backend',
  );

  /// Selected provider model. Validated against the current registry.
  static const SettingKey<String> aiModel = SettingKey<String>(
    'ai.model',
    'default',
  );

  /// UI language.
  static const SettingKey<String> appLanguage = SettingKey<String>(
    'language.app',
    AppConstants.defaultLanguage,
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
    contextAutoClearEnabled.name,
    contextAutoClearSeconds.name,
    contextMovementPromptEnabled.name,
    contextMovementMetres.name,
    autoFillDates.name,
    photoQuality.name,
    folderStrategy.name,
    namingPattern.name,
    cameraMode.name,
    flash.name,
    grid.name,
    lastPhotoType.name,
    pinnedTemplateId.name,
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
    aiConcurrency.name,
    aiDailyRequestCap.name,
    aiOpportunisticOcr.name,
    aiRowMatchThreshold.name,
    aiDetectionConfident.name,
    aiDetectionGap.name,
    aiProviderSelection.name,
    aiProvider.name,
    aiModel.name,
    appLanguage.name,
    voiceLanguage.name,
    themeMode.name,
  ];
}
