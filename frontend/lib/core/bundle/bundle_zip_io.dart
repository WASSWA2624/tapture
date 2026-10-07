import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tapture/core/concurrency/cooperative_cancellation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_cancellation.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';

import 'bundle_encryption.dart';
import 'bundle_entry.dart';
import 'bundle_format.dart';
import 'bundle_manifest.dart';
import 'bundle_output.dart';
import 'bundle_payload_scanner.dart';
import 'bundle_redaction.dart';
import 'bundle_redaction_io.dart';
import 'bundle_zip_job.dart';

final Set<String> _liveScratch = <String>{};

/// Active writer-owned directories, so cancellation tests verify actual cleanup.
@visibleForTesting
List<String> get debugBundleWriteScratchPaths =>
    List<String>.unmodifiable(_liveScratch);

/// Streams the package to `<target>.part` off the UI thread, then renames it
/// (FE-PERF-02, FE-PERF-07). Files go in stored, as photos and audio are
/// already compressed; the JSON tables are deflated. A cancel or a failure
/// leaves no partial file.
Future<Result<BundleOutput>> zipBundle(BundleZipJob job) async {
  final Result<Directory> root = await job.storageRoot.resolve();
  if (root case FailureResult<Directory>(:final Failure failure)) {
    return FailureResult<BundleOutput>(failure);
  }
  final String base = (root as Success<Directory>).value.path;
  return job.storageRoot.withWriteLock(
    File('$base/${job.targetPath}').parent.path,
    () async {
      final File part = File('$base/${job.targetPath}.part');
      final File sealed = File('${part.path}.sealed');
      CooperativeCancellation? cancellation;
      Directory? scratch;
      try {
        if (job.cancel.isCancelled) {
          return const FailureResult<BundleOutput>(CancelledFailure());
        }
        scratch = await Directory.systemTemp.createTemp(
          'tapture-bundle-write-',
        );
        _liveScratch.add(scratch.path);
        final File lease = await File(
          '${scratch.path}/active',
        ).create(exclusive: true);
        cancellation = CooperativeCancellation(
          job.cancel,
          signal: () => lease.deleteSync(),
        );
        final Result<List<Object>> zipped =
            await runIsolate<Map<String, Object?>, List<Object>>(
              _zipToDisk,
              <String, Object?>{
                'root': base,
                'scratch': scratch.path,
                'folder': job.folderName,
                'target': job.targetPath,
                'entries': job.entries,
                'files': job.projectFiles,
                'fileSources': job.fileSources,
                'manifest': job.manifest.toJson(),
                'cancellation': cancellation.handshake,
                'lease': lease.path,
                'password': job.password,
                'patterns': job.patternsYaml.isEmpty
                    ? await BundleRedaction.loadPatterns()
                    : job.patternsYaml,
              },
              onProgress: (double progress) {
                try {
                  job.onProgress?.call(progress);
                } on Object {
                  // An observer cannot skip the worker's native handle cleanup.
                }
              },
            );
        switch (zipped) {
          case FailureResult<List<Object>>(:final Failure failure):
            return FailureResult<BundleOutput>(failure);
          case Success<List<Object>>(:final List<Object> value):
            if (job.cancel.isCancelled) {
              return const FailureResult<BundleOutput>(CancelledFailure());
            }
            // The parent publishes only a completed, uncancelled worker result.
            // Rename preserves an earlier bundle until replacement is whole.
            await (job.password == null ? part : sealed).rename(
              '$base/${job.targetPath}',
            );
            try {
              job.onProgress?.call(1);
            } on Object {
              // A progress observer cannot undo the completed publication.
            }
            return Success<BundleOutput>(
              StoredBundle(
                relativePath: job.targetPath,
                byteLength: value[0] as int,
                sha256: value[1] as String,
              ),
            );
        }
      } on Object catch (error) {
        return FailureResult<BundleOutput>(Failure.from(error));
      } finally {
        cancellation?.close();
        await _discard(part);
        await _discard(sealed);
        await _discard(File('${sealed.path}.cipher'));
        if (scratch != null) {
          if (await scratch.exists()) {
            await scratch.delete(recursive: true);
          }
          _liveScratch.remove(scratch.path);
        }
      }
    },
  );
}

Future<void> _discard(File part) async {
  try {
    await discardUnpublishedFile(part);
  } on Object {
    // A leftover .part is never read as a package; cleanup removes it.
  }
}

/// Runs in the isolate: writes every entry, the checksums and the manifest,
/// leaves publication to the parent and returns its length and SHA-256.
Future<List<Object>> _zipToDisk(Map<String, Object?> job) async {
  final String root = job['root']! as String;
  final String folder = job['folder']! as String;
  final String target = job['target']! as String;
  final Map<String, List<int>> entries =
      (job['entries']! as Map<Object?, Object?>).map(
        (Object? key, Object? value) =>
            MapEntry<String, List<int>>(key! as String, value! as List<int>),
      );
  final List<String> files = <String>[
    for (final Object? path in job['files']! as List<Object?>) path! as String,
  ];
  final BundleManifest manifest = BundleManifest.fromJson(job['manifest']);
  final BundleRedaction redaction = BundleRedaction.parse(
    job['patterns']! as String,
  );
  final Map<String, String> fileSources = Map<String, String>.from(
    job['fileSources']! as Map,
  );
  final File finished = File('$root/$target');
  final File part = File('${finished.path}.part');
  part.parent.createSync(recursive: true);
  final WorkerCancellation cancellation = WorkerCancellation(
    job['cancellation']! as SendPort,
    lease: File(job['lease']! as String),
  );
  final ZipFileEncoder zip = ZipFileEncoder();
  FileHandle? outputHandle;
  var closed = false;
  var created = false;
  try {
    outputHandle = FileHandle(part.path, openMode: AbstractFileOpenMode.write);
    zip.createWithBuffer(
      OutputFileStream.withFileHandle(
        outputHandle,
        bufferSize: AppConstants.hashing.chunkBytes,
      ),
    );
    created = true;
    final List<BundleEntry> written = <BundleEntry>[];
    final List<String> missing = <String>[];
    final int total = entries.length + files.length;
    var done = 0;
    final List<String> names = entries.keys.toList()..sort();
    for (final String name in names) {
      await cancellation.checkpoint();
      final Uint8List bytes = Uint8List.fromList(entries[name]!);
      redaction.assertClean(name);
      redaction.assertCleanPayload(bytes);
      zip.addArchiveFile(ArchiveFile(name, bytes.length, bytes));
      written.add(
        BundleEntry(
          path: name,
          byteLength: bytes.length,
          sha256: crypto.sha256.convert(bytes).toString(),
        ),
      );
      IsolateRunner.reportProgress(++done / (total + 1));
    }
    for (final String path in files) {
      redaction.assertClean(path);
      await cancellation.checkpoint();
      final File file = File(
        '$root/${fileSources[path] ?? 'projects/$folder/$path'}',
      );
      if (!file.existsSync()) {
        missing.add(path);
        IsolateRunner.reportProgress(++done / (total + 1));
        continue;
      }
      scanNestedBundleArchive(
        file,
        redaction,
        check: cancellation.check,
        temporaryRoot: Directory(job['scratch']! as String),
      );
      final BundlePayloadScanner scanner = redaction.payloadScanner();
      int crc = 0;
      final crypto.Digest digest = await crypto.sha256
          .bind(
            file.openRead().map((List<int> chunk) {
              cancellation.check();
              crc = getCrc32(chunk, crc);
              scanner.add(chunk);
              return chunk;
            }),
          )
          .first;
      scanner.finish();
      final InputFileStream input = InputFileStream.withFileHandle(
        _CheckedFileHandle(file.path, cancellation.check),
        bufferSize: AppConstants.hashing.chunkBytes,
      );
      try {
        // SHA/redaction and CRC share the first bounded pass. STORE then streams
        // the second pass without another complete CRC read, with cancellation
        // at each native input refill and deterministic handle closure.
        zip.addArchiveFile(
          ArchiveFile.stream(path, file.lengthSync(), input)
            ..compress = false
            ..crc32 = crc,
        );
      } finally {
        input.closeSync();
      }
      await cancellation.checkpoint();
      written.add(
        BundleEntry(
          path: path,
          byteLength: file.lengthSync(),
          sha256: digest.toString(),
        ),
      );
      IsolateRunner.reportProgress(++done / (total + 1));
    }
    await cancellation.checkpoint();
    final ({List<int> manifest, List<int> checksums}) last = finishBundle(
      manifest,
      written,
      missingFiles: missing,
    );
    redaction.assertCleanBytes(last.manifest);
    redaction.assertCleanBytes(last.checksums);
    zip.addArchiveFile(
      ArchiveFile(
        BundleFormat.checksums,
        last.checksums.length,
        Uint8List.fromList(last.checksums),
      ),
    );
    zip.addArchiveFile(
      ArchiveFile(
        BundleFormat.manifest,
        last.manifest.length,
        Uint8List.fromList(last.manifest),
      ),
    );
    await zip.close();
    closed = true;
    File output = part;
    final String? password = job['password'] as String?;
    if (password != null) {
      output = File('${part.path}.sealed');
      BundleEncryption().sealFile(
        part,
        output,
        password,
        check: cancellation.check,
      );
      await cancellation.checkpoint();
    }
    final crypto.Digest whole = await crypto.sha256
        .bind(
          output.openRead().map((List<int> chunk) {
            cancellation.check();
            return chunk;
          }),
        )
        .first;
    return <Object>[output.lengthSync(), whole.toString()];
  } on Object {
    if (created && !closed) {
      try {
        zip.closeSync();
      } on Object {
        // The encoder may already be broken; the file is removed below.
      }
    }
    await _discard(part);
    rethrow;
  } finally {
    // Closing the raw owned handle also covers an encoder/flush failure that
    // interrupts ZipFileEncoder.closeSync before it reaches its output close.
    outputHandle?.closeSync();
    cancellation.close();
  }
}

final class _CheckedFileHandle extends FileHandle {
  _CheckedFileHandle(super.path, this._check);
  final void Function() _check;

  @override
  int readInto(Uint8List buffer, [int? end]) {
    _check();
    return super.readInto(buffer, end);
  }
}
