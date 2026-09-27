import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'bundle_entry.dart';
import 'bundle_format.dart';
import 'bundle_manifest.dart';

/// What one package write zips: the JSON and extra entries in memory, the
/// project's files by their path inside the project folder, and the manifest
/// the entries complete. Built by `BundleWriter`, zipped by the platform.
final class BundleZipJob {
  /// Creates a job.
  const BundleZipJob({
    required this.storageRoot,
    required this.files,
    required this.folderName,
    required this.targetPath,
    required this.entries,
    required this.projectFiles,
    required this.manifest,
    required this.ceiling,
    required this.cancel,
    this.onProgress,
  });

  /// The device's storage root.
  final StorageRoot storageRoot;

  /// Where a browser reads the project's files from.
  final FileReader files;

  /// The project's folder under `projects/`.
  final String folderName;

  /// Where a device writes the package, under the storage root.
  final String targetPath;

  /// JSON tables and extras such as the workbook, by entry path.
  final Map<String, List<int>> entries;

  /// Paths inside the project folder of every file a row points at.
  final List<String> projectFiles;

  /// The manifest, without its entries.
  final BundleManifest manifest;

  /// The largest package this platform may write.
  final int ceiling;

  /// Stops the write; the partial file is removed.
  final CancellationToken cancel;

  /// Share of the entries written so far, 0 to 1.
  final void Function(double)? onProgress;
}

/// The last two entries of a package: `checksums.txt`, one `sha256  path`
/// line per entry sorted by path, and `manifest.json` listing every entry.
({List<int> manifest, List<int> checksums}) finishBundle(
  BundleManifest manifest,
  List<BundleEntry> written, {
  required List<String> missingFiles,
}) {
  final List<BundleEntry> sorted = List<BundleEntry>.of(written)
    ..sort((BundleEntry a, BundleEntry b) => a.path.compareTo(b.path));
  final List<int> checksums = utf8.encode(
    <String>[
      for (final BundleEntry entry in sorted)
        '${entry.sha256}  ${entry.path}\n',
    ].join(),
  );
  final List<BundleEntry> listed = <BundleEntry>[
    ...sorted,
    BundleEntry(
      path: BundleFormat.checksums,
      byteLength: checksums.length,
      sha256: crypto.sha256.convert(checksums).toString(),
    ),
  ];
  final List<int> manifestBytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(
      manifest.withEntries(listed, missingFiles: missingFiles).toJson(),
    ),
  );
  return (manifest: manifestBytes, checksums: checksums);
}
