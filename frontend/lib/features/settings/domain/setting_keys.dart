import 'package:tapture/core/constants/app_constants.dart';

import 'setting_key.dart';

/// Every app-wide preference, typed, with its default.
///
/// Limits and durations come from [AppConstants]. Secrets never appear here.
abstract final class SettingKeys {
  /// Nonsecret backend provider/model capabilities cached for offline selection.
  static const SettingKey<String> aiCatalogue = SettingKey<String>(
    'ai.catalogue',
    '[]',
  );

  /// Explicit per-request approval in the organisation's budget units; zero
  /// allows only its base model. A default cannot authorize costly escalation.
  static const SettingKey<double> aiRequestMaxCost = SettingKey<double>(
    'ai.requestMaxCost',
    0,
  );

  /// GPS at capture. Off until a person turns it on (FE-SEC-07).
  static const SettingKey<bool> gpsEnabled = SettingKey<bool>(
    'capture.gps',
    false,
  );

  /// Exports leave coordinates out: location fields and photo location
  /// details. On until a person turns it off (FE-SEC-07).
  static const SettingKey<bool> excludeCoordinates = SettingKey<bool>(
    'privacy.excludeCoordinates',
    true,
  );

  /// Exported photos have detected faces blurred; a photo whose faces cannot
  /// be checked stays out of the export. Off until a person turns it on.
  static const SettingKey<bool> blurFaces = SettingKey<bool>(
    'privacy.blurFaces',
    false,
  );

  /// Explicit outbound permissions, encoded by EgressSwitches. Missing or
  /// legacy implicit permissions keep every path off.
  static const SettingKey<String> egressOff = SettingKey<String>(
    'privacy.egressOff',
    '{}',
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

  /// The records list's last filter and sort per project (task 014, D11), as
  /// a JSON object keyed by project id:
  /// `{"<projectId>": {"filter": {…}, "sort": {"key": "number", …}}}`.
  /// Search text is never stored. A project missing from the map lists with
  /// no filter, newest first.
  static const SettingKey<String> recordListCriteria = SettingKey<String>(
    'records.listCriteria',
    '{}',
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

  /// UTC-day request counts outside record jobs; no prompt or result content.
  static const SettingKey<String> aiAuxiliaryUsage = SettingKey<String>(
    'ai.auxiliaryUsage',
    '{}',
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

  /// How on-device speech trades speed for accuracy: `auto`, `fast` or
  /// `accurate` (spec §30.4.2). Automatic, so most people never touch it;
  /// FE-SIMP-12: one device serves battery-limited field days (fast) and
  /// accuracy-critical meetings while charging (accurate), which no single
  /// default can serve both.
  static const SettingKey<String> speechQuality = SettingKey<String>(
    'speech.quality',
    'auto',
  );

  /// Chosen appearance. Survives a restart and a cache clear.
  static const SettingKey<String> themeMode = SettingKey<String>(
    'appearance.themeMode',
    'system',
  );

  /// Verification mode for the open project: capture confirms a register
  /// instead of creating a blank record (task 015). Off until a person
  /// turns it on.
  static const SettingKey<bool> verificationMode = SettingKey<bool>(
    'quality.verificationMode',
    false,
  );

  /// Which side a review row shows first: `raw` or `refined` (task 016).
  /// The latest choice in a project becomes the next field's starting side.
  static const SettingKey<String> reviewValueSide = SettingKey<String>(
    'review.valueSide',
    'refined',
  );

  /// Wire names of every declared key, so a raw string cannot sneak in.
  static List<String> get names => <String>[
    aiCatalogue.name,
    aiRequestMaxCost.name,
    gpsEnabled.name,
    excludeCoordinates.name,
    blurFaces.name,
    egressOff.name,
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
    recordListCriteria.name,
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
    aiAuxiliaryUsage.name,
    aiOpportunisticOcr.name,
    aiRowMatchThreshold.name,
    aiDetectionConfident.name,
    aiDetectionGap.name,
    aiProviderSelection.name,
    aiProvider.name,
    aiModel.name,
    appLanguage.name,
    voiceLanguage.name,
    speechQuality.name,
    themeMode.name,
    verificationMode.name,
    reviewValueSide.name,
  ];
}
