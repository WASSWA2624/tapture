import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_workbook.dart';
import 'package:xml/xml.dart';

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
      utf8.decode(archive.findFile('xl/workbook.xml')!.content),
      contains('Feedback'),
    );
  });

  for (final bool hasScreenshot in <bool>[false, true]) {
    test('encoded feedback stays aligned with screenshots $hasScreenshot', () {
      const String accountId = 'excluded-account-id';
      final FeedbackWorkbook workbook = FeedbackWorkbook(
        entries: <FeedbackEntry>[
          aFeedbackEntry(hasScreenshot: hasScreenshot, accountId: accountId),
        ],
        screenshots: <String, Uint8List>{
          if (hasScreenshot) 'fb-1': aFeedbackPng,
        },
        filter: const FeedbackFilter(),
        generatedAtUtc: DateTime.utc(2026, 9, 18, 7, 2),
        utcOffset: const Duration(hours: 3),
        timeZone: 'EAT',
        generatedBy: 'Ada',
      );
      final Archive archive = ZipDecoder().decodeBytes(
        FeedbackWorkbook.encode(workbook),
      );
      final XmlDocument sheet = XmlDocument.parse(
        utf8.decode(archive.findFile('xl/worksheets/sheet1.xml')!.content),
      );
      final List<String> strings =
          XmlDocument.parse(
                utf8.decode(archive.findFile('xl/sharedStrings.xml')!.content),
              )
              .findAllElements('si')
              .map((XmlElement value) => value.innerText)
              .toList();
      final Map<String, XmlElement> cells = <String, XmlElement>{
        for (final XmlElement cell in sheet.findAllElements('c'))
          cell.getAttribute('r')!: cell,
      };
      String textAt(String reference) =>
          strings[int.parse(cells[reference]!.getElement('v')!.innerText)];

      expect(strings, isNot(contains(accountId)));
      expect(textAt('H1'), 'User Name');
      expect(textAt('I1'), 'Screen');
      expect(textAt('AE1'), 'Screenshot');
      expect(textAt('AJ1'), 'OS Version');
      expect(textAt('G2'), 'ada@x');
      expect(textAt('H2'), 'Ada');
      expect(textAt('I2'), 'Projects');
      expect(textAt('K2'), 'No');
      expect(textAt('O2'), 'windows');
      expect(textAt('AF2'), 'A');
      expect(textAt('AG2'), 'p1');
      expect(textAt('AH2'), 'device-1');
      expect(textAt('AI2'), 'test-model');
      expect(textAt('AJ2'), 'test-os');
      expect(cells['B2']!.getAttribute('t'), isNull);
      expect(cells['B2']!.getAttribute('s'), '2');
      expect(cells['Z2']!.getAttribute('t'), isNull);
      expect(cells['Z2']!.getElement('v')!.innerText, '1');
      expect(
        sheet.findAllElements('dimension').single.getAttribute('ref'),
        'A1:AJ2',
      );
      expect(
        sheet.findAllElements('autoFilter').single.getAttribute('ref'),
        'A1:AJ2',
      );
      final List<XmlElement> links = sheet
          .findAllElements('hyperlink')
          .toList();
      if (hasScreenshot) {
        expect(textAt('AE2'), 'View screenshot');
        expect(links.single.getAttribute('ref'), 'AE2');
        expect(links.single.getAttribute('location'), "'Screenshots'!D2");
        expect(archive.findFile('xl/media/image1.png')!.content, aFeedbackPng);
      } else {
        expect(cells['AE2'], isNull);
        expect(links, isEmpty);
      }
    });
  }
}
