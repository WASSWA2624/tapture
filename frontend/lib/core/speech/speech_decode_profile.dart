import 'package:tapture/core/constants/app_constants.dart';

/// whisper.cpp sizes the encoder context in steps of this many frames.
const int _audioContextStep = 64;

/// How a window is decoded: threads, sampling, fallback thresholds and
/// how much encoder context it gets.
final class SpeechDecodeProfile {
  /// Describes a decode. Thresholds default to `AppConstants.speechEngine`.
  const SpeechDecodeProfile({
    required this.threads,
    this.bestOf = 1,
    this.beamSize = 0,
    this.temperatureStep = 0,
    this.noSpeechThreshold = _noSpeechThreshold,
    this.logprobThreshold = _logprobThreshold,
    this.entropyThreshold = _entropyThreshold,
    this.singleSegment = false,
    this.timestamps = true,
    this.maxPieces = 0,
    this.piecesPerSecond = 0,
    this.audioContextPad = 0,
    this.suppressBlank = true,
    this.suppressNonSpeech = true,
  });

  /// Threads the decode uses.
  final int threads;

  /// Candidates sampled per step; 1 is greedy.
  final int bestOf;

  /// Beam width; 0 decodes greedily.
  final int beamSize;

  /// Temperature added on each fallback; 0 never falls back.
  final double temperatureStep;

  /// Above this no-speech probability a weak window counts as silence.
  final double noSpeechThreshold;

  /// Below this mean log probability a decode falls back.
  final double logprobThreshold;

  /// Above this compression entropy a decode falls back.
  final double entropyThreshold;

  /// Whether the window is returned as one segment.
  final bool singleSegment;

  /// Whether segments carry timestamps.
  final bool timestamps;

  /// Most pieces one decoding pass yields; 0 is unlimited. With
  /// [piecesPerSecond] it is the allowance before the audio's share.
  final int maxPieces;

  /// Pieces a pass may add per second of audio on top of [maxPieces]; 0
  /// keeps [maxPieces] fixed. Bounds the cost of a pass that loops, which
  /// otherwise runs to whisper's own limit before it falls back.
  final int piecesPerSecond;

  /// Encoder frames past the audio; 0 encodes the full context.
  final int audioContextPad;

  /// Whether a blank first piece is suppressed.
  final bool suppressBlank;

  /// Whether non-speech pieces such as music marks are suppressed.
  final bool suppressNonSpeech;

  /// The encoder context for [sampleCount] samples at 16 kHz: 0 (the full
  /// context) when [audioContextPad] is 0, otherwise the audio's frames plus
  /// the pad, rounded up to whisper's step and capped at the model maximum.
  int audioContextFor(int sampleCount) {
    if (audioContextPad == 0) return 0;
    final int rate = AppConstants.audio.sampleRate;
    final int frames =
        (sampleCount * AppConstants.speechEngine.encoderFramesPerSecond +
            rate -
            1) ~/
        rate;
    final int padded = frames + audioContextPad;
    final int rounded =
        (padded + _audioContextStep - 1) ~/
        _audioContextStep *
        _audioContextStep;
    final int cap = AppConstants.speechEngine.maxAudioContext;
    return rounded < cap ? rounded : cap;
  }

  /// The most pieces one pass yields for [sampleCount] samples at 16 kHz:
  /// [maxPieces] when [piecesPerSecond] is 0, otherwise [maxPieces] plus
  /// [piecesPerSecond] for each second of audio, rounded up.
  int maxPiecesFor(int sampleCount) {
    if (piecesPerSecond == 0) return maxPieces;
    final int rate = AppConstants.audio.sampleRate;
    return maxPieces + (sampleCount * piecesPerSecond + rate - 1) ~/ rate;
  }

  /// This profile with the given fields replaced.
  SpeechDecodeProfile copyWith({
    int? threads,
    int? bestOf,
    int? beamSize,
    double? temperatureStep,
    double? noSpeechThreshold,
    double? logprobThreshold,
    double? entropyThreshold,
    bool? singleSegment,
    bool? timestamps,
    int? maxPieces,
    int? piecesPerSecond,
    int? audioContextPad,
    bool? suppressBlank,
    bool? suppressNonSpeech,
  }) {
    return SpeechDecodeProfile(
      threads: threads ?? this.threads,
      bestOf: bestOf ?? this.bestOf,
      beamSize: beamSize ?? this.beamSize,
      temperatureStep: temperatureStep ?? this.temperatureStep,
      noSpeechThreshold: noSpeechThreshold ?? this.noSpeechThreshold,
      logprobThreshold: logprobThreshold ?? this.logprobThreshold,
      entropyThreshold: entropyThreshold ?? this.entropyThreshold,
      singleSegment: singleSegment ?? this.singleSegment,
      timestamps: timestamps ?? this.timestamps,
      maxPieces: maxPieces ?? this.maxPieces,
      piecesPerSecond: piecesPerSecond ?? this.piecesPerSecond,
      audioContextPad: audioContextPad ?? this.audioContextPad,
      suppressBlank: suppressBlank ?? this.suppressBlank,
      suppressNonSpeech: suppressNonSpeech ?? this.suppressNonSpeech,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SpeechDecodeProfile &&
      other.threads == threads &&
      other.bestOf == bestOf &&
      other.beamSize == beamSize &&
      other.temperatureStep == temperatureStep &&
      other.noSpeechThreshold == noSpeechThreshold &&
      other.logprobThreshold == logprobThreshold &&
      other.entropyThreshold == entropyThreshold &&
      other.singleSegment == singleSegment &&
      other.timestamps == timestamps &&
      other.maxPieces == maxPieces &&
      other.piecesPerSecond == piecesPerSecond &&
      other.audioContextPad == audioContextPad &&
      other.suppressBlank == suppressBlank &&
      other.suppressNonSpeech == suppressNonSpeech;

  @override
  int get hashCode => Object.hash(
    threads,
    bestOf,
    beamSize,
    temperatureStep,
    noSpeechThreshold,
    logprobThreshold,
    entropyThreshold,
    singleSegment,
    timestamps,
    maxPieces,
    piecesPerSecond,
    audioContextPad,
    suppressBlank,
    suppressNonSpeech,
  );
}

// `AppConstants.speechEngine`'s thresholds, restated because a record field
// cannot be read in a const constructor's defaults.
// `speech_decode_profile_test` holds them equal.
const double _noSpeechThreshold = 0.6;
const double _logprobThreshold = -1;
const double _entropyThreshold = 2.4;
