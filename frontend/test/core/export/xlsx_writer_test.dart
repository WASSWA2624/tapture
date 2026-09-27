import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_multi_sheet.dart';
import 'package:tapture/core/export/xlsx_photo_refs.dart';
import 'package:tapture/core/export/xlsx_row_targeting.dart';
import 'package:tapture/core/export/xlsx_template_copy.dart';
import 'package:tapture/core/export/xlsx_writer.dart';

void main() {
  test(
    'sheets keep raw and refined side by side and stamp incomplete',
    () async {
      final ExportRequest request = _request(marked: true);
      final List<double> progress = <double>[];
      Uint8List? bytes;
      await for (final double step in XlsxWriter.write(
        request: request,
        token: CancellationToken(),
        emit: (Uint8List value) => bytes = value,
        discard: () {},
      )) {
        progress.add(step);
      }
      expect(progress, <double>[0, 1]);
      final String xml = _xml(bytes!);
      expect(xml, contains('Serial (refined)'));
      expect(xml, contains('00734'));
      expect(xml, contains('Marked incomplete'));
      expect(xml, contains('Photo index'));
    },
  );

  test('a batch finishes with progress inside thirty seconds', () async {
    final ExportRequest request = _request(count: 5000);
    final Stopwatch watch = Stopwatch()..start();
    await XlsxWriter.write(
      request: request,
      token: CancellationToken(),
      emit: (Uint8List _) {},
      discard: () {},
    ).drain<void>();
    watch.stop();
    expect(watch.elapsed, lessThan(const Duration(seconds: 30)));
  });

  test('sheet names are unique and valid', () {
    final List<SheetPlan> plans = XlsxMultiSheet.plan(
      <({String id, String name})>[
        (id: 'a', name: 'Pump'),
        (id: 'b', name: 'Pump'),
      ],
    );
    expect(plans.map((SheetPlan plan) => plan.sheetName).toSet(), hasLength(2));
  });

  test('the stored template bytes are unchanged by a copy', () {
    final Uint8List source = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final int before = Object.hashAll(source);
    final Uint8List copy = XlsxTemplateCopy.copyOf(source);
    copy[0] = 9;
    expect(Object.hashAll(source), before);
    expect(XlsxTemplateCopy.unpreserved, contains('macros'));
  });

  test('row targeting marks matched, missing and duplicate rows', () {
    final List<RowTarget> targets = XlsxRowTargeting.resolve(
      recordKeys: const <String>['a', 'b', 'c'],
      rowsByKey: const <String, List<int>>{
        'a': <int>[2],
        'c': <int>[4, 5],
      },
    );
    expect(targets[0].status, 'matched');
    expect(targets[1].status, 'notFound');
    expect(targets[2].status, 'duplicate');
    expect(XlsxRowTargeting.unmatchedCount(targets), 1);
  });

  test('photo mode changes only the photo cell', () {
    expect(
      XlsxPhotoRefs.cell(
        mode: 'filename',
        fileName: 'front.jpg',
        relativePath: 'photos/front.jpg',
      ),
      'front.jpg',
    );
    expect(
      XlsxPhotoRefs.cell(
        mode: 'path',
        fileName: 'front.jpg',
        relativePath: 'photos/front.jpg',
      ),
      'photos/front.jpg',
    );
    expect(
      XlsxPhotoRefs.rowHeight('embed'),
      greaterThan(XlsxPhotoRefs.rowHeight('filename')),
    );
  });
}

ExportRequest _request({bool marked = false, int count = 1}) {
  return ExportRequest(
    projectId: 'p1',
    formats: const <ExportFormat>{ExportFormat.xlsx},
    scope: (
      kind: ExportScopeKind.all,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: true, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: false,
      photoIndex: true,
      photoMode: 'filename',
      delimiter: ',',
    ),
    markedIncomplete: marked,
    records: <ExportRecord>[
      for (var i = 0; i < count; i++)
        const ExportRecord(
          id: 'r1',
          number: '00734',
          templateId: 't1',
          templateName: 'Asset',
          status: 'approved',
          photos: <ExportPhoto>[
            (
              id: 'ph1',
              recordId: 'r1',
              type: 'front',
              caption: 'Front',
              storedPath: 'photos/front.jpg',
              originalName: 'front.jpg',
              sequence: 1,
            ),
          ],
          values: <ExportValue>[
            (
              key: 'Serial',
              label: 'Serial',
              type: 'barcode',
              raw: '00734',
              refined: '734',
              finalText: '00734',
              unit: null,
              code: null,
              confidence: null,
              evidence: null,
            ),
          ],
        ),
    ],
  );
}

String _xml(Uint8List bytes) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final StringBuffer buffer = StringBuffer();
  for (final ArchiveFile file in archive.files) {
    if (file.name.endsWith('.xml')) {
      buffer.write(utf8.decode(file.content as List<int>));
    }
  }
  return buffer.toString();
}
