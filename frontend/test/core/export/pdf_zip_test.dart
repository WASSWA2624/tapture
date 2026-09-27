import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/export/export_manifest.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/pdf/inspection_report.dart';
import 'package:tapture/core/export/pdf/minutes_report.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/core/export/pdf/record_report.dart';
import 'package:tapture/core/export/pdf/summary_report.dart';
import 'package:tapture/core/export/pdf/variance_report.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/zip_package.dart';

void main() {
  const PdfEngine engine = PdfEngine();

  test('a cancelled render emits nothing', () async {
    final CancellationToken token = CancellationToken()..cancel();
    var discarded = false;
    final List<double> progress = <double>[];
    await for (final double step in engine.render(
      document: engine.document(
        title: 'Record report',
        project: 'p1',
        coverLines: const <String>['records 0'],
        bodyLines: const <String>[],
      ),
      token: token,
      emit: (Uint8List _) {},
      discard: () => discarded = true,
    )) {
      progress.add(step);
    }
    expect(discarded, isTrue);
    expect(progress, isEmpty);
  });

  test('reports share the engine and label raw and refined minutes', () async {
    const ExportRequest request = ExportRequest(
      projectId: 'Plant',
      formats: <ExportFormat>{ExportFormat.pdf},
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
      records: <ExportRecord>[
        ExportRecord(
          id: 'r1',
          number: '1',
          templateId: 't',
          templateName: 'Asset',
          status: 'approved',
          contextPath: 'North',
          operatorName: 'Ada',
          values: <ExportValue>[
            (
              key: 'condition',
              label: 'Condition',
              type: 'text',
              raw: 'fair',
              refined: 'good',
              finalText: 'good',
              unit: null,
              code: null,
              confidence: null,
              evidence: null,
            ),
          ],
        ),
      ],
    );
    final PdfDocument record = RecordReport.build(
      request,
      engine: engine,
      photoColumns: 2,
    );
    expect(record.bodyLines.join(' '), contains('North'));
    expect(record.bodyLines.join(' '), contains('Ada'));
    expect(record.bodyLines.join(' '), contains('Refined'));
    final PdfDocument inspection = InspectionReport.build(
      engine: engine,
      project: 'Plant',
      rowOrder: const <String>['row-a', 'row-b'],
      captured: const <String, InspectionRow>{
        'row-b': (
          result: 'pass',
          observation: 'ok',
          risk: 'low',
          recommendation: 'none',
        ),
      },
    );
    expect(inspection.bodyLines.first, contains('row-a'));
    expect(inspection.bodyLines.join(' '), contains('Not found'));
    expect(inspection.coverLines.join(' '), contains('not found 1'));
    final summary = SummaryReport.build(
      engine: engine,
      project: 'Plant',
      records: request.records,
    );
    expect(summary.counts['status:approved'], 1);
    final PdfDocument variance = VarianceReport.build(
      engine: engine,
      project: 'Plant',
      matched: const <VarianceLine>[(key: 'k1', label: 'Pump')],
      missing: const <VarianceLine>[(key: 'k2', label: 'Valve')],
      notInRegister: const <VarianceLine>[(key: 'k3', label: 'Extra')],
    );
    expect(variance.bodyLines, contains('Missing'));
    expect(variance.bodyLines.join(' '), contains('k2'));
    final PdfDocument minutes = MinutesReport.build(
      engine: engine,
      project: 'Plant',
      attendance: const <String>['Ada'],
      agenda: const <MinutesSection>[
        (
          title: 'Welcome',
          raw: 'spoken',
          refined: 'summary',
          decisions: <String>['Adopt'],
          actions: <String>['Send'],
        ),
      ],
      photos: const <({String caption, String path})>[
        (caption: 'Board', path: 'photos/board.jpg'),
      ],
    );
    final String lines = minutes.bodyLines.join(' ');
    expect(lines, contains('Raw notes spoken'));
    expect(lines, contains('Refined minutes summary'));
    expect(lines, isNot(contains('Raw notes summary')));
    late Uint8List pdf;
    await for (final double _ in engine.render(
      document: minutes,
      token: CancellationToken(),
      emit: (Uint8List value) => pdf = value,
      discard: () {},
    )) {}
    expect(utf8.decode(pdf), contains('%PDF'));
    expect(utf8.decode(pdf), contains('Refined minutes summary'));
  });

  test('the archive layout and manifest name every record', () {
    const ExportRequest request = ExportRequest(
      projectId: 'p1',
      formats: <ExportFormat>{ExportFormat.zip},
      scope: (
        kind: ExportScopeKind.all,
        context: null,
        from: null,
        to: null,
        filter: null,
      ),
      columns: (raw: false, refined: true, confidence: false, evidence: false),
      extras: (
        dictionary: false,
        photoIndex: true,
        photoMode: 'path',
        delimiter: ',',
      ),
    );
    final ExportManifest manifest = ExportManifest(
      exportId: 'e1',
      createdAt: DateTime.utc(2026, 9, 28),
      request: request,
      entries: const <ManifestEntry>[
        (
          recordId: 'r1',
          recordNumber: '1',
          sheet: 'Asset',
          row: 2,
          photoPaths: <String>['photos/front.jpg'],
        ),
      ],
    );
    final Map<String, Object?> json = manifest.toJson();
    expect(json['exportId'], 'e1');
    expect(json['request'], request.toJson());
    final Uint8List zip = ZipPackage.build(
      outputs: <String, List<int>>{
        'records.xlsx': <int>[1, 2],
      },
      photos: <String, List<int>>{
        'front.jpg': <int>[3],
      },
      manifest: manifest,
    );
    final Archive archive = ZipDecoder().decodeBytes(zip);
    final Set<String> names = <String>{
      for (final ArchiveFile file in archive.files) file.name,
    };
    expect(names, contains('outputs/records.xlsx'));
    expect(names, contains('photos/front.jpg'));
    expect(names, contains('manifest.json'));
  });
}
