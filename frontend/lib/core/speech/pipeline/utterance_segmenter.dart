import 'dart:math' as math;
import 'dart:typed_data';

import 'segmenter_phase.dart';
import 'speech_pipeline_config.dart';
import 'utterance_boundary.dart';
import 'utterance_end_reason.dart';
import 'utterance_evidence.dart';

/// Splits the detector's frame-by-frame speech probabilities into
/// utterances (spec §30.4.7).
///
/// Per frame: speech from `vadOnThreshold` starts an onset, which opens an
/// utterance once it holds `minSpeech` of frames at or above
/// `vadOffThreshold`, surviving dips up to `onsetGapTolerance`. The
/// utterance starts `preRoll` before the onset, never before the previous
/// utterance's end, the last resume or sample 0. A frame below the off
/// threshold starts a hangover: speech from the on threshold resumes the
/// utterance, and `endSilence` of non-speech closes it `postRoll` after its
/// last speech. Past `softMaxUtterance` the first dip closes it at once.
/// Continuous speech reaching `maxUtterance` is cut at the centre of the
/// quietest three frames of the last `cutSearchWindow`; the next utterance
/// opens `seamOverlap` before the cut and decodes that audio again.
///
/// Every frame's probability and level are kept for the length of the
/// longest utterance, so a closed utterance carries its
/// [UtteranceEvidence].
final class UtteranceSegmenter {
  /// A segmenter over frames of [frameSamples] samples, numbering
  /// utterances from [firstId].
  UtteranceSegmenter({
    required this.frameSamples,
    required SpeechPipelineConfig config,
    int firstId = 1,
  }) : _on = config.vadOnThreshold,
       _off = config.vadOffThreshold,
       _minSpeechFrames = math.max(
         1,
         config.framesOf(config.minSpeech, frameSamples),
       ),
       _gapFrames = config.framesOf(config.onsetGapTolerance, frameSamples),
       _preRoll = config.framesOf(config.preRoll, frameSamples) * frameSamples,
       _endSilence =
           config.framesOf(config.endSilence, frameSamples) * frameSamples,
       _postRoll =
           config.framesOf(config.postRoll, frameSamples) * frameSamples,
       _softMax = config.samplesOf(config.softMaxUtterance),
       _max = config.samplesOf(config.maxUtterance),
       _cutSearch = config.samplesOf(config.cutSearchWindow),
       _seam = config.samplesOf(config.seamOverlap),
       _nextId = firstId,
       _log = _FrameLog(
         config.framesOf(
               config.maxUtterance +
                   config.seamOverlap +
                   config.endSilence +
                   config.preRoll,
               frameSamples,
             ) +
             2 * config.vadBatchWindows,
       ) {
    if (frameSamples <= 0 ||
        _max - _cutSearch <= _seam ||
        config.vadOffThreshold > config.vadOnThreshold) {
      throw ArgumentError.value(
        config,
        'config',
        'needs positive frames, off ≤ on, and a seam shorter than the '
            'earliest hard cut',
      );
    }
  }

  /// Samples per detector frame.
  final int frameSamples;

  final double _on;
  final double _off;
  final int _minSpeechFrames;
  final int _gapFrames;
  final int _preRoll;
  final int _endSilence;
  final int _postRoll;
  final int _softMax;
  final int _max;
  final int _cutSearch;
  final int _seam;
  final _FrameLog _log;

  SegmenterPhase _phase = SegmenterPhase.silence;
  int _nextId;
  int _floor = 0;
  int _previousEnd = 0;
  int _onsetStart = 0;
  int _onsetSpeechFrames = 0;
  int _onsetGap = 0;
  int _start = 0;
  int? _seamFrom;
  int _silenceStart = 0;
  int _lastSpeechSample = 0;

  /// Where the segmenter stands.
  SegmenterPhase get phase => _phase;

  /// Whether an utterance is open.
  bool get isOpen =>
      _phase == SegmenterPhase.speech || _phase == SegmenterPhase.hangover;

  /// The open utterance's first sample, or null when none is open.
  int? get openStart => isOpen ? _start : null;

  /// Where the open utterance's re-decoded seam begins, or null.
  int? get openSeamFrom => isOpen ? _seamFrom : null;

  /// The id the next utterance to open, or the open one, carries.
  int get nextId => _nextId;

  /// The sample after the last frame heard as speech.
  int get lastSpeechSample => _lastSpeechSample;

  /// The earliest sample an utterance not closed yet can start at, once
  /// the frames before [cursor] are heard: the open utterance's start, or
  /// where a building onset, or one starting at [cursor], would open.
  int earliestStart(int cursor) {
    if (isOpen) {
      return _start;
    }
    final int onset = _phase == SegmenterPhase.onset ? _onsetStart : cursor;
    return math.max(
      math.max(onset - _preRoll, _previousEnd),
      math.max(_floor, 0),
    );
  }

  /// Takes the frame starting at [frameStart] with speech probability [p]
  /// and level [dbfs], and returns the utterances it closed, oldest first:
  /// usually none, one, or one per hard cut.
  List<UtteranceBoundary> step({
    required int frameStart,
    required double p,
    required double dbfs,
  }) {
    final int end = frameStart + frameSamples;
    _log.add(frameStart, p, dbfs);
    switch (_phase) {
      case SegmenterPhase.silence:
        if (p >= _on) {
          _phase = SegmenterPhase.onset;
          _onsetStart = frameStart;
          _onsetSpeechFrames = 1;
          _onsetGap = 0;
          _lastSpeechSample = end;
          _openIfConfirmed();
        }
      case SegmenterPhase.onset:
        if (p >= _off) {
          _onsetSpeechFrames++;
          _onsetGap = 0;
          _lastSpeechSample = end;
          _openIfConfirmed();
        } else if (++_onsetGap > _gapFrames) {
          _phase = SegmenterPhase.silence;
        }
      case SegmenterPhase.speech:
        if (p >= _off) {
          _lastSpeechSample = end;
          if (end - _start >= _max) {
            return <UtteranceBoundary>[_hardCut(end)];
          }
        } else {
          _phase = SegmenterPhase.hangover;
          _silenceStart = frameStart;
          return _closeHangover(end);
        }
      case SegmenterPhase.hangover:
        if (p >= _on) {
          _phase = SegmenterPhase.speech;
          _lastSpeechSample = end;
          if (end - _start >= _max) {
            return <UtteranceBoundary>[_hardCut(end)];
          }
        } else {
          return _closeHangover(end);
        }
    }
    return const <UtteranceBoundary>[];
  }

  /// Closes the open utterance at [atSample] for [reason] (a pause or a
  /// stop) and returns it. A building onset is dropped as too short to be
  /// speech; null when no utterance was open.
  UtteranceBoundary? closeAt(int atSample, UtteranceEndReason reason) {
    if (!isOpen) {
      _phase = SegmenterPhase.silence;
      return null;
    }
    if (atSample <= _start) {
      _phase = SegmenterPhase.silence;
      return null;
    }
    return _close(atSample, reason);
  }

  /// Capture resumed at [atSample] after a pause: no later utterance may
  /// start before it. The open utterance must already be closed.
  void markResume(int atSample) {
    assert(!isOpen, 'close the utterance at the pause first');
    _phase = SegmenterPhase.silence;
    _floor = math.max(_floor, atSample);
  }

  void _openIfConfirmed() {
    if (_onsetSpeechFrames < _minSpeechFrames) {
      return;
    }
    _phase = SegmenterPhase.speech;
    _start = math.max(
      math.max(_onsetStart - _preRoll, _previousEnd),
      math.max(_floor, 0),
    );
    _seamFrom = null;
  }

  List<UtteranceBoundary> _closeHangover(int end) {
    if (end - _start >= _softMax) {
      return <UtteranceBoundary>[
        _close(
          math.min(_silenceStart + _postRoll, end),
          UtteranceEndReason.softCut,
        ),
      ];
    }
    if (end - _silenceStart >= _endSilence) {
      return <UtteranceBoundary>[
        _close(
          math.min(_silenceStart + _postRoll, end),
          UtteranceEndReason.silence,
        ),
      ];
    }
    return const <UtteranceBoundary>[];
  }

  UtteranceBoundary _hardCut(int end) {
    final int cut = _log.quietestCentre(
      from: math.max(end - _cutSearch, _start + _seam + 1),
      to: end,
      frameSamples: frameSamples,
      fallback: end,
    );
    final UtteranceBoundary closed = _close(cut, UtteranceEndReason.hardCut);
    _phase = SegmenterPhase.speech;
    _start = cut - _seam;
    _seamFrom = _start;
    return closed;
  }

  UtteranceBoundary _close(int end, UtteranceEndReason reason) {
    final UtteranceBoundary boundary = UtteranceBoundary(
      id: _nextId++,
      startSample: _start,
      endSample: end,
      reason: reason,
      seamFromSample: _seamFrom,
      evidence: _log.evidence(_start, end, frameSamples),
    );
    _previousEnd = end;
    _seamFrom = null;
    _phase = SegmenterPhase.silence;
    return boundary;
  }
}

/// The most recent frames' starts, probabilities and levels, in a ring.
final class _FrameLog {
  _FrameLog(int capacity)
    : _starts = Int32List(capacity),
      _probabilities = Uint8List(capacity),
      _levels = Int8List(capacity);

  final Int32List _starts;
  final Uint8List _probabilities;
  final Int8List _levels;
  int _next = 0;
  int _count = 0;

  int get _capacity => _starts.length;

  void add(int start, double p, double dbfs) {
    _starts[_next] = start;
    _probabilities[_next] = UtteranceEvidence.quantiseProbability(p);
    _levels[_next] = UtteranceEvidence.quantiseLevel(dbfs);
    _next = (_next + 1) % _capacity;
    _count = math.min(_count + 1, _capacity);
  }

  /// The slot of the [age]-th oldest frame held.
  int _slot(int age) => (_next - _count + age + _capacity) % _capacity;

  /// The frames overlapping samples `[from, to)`.
  UtteranceEvidence evidence(int from, int to, int frameSamples) {
    int first = -1;
    int last = -1;
    for (int age = 0; age < _count; age++) {
      final int start = _starts[_slot(age)];
      if (start + frameSamples > from && start < to) {
        if (first < 0) {
          first = age;
        }
        last = age;
      }
    }
    if (first < 0) {
      return UtteranceEvidence.empty(
        firstStart: from,
        frameSamples: frameSamples,
      );
    }
    final int length = last - first + 1;
    final Uint8List probabilities = Uint8List(length);
    final Int8List levels = Int8List(length);
    for (int index = 0; index < length; index++) {
      final int slot = _slot(first + index);
      probabilities[index] = _probabilities[slot];
      levels[index] = _levels[slot];
    }
    return UtteranceEvidence(
      firstStart: _starts[_slot(first)],
      frameSamples: frameSamples,
      probabilities: probabilities,
      levels: levels,
    );
  }

  /// The centre of the three consecutive frames with the least energy that
  /// lie inside `[from, to)`, the latest on a tie; [fallback] when no three
  /// frames fit.
  int quietestCentre({
    required int from,
    required int to,
    required int frameSamples,
    required int fallback,
  }) {
    double best = double.infinity;
    int centre = fallback;
    for (int age = 0; age + 2 < _count; age++) {
      final int first = _slot(age);
      final int middle = _slot(age + 1);
      final int third = _slot(age + 2);
      if (_starts[first] < from ||
          _starts[third] + frameSamples > to ||
          _starts[middle] - _starts[first] != frameSamples ||
          _starts[third] - _starts[middle] != frameSamples) {
        continue;
      }
      final double energy =
          _power(_levels[first]) +
          _power(_levels[middle]) +
          _power(_levels[third]);
      if (energy <= best) {
        best = energy;
        centre = _starts[middle] + frameSamples ~/ 2;
      }
    }
    return centre;
  }

  static double _power(int dbfs) => math.pow(10, dbfs / 10).toDouble();
}
