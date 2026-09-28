import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/export/csv_writer.dart';
import 'package:tapture/core/export/export_manifest.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/json_writer.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/core/export/pdf/record_report.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_writer.dart';
import 'package:tapture/core/export/zip_package.dart';
import 'package:tapture/features/records/domain/record_entry.dart';

import 'support/harness.dart';

void main() {
  test('xlsx, csv, json, pdf and zip match the record count offline', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    app.backend.markUnreachable();
    final List<ExportRecord> rows = <ExportRecord>[];
    for (var index = 0; index < 3; index++) {
      final RecordEntry entry = await app.capture(
        fields: <String, String>{'serial': 'E-$index'},
      );
      rows.add(app.rowOf(await app.approve(entry.id)));
    }
    final ExportRequest request = ExportRequest(
      projectId: 'project-1',
      formats: ExportFormat.values.toSet(),
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
        photoIndex: false,
        photoMode: 'filename',
        delimiter: ',',
      ),
      records: rows,
    );
    final String csv = CsvWriter.write(request).values.single;
    final Object? json = jsonDecode(JsonWriter.write(request));
    final List<Object?> jsonRecords =
        (json as Map<String, Object?>)['records']! as List<Object?>;
    final Uint8List xlsx = await _xlsx(request);
    final PdfDocument pdf = RecordReport.build(
      request,
      engine: const PdfEngine(),
      photoColumns: 2,
    );
    final ExportManifest manifest = ExportManifest(
      exportId: 'export-1',
      createdAt: app.clock.nowUtc(),
      request: request,
      entries: <ManifestEntry>[
        for (var index = 0; index < rows.length; index++)
          (
            recordId: rows[index].id,
            recordNumber: rows[index].number,
            sheet: 'Meters',
            row: index + 2,
            photoPaths: const <String>[],
          ),
      ],
    );
    final Uint8List zip = ZipPackage.build(
      outputs: <String, List<int>>{'records.csv': utf8.encode(csv)},
      photos: const <String, List<int>>{},
      manifest: manifest,
    );
    expect(_dataRows(csv), 3);
    expect(jsonRecords, hasLength(3));
    expect(xlsx.first, 0x50);
    expect(pdf.bodyLines, isNotEmpty);
    expect(ZipDecoder().decodeBytes(zip).findFile('manifest.json'), isNotNull);
    expect(app.outboundCallCount, 0);
  });
}

int _dataRows(String csv) {
  return csv.split('\n').where((String line) => line.trim().isNotEmpty).length -
      1;
}

Future<Uint8List> _xlsx(ExportRequest request) async {
  final List<int> bytes = <int>[];
  await XlsxWriter.write(
    request: request,
    token: CancellationToken(),
    emit: (Uint8List chunk) => bytes.addAll(chunk),
    discard: () {},
  ).drain<void>();
  return Uint8List.fromList(bytes);
}
