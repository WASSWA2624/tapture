import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/files/picked_document.dart';

import 'bundle_entry.dart';
import 'bundle_format.dart';
import 'bundle_manifest.dart';
import 'bundle_rejection.dart';
import 'inspected_bundle.dart';

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
  }) {
    return switch (source) {
      PickedFile(:final File file) => _inspectFile(file, source.name, maxBytes),
      PickedBytes(:final Uint8List bytes) => _inspectBytes(
        bytes,
        source.name,
        maxBytes,
      ),
    };
  }

  /// The failure a refusal for [reason] is reported as.
  static CorruptionFailure rejection(BundleRejection reason) {
    return CorruptionFailure(
      message: rejectionMessage(reason),
      recoveryAction: Copy.packageRejectedRecovery,
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
) async {
  final Result<List<Object?>> checked =
      await runIsolate<List<Object?>, List<Object?>>(
        _checkFileInIsolate,
        <Object?>[file.path, maxBytes],
      );
  switch (checked) {
    case FailureResult<List<Object?>>(:final Failure failure):
      return FailureResult<InspectedBundle>(failure);
    case Success<List<Object?>>(:final List<Object?> value):
      if (value.first case final int reason) {
        return FailureResult<InspectedBundle>(
          BundleReader.rejection(BundleRejection.values[reason]),
        );
      }
      InputFileStream? input;
      Archive? archive;
      return Success<InspectedBundle>(
        InspectedBundle(
          name: name,
          manifest: BundleManifest.fromJson(value[1]),
          tables: _tablesFrom(value[2]),
          readEntry: (String path) async {
            try {
              input ??= InputFileStream(file.path);
              archive ??= ZipDecoder().decodeBuffer(input!);
              return _entry(archive!, path);
            } on Object {
              return FailureResult<Uint8List>(
                BundleReader.rejection(BundleRejection.unreadable),
              );
            }
          },
          close: () async {
            await input?.close();
            input = null;
            archive = null;
          },
        ),
      );
  }
}

Future<Result<InspectedBundle>> _inspectBytes(
  Uint8List bytes,
  String name,
  int? maxBytes,
) async {
  final Object checked = _check(
    length: bytes.length,
    read: (int offset, int count) => Uint8List.sublistView(
      bytes,
      offset.clamp(0, bytes.length),
      (offset + count).clamp(0, bytes.length),
    ),
    maxBytes: maxBytes ?? AppConstants.imports.bundleMaxBytes,
    maxUncompressed: AppConstants.imports.archiveUncompressedMaxBytes,
    open: () => ZipDecoder().decodeBytes(bytes),
  );
  if (checked is BundleRejection) {
    return FailureResult<InspectedBundle>(BundleReader.rejection(checked));
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
/// `[null, manifestJson, tables]`.
List<Object?> _checkFileInIsolate(List<Object?> job) {
  final String path = job[0]! as String;
  final int? ceiling = job[1] as int?;
  final File file = File(path);
  final RandomAccessFile raf = file.openSync();
  InputFileStream? input;
  try {
    final Object checked = _check(
      length: raf.lengthSync(),
      read: (int offset, int count) {
        raf.setPositionSync(offset);
        return raf.readSync(count);
      },
      maxBytes: ceiling ?? AppConstants.bundles.nativeMaxBytes,
      maxUncompressed: AppConstants.bundles.nativeMaxUncompressedBytes,
      open: () {
        input = InputFileStream(path);
        return ZipDecoder().decodeBuffer(input!);
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
    return <Object?>[null, ready.manifest, ready.tables];
  } finally {
    raf.closeSync();
    input?.closeSync();
  }
}

/// Every check in order. Returns the first [BundleRejection], or the
/// decoded archive, the manifest's JSON and the tables.
Object _check({
  required int length,
  required Uint8List Function(int offset, int count) read,
  required int maxBytes,
  required int maxUncompressed,
  required Archive Function() open,
}) {
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
    listed.add(entry.path);
    final ArchiveFile? file = archive.findFile(entry.path);
    if (file == null || !file.isFile) {
      return BundleRejection.missingEntry;
    }
    final Uint8List bytes;
    try {
      bytes = _bytesOf(file);
    } on Object {
      return BundleRejection.unreadable;
    }
    if (bytes.length != entry.byteLength ||
        crypto.sha256.convert(bytes).toString() != entry.sha256) {
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
  final Object? content = file.content;
  if (content is Uint8List) {
    return content;
  }
  if (content is List<int>) {
    return Uint8List.fromList(content);
  }
  throw const FormatException('An entry has no content.');
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
