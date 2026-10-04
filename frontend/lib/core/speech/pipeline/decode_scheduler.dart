import 'dart:collection';

import '../speech_decode_kind.dart';
import 'backpressure_level.dart';
import 'decode_job.dart';
import 'speech_pipeline_config.dart';
import 'utterance_boundary.dart';

/// Decides what a speech pipeline decodes next (spec §30.4.7).
///
/// **Order.** One job is in flight. Finals run first, in the order their
/// utterances closed, and are never dropped: a final stays at the head of
/// the queue until [completed] removes it, so a failed one can be retried.
/// Drafts use a single slot that a newer offer replaces.
///
/// **Cadence.** The open utterance is drafted once it holds
/// `interimMinAudio`, then each time it grows by a step: the smoothed
/// draft compute time (weight `interimEwmaAlpha`) over the duty share,
/// held between `interimMinStep` and `interimMaxStep`. Measured in audio,
/// so it is deterministic. An utterance stops being drafted once the
/// smoothed compute time passes `interimMaxStep` × duty, or on a phone
/// once it is longer than `interimMaxUtterance`.
///
/// **Ladder.** Closed audio waiting for its final raises the level:
/// beyond `finalBacklogInterimsOff` drafts stop, beyond
/// `finalBacklogReducedContext` finals encode less context; each level is
/// left only below `finalBacklogRecover`.
final class DecodeScheduler {
  /// A scheduler with [config]'s cadence and ladder.
  DecodeScheduler({required SpeechPipelineConfig config})
    : _config = config,
      _minAudio = config.samplesOf(config.interimMinAudio),
      _maxUtterance = config.interimMaxUtterance == null
          ? null
          : config.samplesOf(config.interimMaxUtterance!),
      _interimsOff = config.samplesOf(config.finalBacklogInterimsOff),
      _reducedContext = config.samplesOf(config.finalBacklogReducedContext),
      _recover = config.samplesOf(config.finalBacklogRecover);

  final SpeechPipelineConfig _config;
  final int _minAudio;
  final int? _maxUtterance;
  final int _interimsOff;
  final int _reducedContext;
  final int _recover;
  final ListQueue<UtteranceBoundary> _finals = ListQueue<UtteranceBoundary>();

  DecodeJob? _slot;
  DecodeJob? _inFlight;
  BackpressureLevel _level = BackpressureLevel.normal;
  BackpressureLevel _highest = BackpressureLevel.normal;
  int _backlog = 0;
  double _ewmaMicroseconds = 0;
  int? _draftedId;
  int? _lastDraftTo;
  int? _stoppedId;

  /// The job in flight, or null.
  DecodeJob? get inFlight => _inFlight;

  /// The level the backlog has raised.
  BackpressureLevel get level => _level;

  /// The highest level reached, for the stop summary.
  BackpressureLevel get highestLevel => _highest;

  /// Closed audio still waiting for its final, in samples.
  int get backlogSamples => _backlog;

  /// The closed utterances waiting for their finals, oldest first,
  /// including the one in flight.
  Iterable<UtteranceBoundary> get pendingFinals => _finals;

  /// The smoothed compute time of a draft.
  Duration get interimCompute =>
      Duration(microseconds: _ewmaMicroseconds.round());

  /// Queues the final of [utterance] behind every earlier one.
  void enqueueFinal(UtteranceBoundary utterance) {
    _finals.addLast(utterance);
    _backlog += utterance.endSample - utterance.decodeFromSample;
    _updateLevel();
  }

  /// Offers a draft of open utterance [utteranceId], which started at
  /// [startSample], over `[fromSample, toSample)`. Returns whether the
  /// draft is due and now waits in the slot, replacing any earlier one.
  bool offerInterim({
    required int utteranceId,
    required int startSample,
    required int fromSample,
    required int toSample,
  }) {
    if (_draftedId != utteranceId) {
      _draftedId = utteranceId;
      _lastDraftTo = null;
    }
    if (!_config.interims ||
        _level != BackpressureLevel.normal ||
        _stoppedId == utteranceId ||
        toSample <= fromSample) {
      return false;
    }
    final int length = toSample - startSample;
    if (length < _minAudio) {
      return false;
    }
    final int? limit = _maxUtterance;
    if (limit != null && length > limit) {
      _stoppedId = utteranceId;
      return false;
    }
    final int? last = _lastDraftTo;
    if (last != null && toSample - last < _stepSamples) {
      return false;
    }
    _slot = DecodeJob.interim(
      utteranceId: utteranceId,
      fromSample: fromSample,
      toSample: toSample,
    );
    _lastDraftTo = toSample;
    return true;
  }

  /// The next job to run, now in flight: the oldest final, else the draft;
  /// null while a job is in flight or nothing waits.
  DecodeJob? next() {
    if (_inFlight != null) {
      return null;
    }
    if (_finals.isNotEmpty) {
      return _inFlight = DecodeJob.committed(_finals.first);
    }
    final DecodeJob? draft = _slot;
    _slot = null;
    return _inFlight = draft;
  }

  /// [job] finished. A final leaves the queue; a draft's [compute] time
  /// feeds the cadence.
  void completed(DecodeJob job, {Duration? compute}) {
    if (identical(_inFlight, job)) {
      _inFlight = null;
    }
    if (job.kind == SpeechDecodeKind.committed) {
      if (_finals.isNotEmpty && _finals.first.id == job.utteranceId) {
        final UtteranceBoundary done = _finals.removeFirst();
        _backlog -= done.endSample - done.decodeFromSample;
        _updateLevel();
      }
      return;
    }
    if (compute != null) {
      final double micros = compute.inMicroseconds.toDouble();
      final double alpha = _config.interimEwmaAlpha;
      _ewmaMicroseconds = _ewmaMicroseconds == 0
          ? micros
          : alpha * micros + (1 - alpha) * _ewmaMicroseconds;
      final double limit =
          _config.interimMaxStep.inMicroseconds * _config.interimMaxDuty;
      if (_ewmaMicroseconds > limit) {
        _stoppedId = job.utteranceId;
      }
    }
  }

  /// [job] ended without a result. A final stays at the head of the queue
  /// to be retried or skipped; a draft is gone.
  void released(DecodeJob job) {
    if (identical(_inFlight, job)) {
      _inFlight = null;
    }
  }

  /// Utterance [utteranceId] closed: its waiting draft is dropped. Returns
  /// whether a draft of it is in flight, which the caller aborts so its
  /// final starts at once.
  bool closeUtterance(int utteranceId) {
    if (_slot?.utteranceId == utteranceId) {
      _slot = null;
    }
    final DecodeJob? running = _inFlight;
    return running != null &&
        running.kind == SpeechDecodeKind.interim &&
        running.utteranceId == utteranceId;
  }

  int get _stepSamples {
    final double micros = _ewmaMicroseconds / _config.interimMaxDuty;
    final int low = _config.interimMinStep.inMicroseconds;
    final int high = _config.interimMaxStep.inMicroseconds;
    final int step = micros.round().clamp(low, high);
    return _config.samplesOf(Duration(microseconds: step));
  }

  void _updateLevel() {
    switch (_level) {
      case BackpressureLevel.normal:
        if (_backlog > _reducedContext) {
          _level = BackpressureLevel.reducedContext;
        } else if (_backlog > _interimsOff) {
          _level = BackpressureLevel.interimsOff;
        }
      case BackpressureLevel.interimsOff:
        if (_backlog > _reducedContext) {
          _level = BackpressureLevel.reducedContext;
        } else if (_backlog < _recover) {
          _level = BackpressureLevel.normal;
        }
      case BackpressureLevel.reducedContext:
        if (_backlog < _recover) {
          _level = BackpressureLevel.normal;
        }
    }
    if (_level.index > _highest.index) {
      _highest = _level;
    }
    if (_level != BackpressureLevel.normal) {
      _slot = null;
    }
  }
}
