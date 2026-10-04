import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_recording.dart';
import 'audio_recovery_service.dart';
import 'blob_capture_staging.dart';
import 'staged_take.dart';
import 'wav_take.dart';

/// Recovers a take after the process was killed while it was recorded or
/// published, for every recorder that stages takes beside their target.
///
/// A take already published is re-hashed, never rewritten. A staged take
/// whose header matches its size is published as it stands. Any other
/// staged take gets a repaired, playable derivative at the target, and the
/// raw `.recording` file is kept byte-for-byte (rule 1). A browser's take
/// is assembled from its stored chunks, which are kept too.
final class StagedTakeRecovery implements AudioRecoveryService {
  /// Recovery under `storageRoot`, publishing through `writer`.
  StagedTakeRecovery({
    required FileWriter writer,
    required StorageRoot storageRoot,
  }) : _recover = ((String path) => _recoverFile(writer, storageRoot, path));

  /// Recovery of takes a browser staged as chunks in `store`, publishing
  /// through `writer` (see [BlobCaptureStaging]).
  StagedTakeRecovery.chunked({
    required FileWriter writer,
    required BlobStore store,
  }) : _recover = ((String path) {
         return BlobCaptureStaging.recover(
           store: store,
           writer: writer,
           relativePath: path,
         );
       });

  final Future<Result<AudioRecording?>> Function(String) _recover;

  @override
  Future<Result<AudioRecording?>> recover(String relativePath) {
    return _recover(relativePath);
  }
}

/// Recovers the take staged beside `<root>/<relativePath>` on a device.
Future<Result<AudioRecording?>> _recoverFile(
  FileWriter writer,
  StorageRoot storageRoot,
  String relativePath,
) async {
  try {
    final String path = stagedTakePath(relativePath);
    final Result<Directory> root = await storageRoot.resolve();
    if (root case FailureResult<Directory>(:final Failure failure)) {
      return FailureResult<AudioRecording?>(failure);
    }
    final Directory folder = (root as Success<Directory>).value;
    final File published = File('${folder.path}/$path');
    if (await published.exists()) {
      // A kill may occur between publication and saving the session. Do
      // not overwrite that file; stream its hash and recover its metadata.
      return runIsolate<(String, String), AudioRecording?>(_readPublishedTake, (
        published.path,
        path,
      ));
    }
    final File staging = File('${published.path}$stagedTakeSuffix');
    if (!await staging.exists()) {
      return const Success<AudioRecording?>(null);
    }
    final WavTake? take = await WavTake.read(staging, interrupted: true);
    if (take == null) throw const FormatException('Invalid staged WAV take.');
    if (take.consistent) {
      final Result<AudioRecording> adopted = await publishStagedTake(
        writer: writer,
        staging: staging,
        relativePath: path,
      );
      return adopted.map((AudioRecording recording) => recording);
    }
    final Result<WrittenFile> written = await writer.write(
      take.repairedBytes(staging),
      path,
    );
    return written.map((WrittenFile file) {
      // Header repair produces a playable derivative. The raw .recording
      // file remains beside it, byte-for-byte, for recovery and inspection.
      return AudioRecording(
        relativePath: file.relativePath,
        sha256: file.sha256,
        byteLength: file.byteLength,
        duration: take.duration,
        mimeType: stagedTakeMimeType,
      );
    });
  } on Object catch (error) {
    return FailureResult<AudioRecording?>(Failure.from(error));
  }
}

/// Metadata of a take already published at `paths.$1`, whose relative path
/// is `paths.$2`. Streams the hash; runs on a worker isolate.
Future<AudioRecording?> _readPublishedTake((String, String) paths) async {
  final File published = File(paths.$1);
  final WavTake? take = await WavTake.read(published);
  if (take == null) throw const FormatException('Invalid WAV take.');
  final Digest hash = await sha256.bind(published.openRead()).first;
  return AudioRecording(
    relativePath: paths.$2,
    sha256: hash.toString(),
    byteLength: await published.length(),
    duration: take.duration,
    mimeType: stagedTakeMimeType,
  );
}
