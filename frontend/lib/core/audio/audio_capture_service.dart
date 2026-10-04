import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart' as record;
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_capture_plugin.dart';
import 'audio_capture_request.dart';
import 'audio_capture_session.dart';
import 'microphone_access.dart';
import 'microphone_arbiter.dart';

/// Streams the microphone as 16 kHz mono PCM while teeing it into a
/// durable take. Features never call the recorder plugin (FE-STR-11).
abstract interface class AudioCaptureService {
  /// The platform adapter over the recorder plugin's stream mode, staging
  /// takes under [storageRoot] and publishing them through [writer].
  /// [recorderFactory] is the test seam; each capture gets a new recorder.
  factory AudioCaptureService({
    required FileWriter writer,
    required StorageRoot storageRoot,
    required MicrophoneAccess access,
    required MicrophoneArbiter arbiter,
    @visibleForTesting record.AudioRecorder Function()? recorderFactory,
  }) = AudioCapturePlugin;

  /// The stand-in until `main` binds the adapter: every start fails.
  const factory AudioCaptureService.unavailable() = _UnavailableAudioCapture;

  /// Claims the microphone, checks the permission, opens staging and starts
  /// the stream.
  Future<Result<AudioCaptureSession>> start(AudioCaptureRequest request);
}

/// The process-wide streaming capture. Unavailable until `main` overrides
/// it.
final Provider<AudioCaptureService> audioCaptureServiceProvider =
    Provider<AudioCaptureService>((Ref _) {
      return const AudioCaptureService.unavailable();
    });

final class _UnavailableAudioCapture implements AudioCaptureService {
  const _UnavailableAudioCapture();

  @override
  Future<Result<AudioCaptureSession>> start(AudioCaptureRequest request) async {
    return FailureResult<AudioCaptureSession>(
      ProviderFailure(
        kind: ProviderFailureKind.unavailable,
        localizedMessage: Copy.messages.audioRecorderUnavailable,
      ),
    );
  }
}
