import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/features/exports/domain/deliverable_repository.dart';
import 'package:tapture/features/exports/domain/export_validation.dart';

void main() {
  const ExportRequest request = ExportRequest(
    projectId: 'p1',
    formats: <ExportFormat>{ExportFormat.xlsx, ExportFormat.zip},
    scope: (
      kind: ExportScopeKind.all,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: false, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: true,
      photoIndex: true,
      photoMode: 'relative',
      delimiter: ',',
    ),
    records: <ExportRecord>[
      ExportRecord(
        id: 'ready',
        number: '1',
        templateId: 't',
        templateName: 'Asset',
        status: 'approved',
        approved: true,
      ),
      ExportRecord(
        id: 'orphan',
        number: '2',
        templateId: 'gone',
        templateName: 'Removed template',
        status: 'approved',
        approved: true,
      ),
      ExportRecord(
        id: 'draft',
        number: '3',
        templateId: 't',
        templateName: 'Asset',
        status: 'captured',
      ),
    ],
  );

  const PreparedDeliverable prepared = (
    request: request,
    validation: (incomplete: <String>['orphan'], unapproved: <String>['draft']),
  );

  test('a prepared deliverable feeds the export gate its record ids', () {
    expect(ExportValidation.isClean(prepared.validation), isFalse);

    final ExportGate excluded = ExportValidation.apply(
      request: prepared.request,
      report: prepared.validation,
      choice: ExportGateChoice.excludeThem,
    );
    expect(excluded.proceed, isTrue);
    expect(excluded.request.records.single.id, 'ready');

    final ExportGate anyway = ExportValidation.apply(
      request: prepared.request,
      report: prepared.validation,
      choice: ExportGateChoice.exportAnyway,
    );
    expect(anyway.request.markedIncomplete, isTrue);
    expect(anyway.request.records, hasLength(3));
    expect(anyway.named, containsAll(<String>['orphan', 'draft']));
  });

  test('a prepared request replays to the same records and files', () {
    final ExportRequest resolved = prepared.request.copyWith(
      files: const <ExportFile>[
        (path: 'outputs/records.xlsx', role: 'output'),
        (path: 'photos/1_front_1.jpg', role: 'photo'),
      ],
    );

    final ExportRequest replayed = ExportRequest.fromJson(resolved.toJson());

    expect(replayed.toJson(), resolved.toJson());
    expect(replayed.records.map((ExportRecord record) => record.id), <String>[
      'ready',
      'orphan',
      'draft',
    ]);
    expect(replayed.files, resolved.files);
    expect(replayed.extras.photoMode, 'relative');
  });

  test('progress and history entries compare by value', () {
    const DeliverableProgress done = (stage: 'archive', fraction: 1);
    expect(done, (stage: 'archive', fraction: 1.0));
    expect(done, isNot((stage: 'reports', fraction: 1.0)));

    final DeliverableEntry entry = _entry(missing: false);
    expect(entry, _entry(missing: false));
    expect(entry.hashCode, _entry(missing: false).hashCode);
    // A history row whose file went missing is a different row to show.
    expect(entry, isNot(_entry(missing: true)));
  });
}

DeliverableEntry _entry({required bool missing}) {
  return (
    id: 'e1',
    projectId: 'p1',
    projectName: 'Plant',
    version: 2,
    createdAt: DateTime.utc(2026, 9, 24, 8),
    operatorName: 'device-a',
    recordCount: 3,
    path: 'projects/plant/exports/2026-09-24/e1/deliverables.zip',
    fileName: 'Plant_v2.zip',
    mimeType: 'application/zip',
    sha256: 'abc',
    missing: missing,
  );
}
