/// The one place every duration, size, limit, threshold and storage key
/// name is defined (FE-CODE-09).
///
/// Values are grouped by area on this type. Dart has no nested classes, so
/// each area is a const record a caller reaches through one name
/// (`AppConstants.lists.pageSize`) rather than a flat namespace.
abstract final class AppConstants {
  /// Bounded catalogue shortlist for explicit text-only AI suggestions.
  static const int aiTemplateCandidateLimit = 8;

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

  /// The on-device speech engine (spec §30.4.3).
  ///
  /// Lifetimes: a worker isolate has `workerStart` to begin serving and
  /// `workerCloseGrace` to clean up after a close before it is killed. An
  /// idle model is released after `idleRelease` on a phone on battery, and
  /// after `idleReleaseExtended` on a desktop or while charging.
  ///
  /// Device thresholds for model selection: memory in bytes (or GiB of the
  /// browser's `deviceMemory`), cores, the `memoryHeadroomPercent` a model's
  /// estimate is scaled by, and the battery level below which a phone is
  /// treated as saving power. Thread caps per class of device.
  ///
  /// Decoding: a request carries `minDecodeSamples` to `maxDecodeSamples`
  /// of 16 kHz audio. The encoder sees `encoderFramesPerSecond` frames per
  /// second of audio, at most `maxAudioContext`; a profile's pad adds
  /// context frames past the audio (`interimAudioContextPad`,
  /// `committedAudioContextPad` for finals, `reducedAudioContextPad` for a
  /// full-context final under backlog, `mobileDictationCommittedPad` for a
  /// phone's dictation finals shorter than `mobileDictationShortUtterance`).
  /// A committed final's context is never shorter than
  /// `committedMinAudioContext` frames: whisper, trained on 30 s windows,
  /// loops, drops or invents words when its context ends soon after the
  /// speech (spec §30.4.2 rule 8).
  /// The three thresholds and `temperatureStep` are whisper's fallback
  /// rules. Native log lines are cut to `logLineChars`, at most
  /// `logLinesPerDrain` per command. A lane restarts at most
  /// `maxWorkerRestarts` times per host session, and a model whose load
  /// killed the process `maxLoadAttempts` times is held as suspect.
  static const ({
    Duration workerStart,
    Duration workerCloseGrace,
    Duration idleRelease,
    Duration idleReleaseExtended,
    int minTotalMemoryBytes,
    int webMinDeviceMemoryGiB,
    int webBaseDeviceMemoryGiB,
    int balancedMemoryBytes,
    int accurateMemoryBytes,
    int balancedCores,
    int accurateCores,
    int memoryHeadroomPercent,
    int lowBatteryPercent,
    int mobileMaxThreads,
    int desktopMaxThreads,
    int saverThreads,
    int webMaxThreads,
    int maxDecodeSamples,
    int minDecodeSamples,
    int interimMaxPieces,
    int interimAudioContextPad,
    int committedAudioContextPad,
    int committedMinAudioContext,
    int reducedAudioContextPad,
    int mobileDictationCommittedPad,
    Duration mobileDictationShortUtterance,
    int encoderFramesPerSecond,
    int maxAudioContext,
    double noSpeechThreshold,
    double logprobThreshold,
    double entropyThreshold,
    double temperatureStep,
    int logLineChars,
    int logLinesPerDrain,
    int maxWorkerRestarts,
    int maxLoadAttempts,
  })
  speechEngine = (
    workerStart: Duration(seconds: 10),
    workerCloseGrace: Duration(seconds: 5),
    idleRelease: Duration(minutes: 2),
    idleReleaseExtended: Duration(minutes: 10),
    minTotalMemoryBytes: 1536 * _mib,
    webMinDeviceMemoryGiB: 2,
    webBaseDeviceMemoryGiB: 4,
    balancedMemoryBytes: 3072 * _mib,
    accurateMemoryBytes: 6144 * _mib,
    balancedCores: 4,
    accurateCores: 6,
    memoryHeadroomPercent: 125,
    lowBatteryPercent: 30,
    mobileMaxThreads: 4,
    desktopMaxThreads: 8,
    saverThreads: 2,
    webMaxThreads: 4,
    maxDecodeSamples: 30 * 16000,
    minDecodeSamples: 16000,
    interimMaxPieces: 96,
    interimAudioContextPad: 64,
    committedAudioContextPad: 128,
    committedMinAudioContext: 896,
    reducedAudioContextPad: 128,
    mobileDictationCommittedPad: 256,
    mobileDictationShortUtterance: Duration(seconds: 10),
    encoderFramesPerSecond: 50,
    maxAudioContext: 1500,
    noSpeechThreshold: 0.6,
    logprobThreshold: -1,
    entropyThreshold: 2.4,
    temperatureStep: 0.2,
    logLineChars: 160,
    logLinesPerDrain: 8,
    maxWorkerRestarts: 2,
    maxLoadAttempts: 2,
  );

  /// Speech budgets the benchmarks assert (spec §30.4.3, FE-TEST-09), on
  /// the Windows reference machine. Load times include the in-shim SHA-256
  /// check. A real-time factor is compute time over audio time. `vadSecond`
  /// is VAD compute per second of audio, and `pipelinePerAudioSecond` the
  /// pipeline's own main-isolate work per second. RSS budgets are peaks
  /// while loaded and what stays after release; `uiDrift` bounds how much
  /// later than with the engine idle the 99th-percentile tick of a
  /// frame-rate timer on the UI isolate fires while a decode runs (an idle
  /// tick is already late by the system timer's granularity). Benchmarks
  /// check the other budgets on medians because other work on the machine
  /// adds noise.
  ///
  /// Recalibrated by task 128 (2026-10-05, i7-1165G7, 29–100% busy with
  /// other work; evidence in `build/speech-benchmark*.json`,
  /// `speech-memory-profile.json` and `stt-long-session-heap.json`). The
  /// peak RSS budgets are tightened to about 1.5 times the measured peaks
  /// (tiny 119–128 MiB, base 165–167 MiB). `longSessionRetainedRssBytes` is
  /// raised from 8 MiB: five identical sessions kept the live heap after a
  /// forced collection flat (121.3–122.2 MiB) while RSS retention, which
  /// is garbage not yet collected, ranged from −38 to 40.5 MiB. The rest
  /// stand as designed and are not loosened.
  ///
  /// A final's compute at p90 has a budget per model (2026-10-05, tasks
  /// 117 and 118): with finals sized over `committedMinAudioContext`, tiny
  /// meets the original 1000 ms, while base, which no context that keeps
  /// every word brings under 1.1 s on this 4-core machine, gets 2000 ms
  /// rather than `auto` falling back to the less accurate tiny (spec
  /// §30.4.2 rule 8, §30.4.3).
  static const ({
    Duration tinyLoad,
    Duration baseLoad,
    double tinyRealTime,
    double baseRealTime,
    Duration abortLatencyDesktop,
    Duration vadSecond,
    int tinyPeakRssBytes,
    int basePeakRssBytes,
    int retainedRssBytes,
    Duration pipelinePerAudioSecond,
    Duration firstPartialCompute,
    Duration tinyFinalizeCompute,
    Duration baseFinalizeCompute,
    int longSessionPeakRssBytes,
    int longSessionRetainedRssBytes,
    Duration uiDrift,
  })
  speechBudgets = (
    tinyLoad: Duration(seconds: 2),
    baseLoad: Duration(seconds: 4),
    tinyRealTime: 0.35,
    baseRealTime: 0.5,
    abortLatencyDesktop: Duration(milliseconds: 500),
    vadSecond: Duration(milliseconds: 60),
    tinyPeakRssBytes: 192 * _mib,
    basePeakRssBytes: 256 * _mib,
    retainedRssBytes: 32 * _mib,
    pipelinePerAudioSecond: Duration(milliseconds: 15),
    firstPartialCompute: Duration(milliseconds: 1500),
    tinyFinalizeCompute: Duration(milliseconds: 1000),
    baseFinalizeCompute: Duration(milliseconds: 2500),
    longSessionPeakRssBytes: 64 * _mib,
    longSessionRetainedRssBytes: 48 * _mib,
    uiDrift: Duration(milliseconds: 32),
  );

  /// The on-device speech pipeline (spec §30.4.3, §30.4.7).
  ///
  /// Voice detection: a frame counts as speech from `vadOnThreshold` and
  /// keeps an utterance going down to `vadOffThreshold`; frames are sent to
  /// the detector `vadBatchWindows` at a time. Durations are rounded up to
  /// whole detector frames. An utterance opens after `minSpeech` of speech,
  /// tolerating dips up to `onsetGapTolerance` while it builds, and starts
  /// `preRoll` before its onset (also the detector's warm-up context after
  /// a reset). It closes after `endSilence` of silence, keeping `postRoll`
  /// past its last speech; past `softMaxUtterance` it closes at the first
  /// dip, and at `maxUtterance` it is cut at the quietest three frames of
  /// the last `cutSearchWindow`, the next one re-reading `seamOverlap`
  /// before the cut. In silence a frame is quiet, and a batch of quiet
  /// frames skips the detector, only below `energyGateCeilingDbfs` and
  /// within `energyGateMarginDb` of the quietest level of the last
  /// `noiseFloorWindow`.
  ///
  /// Decoding: an open utterance is drafted from `interimMinAudio` on, each
  /// time it grows by a step of its smoothed interim compute time
  /// (`interimEwmaAlpha`) over the duty share (`interimMaxDutyDesktop`,
  /// `interimMaxDutyMobile`), held between `interimMinStep` and
  /// `interimMaxStep`; a phone stops drafting past
  /// `mobileInterimMaxUtterance`. A draft's words from where it repeats a
  /// phrase of `interimRepeatWords` words it already said stay tentative.
  /// Finals waiting beyond
  /// `finalBacklogInterimsOff` switch drafts off and warn at most every
  /// `engineBehindNoticeInterval` of audio; beyond
  /// `finalBacklogReducedContext` a final that would encode the full
  /// context is sized like the committed profile's; both
  /// recover below `finalBacklogRecover`. After
  /// `maxConsecutiveDecodeFailures` failed decodes in a row transcription
  /// stops. Drafts never carry a prompt, and finals carry one only with
  /// `carryPrompt`, off by default as in whisper.cpp's streaming example:
  /// whisper skips speech its prompt already holds, which drops repeated
  /// sentences. When on, the last `promptCarryChars` of the transcript
  /// condition the next final, except for an utterance shorter than
  /// `promptCarryMinUtterance` or quieter than `promptCarryMinDbfs`, and
  /// are forgotten after `promptResetGap` without speech. A known
  /// hallucination is dropped over audio quieter than
  /// `hallucinationEnergyDbfs`, less than `hallucinationSpeechRatio` speech
  /// or a mean log probability below `hallucinationLogProb`; a weak edge
  /// word is trimmed only when no speech frame lies within
  /// `edgeTrimTolerance` of it, since whisper times a first word a few
  /// frames early. A phrase of up
  /// to `loopMaxNgram` words repeated `loopMinRepeatsPhrase` times (a word
  /// `loopMinRepeatsWord` times) collapses when it has more words than
  /// `loopWordsPerSecond` per second of detected speech, or is said faster
  /// than `minSecondsPerWord` a word. Across a hard cut, the earlier
  /// utterance holds back its words ending past the seam less
  /// `seamTolerance`, and the next one's decode settles them by text.
  ///
  /// The resampler brings a 48 or 44.1 kHz capture down to 16 kHz with a
  /// Kaiser-windowed sinc:
  /// `resamplerZeroCrossings` per side, a β of `resamplerKaiserBeta` (about
  /// 70 dB stopband), a cutoff at `resamplerCutoffRatio` of the lower
  /// Nyquist rate, and at most `resamplerMaxPhases` polyphase branches. The
  /// last `ringDuration` of a take is served from memory, the rest from
  /// its file.
  static const ({
    double vadOnThreshold,
    double vadOffThreshold,
    int vadBatchWindows,
    Duration minSpeech,
    Duration onsetGapTolerance,
    Duration preRoll,
    Duration endSilence,
    Duration postRoll,
    Duration softMaxUtterance,
    Duration maxUtterance,
    Duration cutSearchWindow,
    Duration seamOverlap,
    Duration seamTolerance,
    Duration noiseFloorWindow,
    double energyGateMarginDb,
    double energyGateCeilingDbfs,
    Duration interimMinAudio,
    Duration interimMinStep,
    Duration interimMaxStep,
    double interimMaxDutyDesktop,
    double interimMaxDutyMobile,
    Duration mobileInterimMaxUtterance,
    double interimEwmaAlpha,
    int interimRepeatWords,
    bool carryPrompt,
    int promptCarryChars,
    Duration promptCarryMinUtterance,
    double promptCarryMinDbfs,
    Duration promptResetGap,
    double hallucinationEnergyDbfs,
    double hallucinationSpeechRatio,
    double hallucinationLogProb,
    Duration edgeTrimTolerance,
    int loopMinRepeatsPhrase,
    int loopMinRepeatsWord,
    int loopMaxNgram,
    double minSecondsPerWord,
    double loopWordsPerSecond,
    Duration ringDuration,
    Duration finalBacklogInterimsOff,
    Duration finalBacklogReducedContext,
    Duration finalBacklogRecover,
    Duration engineBehindNoticeInterval,
    int maxConsecutiveDecodeFailures,
    int resamplerZeroCrossings,
    double resamplerKaiserBeta,
    double resamplerCutoffRatio,
    int resamplerMaxPhases,
  })
  speechPipeline = (
    vadOnThreshold: 0.5,
    vadOffThreshold: 0.35,
    vadBatchWindows: 4,
    minSpeech: Duration(milliseconds: 250),
    onsetGapTolerance: Duration(milliseconds: 96),
    preRoll: Duration(milliseconds: 320),
    endSilence: Duration(milliseconds: 800),
    postRoll: Duration(milliseconds: 192),
    softMaxUtterance: Duration(seconds: 20),
    maxUtterance: Duration(seconds: 25),
    cutSearchWindow: Duration(seconds: 3),
    seamOverlap: Duration(seconds: 1),
    seamTolerance: Duration(milliseconds: 200),
    noiseFloorWindow: Duration(seconds: 5),
    energyGateMarginDb: 3,
    energyGateCeilingDbfs: -60,
    interimMinAudio: Duration(milliseconds: 800),
    interimMinStep: Duration(milliseconds: 600),
    interimMaxStep: Duration(seconds: 3),
    interimMaxDutyDesktop: 0.6,
    interimMaxDutyMobile: 0.3,
    mobileInterimMaxUtterance: Duration(seconds: 10),
    interimEwmaAlpha: 0.3,
    interimRepeatWords: 3,
    carryPrompt: false,
    promptCarryChars: 200,
    promptCarryMinUtterance: Duration(seconds: 2),
    promptCarryMinDbfs: -55,
    promptResetGap: Duration(seconds: 60),
    hallucinationEnergyDbfs: -55,
    hallucinationSpeechRatio: 0.3,
    hallucinationLogProb: -0.8,
    edgeTrimTolerance: Duration(milliseconds: 96),
    loopMinRepeatsPhrase: 3,
    loopMinRepeatsWord: 4,
    loopMaxNgram: 6,
    minSecondsPerWord: 0.12,
    loopWordsPerSecond: 4,
    ringDuration: Duration(seconds: 30),
    finalBacklogInterimsOff: Duration(seconds: 10),
    finalBacklogReducedContext: Duration(seconds: 30),
    finalBacklogRecover: Duration(seconds: 3),
    engineBehindNoticeInterval: Duration(seconds: 30),
    maxConsecutiveDecodeFailures: 3,
    resamplerZeroCrossings: 16,
    resamplerKaiserBeta: 7,
    resamplerCutoffRatio: 0.9,
    resamplerMaxPhases: 512,
  );

  /// Streaming capture and live-session limits (spec §30.4.3). A capture
  /// that refuses 16 kHz retries `fallbackCaptureRates` in order. The
  /// staging WAV header is patched and flushed every `wavFlushInterval` of
  /// audio. Publishing a take holds the directory lock for no longer than
  /// `adoptLockBudget`.
  static const ({
    List<int> fallbackCaptureRates,
    Duration wavFlushInterval,
    Duration webChunkDuration,
    Duration maxSessionDuration,
    Duration webMaxSessionDuration,
    Duration storageCheckInterval,
    Duration adoptLockBudget,
  })
  speechSession = (
    fallbackCaptureRates: <int>[48000, 44100],
    wavFlushInterval: Duration(seconds: 5),
    webChunkDuration: Duration(seconds: 5),
    maxSessionDuration: Duration(hours: 4),
    webMaxSessionDuration: Duration(minutes: 30),
    storageCheckInterval: Duration(seconds: 60),
    adoptLockBudget: Duration(milliseconds: 100),
  );

  /// Live transcripts and their history (spec §30.4.3). Interim text is
  /// shown at most every `partialInterval`; dictation waits up to
  /// `dictationFinalize` for its last words. A paragraph breaks after a
  /// pause of `paragraphGap`, or at `paragraphMaxSegments` segments or
  /// `paragraphMaxChars` characters. A history row previews
  /// `previewChars` characters, `historyPage` rows at a time. Appending an
  /// utterance stays within `segmentWriteBudget` with `benchmarkSegments`
  /// segments stored, and the first history page within
  /// `historyQueryBudget` over `benchmarkTranscripts` transcripts.
  static const ({
    Duration partialInterval,
    Duration dictationFinalize,
    Duration paragraphGap,
    int paragraphMaxSegments,
    int paragraphMaxChars,
    int previewChars,
    int historyPage,
    Duration segmentWriteBudget,
    Duration historyQueryBudget,
    int benchmarkSegments,
    int benchmarkTranscripts,
  })
  transcripts = (
    partialInterval: Duration(milliseconds: 250),
    dictationFinalize: Duration(seconds: 12),
    paragraphGap: Duration(milliseconds: 1500),
    paragraphMaxSegments: 6,
    paragraphMaxChars: 600,
    previewChars: 120,
    historyPage: listPageSize,
    segmentWriteBudget: Duration(milliseconds: 20),
    historyQueryBudget: Duration(milliseconds: 150),
    benchmarkSegments: 5000,
    benchmarkTranscripts: 2000,
  );

  /// How long a location fix may take before capture goes on without one.
  static const Duration locationTimeout = Duration(seconds: 3);

  /// How long the same barcode is ignored after a hit, so one code held in
  /// front of the camera is read once.
  static const Duration barcodeRepeatWindow = Duration(milliseconds: 800);

  /// One second, for durations a setting stores as a count of seconds.
  static const Duration second = Duration(seconds: 1);

  /// One millisecond, for delays a setting stores as a count of
  /// milliseconds, such as an upload retry backoff.
  static const Duration millisecond = Duration(milliseconds: 1);

  /// One microsecond, for exact durations derived from recorded sample bytes.
  static const Duration microsecond = Duration(microseconds: 1);

  /// Bounds for virtualised lists and trays.
  static const ({int pageSize}) lists = (pageSize: listPageSize);

  /// Scrolling the records list smoothly at 10,000 rows (FE-PERF-01,
  /// task 014), as the scroll measurement asserts it (FE-TEST-09): nine
  /// drag frames in ten finish within [frame], no frame takes longer than
  /// [worstFrame], and no more than [livePages] pages of [lists] rows are
  /// read at once:
  /// the two a screen can straddle, and the two a jump replaces them with.
  ///
  /// The times are for the debug test runner, which builds a frame many
  /// times slower than a release build and shares the machine with other
  /// suites. They catch a list whose work grows with its length (rows
  /// materialised, sorted or laid out off screen), which costs seconds a
  /// frame at this size; the measurement also bounds the rows a frame
  /// builds to the ones on screen, which holds on any machine.
  static const ({Duration frame, Duration worstFrame, int livePages})
  scrolling = (
    frame: Duration(milliseconds: 250),
    worstFrame: Duration(seconds: 2),
    livePages: 4,
  );

  /// Reference datasets (task 010). A table file is read [readChunkBytes]
  /// at a time and reports progress every [progressRows] rows; a search the
  /// database cannot fold reads [scanChunk] rows a query; and a search over
  /// ten thousand rows answers within [searchBudget], as the repository and
  /// browser measurements assert (FE-TEST-09).
  static const ({
    int readChunkBytes,
    int progressRows,
    int scanChunk,
    Duration searchBudget,
  })
  datasets = (
    readChunkBytes: 64 * 1024,
    progressRows: 1000,
    scanChunk: 500,
    searchBudget: Duration(milliseconds: 300),
  );

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
  static const ({int days, Duration duration}) retention = (
    days: _retentionDays,
    duration: Duration(days: _retentionDays),
  );

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
    String backendSession,
    String relayKeys,
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
    backendSession: 'tapture.backend.session',
    relayKeys: 'tapture.relay.keys',
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
    Duration incomingBridgeTimeout,
  })
  imports = (
    sniffHeaderBytes: 64,
    imageMaxBytes: 25 * _mib,
    documentMaxBytes: 20 * _mib,
    spreadsheetMaxBytes: 15 * _mib,
    audioMaxBytes: 50 * _mib,
    bundleMaxBytes: 200 * _mib,
    archiveUncompressedMaxBytes: 500 * _mib,
    incomingBridgeTimeout: Duration(seconds: 5),
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
    Duration idleAfter,
    double detectionConfident,
    double detectionGap,
    double fuzzyMatch,
    double preprocessContrast,
    int inkLumaThreshold,
    List<double> deskewAnglesDegrees,
    int deskewMarginDivisor,
    int deskewMinEdge,
    int projectionSamples,
    double detectionKeywordWeight,
    double detectionPatternWeight,
    double detectionNegativeKeywordWeight,
    double rowMatchAliasScore,
    double rowMatchNormalisedScore,
    double rowMatchNormalisedAliasScore,
    double rowMatchModelScore,
    double identifierFallbackConfidence,
    double identifierPositionWeight,
    double identifierSpecificityWeight,
    double identifierConfidenceWeight,
    int failuresPageSize,
    int notificationId,
    String ocrEngineMlKit,
    String ocrEngineDesktop,
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
    idleAfter: Duration(minutes: 2),
    detectionConfident: 0.75,
    detectionGap: 0.1,
    fuzzyMatch: 0.82,
    // Contrast multiplier applied to a copy prepared for reading.
    preprocessContrast: 1.25,
    // Luma below which a pixel counts as ink when deskewing.
    inkLumaThreshold: 180,
    // Small rotations tried when straightening a prepared copy.
    deskewAnglesDegrees: <double>[-2, -1, 1, 2],
    // The deskew canvas margin is the upright edge divided by this.
    deskewMarginDivisor: 5,
    // Images narrower or shorter than this are not deskewed.
    deskewMinEdge: 16,
    // Samples per axis when scoring a deskew projection.
    projectionSamples: 80,
    // Template detection: each keyword hit, each identifier pattern hit,
    // and each negative keyword hit (subtracted).
    detectionKeywordWeight: 0.35,
    detectionPatternWeight: 0.5,
    detectionNegativeKeywordWeight: 0.4,
    // Row matching scores for the alias, normalised and normalised-alias
    // strategies.
    rowMatchAliasScore: 0.98,
    rowMatchNormalisedScore: 0.95,
    rowMatchNormalisedAliasScore: 0.93,
    rowMatchModelScore: 0.9,
    // Confidence given to an identifier candidate with no block score.
    identifierFallbackConfidence: 0.5,
    // Identifier ranking: how high the block sits on the plate, how specific
    // the field's pattern is, and the block's OCR confidence. Each term lies
    // in 0..1, so the weights say how much each one counts.
    identifierPositionWeight: 0.3,
    identifierSpecificityWeight: 0.3,
    identifierConfidenceWeight: 0.4,
    // Failed jobs per page on the failures list.
    failuresPageSize: 50,
    // The one local notification a batch posts, replaced by the next.
    notificationId: 1,
    // The name an OCR result records for the reader that produced it.
    ocrEngineMlKit: 'ml-kit-text-recognition',
    ocrEngineDesktop: 'desktop-glyph-reader',
  );

  /// The OCR engine name when a result does not say which reader made it.
  ///
  /// A plain constant rather than a [processing] field so it can be a
  /// parameter default.
  static const String ocrEngineUnspecified = 'unspecified';

  /// The language a project falls back to when neither it nor the app
  /// store names one.
  static const String defaultLanguage = 'en';

  /// Builds a processing retry delay from the configured millisecond value.
  static Duration processingBackoff(int milliseconds) {
    return Duration(milliseconds: milliseconds);
  }

  /// Streaming reads for hashing and other heavy file jobs (FE-PERF-07).
  static const ({int chunkBytes}) hashing = (chunkBytes: 64 * 1024);

  /// Attendance-sheet row grouping and how a long recording is split
  /// before transcription (task 017).
  static const ({int rowBand, int transcriptChunkBytes}) meetings = (
    rowBand: 8,
    transcriptChunkBytes: 64 * 1024,
  );

  /// Password sealing for a project bundle (task 019).
  static const ({int iterations, int maxIterations}) bundleSeal = (
    iterations: 600000,
    maxIterations: 1200000,
  );

  /// How exported multi-values are joined, in every format (task 018).
  static const ({String multiSeparator}) exportValues = (multiSeparator: '; ');

  /// Shared PDF page geometry beyond the type and spacing tokens: the photo
  /// block's full-size height and the page cap. Reports never define
  /// private layout values.
  static const ({double photoHeight, int maxPages}) pdfLayout = (
    photoHeight: 400,
    maxPages: 10000,
  );

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

  /// Project packages (task 076, D6). On a device a package streams to
  /// disk and stays under the ZIP32 limit, so no ZIP64 is needed; its entries
  /// may uncompress to at most ten percent more. A browser builds and opens
  /// packages in memory under the import ceilings instead.
  static const ({
    int nativeMaxBytes,
    int nativeMaxUncompressedBytes,
    int metadataMaxBytes,
    int manifestMaxBytes,
  })
  bundles = (
    nativeMaxBytes: 4000000000,
    nativeMaxUncompressedBytes: 4400000000,
    metadataMaxBytes: 32 * _mib,
    manifestMaxBytes: _mib,
  );

  /// Capture's guide (task 076, W18): at most this many fields in each of
  /// its lists, so it stays a glance, not a form.
  static const ({int guideMaxFields}) capture = (guideMaxFields: 6);

  /// Searching lists and the template catalogue: a word shorter than
  /// [minWordLength] means nothing on its own and is skipped, unless it holds
  /// a digit, as a code's "001" does.
  static const ({int minWordLength}) search = (minWordLength: 3);

  /// Merging a package (task 076, W22): an incoming record captured within
  /// [duplicateWindow] of a local one, with the same context and a caption
  /// at least [duplicateCaptionSimilarity] alike, is shown as a possible
  /// duplicate. A person decides; nothing is merged by it.
  static const ({Duration duplicateWindow, double duplicateCaptionSimilarity})
  merge = (
    duplicateWindow: Duration(hours: 24),
    duplicateCaptionSimilarity: 0.9,
  );

  /// How strongly each duplicate signal ranks a pair (task 015). A higher
  /// score is a closer match. Detection only proposes; a person decides.
  static const ({
    double identity,
    double samePhoto,
    double nearPhoto,
    double predefinedRow,
    double nameContext,
  })
  quality = (
    identity: 1,
    samePhoto: 0.95,
    nearPhoto: 0.8,
    predefinedRow: 0.7,
    nameContext: 0.6,
  );

  /// Project files in a browser, which has no file system: the IndexedDB
  /// store `FileWriter` and `FileReader` keep them in, keyed by their path
  /// under the storage root.
  static const ({String storeName}) projectFiles = (storeName: 'project-files');

  /// Optional app-lock PIN shape, the persisted attempt backoff, and how
  /// often the unlock screen counts that backoff down.
  static const ({
    int pinMin,
    int pinMax,
    int saltBytes,
    List<Duration> backoff,
    Duration countdownTick,
    Duration storageTimeout,
    Duration biometricTimeout,
  })
  lock = (
    pinMin: 4,
    pinMax: 8,
    saltBytes: 16,
    countdownTick: Duration(seconds: 1),
    storageTimeout: Duration(seconds: 5),
    biometricTimeout: Duration(minutes: 2),
    backoff: <Duration>[
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
      Duration(seconds: 30),
    ],
  );

  /// Chunk size, retry cap and backoff for a confirmed cloud upload (task 021).
  static const ({
    int partBytes,
    int maxAttempts,
    int backoffBaseMs,
    int backoffCapMs,
    int streamBytes,
    int replyMaxBytes,
    Duration requestTimeout,
    int maxSessions,
    Duration sessionMaxAge,
    int googleChunkUnit,
    int oneDriveChunkUnit,
    int oneDriveMaxChunkBytes,
    Duration checkpointTimeout,
    Duration signInTimeout,
    int signInCallbackMaxBytes,
    int signInMaxCallbacks,
  })
  cloudUpload = (
    partBytes: 8 * 1024 * 1024,
    maxAttempts: 5,
    backoffBaseMs: 200,
    backoffCapMs: 5000,
    streamBytes: 64 * 1024,
    replyMaxBytes: 1024 * 1024,
    requestTimeout: Duration(seconds: 60),
    maxSessions: 8,
    sessionMaxAge: Duration(days: 7),
    googleChunkUnit: 256 * 1024,
    oneDriveChunkUnit: 320 * 1024,
    oneDriveMaxChunkBytes: 60 * 1024 * 1024,
    checkpointTimeout: Duration(seconds: 8),
    signInTimeout: Duration(minutes: 3),
    signInCallbackMaxBytes: 8192,
    signInMaxCallbacks: 16,
  );

  /// The organisation backend (§30.2): how long a proxied analysis call may
  /// take before the request is queued for later, and how recently a grant
  /// must have been confirmed to count as fresh. How long a grant lasts is
  /// the server's `grantValidUntil`.
  static const ({
    Duration proxyTimeout,
    Duration grantFreshFor,
    int relayMaxBytes,
  })
  backend = (
    proxyTimeout: Duration(seconds: 8),
    grantFreshFor: Duration(hours: 1),
    // Conservative client ceiling matching the standard server deployment's
    // PACKAGE_MAX_BYTES. A deployment can enforce a lower ceiling as well.
    relayMaxBytes: 20000000,
  );
}

/// One mebibyte, the unit storage and import ceilings are stated in.
const int _mib = 1024 * 1024;

/// Keeps stored day counts and operational deadlines on the same policy.
const int _retentionDays = 30;
