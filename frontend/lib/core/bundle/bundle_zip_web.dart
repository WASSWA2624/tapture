import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'bundle_encryption.dart';
import 'bundle_entry.dart';
import 'bundle_format.dart';
import 'bundle_output.dart';
import 'bundle_redaction.dart';
import 'bundle_zip_job.dart';

/// Builds the package in memory: a browser has no file system, so its files
/// are read from the project-file store and the result is handed to a
/// download (task 076, D6). The size was checked against the browser's
/// ceiling before any file was read.
Future<Result<BundleOutput>> zipBundle(BundleZipJob job) async {
  try {
    final BundleRedaction redaction = BundleRedaction.parse(
      job.patternsYaml.isEmpty
          ? await BundleRedaction.loadPatterns()
          : job.patternsYaml,
    );
    final Archive archive = Archive();
    final List<BundleEntry> written = <BundleEntry>[];
    final List<String> missing = <String>[];
    final int total = job.entries.length + job.projectFiles.length;
    var done = 0;
    var size = 0;
    void add(String name, Uint8List bytes, {required bool compress}) {
      redaction.assertClean(name);
      redaction.assertCleanPayload(bytes);
      final ArchiveFile file = ArchiveFile(name, bytes.length, bytes)
        ..compression = compress
            ? CompressionType.deflate
            : CompressionType.none;
      archive.addFile(file);
      written.add(
        BundleEntry(
          path: name,
          byteLength: bytes.length,
          sha256: crypto.sha256.convert(bytes).toString(),
        ),
      );
      size += bytes.length;
      job.onProgress?.call(++done / total);
    }

    final List<String> names = job.entries.keys.toList()..sort();
    for (final String name in names) {
      add(name, Uint8List.fromList(job.entries[name]!), compress: true);
    }
    for (final String path in job.projectFiles) {
      if (job.cancel.isCancelled) {
        return const FailureResult<BundleOutput>(CancelledFailure());
      }
      final Result<Uint8List> read = await job.files.read(
        job.fileSources[path] ?? 'projects/${job.folderName}/$path',
      );
      switch (read) {
        case FailureResult<Uint8List>():
          missing.add(path);
          job.onProgress?.call(++done / total);
        case Success<Uint8List>(:final Uint8List value):
          add(path, value, compress: false);
      }
      if (size > job.ceiling) {
        return FailureResult<BundleOutput>(
          StorageFailure(
            localizedMessage: Copy.messages.packageTooLarge(size, job.ceiling),
            localizedRecovery: Copy.messages.packageTooLargeRecovery,
          ),
        );
      }
    }
    final ({List<int> manifest, List<int> checksums}) last = finishBundle(
      job.manifest,
      written,
      missingFiles: missing,
    );
    redaction.assertCleanBytes(last.manifest);
    redaction.assertCleanBytes(last.checksums);
    archive
      ..addFile(
        ArchiveFile(
          BundleFormat.checksums,
          last.checksums.length,
          Uint8List.fromList(last.checksums),
        ),
      )
      ..addFile(
        ArchiveFile(
          BundleFormat.manifest,
          last.manifest.length,
          Uint8List.fromList(last.manifest),
        ),
      );
    final Uint8List plain = ZipEncoder().encodeBytes(archive);
    final Uint8List bytes = job.password == null
        ? plain
        : await BundleEncryption().sealAsync(
            plain,
            job.password!,
            cancel: job.cancel,
          );
    return Success<BundleOutput>(
      InMemoryBundle(
        bytes: bytes,
        byteLength: bytes.length,
        sha256: crypto.sha256.convert(bytes).toString(),
      ),
    );
  } on Object catch (error) {
    return FailureResult<BundleOutput>(Failure.from(error));
  }
}
