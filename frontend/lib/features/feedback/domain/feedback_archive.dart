import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'feedback_entry.dart';
import 'feedback_workbook.dart';

/// A feedback download: the [FeedbackWorkbook] spreadsheet plus the matching
/// screenshot files, packed so they travel together.
final class FeedbackArchive {
  /// Creates the archive around [workbook].
  const FeedbackArchive({required this.workbook});

  /// The spreadsheet and the screenshot bytes it already holds.
  final FeedbackWorkbook workbook;

  /// Media type a browser or share sheet is given for the result.
  static const String mimeType = 'application/zip';

  /// `TAPTURE-18092026-1002.zip`: the same stamp as [FeedbackWorkbook.fileName].
  String get fileName {
    final String xlsx = workbook.fileName;
    const String suffix = '.xlsx';
    if (xlsx.endsWith(suffix)) {
      return '${xlsx.substring(0, xlsx.length - suffix.length)}.zip';
    }
    return '$xlsx.zip';
  }

  /// The encoded zip. Top-level so the isolate runner can call it
  /// (FE-PERF-02).
  static Uint8List encode(FeedbackArchive pack) {
    final FeedbackWorkbook workbook = pack.workbook;
    final Uint8List xlsx = FeedbackWorkbook.encode(workbook);
    final Archive zip = Archive();
    zip.addFile(ArchiveFile.noCompress(workbook.fileName, xlsx.length, xlsx));
    for (final FeedbackEntry entry in workbook.entries) {
      final Uint8List? png = workbook.screenshots[entry.id];
      if (png == null || png.isEmpty) {
        continue;
      }
      final String name = '$_shotsFolder/${entry.reference}.png';
      zip.addFile(ArchiveFile.noCompress(name, png.length, png));
    }
    final List<int>? bytes = ZipEncoder().encode(
      zip,
      modified: workbook.generatedAtUtc,
    );
    return Uint8List.fromList(bytes ?? const <int>[]);
  }
}

const String _shotsFolder = 'screenshots';
