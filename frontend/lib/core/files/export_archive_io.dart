import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/concurrency/cooperative_cancellation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_cancellation.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'file_writer.dart';
import 'storage_root.dart';

/// Adds file streams through the approved encoder, on the shared worker.
Future<Result<WrittenFile>> writeArchive({
  required StorageRoot storageRoot,
  required String target,
  required Map<String, String> sources,
  required Uint8List manifest,
  required CancellationToken cancel,
  void Function(double)? onProgress,
  String? manifestSource,
}) async {
  final Result<Directory> root = await storageRoot.resolve();
  if (root case FailureResult<Directory>(:final Failure failure)) {
    return FailureResult<WrittenFile>(failure);
  }
  final String base = (root as Success<Directory>).value.path;
  return storageRoot.withWriteLock(File('$base/$target').parent.path, () async {
    final File partial = File('$base/$target.part');
    final CooperativeCancellation cancellation = CooperativeCancellation(
      cancel,
    );
    try {
      if (cancel.isCancelled) {
        return const FailureResult<WrittenFile>(CancelledFailure());
      }
      final Result<WrittenFile> result =
          await runIsolate<_ArchiveJob, WrittenFile>(_write, (
            root: base,
            target: target,
            sources: sources,
            manifest: manifest,
            manifestSource: manifestSource,
            cancellation: cancellation.handshake,
          ), onProgress: onProgress);
      if (result is FailureResult<WrittenFile>) return result;
      if (cancel.isCancelled) {
        return const FailureResult<WrittenFile>(CancelledFailure());
      }
      // Publication is the commit point. A failed or cancelled worker may
      // remove its partial file, but never an earlier completed export.
      await partial.rename('$base/$target');
      try {
        onProgress?.call(1);
      } on Object {
        // A progress observer cannot undo the completed publication.
      }
      return result;
    } on Object catch (error) {
      return FailureResult<WrittenFile>(Failure.from(error));
    } finally {
      cancellation.close();
      if (await partial.exists()) await partial.delete();
    }
  });
}

typedef _ArchiveJob = ({
  String root,
  String target,
  Map<String, String> sources,
  Uint8List manifest,
  String? manifestSource,
  SendPort cancellation,
});

Future<WrittenFile> _write(_ArchiveJob job) async {
  final File finalFile = File('${job.root}/${job.target}');
  final File partial = File('${finalFile.path}.part');
  await partial.parent.create(recursive: true);
  final WorkerCancellation cancellation = WorkerCancellation(job.cancellation);
  final ZipFileEncoder encoder = ZipFileEncoder();
  var created = false;
  var closed = false;
  try {
    encoder.create(partial.path);
    created = true;
    var done = 0;
    for (final MapEntry<String, String> entry in job.sources.entries) {
      await cancellation.checkpoint();
      final File file = File('${job.root}/${entry.value}');
      if (!await file.exists()) {
        throw StorageFailure(
          localizedMessage: Copy.messages.failureAnExportSourceIsMissingValue(
            (entry.key).toString(),
          ),
        );
      }
      await _addStoredFile(encoder, file, entry.key);
      await cancellation.checkpoint();
      IsolateRunner.reportProgress(++done / (job.sources.length + 1));
    }
    await cancellation.checkpoint();
    if (job.manifestSource case final String source) {
      await _addStoredFile(
        encoder,
        File('${job.root}/$source'),
        'manifest.json',
      );
    } else {
      encoder.addArchiveFile(
        ArchiveFile('manifest.json', job.manifest.length, job.manifest),
      );
    }
    await encoder.close();
    closed = true;
    final crypto.Digest digest = await crypto.sha256
        .bind(
          partial.openRead().map((List<int> chunk) {
            cancellation.check();
            return chunk;
          }),
        )
        .first;
    final int bytes = await partial.length();
    return WrittenFile(
      relativePath: job.target,
      sha256: digest.toString(),
      byteLength: bytes,
    );
  } on Object {
    if (created && !closed) {
      try {
        encoder.closeSync();
      } on Object {
        /* Already closed after a failure. */
      }
    }
    if (await partial.exists()) await partial.delete();
    rethrow;
  } finally {
    cancellation.close();
  }
}

Future<void> _addStoredFile(
  ZipFileEncoder encoder,
  File file,
  String name,
) async {
  final InputFileStream input = InputFileStream(file.path);
  try {
    final FileStat stat = await file.stat();
    // Archive 4 treats its store constant as a DEFLATE level. Select the ZIP
    // method explicitly so an already-compressed file never expands in memory.
    encoder.addArchiveFile(
      ArchiveFile.stream(name, input)
        ..compression = CompressionType.none
        ..lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000
        ..mode = stat.mode,
    );
  } finally {
    await input.close();
  }
}
