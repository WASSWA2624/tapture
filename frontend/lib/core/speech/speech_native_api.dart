import 'dart:typed_data';

import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_model_shape.dart';
import 'speech_runtime_facts.dart';

/// The native engine as one worker isolate sees it (spec §30.4.2): the
/// `tw_*` library behind pointer-free signatures.
///
/// Each worker opens its own instance and calls it from that isolate only;
/// the main isolate never does (FE-PERF-02). Every method is synchronous and
/// blocks its isolate, and every refusal is thrown as a typed failure from
/// `speech_failures.dart` (spec §30.4.4), never a raw exception. Handles are
/// small integers this instance hands out; they mean nothing to another
/// instance.
abstract interface class SpeechNativeApi {
  /// What the library and the device offer. A library that could not be
  /// opened reports `available: false` with its reason rather than throwing.
  SpeechRuntimeFacts facts();

  /// Opens the whisper model at [path] with [threads] threads, after the
  /// library has checked that the file holds exactly [bytes] bytes with the
  /// SHA-256 [sha256] (64 hex digits). Unverified bytes are never parsed.
  int loadModel(
    String path, {
    required int threads,
    required int bytes,
    required String sha256,
  });

  /// The hyperparameters of the loaded [model].
  SpeechModelShape shape(int model);

  /// Opens the Silero detector at [path] after the same size and SHA-256
  /// check as [loadModel], on one thread.
  int loadVad(String path, {required int bytes, required String sha256});

  /// Samples the detector [vad] scores per probability.
  int vadWindow(int vad);

  /// Transcribes [request] with [model]. The decode stops with
  /// `CancelledFailure` once the abort cell at [abortAddress] holds a value
  /// of at least [jobId]; an [abortAddress] of 0 means no cell. Times are
  /// placed on the session timeline (`offsetSamples` plus the decoded
  /// time), not yet clamped to the window.
  SpeechDecodeResult decode(
    int model,
    SpeechDecodeRequest request, {
    required int abortAddress,
    required int jobId,
  });

  /// One speech probability per whole window of [samples] on detector
  /// [vad]; [reset] clears its running state first.
  Float32List detectSpeech(int vad, Float32List samples, {required bool reset});

  /// Closes the model or detector [handle]. An unknown handle does nothing.
  void release(int handle);

  /// Takes up to [max] lines out of the library's log ring, oldest first,
  /// each with its `tw_log_level` (1 debug, 2 info, 3 warn, 4 error). A
  /// line never carries decoded text, prompts or audio.
  List<({int level, String line})> drainLog(int max);

  /// Lines the full log ring has dropped since the library loaded.
  int get droppedLogLines;

  /// Models and detectors this instance holds open.
  int get liveHandles;

  /// Releases every handle and every borrowed abort cell. Later calls throw
  /// `speechEngineStopped()`.
  void close();
}
