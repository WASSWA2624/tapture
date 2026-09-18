import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_archive.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_workbook.dart';

import '../../../support/factories.dart';

void main() {
  test('the archive name matches the workbook stamp', () {
    final FeedbackArchive pack = FeedbackArchive(workbook: _book());
    expect(pack.fileName, 'TAPTURE-18092026-1002.zip');
  });

  test('the zip holds the workbook and the screenshot files', () {
    final FeedbackEntry pictured = aFeedbackEntry(
      id: 'fb-1',
      number: 1,
      hasScreenshot: true,
    );
    final FeedbackEntry plain = aFeedbackEntry(
      id: 'fb-2',
      number: 2,
      hasScreenshot: false,
      message: 'No picture',
    );
    final FeedbackArchive pack = FeedbackArchive(
      workbook: _book(
        entries: <FeedbackEntry>[pictured, plain],
        screenshots: <String, Uint8List>{pictured.id: aFeedbackPng},
      ),
    );
    final Archive zip = ZipDecoder().decodeBytes(FeedbackArchive.encode(pack));
    expect(zip.findFile('TAPTURE-18092026-1002.xlsx'), isNotNull);
    expect(
      Uint8List.fromList(
        zip.findFile('screenshots/${pictured.reference}.png')!.content
            as List<int>,
      ),
      aFeedbackPng,
    );
    expect(zip.findFile('screenshots/${plain.reference}.png'), isNull);
  });

  test('the prompts guide sits at the archive root when given', () {
    const String guide = '# Feedback prompts generator';
    final FeedbackArchive pack = FeedbackArchive(
      workbook: _book(),
      guide: guide,
    );
    final Archive zip = ZipDecoder().decodeBytes(FeedbackArchive.encode(pack));
    final ArchiveFile? file = zip.findFile(FeedbackArchive.guideFileName);
    expect(FeedbackArchive.guideFileName, 'feedback-prompts-generator.md');
    expect(utf8.decode(file!.content as List<int>), guide);
  });

  test('a blank guide is left out rather than shipped empty', () {
    final FeedbackArchive pack = FeedbackArchive(workbook: _book(), guide: ' ');
    final Archive zip = ZipDecoder().decodeBytes(FeedbackArchive.encode(pack));
    expect(zip.findFile(FeedbackArchive.guideFileName), isNull);
  });

  test('a download with no screenshots is still a zip of the workbook', () {
    final FeedbackArchive pack = FeedbackArchive(workbook: _book());
    final Archive zip = ZipDecoder().decodeBytes(FeedbackArchive.encode(pack));
    expect(zip.files.where((ArchiveFile file) => file.isFile).length, 1);
    expect(zip.findFile('TAPTURE-18092026-1002.xlsx'), isNotNull);
  });
}

FeedbackWorkbook _book({
  List<FeedbackEntry>? entries,
  Map<String, Uint8List> screenshots = const <String, Uint8List>{},
}) {
  return FeedbackWorkbook(
    entries: entries ?? <FeedbackEntry>[aFeedbackEntry()],
    screenshots: screenshots,
    filter: const FeedbackFilter(),
    generatedAtUtc: DateTime.utc(2026, 9, 18, 7, 2),
    utcOffset: const Duration(hours: 3),
    timeZone: 'EAT',
    generatedBy: 'Ada',
  );
}
