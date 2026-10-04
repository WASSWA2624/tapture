import '../finished_utterance.dart';
import '../speech_decode_result.dart';
import '../speech_segment.dart';
import '../transcript_segment.dart';
import '../transcript_word.dart';
import 'hallucination_filter.dart';
import 'repetition_collapse.dart';
import 'seam_aligner.dart';
import 'segment_text.dart';
import 'speech_pipeline_config.dart';
import 'utterance_boundary.dart';
import 'utterance_end_reason.dart';
import 'word_sequence.dart';

/// Turns each closed utterance's final decode into the transcript segments
/// the sink stores (spec §30.4.7).
///
/// Utterances are assembled strictly in id order, whatever order their
/// outcomes arrive in. For each one: segment and word times are clamped
/// into its decode range; text is tidied ([SegmentText]); hallucinated
/// segments are dropped and weak edge words over non-speech trimmed
/// ([HallucinationFilter]); loops collapse ([RepetitionCollapse]); across a
/// hard cut, the words reaching into the seam wait for the next utterance
/// and the two are joined by text ([SeamAligner]); times are made monotonic
/// and segments numbered from the session's counter. An utterance that
/// could not be decoded becomes a skipped one, recorded as a gap. Nothing
/// stored is ever edited.
final class SegmentAssembler {
  /// An assembler with [config]'s rules, numbering segments from
  /// `nextSegmentId` and expecting utterance [firstUtteranceId] first.
  SegmentAssembler({
    required SpeechPipelineConfig config,
    required this._nextSegmentId,
    int firstUtteranceId = 1,
  }) : _config = config,
       _filter = HallucinationFilter(config: config),
       _tolerance = config.samplesOf(config.seamTolerance),
       _seamOverlap = config.samplesOf(config.seamOverlap),
       _expected = firstUtteranceId;

  final SpeechPipelineConfig _config;
  final HallucinationFilter _filter;
  final int _tolerance;
  final int _seamOverlap;
  final Map<int, _Outcome> _waiting = <int, _Outcome>{};
  int _nextSegmentId;
  int _expected;
  int _lastEnd = 0;
  _Held? _held;
  int _droppedSegments = 0;
  int _collapsedLoops = 0;

  /// The id the next segment gets.
  int get nextSegmentId => _nextSegmentId;

  /// Segments dropped as hallucinations so far, for the stop summary.
  int get droppedSegments => _droppedSegments;

  /// Loops collapsed so far, for the stop summary.
  int get collapsedLoops => _collapsedLoops;

  /// The utterances whose outcome arrived but wait for an earlier one.
  Iterable<UtteranceBoundary> get waiting =>
      _waiting.values.map((_Outcome outcome) => outcome.utterance);

  /// Takes the outcome of [utterance]'s final: its decode [result], or
  /// null when it is skipped, decoded with [prompt] in whisper [language]
  /// by [modelId]. Returns every utterance now ready, in id order, each
  /// with whether the carried prompt must be forgotten after it.
  List<({FinishedUtterance utterance, bool resetPrompt})> add(
    UtteranceBoundary utterance, {
    required SpeechDecodeResult? result,
    required String language,
    required String modelId,
    String prompt = '',
  }) {
    _waiting[utterance.id] = _Outcome(
      utterance,
      result,
      prompt: prompt,
      language: language,
      modelId: modelId,
    );
    final List<({FinishedUtterance utterance, bool resetPrompt})> ready =
        <({FinishedUtterance utterance, bool resetPrompt})>[];
    while (true) {
      final _Outcome? next = _waiting.remove(_expected);
      if (next == null) {
        return ready;
      }
      _expected++;
      ready.add(_assemble(next));
    }
  }

  ({FinishedUtterance utterance, bool resetPrompt}) _assemble(
    _Outcome outcome,
  ) {
    final UtteranceBoundary utterance = outcome.utterance;
    final SpeechDecodeResult? result = outcome.result;
    final _Held? held = _held?.forId == utterance.id ? _held : null;
    _held = null;
    if (result == null) {
      // The gap recorded for this utterance covers the seam the held words
      // were waiting on.
      return (
        utterance: FinishedUtterance(
          utteranceId: utterance.id,
          fromSample: utterance.startSample,
          toSample: utterance.endSample,
          segments: const <TranscriptSegment>[],
          skipped: true,
        ),
        resetPrompt: false,
      );
    }
    final int from = utterance.decodeFromSample;
    final int to = utterance.endSample;
    final List<_Draft> heard = <_Draft>[
      for (final SpeechSegment segment in result.segments)
        if (_draft(segment, from, to) case final _Draft draft
            when draft.words.isNotEmpty &&
                !SegmentText.isBlank(SegmentText.join(draft.words)))
          draft,
    ];
    final List<_Draft> kept = <_Draft>[
      for (final _Draft draft in heard)
        if (!_filter.drops(
          words: draft.words,
          startSample: draft.startSample,
          endSample: draft.endSample,
          noSpeechProbability: draft.noSpeechProbability,
          averageLogProbability: draft.averageLogProbability,
          evidence: utterance.evidence,
          language: outcome.language,
          prompt: outcome.prompt,
        ))
          draft,
    ];
    _droppedSegments += heard.length - kept.length;
    final bool hallucinationOnly = heard.isNotEmpty && kept.isEmpty;

    // One list of every word, each with the segment it came from, so edge
    // trim, loop collapse and the seam act on the utterance as a whole.
    List<_Entry> words = <_Entry>[
      for (final _Draft draft in kept)
        for (final TranscriptWord word in draft.words) _Entry(word, draft),
    ];
    final List<TranscriptWord> trimmed = _filter.trimEdges(
      _wordsOf(words),
      utterance.evidence,
      leading: utterance.seamFromSample == null,
      trailing: utterance.reason != UtteranceEndReason.hardCut,
    );
    if (trimmed.length != words.length) {
      final int first = trimmed.isEmpty
          ? 0
          : words.indexWhere(
              (_Entry entry) => identical(entry.word, trimmed.first),
            );
      words = words.sublist(first, first + trimmed.length);
    }
    final Set<int> looped = RepetitionCollapse.removals(
      _wordsOf(words),
      speechSamples: utterance.evidence.speechSamples(_config.vadOffThreshold),
      config: _config,
    );
    if (looped.isNotEmpty) {
      _collapsedLoops++;
      words = <_Entry>[
        for (int index = 0; index < words.length; index++)
          if (!looped.contains(index)) words[index],
      ];
    }
    if (held != null) {
      final List<({bool held, int index})> picks = SeamAligner.join(
        held: _wordsOf(held.entries),
        next: _wordsOf(words),
        cut: held.cut,
        tolerance: _tolerance,
        weakLogProbability: _config.hallucinationLogProb,
        context: held.context,
      );
      final List<_Entry> joined = <_Entry>[
        for (final ({bool held, int index}) pick in picks)
          pick.held ? held.entries[pick.index] : words[pick.index],
      ];
      words = joined;
    }
    if (utterance.reason == UtteranceEndReason.hardCut) {
      final int keep = SeamAligner.heldFrom(
        _wordsOf(words),
        seamFrom: utterance.endSample - _seamOverlap,
        tolerance: _tolerance,
      );
      _held = _Held(
        forId: utterance.id + 1,
        cut: utterance.endSample,
        entries: words.sublist(keep),
        context: keep > 0 ? words[keep - 1].word : null,
      );
      words = words.sublist(0, keep);
    }

    final List<TranscriptSegment> segments = <TranscriptSegment>[];
    int start = 0;
    while (start < words.length) {
      int end = start + 1;
      while (end < words.length &&
          identical(words[end].draft, words[start].draft)) {
        end++;
      }
      segments.add(
        _segment(
          words[start].draft,
          _wordsOf(words.sublist(start, end)),
          utterance: utterance,
          modelId: outcome.modelId,
        ),
      );
      start = end;
    }
    return (
      utterance: FinishedUtterance(
        utteranceId: utterance.id,
        fromSample: utterance.startSample,
        toSample: utterance.endSample,
        segments: segments,
      ),
      resetPrompt: hallucinationOnly || looped.isNotEmpty,
    );
  }

  /// One decoded segment with its times clamped into `[from, to)` and its
  /// words timed and tidied.
  _Draft _draft(SpeechSegment segment, int from, int to) {
    final int start = _clamp(segment.startSample, from, to);
    final int end = _clamp(segment.endSample, start, to);
    final List<TranscriptWord> raw = segment.pieces.isNotEmpty
        ? WordSequence.fromPieces(segment.pieces)
        : WordSequence.spread(
            segment.text,
            start: start,
            end: end,
            probability: segment.confidence,
          );
    final List<TranscriptWord> words = SegmentText.cleanWords(<TranscriptWord>[
      for (final TranscriptWord word in raw)
        TranscriptWord(
          text: word.text,
          startSample: _clamp(word.startSample, from, to),
          endSample: _clamp(
            word.endSample,
            _clamp(word.startSample, from, to),
            to,
          ),
          probability: word.probability,
        ),
    ]);
    return _Draft(
      startSample: start,
      endSample: end,
      words: words,
      noSpeechProbability: segment.noSpeechProbability,
      averageLogProbability: segment.averageLogProbability,
    );
  }

  /// The stored segment for [words] of [draft], with monotonic times and
  /// the next id.
  TranscriptSegment _segment(
    _Draft draft,
    List<TranscriptWord> words, {
    required UtteranceBoundary utterance,
    required String modelId,
  }) {
    int start = words.first.startSample;
    int end = start;
    for (final TranscriptWord word in words) {
      if (word.endSample > end) {
        end = word.endSample;
      }
    }
    if (start < _lastEnd) {
      start = _lastEnd;
    }
    if (end < start) {
      end = start;
    }
    final List<TranscriptWord> timed = <TranscriptWord>[];
    int floor = start;
    double probability = 0;
    for (final TranscriptWord word in words) {
      final int wordStart = _clamp(word.startSample, floor, end);
      timed.add(
        TranscriptWord(
          text: word.text,
          startSample: wordStart,
          endSample: _clamp(word.endSample, wordStart, end),
          probability: word.probability,
        ),
      );
      floor = wordStart;
      probability += word.probability;
    }
    _lastEnd = end;
    return TranscriptSegment(
      id: _nextSegmentId++,
      utteranceId: utterance.id,
      startSample: start,
      endSample: end,
      text: SegmentText.join(timed),
      languageTag: _config.languageTag,
      modelId: modelId,
      noSpeechProbability: draft.noSpeechProbability,
      averageLogProbability: draft.averageLogProbability,
      confidence: probability / timed.length,
      words: timed,
    );
  }

  static List<TranscriptWord> _wordsOf(List<_Entry> entries) =>
      <TranscriptWord>[for (final _Entry entry in entries) entry.word];

  static int _clamp(int sample, int low, int high) =>
      sample < low ? low : (sample > high ? high : sample);
}

/// One utterance's final outcome waiting for its turn.
final class _Outcome {
  _Outcome(
    this.utterance,
    this.result, {
    required this.prompt,
    required this.language,
    required this.modelId,
  });

  final UtteranceBoundary utterance;
  final SpeechDecodeResult? result;
  final String prompt;
  final String language;
  final String modelId;
}

/// One decoded segment on its way to being stored.
final class _Draft {
  _Draft({
    required this.startSample,
    required this.endSample,
    required this.words,
    required this.noSpeechProbability,
    required this.averageLogProbability,
  });

  final int startSample;
  final int endSample;
  final List<TranscriptWord> words;
  final double noSpeechProbability;
  final double averageLogProbability;
}

/// A word on its way to being stored, with the segment it was decoded in.
final class _Entry {
  _Entry(this.word, this.draft);

  final TranscriptWord word;
  final _Draft draft;
}

/// Words of an utterance ended by a hard cut that wait for the next one.
final class _Held {
  _Held({
    required this.forId,
    required this.cut,
    required this.entries,
    required this.context,
  });

  /// The utterance they are joined with.
  final int forId;

  /// The cut's sample.
  final int cut;

  final List<_Entry> entries;

  /// The last word stored before them, if any.
  final TranscriptWord? context;
}
