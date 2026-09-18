/// The one place every duration, size, limit, threshold and storage key
/// name is defined (FE-CODE-09).
///
/// Values are grouped by area on this type. Dart has no nested classes, so
/// each area is a const record a caller reaches through one name
/// (`AppConstants.lists.pageSize`) rather than a flat namespace.
abstract final class AppConstants {
  /// Page length for every paged query (FE-PERF-03).
  static const int listPageSize = 50;

  /// Long edge, in pixels, of a reduced photo written for upload.
  static const int imageLongEdge = 1600;

  /// Motion timings used by chrome that is not a design-token duration.
  static const ({Duration short, Duration medium, Duration long}) motion = (
    short: Duration(milliseconds: 150),
    medium: Duration(milliseconds: 300),
    long: Duration(milliseconds: 450),
  );

  /// How long a snack stays up so a second message can queue behind it.
  static const ({Duration snack}) feedback = (
    snack: Duration(milliseconds: 4000),
  );

  /// Intervals that wait for the operator to finish typing or scanning.
  static const ({Duration debounce}) interaction = (
    debounce: Duration(milliseconds: 300),
  );

  /// Bounds for virtualised lists and trays.
  static const ({int pageSize}) lists = (pageSize: listPageSize);

  /// Capture, thumbnail and upload image sizes.
  static const ({
    int longEdge,
    int quality,
    int thumbnailEdge,
    int previewEdge,
    int thumbnailQuality,
    int concurrentDecodes,
    Duration cacheMaxAge,
    int cacheMaxBytes,
  })
  images = (
    longEdge: imageLongEdge,
    quality: 85,
    thumbnailEdge: 96,
    previewEdge: 256,
    thumbnailQuality: 70,
    concurrentDecodes: 2,
    cacheMaxAge: Duration(days: 30),
    cacheMaxBytes: 200 * _mib,
  );

  /// How long a tombstone and its files stay recoverable.
  static const ({int days}) retention = (days: 30);

  /// Default proposal bands; a project may override these in settings.
  static const ({double high, double medium}) confidence = (
    high: 0.85,
    medium: 0.60,
  );

  /// Names written into the on-disk preference store. Values never live here.
  static const ({String themeMode, String firstRun}) preferences = (
    themeMode: 'tapture.theme.mode',
    firstRun: 'tapture.first-run',
  );

  /// Names written into platform secure storage. Values never live here.
  static const ({
    String pinSalt,
    String pinHash,
    String pinBackoff,
    String providerCredential,
    String relayProject,
    String cloudAccess,
    String cloudRefresh,
    String databaseEncryption,
  })
  secrets = (
    pinSalt: 'tapture.pin.salt',
    pinHash: 'tapture.pin.hash',
    pinBackoff: 'tapture.pin.backoff',
    providerCredential: 'tapture.provider.credential',
    relayProject: 'tapture.relay.project',
    cloudAccess: 'tapture.cloud.access',
    cloudRefresh: 'tapture.cloud.refresh',
    databaseEncryption: 'tapture.db.encryption',
  );

  /// Ring buffer and observer limits for the logger (task 022).
  static const ({
    int bufferSize,
    int rotationCount,
    int retentionDays,
    int rebuildThreshold,
  })
  logging = (
    bufferSize: 500,
    rotationCount: 3,
    retentionDays: 7,
    rebuildThreshold: 20,
  );

  /// Free-space headroom that warns and then blocks capture.
  static const ({int lowBytes, int criticalBytes}) storage = (
    lowBytes: 500 * _mib,
    criticalBytes: 100 * _mib,
  );

  /// Path sanitiser and photo-folder defaults.
  static const ({
    int maxSegmentLength,
    int idSuffixLength,
    String defaultStrategy,
  })
  folders = (
    maxSegmentLength: 80,
    idSuffixLength: 6,
    defaultStrategy: 'byContext',
  );

  /// Ceilings an imported file must clear before it is parsed.
  static const ({
    int sniffHeaderBytes,
    int imageMaxBytes,
    int documentMaxBytes,
    int spreadsheetMaxBytes,
    int audioMaxBytes,
    int bundleMaxBytes,
    int archiveUncompressedMaxBytes,
  })
  imports = (
    sniffHeaderBytes: 64,
    imageMaxBytes: 25 * _mib,
    documentMaxBytes: 20 * _mib,
    spreadsheetMaxBytes: 15 * _mib,
    audioMaxBytes: 50 * _mib,
    bundleMaxBytes: 200 * _mib,
    archiveUncompressedMaxBytes: 500 * _mib,
  );

  /// Caps for extraction requests and perceptual matching.
  static const ({int extractionImageCap, int perceptualHashDistance})
  processing = (extractionImageCap: 8, perceptualHashDistance: 10);

  /// Streaming reads for hashing and other heavy file jobs (FE-PERF-07).
  static const ({int chunkBytes}) hashing = (chunkBytes: 64 * 1024);

  /// Local operator identity: initials length and preference-map keys.
  static const ({
    int initialsMin,
    int initialsMax,
    String initialsKey,
    String contactKey,
  })
  operator = (
    initialsMin: 1,
    initialsMax: 3,
    initialsKey: 'operatorInitials',
    contactKey: 'operatorContact',
  );

  /// Optional app-lock PIN shape and the persisted attempt backoff.
  static const ({int pinMin, int pinMax, int saltBytes, List<Duration> backoff})
  lock = (
    pinMin: 4,
    pinMax: 8,
    saltBytes: 16,
    backoff: <Duration>[
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
      Duration(seconds: 30),
    ],
  );
}

/// One mebibyte, the unit storage and import ceilings are stated in.
const int _mib = 1024 * 1024;
