import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/concurrency/isolate_runner.dart';
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
}) async {
  final Result<Directory> root = await storageRoot.resolve();
  if (root case FailureResult<Directory>(:final Failure failure)) {
    return FailureResult<WrittenFile>(failure);
  }
  final String base = (root as Success<Directory>).value.path;
  final Result<WrittenFile> result = await runIsolate<_ArchiveJob, WrittenFile>(
    _write,
    (root: base, target: target, sources: sources, manifest: manifest),
    cancel: cancel,
    onProgress: onProgress,
  );
  if (result is FailureResult<WrittenFile>) {
    for (final String path in <String>['$base/$target.part', '$base/$target']) {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    }
  }
  return result;
}

typedef _ArchiveJob = ({
  String root,
  String target,
  Map<String, String> sources,
  Uint8List manifest,
});

Future<WrittenFile> _write(_ArchiveJob job) async {
  final File finalFile = File('${job.root}/${job.target}');
  final File partial = File('${finalFile.path}.part');
  await partial.parent.create(recursive: true);
  final ZipFileEncoder encoder = ZipFileEncoder()..create(partial.path);
  try {
    var done = 0;
    for (final MapEntry<String, String> entry in job.sources.entries) {
      final File file = File('${job.root}/${entry.value}');
      if (!await file.exists()) {
        throw StorageFailure(
          message: 'An export source is missing: ${entry.key}',
        );
      }
      await encoder.addFile(file, entry.key, ZipFileEncoder.STORE);
      IsolateRunner.reportProgress(++done / (job.sources.length + 1));
    }
    encoder.addArchiveFile(
      ArchiveFile('manifest.json', job.manifest.length, job.manifest),
    );
    await encoder.close();
    final crypto.Digest digest = await crypto.sha256
        .bind(partial.openRead())
        .first;
    final int bytes = await partial.length();
    await partial.rename(finalFile.path);
    IsolateRunner.reportProgress(1);
    return WrittenFile(
      relativePath: job.target,
      sha256: digest.toString(),
      byteLength: bytes,
    );
  } on Object {
    try {
      encoder.closeSync();
    } on Object {
      /* Already closed after a failure. */
    }
    if (await partial.exists()) await partial.delete();
    rethrow;
  }
}
