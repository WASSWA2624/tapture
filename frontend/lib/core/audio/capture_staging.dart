import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_recording.dart';
import 'capture_staging_stub.dart'
    if (dart.library.io) 'capture_staging_io.dart'
    as platform;
import 'memory_pcm_store.dart';
import 'pcm_store.dart';

/// Where a streaming capture keeps its audio while it records: the tee
/// between the microphone and the published take.
///
/// On device a take is a WAV file beside its target, written as it is
/// captured, with its header patched at every checkpoint. A capture with no
/// target keeps its audio in memory only. Every call is applied in order.
abstract interface class CaptureStaging {
  /// Opens staging for a take published at [relativePath] under [root]
  /// through [writer], or, when [relativePath] is null, in memory for at
  /// most [maxDuration] of audio.
  static Future<Result<CaptureStaging>> open({
    required StorageRoot root,
    required FileWriter writer,
    String? relativePath,
    Duration? maxDuration,
  }) async {
    if (relativePath != null) {
      return platform.openCaptureStaging(
        root: root,
        writer: writer,
        relativePath: relativePath,
      );
    }
    if (maxDuration == null || maxDuration <= Duration.zero) {
      return const FailureResult<CaptureStaging>(ValidationFailure());
    }
    return Success<CaptureStaging>(
      _MemoryCaptureStaging(
        MemoryPcmStore(
          maxSamples:
              maxDuration.inMicroseconds *
              AppConstants.audio.sampleRate ~/
              Duration.microsecondsPerSecond,
        ),
      ),
    );
  }

  /// Random access to everything appended so far.
  PcmStore get store;

  /// Appends 16 kHz mono [samples]. Once it completes they are in [store]
  /// and handed to the operating system.
  Future<Result<void>> append(Int16List samples);

  /// Patches the take's header to its current length and flushes it to
  /// disk.
  Future<Result<void>> checkpoint();

  /// Finishes and publishes the take; null for a memory-only capture. On
  /// success [store] reads from the published take; on failure the staged
  /// take stays where it is.
  Future<Result<AudioRecording?>> publish();

  /// Finishes the take without publishing it and keeps every byte. Returns
  /// the staged take's relative path, or null for a memory-only capture.
  Future<Result<String?>> abandon();

  /// Closes the take and removes it when no audio was ever appended, after
  /// a start that never opened the microphone.
  Future<void> discardIfEmpty();

  /// Closes [store]; later reads fail.
  Future<void> release();
}

/// Memory-only staging, for a capture that keeps nothing on disk.
final class _MemoryCaptureStaging implements CaptureStaging {
  _MemoryCaptureStaging(this._store);

  final MemoryPcmStore _store;

  @override
  PcmStore get store => _store;

  @override
  Future<Result<void>> append(Int16List samples) async {
    if (_store.append(samples)) {
      return const Success<void>(null);
    }
    return const FailureResult<void>(StorageFailure());
  }

  @override
  Future<Result<void>> checkpoint() async => const Success<void>(null);

  @override
  Future<Result<AudioRecording?>> publish() async {
    return const Success<AudioRecording?>(null);
  }

  @override
  Future<Result<String?>> abandon() async => const Success<String?>(null);

  @override
  Future<void> discardIfEmpty() async {}

  @override
  Future<void> release() async => _store.close();
}
