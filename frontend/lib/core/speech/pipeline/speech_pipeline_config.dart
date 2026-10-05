import 'package:tapture/core/constants/app_constants.dart';

/// The thresholds one speech pipeline runs with (spec §30.4.7).
///
/// Every value defaults to its `AppConstants.speechPipeline` field; a test
/// overrides one to reach an edge without minutes of audio. Durations are
/// turned into samples of the 16 kHz timeline by [samplesOf] and into whole
/// detector frames, rounded up, by [framesOf].
///
/// The session adds what it knows of the request: the transcript's
/// [languageTag], whether drafts are wanted ([interims]), whether this is a
/// phone ([mobile], which picks the interim duty and length limit) and
/// whether it is field [dictation] (whose short finals a phone encodes with
/// less context).
final class SpeechPipelineConfig {
  /// The standard thresholds, with any given value in place of its
  /// constant.
  SpeechPipelineConfig({
    double? vadOnThreshold,
    double? vadOffThreshold,
    int? vadBatchWindows,
    Duration? minSpeech,
    Duration? onsetGapTolerance,
    Duration? preRoll,
    Duration? endSilence,
    Duration? postRoll,
    Duration? softMaxUtterance,
    Duration? maxUtterance,
    Duration? cutSearchWindow,
    Duration? seamOverlap,
    Duration? seamTolerance,
    Duration? noiseFloorWindow,
    double? energyGateMarginDb,
    double? energyGateCeilingDbfs,
    Duration? interimMinAudio,
    Duration? interimMinStep,
    Duration? interimMaxStep,
    double? interimMaxDuty,
    Duration? interimMaxUtterance,
    double? interimEwmaAlpha,
    int? interimRepeatWords,
    bool? carryPrompt,
    int? promptCarryChars,
    Duration? promptCarryMinUtterance,
    double? promptCarryMinDbfs,
    Duration? promptResetGap,
    double? hallucinationEnergyDbfs,
    double? hallucinationSpeechRatio,
    double? hallucinationLogProb,
    Duration? edgeTrimTolerance,
    int? loopMinRepeatsPhrase,
    int? loopMinRepeatsWord,
    int? loopMaxNgram,
    double? minSecondsPerWord,
    double? loopWordsPerSecond,
    Duration? finalBacklogInterimsOff,
    Duration? finalBacklogReducedContext,
    Duration? finalBacklogRecover,
    Duration? engineBehindNoticeInterval,
    int? maxConsecutiveDecodeFailures,
    this.languageTag = AppConstants.defaultLanguage,
    this.interims = true,
    this.mobile = false,
    this.dictation = false,
  }) : vadOnThreshold =
           vadOnThreshold ?? AppConstants.speechPipeline.vadOnThreshold,
       vadOffThreshold =
           vadOffThreshold ?? AppConstants.speechPipeline.vadOffThreshold,
       vadBatchWindows =
           vadBatchWindows ?? AppConstants.speechPipeline.vadBatchWindows,
       minSpeech = minSpeech ?? AppConstants.speechPipeline.minSpeech,
       onsetGapTolerance =
           onsetGapTolerance ?? AppConstants.speechPipeline.onsetGapTolerance,
       preRoll = preRoll ?? AppConstants.speechPipeline.preRoll,
       endSilence = endSilence ?? AppConstants.speechPipeline.endSilence,
       postRoll = postRoll ?? AppConstants.speechPipeline.postRoll,
       softMaxUtterance =
           softMaxUtterance ?? AppConstants.speechPipeline.softMaxUtterance,
       maxUtterance = maxUtterance ?? AppConstants.speechPipeline.maxUtterance,
       cutSearchWindow =
           cutSearchWindow ?? AppConstants.speechPipeline.cutSearchWindow,
       seamOverlap = seamOverlap ?? AppConstants.speechPipeline.seamOverlap,
       seamTolerance =
           seamTolerance ?? AppConstants.speechPipeline.seamTolerance,
       noiseFloorWindow =
           noiseFloorWindow ?? AppConstants.speechPipeline.noiseFloorWindow,
       energyGateMarginDb =
           energyGateMarginDb ?? AppConstants.speechPipeline.energyGateMarginDb,
       energyGateCeilingDbfs =
           energyGateCeilingDbfs ??
           AppConstants.speechPipeline.energyGateCeilingDbfs,
       interimMinAudio =
           interimMinAudio ?? AppConstants.speechPipeline.interimMinAudio,
       interimMinStep =
           interimMinStep ?? AppConstants.speechPipeline.interimMinStep,
       interimMaxStep =
           interimMaxStep ?? AppConstants.speechPipeline.interimMaxStep,
       interimMaxDuty =
           interimMaxDuty ??
           (mobile
               ? AppConstants.speechPipeline.interimMaxDutyMobile
               : AppConstants.speechPipeline.interimMaxDutyDesktop),
       interimMaxUtterance =
           interimMaxUtterance ??
           (mobile
               ? AppConstants.speechPipeline.mobileInterimMaxUtterance
               : null),
       interimEwmaAlpha =
           interimEwmaAlpha ?? AppConstants.speechPipeline.interimEwmaAlpha,
       interimRepeatWords =
           interimRepeatWords ?? AppConstants.speechPipeline.interimRepeatWords,
       carryPrompt = carryPrompt ?? AppConstants.speechPipeline.carryPrompt,
       promptCarryChars =
           promptCarryChars ?? AppConstants.speechPipeline.promptCarryChars,
       promptCarryMinUtterance =
           promptCarryMinUtterance ??
           AppConstants.speechPipeline.promptCarryMinUtterance,
       promptCarryMinDbfs =
           promptCarryMinDbfs ?? AppConstants.speechPipeline.promptCarryMinDbfs,
       promptResetGap =
           promptResetGap ?? AppConstants.speechPipeline.promptResetGap,
       hallucinationEnergyDbfs =
           hallucinationEnergyDbfs ??
           AppConstants.speechPipeline.hallucinationEnergyDbfs,
       hallucinationSpeechRatio =
           hallucinationSpeechRatio ??
           AppConstants.speechPipeline.hallucinationSpeechRatio,
       hallucinationLogProb =
           hallucinationLogProb ??
           AppConstants.speechPipeline.hallucinationLogProb,
       edgeTrimTolerance =
           edgeTrimTolerance ?? AppConstants.speechPipeline.edgeTrimTolerance,
       loopMinRepeatsPhrase =
           loopMinRepeatsPhrase ??
           AppConstants.speechPipeline.loopMinRepeatsPhrase,
       loopMinRepeatsWord =
           loopMinRepeatsWord ?? AppConstants.speechPipeline.loopMinRepeatsWord,
       loopMaxNgram = loopMaxNgram ?? AppConstants.speechPipeline.loopMaxNgram,
       minSecondsPerWord =
           minSecondsPerWord ?? AppConstants.speechPipeline.minSecondsPerWord,
       loopWordsPerSecond =
           loopWordsPerSecond ?? AppConstants.speechPipeline.loopWordsPerSecond,
       finalBacklogInterimsOff =
           finalBacklogInterimsOff ??
           AppConstants.speechPipeline.finalBacklogInterimsOff,
       finalBacklogReducedContext =
           finalBacklogReducedContext ??
           AppConstants.speechPipeline.finalBacklogReducedContext,
       finalBacklogRecover =
           finalBacklogRecover ??
           AppConstants.speechPipeline.finalBacklogRecover,
       engineBehindNoticeInterval =
           engineBehindNoticeInterval ??
           AppConstants.speechPipeline.engineBehindNoticeInterval,
       maxConsecutiveDecodeFailures =
           maxConsecutiveDecodeFailures ??
           AppConstants.speechPipeline.maxConsecutiveDecodeFailures;

  /// The probability from which a frame starts speech.
  final double vadOnThreshold;

  /// The probability below which a frame stops speech.
  final double vadOffThreshold;

  /// Frames sent to the detector in one call.
  final int vadBatchWindows;

  /// Speech needed before an utterance opens.
  final Duration minSpeech;

  /// The longest dip a building onset survives.
  final Duration onsetGapTolerance;

  /// Audio kept before an onset, and the detector's warm-up after a reset.
  final Duration preRoll;

  /// Silence that closes an utterance.
  final Duration endSilence;

  /// Audio kept after the last speech of an utterance closed by silence.
  final Duration postRoll;

  /// Length after which the first dip closes an utterance.
  final Duration softMaxUtterance;

  /// Length at which continuous speech is cut.
  final Duration maxUtterance;

  /// How far back from a hard cut its quietest moment is searched for.
  final Duration cutSearchWindow;

  /// Audio before a hard cut that the next utterance decodes again.
  final Duration seamOverlap;

  /// How far a word's time may stray across a hard cut's seam and still be
  /// judged by its side of it.
  final Duration seamTolerance;

  /// The span the noise floor is the quietest level of.
  final Duration noiseFloorWindow;

  /// How close to the noise floor, in dB, a quiet frame lies.
  final double energyGateMarginDb;

  /// The level, in dBFS, from which no frame counts as quiet.
  final double energyGateCeilingDbfs;

  /// The open utterance length from which it is drafted.
  final Duration interimMinAudio;

  /// The least growth between two drafts of one utterance.
  final Duration interimMinStep;

  /// The most growth between two drafts, and with [interimMaxDuty] the
  /// draft compute time beyond which an utterance is no longer drafted.
  final Duration interimMaxStep;

  /// The share of real time drafts may take: the step between drafts is
  /// their smoothed compute time over this.
  final double interimMaxDuty;

  /// The utterance length beyond which it is no longer drafted, or null for
  /// no limit.
  final Duration? interimMaxUtterance;

  /// The weight of the newest compute time in the smoothed one.
  final double interimEwmaAlpha;

  /// The length of a phrase whose repeat within a draft keeps the rest of
  /// the draft tentative.
  final int interimRepeatWords;

  /// Whether a final is decoded with the end of the transcript so far as
  /// its prompt. Drafts never are.
  final bool carryPrompt;

  /// Characters of the transcript carried into the next final.
  final int promptCarryChars;

  /// An utterance shorter than this is decoded without the carried text.
  final Duration promptCarryMinUtterance;

  /// An utterance quieter than this, in dBFS, is decoded without the
  /// carried text.
  final double promptCarryMinDbfs;

  /// Audio without finalized speech after which the carried text is
  /// forgotten.
  final Duration promptResetGap;

  /// A known hallucination over audio quieter than this, in dBFS, is
  /// dropped.
  final double hallucinationEnergyDbfs;

  /// A known hallucination over less than this share of speech frames is
  /// dropped.
  final double hallucinationSpeechRatio;

  /// A known hallucination or a prompt echo below this mean log probability
  /// is dropped.
  final double hallucinationLogProb;

  /// A weak edge word is trimmed only when no speech frame lies within
  /// this of it.
  final Duration edgeTrimTolerance;

  /// Repeats of a phrase of two or more words that make a loop.
  final int loopMinRepeatsPhrase;

  /// Repeats of a single word that make a loop.
  final int loopMinRepeatsWord;

  /// The longest phrase, in words, a loop is looked for in.
  final int loopMaxNgram;

  /// A run said faster than this many seconds a word is a loop.
  final double minSecondsPerWord;

  /// A run with more words than this per second of detected speech is a
  /// loop.
  final double loopWordsPerSecond;

  /// Final audio waiting beyond which drafts switch off.
  final Duration finalBacklogInterimsOff;

  /// Final audio waiting beyond which finals encode a shorter context.
  final Duration finalBacklogReducedContext;

  /// Final audio waiting below which the backlog levels are left.
  final Duration finalBacklogRecover;

  /// Audio between two warnings that transcription lags.
  final Duration engineBehindNoticeInterval;

  /// Failed decodes in a row after which transcription stops.
  final int maxConsecutiveDecodeFailures;

  /// The BCP 47 tag the transcript's segments carry.
  final String languageTag;

  /// Whether open utterances are drafted.
  final bool interims;

  /// Whether the device is a phone or tablet.
  final bool mobile;

  /// Whether this is field dictation rather than a long-form recording.
  final bool dictation;

  /// [duration] in samples of the 16 kHz timeline.
  int samplesOf(Duration duration) =>
      duration.inMicroseconds *
      AppConstants.audio.sampleRate ~/
      Duration.microsecondsPerSecond;

  /// [duration] in whole frames of [frameSamples], rounded up.
  int framesOf(Duration duration, int frameSamples) =>
      (samplesOf(duration) + frameSamples - 1) ~/ frameSamples;
}
