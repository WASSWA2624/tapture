import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tapture/core/audio/pcm_store.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../speech_engine_lease.dart';
import '../speech_failures.dart';
import '../speech_vad_result.dart';
import 'energy_gate.dart';
import 'pcm_conversion.dart';
import 'segmenter_phase.dart';
import 'speech_pipeline_config.dart';
import 'utterance_boundary.dart';
import 'utterance_end_reason.dart';
import 'utterance_segmenter.dart';

/// Runs the lease's voice detector over a take as it is captured and turns
/// the result into utterances (spec §30.4.7).
///
/// **Cursor.** Audio is read from the [PcmStore] in batches of
/// `vadBatchWindows` frames, one batch in flight, so a slow or late engine
/// makes the cursor lag and catch up, never lose audio. Every detector call
/// carries whole frames: before a pause, a resume or the end of the take a
/// short batch takes the remaining whole frames, and the part-frame left
/// over is not measured (the closing utterance still covers it).
///
/// **Gate.** While nothing is building or open, a batch of quiet frames
/// skips the detector ([EnergyGate]); its frames count as non-speech.
///
/// **Resets.** The detector's running state is cleared before the first
/// batch, after every utterance closes, after a pause or resume, and after
/// a gated stretch. A reset batch is preceded by up to `preRoll` of warm-up
/// frames, never from before the last pause, whose probabilities are
/// discarded.
final class VadDriver {
  /// A driver over `store` with [config]'s thresholds. Closed utterances go
  /// to `onClosed` in order; `onAdvanced` follows every batch; a detector
  /// or store failure goes to `onFailure` and stops the driver until a
  /// lease is attached again. Detection starts at [startSample] of the
  /// store, the audio before it already accounted for.
  VadDriver({
    required this._store,
    required SpeechPipelineConfig config,
    required this._onClosed,
    this._onAdvanced,
    this._onFailure,
    int firstUtteranceId = 1,
    int startSample = 0,
  }) : _config = config,
       _firstId = firstUtteranceId,
       _cursor = startSample,
       _warmFloor = startSample,
       _gate = EnergyGate(config: config);

  final PcmStore _store;
  final SpeechPipelineConfig _config;
  final void Function(UtteranceBoundary boundary) _onClosed;
  final void Function()? _onAdvanced;
  final void Function(Failure failure)? _onFailure;
  final int _firstId;
  final EnergyGate _gate;
  final ListQueue<int> _breaks = ListQueue<int>();
  final CancellationToken _cancel = CancellationToken();

  SpeechEngineLease? _lease;
  UtteranceSegmenter? _segmenter;
  Failure? _failure;
  int _available = 0;
  int _cursor;
  int _warmFloor;
  int _attachments = 0;
  bool _needsReset = true;
  bool _aborted = false;
  int? _finishAt;
  Completer<void>? _finished;
  Completer<void>? _pumping;

  /// The sample up to which audio has been through the detector.
  int get cursor => _cursor;

  /// Where the segmenter stands.
  SegmenterPhase get phase => _segmenter?.phase ?? SegmenterPhase.silence;

  /// The open utterance's first sample, or null.
  int? get openStart => _segmenter?.openStart;

  /// Where the open utterance's re-decoded seam begins, or null.
  int? get openSeamFrom => _segmenter?.openSeamFrom;

  /// The id the next utterance to open, or the open one, carries.
  int get nextUtteranceId => _segmenter?.nextId ?? _firstId;

  /// The sample after the last frame heard as speech.
  int get lastSpeechSample => _segmenter?.lastSpeechSample ?? 0;

  /// The earliest sample an utterance not closed yet can start at: audio
  /// before it is settled as silence or as closed utterances.
  int get settledTo => _segmenter?.earliestStart(_cursor) ?? _cursor;

  /// The share, from 0 to 1, of batches the energy gate kept from the
  /// detector, for the stop summary.
  double get gatedRatio => _gate.gatedRatio;

  /// Batches decided so far, gated or not.
  int get batches => _gate.batches;

  /// The failure that stopped the driver, or null.
  Failure? get failure => _failure;

  /// Completes once no batch is in flight and nothing more can run yet.
  Future<void> get idle => _pumping?.future ?? Future<void>.value();

  /// Starts, or after a failure restarts, detection on [lease]'s detector.
  /// The first batch after it resets the detector.
  void attachLease(SpeechEngineLease lease) {
    if (_aborted) {
      return;
    }
    final int frameSamples = lease.vadFrameSamples;
    if (frameSamples <= 0) {
      _fail(speechInvalidRequest());
      return;
    }
    final UtteranceSegmenter? current = _segmenter;
    if (current == null || current.frameSamples != frameSamples) {
      final UtteranceBoundary? cut = current?.closeAt(
        _cursor,
        UtteranceEndReason.pause,
      );
      if (cut != null) {
        _onClosed(cut);
      }
      _segmenter = UtteranceSegmenter(
        frameSamples: frameSamples,
        config: _config,
        firstId: current?.nextId ?? _firstId,
      )..markResume(_cursor);
      _warmFloor = _cursor;
    }
    _lease = lease;
    _attachments++;
    _failure = null;
    _needsReset = true;
    unawaited(_pump());
  }

  /// The take now holds [totalSamples] samples.
  void audioAvailable(int totalSamples) {
    _available = math.max(_available, totalSamples);
    unawaited(_pump());
  }

  /// Capture paused at [atSample]: the open utterance closes there, for
  /// [UtteranceEndReason.pause], once the cursor reaches it.
  void markPause(int atSample) => _addBreak(atSample);

  /// Capture resumed at [atSample]: no utterance starts before it and the
  /// detector restarts there. An utterance still open closes there too.
  void markResume(int atSample) => _addBreak(atSample);

  /// Runs the detector up to [atSample], the end of the take, and closes
  /// the open utterance there for [UtteranceEndReason.stop]. Completes
  /// once done, at once when the driver failed, or when it is aborted;
  /// without a lease it waits for one.
  Future<void> finish(int atSample) {
    final Completer<void> finished = _finished ??= Completer<void>();
    if (_aborted) {
      _complete();
      return finished.future;
    }
    _finishAt = math.max(atSample, _cursor);
    _available = math.max(_available, atSample);
    if (_failure != null) {
      _closeAtEnd();
    } else {
      unawaited(_pump());
    }
    return finished.future;
  }

  /// Stops detection: the batch in flight is cancelled, nothing more is
  /// reported, and [finish] completes.
  void abort() {
    _aborted = true;
    _cancel.cancel();
    _complete();
  }

  void _addBreak(int atSample) {
    _breaks.addLast(math.max(atSample, _cursor));
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_pumping != null) {
      return;
    }
    final Completer<void> pumping = _pumping = Completer<void>();
    try {
      while (_runnable) {
        final int? next = _breaks.isEmpty ? null : _breaks.first;
        final int? stop = next ?? _finishAt;
        final int frameSamples = _segmenter!.frameSamples;
        final int ready = math.min(stop ?? _available, _available);
        final int frames = (ready - _cursor) ~/ frameSamples;
        final bool atStop = stop != null && ready == stop;
        if (frames >= _config.vadBatchWindows) {
          await _runBatch(_config.vadBatchWindows);
        } else if (atStop && frames > 0) {
          await _runBatch(frames);
        } else if (atStop && next != null) {
          _applyBreak(_breaks.removeFirst());
        } else if (atStop) {
          _closeAtEnd();
          return;
        } else {
          return;
        }
      }
    } finally {
      _pumping = null;
      pumping.complete();
    }
  }

  bool get _runnable =>
      !_aborted && _lease != null && _failure == null && _segmenter != null;

  Future<void> _runBatch(int frames) async {
    final UtteranceSegmenter segmenter = _segmenter!;
    final SpeechEngineLease lease = _lease!;
    // A lease attached while this batch is in flight discards its result:
    // the batch runs again on the new lease, from a reset.
    final int attachment = _attachments;
    final int frameSamples = segmenter.frameSamples;
    final int from = _cursor;
    final int to = from + frames * frameSamples;
    final int warm = _needsReset
        ? math.min(
            _config.framesOf(_config.preRoll, frameSamples),
            (from - _warmFloor) ~/ frameSamples,
          )
        : 0;
    final int readFrom = from - warm * frameSamples;
    final Result<Int16List> read = await _store.read(readFrom, to);
    if (_aborted || attachment != _attachments) {
      return;
    }
    final Int16List samples;
    switch (read) {
      case Success<Int16List>(:final Int16List value):
        samples = value;
      case FailureResult<Int16List>(:final Failure failure):
        _fail(failure);
        return;
    }
    final Float64List levels = Float64List(frames);
    bool allQuiet = true;
    for (int frame = 0; frame < frames; frame++) {
      final int offset = (warm + frame) * frameSamples;
      levels[frame] = PcmConversion.rmsDbfs(
        samples,
        offset,
        offset + frameSamples,
      );
      if (!_gate.observe(from + frame * frameSamples, levels[frame])) {
        allQuiet = false;
      }
    }
    final Float32List probabilities;
    if (_gate.gates(phase: segmenter.phase, allQuiet: allQuiet)) {
      probabilities = Float32List(frames);
      _needsReset = true;
    } else {
      // A fresh buffer per call: an engine may transfer it to its lane.
      final Float32List input = Float32List(samples.length);
      PcmConversion.toFloat32(samples, input);
      final Result<SpeechVadResult> detected = await lease.detectSpeech(
        input,
        resetState: _needsReset,
        cancel: _cancel,
      );
      if (_aborted || attachment != _attachments) {
        return;
      }
      switch (detected) {
        case Success<SpeechVadResult>(:final SpeechVadResult value)
            when value.probabilities.length == warm + frames:
          probabilities = Float32List.sublistView(value.probabilities, warm);
        case Success<SpeechVadResult>():
          _fail(speechInvalidRequest());
          return;
        case FailureResult<SpeechVadResult>(:final Failure failure):
          _fail(failure);
          return;
      }
      _needsReset = false;
    }
    for (int frame = 0; frame < frames; frame++) {
      final List<UtteranceBoundary> closed = segmenter.step(
        frameStart: from + frame * frameSamples,
        p: probabilities[frame],
        dbfs: levels[frame],
      );
      for (final UtteranceBoundary boundary in closed) {
        _needsReset = true;
        _onClosed(boundary);
      }
    }
    _cursor = to;
    _onAdvanced?.call();
  }

  void _applyBreak(int atSample) {
    final UtteranceSegmenter segmenter = _segmenter!;
    final UtteranceBoundary? closed = segmenter.closeAt(
      atSample,
      UtteranceEndReason.pause,
    );
    if (closed != null) {
      _onClosed(closed);
    }
    segmenter.markResume(atSample);
    _cursor = math.max(_cursor, atSample);
    _warmFloor = _cursor;
    _needsReset = true;
  }

  void _closeAtEnd() {
    final int? end = _finishAt;
    final UtteranceSegmenter? segmenter = _segmenter;
    if (end != null && segmenter != null && !_aborted) {
      final UtteranceBoundary? closed = segmenter.closeAt(
        end,
        UtteranceEndReason.stop,
      );
      if (closed != null) {
        _onClosed(closed);
      }
      _cursor = math.max(_cursor, end);
    }
    _complete();
  }

  void _fail(Failure failure) {
    if (_aborted) {
      return;
    }
    _failure = failure;
    _onFailure?.call(failure);
    if (_finishAt != null) {
      _closeAtEnd();
    }
  }

  void _complete() {
    final Completer<void>? finished = _finished;
    if (finished != null && !finished.isCompleted) {
      finished.complete();
    }
  }
}
