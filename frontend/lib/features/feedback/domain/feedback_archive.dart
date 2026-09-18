import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'feedback_entry.dart';
import 'feedback_workbook.dart';

/// A feedback download: the [FeedbackWorkbook] spreadsheet, the matching
/// screenshot files and, when given, the [guide] an AI agent follows to turn
/// them into implementation prompts, packed so they travel together.
final class FeedbackArchive {
  /// Creates the archive around [workbook].
  const FeedbackArchive({required this.workbook, this.guide});

  /// The spreadsheet and the screenshot bytes it already holds.
  final FeedbackWorkbook workbook;

  /// Markdown written at the archive root as [guideFileName]. Null leaves
  /// it out, so a missing guide never blocks a download.
  final String? guide;

  /// The guide's name inside the archive.
  static const String guideFileName = 'feedback-prompts-generator.md';

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
    final String? guide = pack.guide;
    if (guide != null && guide.trim().isNotEmpty) {
      final List<int> text = utf8.encode(guide);
      zip.addFile(ArchiveFile(guideFileName, text.length, text));
    }
    for (final FeedbackEntry entry in workbook.entries) {
      final Uint8List? png = workbook.screenshots[entry.id];
      if (png != null && png.isNotEmpty) {
        final String name = '$_shotsFolder/${entry.reference}.png';
        zip.addFile(ArchiveFile.noCompress(name, png.length, png));
      }
      for (int index = 2; ; index++) {
        final Uint8List? extra = workbook.screenshots['${entry.id}#$index'];
        if (extra == null) {
          break;
        }
        if (extra.isEmpty) {
          continue;
        }
        final String name = '$_shotsFolder/${entry.reference}-$index.png';
        zip.addFile(ArchiveFile.noCompress(name, extra.length, extra));
      }
    }
    final List<int>? bytes = ZipEncoder().encode(
      zip,
      modified: workbook.generatedAtUtc,
    );
    return Uint8List.fromList(bytes ?? const <int>[]);
  }
}

const String _shotsFolder = 'screenshots';
