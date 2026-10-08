import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'export_archive_stub.dart'
    if (dart.library.io) 'export_archive_io.dart'
    as platform;
import 'file_reader.dart';
import 'file_writer.dart';
import 'path_sanitizer.dart';
import 'storage_root.dart';

/// Streams native deliverable archives; browser archives use the shared file
/// store and a bounded in-memory encoder. Inputs always remain untouched.
final class ExportArchive {
  /// Composes existing storage ports and the approved archive encoder.
  const ExportArchive({
    required this._storageRoot,
    required this._files,
    required this._writer,
    this._inBrowser = kIsWeb,
  });

  final StorageRoot _storageRoot;
  final FileReader _files;
  final FileWriter _writer;
  final bool _inBrowser;

  /// [sources] maps archive entries to source paths under the storage root.
  /// Manifest is always last; cancelled writes leave no published output.
  Future<Result<WrittenFile>> write({
    required String target,
    required Map<String, String> sources,
    required Uint8List manifest,
    required CancellationToken cancel,
    void Function(double)? onProgress,
    String? manifestSource,
  }) async {
    try {
      safeRelativePath(target);
      if (manifestSource != null) safeRelativePath(manifestSource);
      for (final MapEntry<String, String> entry in sources.entries) {
        safeRelativePath(entry.key);
        safeRelativePath(entry.value);
      }
      if (!_inBrowser) {
        return platform.writeArchive(
          storageRoot: _storageRoot,
          target: target,
          sources: sources,
          manifest: manifest,
          cancel: cancel,
          onProgress: onProgress,
          manifestSource: manifestSource,
        );
      }
      final Map<String, Uint8List> entries = <String, Uint8List>{};
      final Uint8List manifestBytes = manifestSource == null
          ? manifest
          : (await _files.read(manifestSource)).fold(
              (Failure failure) => throw failure,
              (Uint8List bytes) => bytes,
            );
      var size = manifestBytes.length;
      for (final MapEntry<String, String> entry in sources.entries) {
        if (cancel.isCancelled) {
          return const FailureResult<WrittenFile>(CancelledFailure());
        }
        final Result<Uint8List> read = await _files.read(entry.value);
        if (read case FailureResult<Uint8List>(:final Failure failure)) {
          return FailureResult<WrittenFile>(failure);
        }
        final Uint8List bytes = (read as Success<Uint8List>).value;
        size += bytes.length;
        if (size > AppConstants.imports.archiveUncompressedMaxBytes) {
          return FailureResult<WrittenFile>(
            StorageFailure(
              localizedMessage:
                  Copy.messages.failureThisExportIsTooLargeForThis,
              localizedRecovery:
                  Copy.messages.failureExportFewerRecordsOrUseADesktop,
            ),
          );
        }
        entries[entry.key] = bytes;
        onProgress?.call(entries.length / (sources.length + 1));
      }
      entries['manifest.json'] = manifestBytes;
      final Result<Uint8List> encoded =
          await runIsolate<Map<String, Uint8List>, Uint8List>(
            _encode,
            entries,
            cancel: cancel,
          );
      if (encoded case FailureResult<Uint8List>(:final Failure failure)) {
        return FailureResult<WrittenFile>(failure);
      }
      if (cancel.isCancelled) {
        return const FailureResult<WrittenFile>(CancelledFailure());
      }
      final Result<WrittenFile> result = await _writer.write(
        Stream<List<int>>.value((encoded as Success<Uint8List>).value),
        target,
      );
      onProgress?.call(1);
      return result;
    } on Object catch (error) {
      return FailureResult<WrittenFile>(Failure.from(error));
    }
  }
}

Uint8List _encode(Map<String, Uint8List> entries) {
  final Archive archive = Archive();
  for (final MapEntry<String, Uint8List> entry in entries.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  return ZipEncoder().encodeBytes(archive);
}
