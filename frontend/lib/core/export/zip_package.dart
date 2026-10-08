import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'export_manifest.dart';

/// A ZIP of outputs, photos and the manifest (task 018).
///
/// Entries are added one at a time. The manifest is last.
final class ZipPackage {
  /// Builds the archive. [outputs] and [photos] are path to bytes.
  static Uint8List build({
    required Map<String, List<int>> outputs,
    required Map<String, List<int>> photos,
    required ExportManifest manifest,
  }) {
    final Archive archive = Archive();
    void add(String path, List<int> bytes) {
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    for (final MapEntry<String, List<int>> entry in outputs.entries) {
      add('outputs/${entry.key}', entry.value);
    }
    for (final MapEntry<String, List<int>> entry in photos.entries) {
      add('photos/${entry.key}', entry.value);
    }
    final List<int> manifestBytes = utf8.encode(manifest.encode());
    add('manifest.json', manifestBytes);
    return ZipEncoder().encodeBytes(archive);
  }
}
