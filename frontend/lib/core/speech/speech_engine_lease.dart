import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_engine.dart';
import 'speech_failures.dart';
import 'speech_selection.dart';
import 'speech_vad_handle.dart';
import 'speech_vad_result.dart';

/// One session's hold on the loaded speech model (spec §30.4.2).
///
/// The host hands out a lease per session. While any lease is held the model
/// is never swapped or released. Each lease decodes under its own id and owns
/// its own voice detector, so neither queue position nor detector state
/// crosses into another session.
abstract interface class SpeechEngineLease {
  /// A lease on [engine]'s loaded model, chosen as [selection], decoding as
  /// [leaseId] and detecting voice on [vad], which [release] closes.
  factory SpeechEngineLease.over(
    SpeechEngine engine,
    SpeechSelection selection, {
    required int leaseId,
    required SpeechVadHandle vad,
  }) = _EngineLease;

  /// The model, threads, language and profiles this lease decodes with.
  SpeechSelection get selection;

  /// The catalogue id of the loaded model, for the transcript row.
  String get modelId;

  /// Samples per voice-detection frame of this lease's detector.
  int get vadFrameSamples;

  /// Transcribes one window as this lease. A released lease's requests fail
  /// with `CancelledFailure`.
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    CancellationToken? cancel,
  });

  /// One speech probability per frame of [samples] on this lease's
  /// detector; [resetState] clears its running state first.
  Future<Result<SpeechVadResult>> detectSpeech(
    Float32List samples, {
    bool resetState = false,
    CancellationToken? cancel,
  });

  /// Drops this lease's pending decodes and aborts its in-flight one. Other
  /// leases' work is untouched.
  void abort();

  /// Aborts this lease's work and closes its voice detector. Idempotent.
  Future<void> release();
}

final class _EngineLease implements SpeechEngineLease {
  _EngineLease(
    this._engine,
    this.selection, {
    required this._leaseId,
    required this._vad,
  });

  final SpeechEngine _engine;
  final int _leaseId;
  final SpeechVadHandle _vad;
  Future<void>? _released;

  @override
  final SpeechSelection selection;

  @override
  String get modelId => selection.model.id;

  @override
  int get vadFrameSamples => _vad.frameSamples;

  @override
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    CancellationToken? cancel,
  }) {
    if (_released != null) {
      return Future<Result<SpeechDecodeResult>>.value(
        FailureResult<SpeechDecodeResult>(speechCancelled()),
      );
    }
    return _engine.decode(request, leaseId: _leaseId, cancel: cancel);
  }

  @override
  Future<Result<SpeechVadResult>> detectSpeech(
    Float32List samples, {
    bool resetState = false,
    CancellationToken? cancel,
  }) {
    if (_released != null) {
      return Future<Result<SpeechVadResult>>.value(
        FailureResult<SpeechVadResult>(speechCancelled()),
      );
    }
    return _engine.detectSpeech(
      _vad,
      samples,
      resetState: resetState,
      cancel: cancel,
    );
  }

  @override
  void abort() => _engine.abortLease(_leaseId);

  @override
  Future<void> release() => _released ??= _close();

  Future<void> _close() async {
    _engine.abortLease(_leaseId);
    await _engine.closeVad(_vad);
  }
}
