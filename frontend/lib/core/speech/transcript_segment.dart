import 'package:flutter/foundation.dart' show listEquals;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';

import 'transcript_word.dart';

/// One finished stretch of a transcript, as the session commits it and the
/// sink stores it. Times are samples on the session timeline at 16 kHz, so
/// pauses are excluded and nothing depends on a wall clock.
final class TranscriptSegment {
  /// Describes [text] heard from [startSample] to [endSample] in utterance
  /// [utteranceId], decoded by [modelId] in [languageTag].
  const TranscriptSegment({
    required this.id,
    required this.utteranceId,
    required this.startSample,
    required this.endSample,
    required this.text,
    required this.languageTag,
    required this.modelId,
    this.noSpeechProbability = 0,
    this.averageLogProbability = 0,
    this.confidence,
    this.words = const <TranscriptWord>[],
  });

  /// Rebuilds a segment written by [toJson]. A malformed map throws
  /// [CorruptionFailure].
  factory TranscriptSegment.fromJson(Map<String, Object?> json) {
    final Object? id = json[_id];
    final Object? utteranceId = json[_utteranceId];
    final Object? start = json[_start];
    final Object? end = json[_end];
    final Object? text = json[_text];
    final Object? languageTag = json[_languageTag];
    final Object? modelId = json[_modelId];
    final Object noSpeech = json[_noSpeech] ?? 0;
    final Object logProbability = json[_logProbability] ?? 0;
    final Object? confidence = json[_confidence];
    final Object words = json[_words] ?? const <Object?>[];
    if (id is! int ||
        utteranceId is! int ||
        start is! int ||
        end is! int ||
        text is! String ||
        languageTag is! String ||
        modelId is! String ||
        noSpeech is! num ||
        logProbability is! num ||
        (confidence != null && confidence is! num) ||
        words is! List<Object?>) {
      throw const CorruptionFailure();
    }
    return TranscriptSegment(
      id: id,
      utteranceId: utteranceId,
      startSample: start,
      endSample: end,
      text: text,
      languageTag: languageTag,
      modelId: modelId,
      noSpeechProbability: noSpeech.toDouble(),
      averageLogProbability: logProbability.toDouble(),
      confidence: (confidence as num?)?.toDouble(),
      words: <TranscriptWord>[
        for (final Object? word in words)
          if (word is Map<String, Object?>)
            TranscriptWord.fromJson(word)
          else
            throw const CorruptionFailure(),
      ],
    );
  }

  /// 1-based insertion order within the transcript; the stored row's `seq`.
  final int id;

  /// The utterance this segment was decoded from.
  final int utteranceId;

  /// First sample of the segment.
  final int startSample;

  /// Sample after the segment's last one.
  final int endSample;

  /// The cleaned text as decoded, written once. Never logged.
  final String text;

  /// The BCP 47 tag of the language it was decoded in.
  final String languageTag;

  /// The catalogue id of the model that decoded it.
  final String modelId;

  /// The model's probability that the window held no speech.
  final double noSpeechProbability;

  /// Mean log probability over the decoded steps.
  final double averageLogProbability;

  /// Mean word probability from 0 to 1, or null when the decode had none.
  final double? confidence;

  /// Timed words, when the decode asked for them.
  final List<TranscriptWord> words;

  /// Where the segment starts in the recording's audio.
  Duration get start => _durationOf(startSample);

  /// Where the segment ends in the recording's audio.
  Duration get end => _durationOf(endSample);

  /// This segment as a JSON map, for the journal and the stored row.
  Map<String, Object?> toJson() => <String, Object?>{
    _id: id,
    _utteranceId: utteranceId,
    _start: startSample,
    _end: endSample,
    _text: text,
    _languageTag: languageTag,
    _modelId: modelId,
    _noSpeech: noSpeechProbability,
    _logProbability: averageLogProbability,
    _confidence: confidence,
    _words: <Map<String, Object?>>[
      for (final TranscriptWord word in words) word.toJson(),
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is TranscriptSegment &&
      other.id == id &&
      other.utteranceId == utteranceId &&
      other.startSample == startSample &&
      other.endSample == endSample &&
      other.text == text &&
      other.languageTag == languageTag &&
      other.modelId == modelId &&
      other.noSpeechProbability == noSpeechProbability &&
      other.averageLogProbability == averageLogProbability &&
      other.confidence == confidence &&
      listEquals(other.words, words);

  @override
  int get hashCode => Object.hash(
    id,
    utteranceId,
    startSample,
    endSample,
    text,
    languageTag,
    modelId,
    noSpeechProbability,
    averageLogProbability,
    confidence,
    Object.hashAll(words),
  );
}

Duration _durationOf(int sample) => Duration(
  microseconds:
      sample * Duration.microsecondsPerSecond ~/ AppConstants.audio.sampleRate,
);

const String _id = 'id';
const String _utteranceId = 'utteranceId';
const String _start = 'startSample';
const String _end = 'endSample';
const String _text = 'text';
const String _languageTag = 'languageTag';
const String _modelId = 'modelId';
const String _noSpeech = 'noSpeechProbability';
const String _logProbability = 'averageLogProbability';
const String _confidence = 'confidence';
const String _words = 'words';
