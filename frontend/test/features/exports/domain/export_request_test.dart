import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';

void main() {
  test('a request round-trips field for field', () {
    const ExportRequest request = ExportRequest(
      projectId: 'p1',
      formats: <ExportFormat>{ExportFormat.xlsx, ExportFormat.csv},
      scope: (
        kind: ExportScopeKind.dateRange,
        context: null,
        from: '2026-09-01',
        to: '2026-09-28',
        filter: <String, Object?>{'status': 'approved'},
      ),
      columns: (raw: true, refined: true, confidence: false, evidence: true),
      extras: (
        dictionary: true,
        photoIndex: true,
        photoMode: 'path',
        delimiter: ';',
      ),
      markedIncomplete: true,
      files: <ExportFile>[(path: 'out/records.xlsx', role: 'workbook')],
      records: <ExportRecord>[
        ExportRecord(
          id: 'r1',
          number: '00734',
          templateId: 't1',
          templateName: 'Asset',
          status: 'approved',
          approved: true,
          values: <ExportValue>[
            (
              key: 'serial',
              label: 'Serial',
              type: 'barcode',
              raw: '00734',
              refined: null,
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
    expect(ExportRequest.fromJson(request.toJson()).toJson(), request.toJson());
  });
}
