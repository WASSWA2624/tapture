import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:tapture/core/concurrency/cooperative_cancellation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_cancellation.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/files/picked_document.dart';

import 'bundle_archive_stream.dart';
import 'bundle_encryption.dart';
import 'bundle_entry.dart';
import 'bundle_format.dart';
import 'bundle_manifest.dart';
import 'bundle_rejection.dart';
import 'inspected_bundle.dart';
import 'native_bundle_entries.dart';

/// Opens a project package the operator chose and checks it before a single
/// row or file is written (FE-SEC-06): its size, its magic bytes, its ZIP
/// directory (no path leaves it, no links, no zip bomb), its required
/// entries, its manifest and format version, every entry's checksum, and
/// the shape of every table. A refusal is a [CorruptionFailure] whose
/// message names the check that failed ([rejectionMessage]).
abstract final class BundleReader {
  /// Inspects [source]: a file on a device, checked off the UI thread
  /// (FE-PERF-02), or bytes in a browser. [maxBytes] replaces the
  /// platform's ceiling with a smaller one, as a test's.
  static Future<Result<InspectedBundle>> inspect(
    PickedDocument source, {
    int? maxBytes,
    String? password,
    CancellationToken? cancel,
  }) {
    return switch (source) {
      PickedFile(:final File file) => _inspectFile(
        file,
        source.name,
        maxBytes,
        password,
        cancel,
      ),
      PickedBytes(:final Uint8List bytes) => _inspectBytes(
        bytes,
        source.name,
        maxBytes,
        password,
        cancel,
      ),
    };
  }

  /// Checks only the format prefix, revealing no protected content.
  static Future<Result<bool>> needsPassword(PickedDocument source) =>
      Result.captureAsync<bool>(() async {
        final List<int> header = switch (source) {
          PickedBytes(:final Uint8List bytes) => bytes.take(8).toList(),
          PickedFile(:final File file) => (await runIsolate<String, List<int>>(
            _readHeader,
            file.path,
          )).getOrThrow(),
        };
        return BundleEncryption.isSealed(header);
      });

  /// The failure a refusal for [reason] is reported as.
  static CorruptionFailure rejection(BundleRejection reason) {
    return CorruptionFailure(
      message: rejectionMessage(reason),
      localizedMessage: Copy.messages.packageRejected(reason.name),
      recoveryAction: reason == BundleRejection.tooLarge
          ? Copy.packageMetadataTooLargeRecovery
          : Copy.packageRejectedRecovery,
      localizedRecovery: reason == BundleRejection.tooLarge
          ? Copy.messages.packageMetadataTooLargeRecovery
          : Copy.messages.packageRejectedRecovery,
    );
  }

  /// The message that names [reason]'s check.
  static String rejectionMessage(BundleRejection reason) {
    return Copy.packageRejected(reason.name);
  }
}

Future<Result<InspectedBundle>> _inspectFile(
  File file,
  String name,
  int? maxBytes,
  String? password,
  CancellationToken? cancel,
) async {
  Directory? scratch;
  CooperativeCancellation? cancellation;
  bool keep = false;
  try {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<InspectedBundle>(CancelledFailure());
    }
    scratch = await Directory.systemTemp.createTemp('tapture-bundle-');
    final File lease = await File(
      '${scratch.path}/active',
    ).create(exclusive: true);
    cancellation = CooperativeCancellation(
      cancel ?? CancellationToken(),
      signal: () => lease.deleteSync(),
    );
    final Result<List<Object?>> checked =
        await runIsolate<List<Object?>, List<Object?>>(
          _checkFileInIsolate,
          <Object?>[
            file.path,
            maxBytes,
            password,
            scratch.path,
            cancellation.handshake,
            lease.path,
          ],
        );
    switch (checked) {
      case FailureResult<List<Object?>>(:final Failure failure):
        return FailureResult<InspectedBundle>(failure);
      case Success<List<Object?>>(:final List<Object?> value):
        if (cancel?.isCancelled ?? false) {
          return const FailureResult<InspectedBundle>(CancelledFailure());
        }
        if (value.first case final int reason) {
          return FailureResult<InspectedBundle>(
            BundleReader.rejection(BundleRejection.values[reason]),
          );
        }
        final String sourcePath = value[3] as String? ?? file.path;
        final BundleManifest manifest = BundleManifest.fromJson(value[1]);
        final NativeBundleEntries files = NativeBundleEntries(
          source: sourcePath,
          scratch: scratch,
          entries: manifest.entries,
          inventory: value[4]! as Map<String, BundleZipEntry>,
        );
        final InspectedBundle bundle = InspectedBundle(
          name: name,
          manifest: manifest,
          tables: _tablesFrom(value[2]),
          readEntry: files.readEntry,
          openEntry: files.openEntry,
          close: files.close,
        );
        keep = true;
        return Success<InspectedBundle>(bundle);
    }
  } on Object catch (error) {
    return FailureResult<InspectedBundle>(Failure.from(error));
  } finally {
    cancellation?.close();
    if (!keep && scratch != null && await scratch.exists()) {
      await scratch.delete(recursive: true);
    }
  }
}

Future<Result<InspectedBundle>> _inspectBytes(
  Uint8List bytes,
  String name,
  int? maxBytes,
  String? password,
  CancellationToken? cancel,
) async {
  if (cancel?.isCancelled ?? false) {
    return const FailureResult<InspectedBundle>(CancelledFailure());
  }
  if (BundleEncryption.isSealed(bytes)) {
    if (password == null) {
      return FailureResult<InspectedBundle>(_passwordRequired);
    }
    if (bytes.length > (maxBytes ?? AppConstants.imports.bundleMaxBytes)) {
      return FailureResult<InspectedBundle>(
        BundleReader.rejection(BundleRejection.tooLarge),
      );
    }
    try {
      bytes = await BundleEncryption().openAsync(
        bytes,
        password,
        cancel: cancel,
      );
    } on Object catch (error) {
      return FailureResult<InspectedBundle>(Failure.from(error));
    }
  }
  final Object checked = _check(
    length: bytes.length,
    read: (int offset, int count) => Uint8List.sublistView(
      bytes,
      offset.clamp(0, bytes.length),
      (offset + count).clamp(0, bytes.length),
    ),
    maxBytes: maxBytes ?? AppConstants.imports.bundleMaxBytes,
    maxUncompressed: AppConstants.imports.archiveUncompressedMaxBytes,
    open: () => BundleArchiveStream.decode(InputMemoryStream(bytes)),
  );
  if (checked is BundleRejection) {
    return FailureResult<InspectedBundle>(BundleReader.rejection(checked));
  }
  if (cancel?.isCancelled ?? false) {
    return const FailureResult<InspectedBundle>(CancelledFailure());
  }
  final ({Archive archive, Map<String, Object?> manifest, Object tables})
  ready =
      checked
          as ({Archive archive, Map<String, Object?> manifest, Object tables});
  return Success<InspectedBundle>(
    InspectedBundle(
      name: name,
      manifest: BundleManifest.fromJson(ready.manifest),
      tables: _tablesFrom(ready.tables),
      readEntry: (String path) async => _entry(ready.archive, path),
      close: () async {},
    ),
  );
}

/// Runs in the isolate: every check over the file at `job[0]`, under the
/// ceiling `job[1]` when set. Returns `[rejectionIndex]`, or
/// `[null, manifestJson, tables, decryptedPath, checkedEntryInventory]`.
List<Object?> _checkFileInIsolate(List<Object?> job) {
  final WorkerCancellation cancellation = WorkerCancellation(
    job[4]! as SendPort,
    lease: File(job[5]! as String),
  );
  try {
    cancellation.check();
    return _checkNativeFile(job, cancellation);
  } finally {
    cancellation.close();
  }
}

List<Object?> _checkNativeFile(
  List<Object?> job,
  WorkerCancellation cancellation,
) {
  String path = job[0]! as String;
  final int? ceiling = job[1] as int?;
  final String? password = job[2] as String?;
  Directory? temporary;
  final List<int> header = _readHeader(path);
  if (BundleEncryption.isSealed(header)) {
    if (password == null) throw _passwordRequired;
    if (File(path).lengthSync() >
        (ceiling ?? AppConstants.bundles.nativeMaxBytes)) {
      return <Object?>[BundleRejection.tooLarge.index];
    }
    temporary = Directory(job[3]! as String);
    final File decrypted = File('${temporary.path}/opened.zip');
    // The parent owns this directory and removes it after a rejected or failed
    // worker. Keeping cleanup there also preserves its cancellation lease.
    BundleEncryption().openFile(
      File(path),
      decrypted,
      password,
      check: cancellation.check,
    );
    path = decrypted.path;
  }
  final File file = File(path);
  final RandomAccessFile raf = file.openSync();
  InputFileStream? input;
  final Map<String, BundleZipEntry> inventory = <String, BundleZipEntry>{};
  try {
    final Object checked = _check(
      length: raf.lengthSync(),
      read: (int offset, int count) {
        cancellation.check();
        raf.setPositionSync(offset);
        return raf.readSync(count);
      },
      maxBytes: ceiling ?? AppConstants.bundles.nativeMaxBytes,
      maxUncompressed: AppConstants.bundles.nativeMaxUncompressedBytes,
      checkpoint: cancellation.check,
      open: () {
        input = InputFileStream(path);
        return BundleArchiveStream.decode(
          input!,
          inventory: inventory,
          checkpoint: cancellation.check,
        );
      },
    );
    if (checked is BundleRejection) {
      return <Object?>[checked.index];
    }
    final ({Archive archive, Map<String, Object?> manifest, Object tables})
    ready =
        checked
            as ({
              Archive archive,
              Map<String, Object?> manifest,
              Object tables,
            });
    return <Object?>[
      null,
      ready.manifest,
      ready.tables,
      temporary == null ? null : path,
      inventory,
    ];
  } finally {
    raf.closeSync();
    input?.closeSync();
  }
}

List<int> _readHeader(String path) {
  final RandomAccessFile input = File(path).openSync();
  try {
    return input.readSync(8);
  } finally {
    input.closeSync();
  }
}

final PermissionFailure _passwordRequired = PermissionFailure(
  localizedMessage: Copy.messages.failureThisBundleNeedsAPassword,
  localizedRecovery: Copy.messages.failureEnterItsPasswordToOpenIt,
);

/// Every check in order. Returns the first [BundleRejection], or the
/// decoded archive, the manifest's JSON and the tables.
Object _check({
  required int length,
  required Uint8List Function(int offset, int count) read,
  required int maxBytes,
  required int maxUncompressed,
  required Archive Function() open,
  void Function()? checkpoint,
}) {
  checkpoint?.call();
  if (length > maxBytes) {
    return BundleRejection.tooLarge;
  }
  if (!looksLikeZip(read(0, AppConstants.imports.sniffHeaderBytes))) {
    return BundleRejection.notAPackage;
  }
  switch (checkZipDirectory(
    length: length,
    read: read,
    maxUncompressed: maxUncompressed,
  )) {
    case null:
      break;
    case ArchiveProblem.notArchive:
      return BundleRejection.notAPackage;
    case ArchiveProblem.unsafePath:
    case ArchiveProblem.link:
      return BundleRejection.unsafePath;
    case ArchiveProblem.tooLarge:
      return BundleRejection.tooLarge;
  }
  final Archive archive;
  try {
    archive = open();
  } on CancelledFailure {
    rethrow;
  } on Object {
    return BundleRejection.notAPackage;
  }
  final Set<String> names = <String>{
    for (final ArchiveFile file in archive.files)
      if (file.isFile) file.name,
  };
  if (!names.contains(BundleFormat.manifest)) {
    return BundleRejection.notAPackage;
  }
  final int metadataBytes = archive.files
      .where(
        (ArchiveFile file) =>
            file.isFile && BundleFormat.isMetadataEntry(file.name),
      )
      .fold<int>(0, (int size, ArchiveFile file) => size + file.size);
  if (metadataBytes > AppConstants.bundles.metadataMaxBytes ||
      archive.findFile(BundleFormat.manifest)!.size >
          AppConstants.bundles.manifestMaxBytes) {
    return BundleRejection.tooLarge;
  }
  final Map<String, Object?> manifestJson;
  final BundleManifest manifest;
  try {
    final Object? decoded = jsonDecode(
      utf8.decode(_bytesOf(archive.findFile(BundleFormat.manifest)!)),
    );
    manifestJson = decoded! as Map<String, Object?>;
    manifest = BundleManifest.fromJson(manifestJson);
  } on Object {
    return BundleRejection.unreadable;
  }
  if (manifest.format != BundleFormat.name) {
    return BundleRejection.notAPackage;
  }
  if (manifest.formatVersion > BundleFormat.version) {
    return BundleRejection.unknownFormatVersion;
  }
  if (!BundleFormat.requiredEntries.every(names.contains)) {
    return BundleRejection.missingEntry;
  }
  final Set<String> listed = <String>{BundleFormat.manifest};
  for (final BundleEntry entry in manifest.entries) {
    checkpoint?.call();
    listed.add(entry.path);
    final ArchiveFile? file = archive.findFile(entry.path);
    if (file == null || !file.isFile) {
      return BundleRejection.missingEntry;
    }
    final String checksum;
    try {
      if (file.size != entry.byteLength) {
        return BundleRejection.checksumMismatch;
      }
      checksum = BundleArchiveStream.checksum(file, checkpoint: checkpoint);
    } on CancelledFailure {
      rethrow;
    } on Object {
      return BundleRejection.unreadable;
    }
    if (checksum != entry.sha256) {
      return BundleRejection.checksumMismatch;
    }
  }
  // An entry the manifest does not vouch for could be anything.
  if (!names.every(listed.contains)) {
    return BundleRejection.checksumMismatch;
  }
  final Map<String, List<Map<String, Object?>>> tables =
      <String, List<Map<String, Object?>>>{};
  try {
    for (final String name in names) {
      final bool tableEntry =
          BundleFormat.tableEntries.containsKey(name) ||
          (name.startsWith(BundleFormat.referenceFolder) &&
              name.endsWith('.json'));
      if (!tableEntry) {
        continue;
      }
      final Object? decoded = jsonDecode(
        utf8.decode(_bytesOf(archive.findFile(name)!)),
      );
      if (decoded is! Map<String, Object?>) {
        return BundleRejection.unreadable;
      }
      for (final MapEntry<String, Object?> table in decoded.entries) {
        if (!BundleFormat.insertOrder.contains(table.key) ||
            table.value is! List<Object?>) {
          return BundleRejection.unreadable;
        }
        final List<Map<String, Object?>> rows = tables.putIfAbsent(
          table.key,
          () => <Map<String, Object?>>[],
        );
        for (final Object? row in table.value! as List<Object?>) {
          if (row is! Map<String, Object?> ||
              row['id'] is! String ||
              !(BundleFormat.requiredColumns[table.key] ?? const <String>[])
                  .every(row.containsKey)) {
            return BundleRejection.unreadable;
          }
          rows.add(row);
        }
      }
    }
  } on Object {
    return BundleRejection.unreadable;
  }
  if ((tables['projects'] ?? const <Map<String, Object?>>[]).length != 1 ||
      tables['projects']!.single['id'] != manifest.projectId) {
    return BundleRejection.unreadable;
  }
  return (archive: archive, manifest: manifestJson, tables: tables);
}

Uint8List _bytesOf(ArchiveFile file) {
  return BundleArchiveStream.bytes(
    file,
    maximum: BundleFormat.isMetadataEntry(file.name)
        ? AppConstants.bundles.metadataMaxBytes
        : AppConstants.imports.bundleMaxBytes,
  );
}

Result<Uint8List> _entry(Archive archive, String path) {
  final ArchiveFile? file = archive.findFile(path);
  if (file == null || !file.isFile) {
    return FailureResult<Uint8List>(
      BundleReader.rejection(BundleRejection.missingEntry),
    );
  }
  return Success<Uint8List>(_bytesOf(file));
}

Map<String, List<Map<String, Object?>>> _tablesFrom(Object? raw) {
  final Map<Object?, Object?> source = raw! as Map<Object?, Object?>;
  return <String, List<Map<String, Object?>>>{
    for (final MapEntry<Object?, Object?> table in source.entries)
      table.key! as String: <Map<String, Object?>>[
        for (final Object? row in table.value! as List<Object?>)
          Map<String, Object?>.from(row! as Map<Object?, Object?>),
      ],
  };
}
