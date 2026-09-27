import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/validation/severity.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/features/exports/domain/export_validation.dart';

void main() {
  const ExportRequest request = ExportRequest(
    projectId: 'p1',
    formats: <ExportFormat>{ExportFormat.xlsx},
    scope: (
      kind: ExportScopeKind.approved,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: false, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: false,
      photoIndex: true,
      photoMode: 'filename',
      delimiter: ',',
    ),
    records: <ExportRecord>[
      ExportRecord(
        id: 'ok',
        number: '1',
        templateId: 't',
        templateName: 'Asset',
        status: 'approved',
        approved: true,
      ),
      ExportRecord(
        id: 'draft',
        number: '2',
        templateId: 't',
        templateName: 'Asset',
        status: 'draft',
      ),
    ],
  );

  ExportValidationReport report() {
    return ExportValidation.assess(
      issues: const <ValidationIssue>[
        ValidationIssue('serial', Severity.error, 'Missing'),
      ],
      records: request.records,
    );
  }

  test('a clean set has nothing to gate', () {
    final ExportValidationReport clean = ExportValidation.assess(
      issues: const <ValidationIssue>[],
      records: <ExportRecord>[request.records.first],
    );
    expect(ExportValidation.isClean(clean), isTrue);
  });

  test('fix now does not export and names the records', () {
    final ExportGate gate = ExportValidation.apply(
      request: request,
      report: report(),
      choice: ExportGateChoice.fixNow,
    );
    expect(gate.proceed, isFalse);
    expect(gate.named, contains('serial'));
    expect(gate.named, contains('draft'));
  });

  test('exclude them drops the named records', () {
    final ExportGate gate = ExportValidation.apply(
      request: request,
      report: report(),
      choice: ExportGateChoice.excludeThem,
    );
    expect(gate.proceed, isTrue);
    expect(gate.request.records.single.id, 'ok');
    expect(gate.request.markedIncomplete, isFalse);
  });

  test('export anyway marks the request incomplete', () {
    final ExportGate gate = ExportValidation.apply(
      request: request,
      report: report(),
      choice: ExportGateChoice.exportAnyway,
    );
    expect(gate.proceed, isTrue);
    expect(gate.request.markedIncomplete, isTrue);
    expect(gate.request.records, hasLength(2));
  });
}
