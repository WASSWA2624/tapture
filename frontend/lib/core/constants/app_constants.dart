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

  /// Recorder elapsed-time and input-level sampling cadence.
  static const Duration audioMeterTick = Duration(milliseconds: 100);

  /// Audio timings and the recording format, grouped for runtime callers.
  /// Speech needs no more than 16 kHz mono, which keeps a take small.
  static const ({Duration meterTick, int sampleRate, int channels}) audio = (
    meterTick: audioMeterTick,
    sampleRate: 16000,
    channels: 1,
  );

  /// How long dictation listens at most, how much silence ends it, and how
  /// long the recogniser gets to hand over its last words after a stop.
  static const ({Duration listenFor, Duration pauseFor, Duration settle})
  dictation = (
    listenFor: Duration(minutes: 1),
    pauseFor: Duration(seconds: 4),
    settle: Duration(seconds: 2),
  );

  /// How long a location fix may take before capture goes on without one.
  static const Duration locationTimeout = Duration(seconds: 3);

  /// How long the same barcode is ignored after a hit, so one code held in
  /// front of the camera is read once.
  static const Duration barcodeRepeatWindow = Duration(milliseconds: 800);

  /// One second, for durations a setting stores as a count of seconds.
  static const Duration second = Duration(seconds: 1);

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

  /// Markup sizes as fractions of the photo, so a mark looks the same at
  /// any resolution: stroke widths of the short edge and text heights of
  /// the height. Index 0 is small, 1 medium and 2 large. [panelShare] is the
  /// most of the screen the markup controls take beside or below the photo.
  /// A text backing is black at [backingAlpha], padded by [backingPad] of a
  /// line's height on every side.
  static const ({
    List<double> strokeFractions,
    List<double> textFractions,
    double panelShare,
    double backingAlpha,
    double backingPad,
  })
  markup = (
    strokeFractions: <double>[0.004, 0.008, 0.016],
    textFractions: <double>[0.04, 0.07, 0.11],
    panelShare: 0.45,
    backingAlpha: 0.6,
    backingPad: 0.25,
  );

  /// How long a tombstone and its files stay recoverable.
  static const ({int days}) retention = (days: 30);

  /// Default proposal bands; a project may override these in settings.
  static const ({double high, double medium}) confidence = (
    high: 0.85,
    medium: 0.60,
  );

  /// Names written into the on-disk preference store. Values never live here.
  static const ({String themeMode}) preferences = (
    themeMode: 'tapture.theme.mode',
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

  /// Context bar, recents and the two optional idle and movement settings.
  /// Both switches stay off until the operator turns them on (FE-SIMP-12).
  static const ({
    int idleSeconds,
    int movementMetres,
    int recentCap,
    int valuePreview,
    int barLines,
    Duration checkEvery,
    List<int> idleChoices,
    List<int> distanceChoices,
  })
  context = (
    idleSeconds: 300,
    movementMetres: 100,
    recentCap: 12,
    valuePreview: 18,
    barLines: 2,
    checkEvery: Duration(seconds: 30),
    idleChoices: <int>[300, 900, 1800],
    distanceChoices: <int>[50, 100, 250],
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

  /// Caps, backoff and detection cutoffs for processing.
  ///
  /// A project may override the concurrency cap, the daily request cap and
  /// the confidence bands through the settings store. These are the defaults.
  static const ({
    int extractionImageCap,
    int perceptualHashDistance,
    int concurrency,
    int dailyRequestCap,
    int maxAttempts,
    int backoffBaseMs,
    int backoffCapMs,
    Duration jobLease,
    Duration dayWindow,
    double detectionConfident,
    double detectionGap,
    double fuzzyMatch,
  })
  processing = (
    extractionImageCap: 8,
    perceptualHashDistance: 10,
    concurrency: 2,
    dailyRequestCap: 200,
    maxAttempts: 5,
    backoffBaseMs: 1000,
    backoffCapMs: 30000,
    jobLease: Duration(minutes: 5),
    dayWindow: Duration(days: 1),
    detectionConfident: 0.75,
    detectionGap: 0.1,
    fuzzyMatch: 0.82,
  );

  /// Builds a processing retry delay from the configured millisecond value.
  static Duration processingBackoff(int milliseconds) {
    return Duration(milliseconds: milliseconds);
  }

  /// Streaming reads for hashing and other heavy file jobs (FE-PERF-07).
  static const ({int chunkBytes}) hashing = (chunkBytes: 64 * 1024);

  /// Spreadsheet import: how many leading rows to score as a header, how
  /// many data rows to sample for type inference, the largest repeating
  /// set treated as a choice, and the shortest identifier.
  static const ({
    int headerScanRows,
    int sampleRows,
    int optionMax,
    int identifierMinLength,
  })
  workbook = (
    headerScanRows: 30,
    sampleRows: 40,
    optionMax: 12,
    identifierMinLength: 6,
  );

  /// Local operator identity: initials length and preference-map keys.
  /// [contactKey] is read for one-time migration; new writes use
  /// [emailKey] and [phoneKey].
  static const ({
    int initialsMin,
    int initialsMax,
    String initialsKey,
    String contactKey,
    String emailKey,
    String phoneKey,
  })
  operator = (
    initialsMin: 1,
    initialsMax: 3,
    initialsKey: 'operatorInitials',
    contactKey: 'operatorContact',
    emailKey: 'operatorEmail',
    phoneKey: 'operatorPhone',
  );

  /// The operator's in-app feedback: where it is kept, how an entry is
  /// numbered, how long it may be, how images are sized and laid out (the
  /// gallery's target tile, the preview cap, the desktop side panel), how
  /// long a webcam may take to produce a frame, and where the floating
  /// button first rests (as a fraction of the free width and height, so a
  /// rotation keeps it on screen).
  static const ({
    String storeName,
    String idPrefix,
    int idDigits,
    int maxMessageLength,
    int maxOtherLength,
    int screenshotLongEdge,
    int workbookImageEdge,
    int listPageSize,
    int maxShots,
    double galleryTile,
    double previewWidth,
    double panelWidth,
    Duration objectUrlLifetime,
    Duration cameraReady,
    double buttonStartX,
    double buttonStartY,
  })
  userFeedback = (
    storeName: 'feedback',
    idPrefix: 'FBK',
    idDigits: 7,
    maxMessageLength: 2000,
    maxOtherLength: 60,
    screenshotLongEdge: imageLongEdge,
    workbookImageEdge: 480,
    listPageSize: listPageSize,
    maxShots: 8,
    galleryTile: 160,
    previewWidth: 960,
    panelWidth: 420,
    objectUrlLifetime: Duration(seconds: 60),
    cameraReady: Duration(seconds: 2),
    buttonStartX: 1,
    buttonStartY: 0.78,
  );

  /// Optional app-lock PIN shape, the persisted attempt backoff, and how
  /// often the unlock screen counts that backoff down.
  static const ({
    int pinMin,
    int pinMax,
    int saltBytes,
    List<Duration> backoff,
    Duration countdownTick,
  })
  lock = (
    pinMin: 4,
    pinMax: 8,
    saltBytes: 16,
    countdownTick: Duration(seconds: 1),
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
