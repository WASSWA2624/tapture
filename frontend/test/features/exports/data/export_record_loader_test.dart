import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/data/export_record_loader.dart';
import 'package:tapture/features/exports/domain/deliverable_repository.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_record_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';

void main() {
  late FakeRecordRepository records;
  late FakeTemplateRepository templates;
  late ExportRecordLoader loader;

  setUp(() {
    records = FakeRecordRepository();
    templates = FakeTemplateRepository();
    loader = ExportRecordLoader(records: records, templates: templates);
  });

  tearDown(() {
    records.dispose();
    templates.dispose();
  });

  test('each record exports the field shape it was captured under', () async {
    final TemplateDef first = _ok(
      await templates.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
          ],
        ),
      ),
    );
    _ok(
      await templates.save(
        first.copyWith(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial number',
              type: FieldType.text,
            ),
            FieldDef(
              fieldKey: 'colour',
              label: 'Colour',
              type: FieldType.text,
              requiredness: Requiredness.required,
            ),
          ],
        ),
      ),
    );
    records.seedEntry(aRecordEntry(id: 'old'));
    records.seedEntry(aRecordEntry(id: 'new').copyWith(templateVersion: 2));

    final PreparedDeliverable prepared = _ok(
      await loader.load(_request(), cancel: CancellationToken()),
    );

    final List<ExportRecord> rows = prepared.request.records;
    expect(rows.map((ExportRecord row) => row.id), <String>['old', 'new']);
    expect(rows.first.templateVersion, '1');
    expect(_labels(rows.first), <String>['Serial']);
    expect(rows.first.values.single.finalText, 'A-1');
    expect(rows.last.templateVersion, '2');
    expect(_labels(rows.last), <String>['Serial number', 'Colour']);
    // Only the record captured under the required field lacks it.
    expect(prepared.validation.incomplete, <String>['new']);
    expect(prepared.validation.unapproved, <String>['old', 'new']);
  });

  test(
    'a record whose version has no stored shape exports its own values and is flagged',
    () async {
      _ok(
        await templates.save(
          aTemplate(
            version: 3,
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial number',
                type: FieldType.number,
              ),
              FieldDef(
                fieldKey: 'secret',
                label: 'Secret',
                type: FieldType.text,
                hidden: true,
              ),
            ],
          ),
        ),
      );
      records.seedEntry(
        aRecordEntry(id: 'behind').copyWith(
          values: const <RecordValue>[
            RecordValue(fieldKey: 'serial', raw: 'A-1'),
            RecordValue(fieldKey: 'note', raw: 'Dented'),
            RecordValue(fieldKey: 'secret', raw: 'Kept out'),
            RecordValue(fieldKey: 'gone', raw: 'Old', retired: true),
          ],
        ),
      );
      records.seedEntry(
        aRecordEntry(
          id: 'current',
          fields: const <String, String>{'note': 'Fine'},
        ).copyWith(templateVersion: 3),
      );

      final PreparedDeliverable prepared = _ok(
        await loader.load(_request(), cancel: CancellationToken()),
      );

      final List<ExportRecord> rows = prepared.request.records;
      expect(rows.map((ExportRecord row) => row.id), <String>[
        'behind',
        'current',
      ]);
      final ExportRecord behind = rows.first;
      expect(behind.templateName, 'Test template');
      expect(behind.templateVersion, '1');
      // A retired value is retained after the live ones (§18); the hidden
      // field stays out.
      expect(behind.values.map((ExportValue value) => value.key), <String>[
        'serial',
        'note',
        'gone',
      ]);
      expect(_labels(behind), <String>['Serial number', 'note', 'gone']);
      // The stored text is never retyped to the current number field.
      expect(behind.values.map((ExportValue value) => value.type), <String>[
        'text',
        'text',
        'text',
      ]);
      expect(
        behind.values.map((ExportValue value) => value.finalText),
        <String?>['A-1', 'Dented', 'Old'],
      );
      expect(
        behind.definitions.map((Map<String, Object?> field) => field['key']),
        <String>['serial', 'note', 'gone'],
      );
      expect(behind.provenance['gone'], containsPair('retired', true));
      expect(rows.last.values.map((ExportValue value) => value.key), <String>[
        'serial',
      ]);
      expect(prepared.validation.incomplete, <String>['behind']);
    },
  );

  test(
    'a record on a deleted template still exports beside the rest',
    () async {
      _ok(
        await templates.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
              ),
            ],
          ),
        ),
      );
      _ok(
        await templates.save(
          aTemplate(
            id: 'template-2',
            name: 'Rooms',
            fields: const <FieldDef>[
              FieldDef(fieldKey: 'room', label: 'Room', type: FieldType.text),
            ],
          ),
        ),
      );
      _ok(await templates.delete('template-1', reason: 'Replaced'));
      records.seedEntry(aRecordEntry(id: 'orphan'));
      records.seedEntry(
        aRecordEntry(
          id: 'kept',
          templateId: 'template-2',
          fields: const <String, String>{'room': 'B2'},
        ),
      );

      final PreparedDeliverable prepared = _ok(
        await loader.load(_request(), cancel: CancellationToken()),
      );

      final List<ExportRecord> rows = prepared.request.records;
      expect(rows.map((ExportRecord row) => row.id), <String>[
        'orphan',
        'kept',
      ]);
      expect(rows.first.templateName, 'Removed template');
      expect(rows.first.templateId, 'template-1');
      expect(_labels(rows.first), <String>['serial']);
      expect(rows.first.values.single.finalText, 'A-1');
      expect(rows.last.templateName, 'Rooms');
      expect(_labels(rows.last), <String>['Room']);
      expect(prepared.validation.incomplete, <String>['orphan']);
    },
  );

  test('the scope decides which records load and are counted', () async {
    _ok(await templates.save(aTemplate()));
    records.seedEntry(aRecordEntry(id: 'captured'));
    records.seedEntry(
      aRecordEntry(id: 'approved', status: RecordStatus.approved),
    );

    final ExportRequest approvedOnly = _request(kind: ExportScopeKind.approved);
    expect(await loader.watchCount(approvedOnly).first, 1);
    final PreparedDeliverable prepared = _ok(
      await loader.load(approvedOnly, cancel: CancellationToken()),
    );

    expect(prepared.request.records.single.id, 'approved');
    expect(prepared.request.records.single.approved, isTrue);
    expect(prepared.validation.unapproved, isEmpty);
    expect(await loader.watchCount(_request()).first, 2);
  });

  test('a date range scope bounds the capture instant', () {
    final RecordFilter filter = ExportRecordLoader.filterFor((
      kind: ExportScopeKind.dateRange,
      context: null,
      from: '2026-09-01T00:00:00Z',
      to: '2026-09-30T23:59:59Z',
      filter: null,
    ));

    expect(filter.capturedFrom, DateTime.utc(2026, 9));
    expect(filter.capturedTo, DateTime.utc(2026, 9, 30, 23, 59, 59));
  });

  test('a cancelled load stops with a cancellation', () async {
    _ok(await templates.save(aTemplate()));
    records.seedEntry(aRecordEntry(id: 'r1'));

    final Result<PreparedDeliverable> loaded = await loader.load(
      _request(),
      cancel: CancellationToken()..cancel(),
    );

    expect(_failure(loaded), isA<CancelledFailure>());
  });

  test('a failed record read fails the load with that failure', () async {
    records.readFailure = const StorageFailure(message: 'Disk unavailable.');

    final Result<PreparedDeliverable> loaded = await loader.load(
      _request(),
      cancel: CancellationToken(),
    );

    expect(_failure(loaded).message, 'Disk unavailable.');
  });
}

ExportRequest _request({ExportScopeKind kind = ExportScopeKind.all}) {
  return ExportRequest(
    projectId: 'project-1',
    formats: const <ExportFormat>{ExportFormat.xlsx},
    scope: (kind: kind, context: null, from: null, to: null, filter: null),
    columns: (raw: false, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: true,
      photoIndex: true,
      photoMode: 'relative',
      pdfPhotos: 'thumbnail',
      delimiter: ',',
    ),
  );
}

List<String> _labels(ExportRecord record) => <String>[
  for (final ExportValue value in record.values) value.label,
];

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    Success<T>() => throw TestFailure('Expected a failure.'),
    FailureResult<T>(:final Failure failure) => failure,
  };
}
