import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'bundle_entry.dart';
import 'bundle_format.dart';
import 'bundle_manifest.dart';
import 'bundle_output.dart';
import 'bundle_zip_job.dart';

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
  final File part = File('$base/${job.targetPath}.part');
  final Result<List<Object>> zipped =
      await runIsolate<Map<String, Object?>, List<Object>>(
        _zipToDisk,
        <String, Object?>{
          'root': base,
          'folder': job.folderName,
          'target': job.targetPath,
          'entries': job.entries,
          'files': job.projectFiles,
          'manifest': job.manifest.toJson(),
        },
        onProgress: job.onProgress,
        cancel: job.cancel,
      );
  switch (zipped) {
    case FailureResult<List<Object>>(:final Failure failure):
      _discard(part);
      return FailureResult<BundleOutput>(failure);
    case Success<List<Object>>(:final List<Object> value):
      return Success<BundleOutput>(
        StoredBundle(
          relativePath: job.targetPath,
          byteLength: value[0] as int,
          sha256: value[1] as String,
        ),
      );
  }
}

void _discard(File part) {
  try {
    if (part.existsSync()) {
      part.deleteSync();
    }
  } on Object {
    // A leftover .part is never read as a package; cleanup removes it.
  }
}

/// Runs in the isolate: writes every entry, the checksums and the manifest,
/// renames the finished file and returns its length and SHA-256.
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
  final File finished = File('$root/$target');
  final File part = File('${finished.path}.part');
  part.parent.createSync(recursive: true);
  final ZipFileEncoder zip = ZipFileEncoder()..create(part.path);
  var closed = false;
  try {
    final List<BundleEntry> written = <BundleEntry>[];
    final List<String> missing = <String>[];
    final int total = entries.length + files.length;
    var done = 0;
    final List<String> names = entries.keys.toList()..sort();
    for (final String name in names) {
      final Uint8List bytes = Uint8List.fromList(entries[name]!);
      zip.addArchiveFile(ArchiveFile(name, bytes.length, bytes));
      written.add(
        BundleEntry(
          path: name,
          byteLength: bytes.length,
          sha256: crypto.sha256.convert(bytes).toString(),
        ),
      );
      IsolateRunner.reportProgress(++done / total);
    }
    for (final String path in files) {
      final File file = File('$root/projects/$folder/$path');
      if (!file.existsSync()) {
        missing.add(path);
        IsolateRunner.reportProgress(++done / total);
        continue;
      }
      final crypto.Digest digest = await crypto.sha256
          .bind(file.openRead())
          .first;
      await zip.addFile(file, path, ZipFileEncoder.STORE);
      written.add(
        BundleEntry(
          path: path,
          byteLength: file.lengthSync(),
          sha256: digest.toString(),
        ),
      );
      IsolateRunner.reportProgress(++done / total);
    }
    final ({List<int> manifest, List<int> checksums}) last = finishBundle(
      manifest,
      written,
      missingFiles: missing,
    );
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
    if (finished.existsSync()) {
      finished.deleteSync();
    }
    part.renameSync(finished.path);
    final crypto.Digest whole = await crypto.sha256
        .bind(finished.openRead())
        .first;
    return <Object>[finished.lengthSync(), whole.toString()];
  } on Object {
    if (!closed) {
      try {
        zip.closeSync();
      } on Object {
        // The encoder may already be broken; the file is removed below.
      }
    }
    _discard(part);
    rethrow;
  }
}
