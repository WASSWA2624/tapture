import 'package:tapture/core/errors/result.dart';

import 'audio_capture_event.dart';
import 'audio_recording.dart';
import 'capture_format.dart';
import 'pcm_chunk.dart';
import 'pcm_store.dart';

/// One streaming capture from start to release.
///
/// The microphone stays claimed until [stop] or [abandon]; [release] must
/// follow either, and runs [abandon] first when neither ran.
abstract interface class AudioCaptureSession {
  /// 16 kHz mono audio, contiguous: each chunk starts where the previous one
  /// ended. Single-subscription and buffered, so nothing is lost before a
  /// listener arrives. A chunk is emitted only after it is in [store].
  Stream<PcmChunk> get chunks;

  /// Levels, pauses, resumes, failures and format changes. Broadcast.
  Stream<AudioCaptureEvent> get events;

  /// Samples captured so far; equal to `store.length`.
  int get capturedSamples;

  /// Random access to everything captured. After [stop] it reads the
  /// published take, until [release].
  PcmStore get store;

  /// What the device opened.
  CaptureFormat get format;

  /// Pauses at the operator's request and checkpoints the take.
  Future<Result<void>> pause();

  /// Resumes after any pause. Re-checks the permission, and re-opens a
  /// microphone stream that was lost; the timeline continues contiguously.
  Future<Result<void>> resume();

  /// Patches the take's header and flushes it to disk.
  Future<Result<void>> checkpoint();

  /// Closes the microphone, finishes the take and publishes it without a
  /// copy. Null for a memory-only capture. On failure the staged take is
  /// kept and calling again retries the publish.
  Future<Result<AudioRecording?>> stop();

  /// Closes the store and frees the session. Idempotent.
  Future<void> release();

  /// Closes the microphone and keeps the staged take byte-for-byte, its
  /// header patched, unpublished. Returns its relative path, or null for a
  /// memory-only capture.
  Future<Result<String?>> abandon();
}
