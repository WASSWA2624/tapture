import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_workbook.dart';

import '../../../support/factories.dart';

void main() {
  test('the file name uses the downloading device clock', () {
    final FeedbackWorkbook workbook = FeedbackWorkbook(
      entries: <FeedbackEntry>[aFeedbackEntry()],
      filter: const FeedbackFilter(),
      generatedAtUtc: DateTime.utc(2026, 9, 18, 7, 2),
      utcOffset: const Duration(hours: 3),
      timeZone: 'EAT',
      generatedBy: 'Ada',
    );
    expect(workbook.fileName, 'TAPTURE-18092026-1002.xlsx');
  });

  test('the book has Feedback, Screenshots and Export Details', () {
    final FeedbackWorkbook workbook = FeedbackWorkbook(
      entries: <FeedbackEntry>[aFeedbackEntry(hasScreenshot: true)],
      screenshots: <String, Uint8List>{'fb-1': aFeedbackPng},
      filter: const FeedbackFilter(),
      generatedAtUtc: DateTime.utc(2026, 9, 18, 7, 2),
      utcOffset: const Duration(hours: 3),
      timeZone: 'EAT',
      generatedBy: 'Ada',
    );
    final List<String> sheets = workbook
        .toBook()
        .sheets
        .map((XlsxSheet sheet) => sheet.name)
        .toList();
    expect(sheets, <String>['Feedback', 'Screenshots', 'Export Details']);

    final Archive archive = ZipDecoder().decodeBytes(
      FeedbackWorkbook.encode(workbook),
    );
    expect(archive.findFile('xl/workbook.xml'), isNotNull);
    expect(
      utf8.decode(archive.findFile('xl/workbook.xml')!.content as List<int>),
      contains('Feedback'),
    );
  });
}
