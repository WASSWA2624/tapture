import 'dart:math' as math;

import 'package:tapture/core/constants/app_constants.dart';

import '../transcript_word.dart';
import 'hallucination_phrases.dart';
import 'segment_text.dart';
import 'speech_pipeline_config.dart';
import 'utterance_evidence.dart';
import 'word_sequence.dart';

/// Drops decoded text the audio does not support (spec §30.4.7).
///
/// A segment is dropped when it is empty or punctuation only; when whisper
/// itself judges it silence (no-speech probability above and mean log
/// probability below `AppConstants.speechEngine`'s thresholds); when it is
/// a [HallucinationPhrases] phrase over weak audio (quieter than
/// `hallucinationEnergyDbfs`, less than `hallucinationSpeechRatio` speech
/// frames, or a mean log probability below `hallucinationLogProb`); or when
/// it echoes the prompt it was decoded with, weakly (only a decode given a
/// prompt can echo one). The last of several segments of an utterance that
/// ended in silence is dropped when the detector heard less than
/// `minSpeech` of speech under it ([dropsTail]). Weak edge words (a log
/// probability below `hallucinationLogProb`) lying over frames the detector
/// heard as non-speech, with none heard as speech within
/// `edgeTrimTolerance` either side, are trimmed; interior words never are.
/// A confident
/// word is kept wherever its time falls: whisper's word times stray by
/// more than the pre-roll, so time alone would trim real speech.
final class HallucinationFilter {
  /// A filter with [config]'s thresholds.
  HallucinationFilter({required SpeechPipelineConfig config})
    : _off = config.vadOffThreshold,
      _energyDbfs = config.hallucinationEnergyDbfs,
      _speechRatio = config.hallucinationSpeechRatio,
      _logProbability = config.hallucinationLogProb,
      _toleranceSamples = config.samplesOf(config.edgeTrimTolerance),
      _minSpeechSamples = config.samplesOf(config.minSpeech);

  final double _off;
  final int _toleranceSamples;
  final int _minSpeechSamples;
  final double _energyDbfs;
  final double _speechRatio;
  final double _logProbability;

  /// Whether the segment of [words] over samples `[startSample, endSample)`,
  /// decoded in [language] with [prompt] and scored [noSpeechProbability]
  /// and [averageLogProbability], is to be dropped.
  bool drops({
    required List<TranscriptWord> words,
    required int startSample,
    required int endSample,
    required double noSpeechProbability,
    required double averageLogProbability,
    required UtteranceEvidence evidence,
    required String language,
    required String prompt,
  }) {
    final List<String> texts = <String>[
      for (final TranscriptWord word in words) word.text,
    ];
    if (texts.isEmpty || SegmentText.isBlank(texts.join(' '))) {
      return true;
    }
    if (noSpeechProbability > AppConstants.speechEngine.noSpeechThreshold &&
        averageLogProbability < AppConstants.speechEngine.logprobThreshold) {
      return true;
    }
    final bool weakScore = averageLogProbability < _logProbability;
    if (HallucinationPhrases.matches(language, texts)) {
      final int to = endSample > startSample ? endSample : startSample + 1;
      if (weakScore ||
          evidence.meanDbfs(from: startSample, to: to) < _energyDbfs ||
          evidence.speechRatio(_off, from: startSample, to: to) <
              _speechRatio) {
        return true;
      }
    }
    return weakScore && _echoes(texts, prompt);
  }

  /// Whether the last segment of an utterance that ended in silence, over
  /// samples `[startSample, endSample)` and decoded after other text of it,
  /// holds less speech than an utterance needs to open. whisper decodes
  /// what is left after its last timestamp as a window of its own, often
  /// only the fading end of the word before and the post-roll, and then
  /// tends to hear a word that was never said, however confidently.
  bool dropsTail({
    required int startSample,
    required int endSample,
    required UtteranceEvidence evidence,
  }) =>
      evidence.length > 0 &&
      evidence.speechSamples(_off, from: startSample, to: endSample) <
          _minSpeechSamples;

  /// [words] without a leading or trailing run of weak words that lie
  /// wholly over frames with a probability below the off threshold.
  ///
  /// Only an edge that borders silence is trimmed: an utterance's start
  /// unless it continues a hard cut ([leading] false), and its end unless a
  /// hard cut ended it ([trailing] false), because a cut's edge lies inside
  /// speech the detector may not have heard as such.
  List<TranscriptWord> trimEdges(
    List<TranscriptWord> words,
    UtteranceEvidence evidence, {
    bool leading = true,
    bool trailing = true,
  }) {
    int first = 0;
    int last = words.length;
    while (leading && first < last && _overSilence(words[first], evidence)) {
      first++;
    }
    while (trailing &&
        last > first &&
        _overSilence(words[last - 1], evidence)) {
      last--;
    }
    return first == 0 && last == words.length
        ? words
        : words.sublist(first, last);
  }

  /// Whether [word] is weak and every frame it overlaps, at least one, is
  /// non-speech, as is every frame within the tolerance of it.
  bool _overSilence(TranscriptWord word, UtteranceEvidence evidence) {
    if (evidence.length == 0 ||
        (word.probability > 0 &&
            math.log(word.probability) >= _logProbability)) {
      return false;
    }
    final int end =
        (word.endSample > word.startSample
            ? word.endSample
            : word.startSample + 1) +
        _toleranceSamples;
    final int first =
        ((word.startSample - _toleranceSamples - evidence.firstStart) ~/
                evidence.frameSamples)
            .clamp(0, evidence.length);
    final int last =
        ((end - evidence.firstStart + evidence.frameSamples - 1) ~/
                evidence.frameSamples)
            .clamp(0, evidence.length);
    if (last <= first) {
      return false;
    }
    for (int index = first; index < last; index++) {
      if (evidence.probabilityAt(index) >= _off) {
        return false;
      }
    }
    return true;
  }

  /// Whether the words, normalised, appear in [prompt] as a run of whole
  /// words.
  static bool _echoes(List<String> texts, String prompt) {
    if (prompt.trim().isEmpty) {
      return false;
    }
    final String said = WordSequence.keys(texts).join(' ');
    final String carried = WordSequence.keys(
      WordSequence.words(prompt),
    ).join(' ');
    return said.isNotEmpty && ' $carried '.contains(' $said ');
  }
}
