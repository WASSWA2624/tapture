import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/import/data/record_import_store_impl.dart';
import 'package:tapture/features/import/domain/import_duplicates.dart';
import 'package:tapture/features/import/domain/record_import_store.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/captured_record_tile.dart';
import 'package:tapture/features/projects/presentation/record_edit_sheet.dart';
import 'package:tapture/features/records/data/record_queries.dart';
import 'package:tapture/features/records/domain/domain.dart';

import '../../../core/db/record_rows.dart';
import '../../records/data/record_read_seeds.dart';

void main() {
  late AppDatabase db;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 13));

  setUp(() async {
    db = AppDatabase.memory();
    await seedProjectRow(db, 'p1');
    await seedTemplateRow(
      db,
      't1',
      fields: const <String>['name', 'serial', 'condition'],
      identity: const <String>['serial'],
    );
    await seedRecord(db, 'r1');
  });
  tearDown(() => db.close());

  Future<void> reject(String key, String raw) => seedField(
    db,
    'f-$key',
    recordId: 'r1',
    fieldKey: key,
    raw: raw,
    refined: '$raw refined',
    approved: '',
  );

  test(
    'rejected parameters stay empty in names, identifiers and filters',
    () async {
      await reject('name', 'Incorrect pump');
      await reject('serial', 'BAD123');
      await reject('condition', 'Faulty');
      final RecordQueries queries = RecordQueries(db: db);
      final RecordEntry entry = (await queries.watchEntry('r1').first)!;
      expect(
        entry.values.every((RecordValue value) => !value.hasValue),
        isTrue,
      );
      expect((await searchDoc(db, 'r1'))?.name, isEmpty);
      expect((await searchDoc(db, 'r1'))?.identifier, isEmpty);
      final Result<RecordFacets> facets = await queries.facets('p1');
      expect((facets as Success<RecordFacets>).value.conditions, isEmpty);
      expect(
        await queries
            .watchCount(
              'p1',
              const RecordFilter(conditions: <String>{'Faulty'}),
            )
            .first,
        0,
      );
      expect(
        (await db.select(db.recordFields).get()).first.valueRaw,
        isNotEmpty,
      );
    },
  );

  test(
    'project rows retain rejected emptiness and absent final values',
    () async {
      await reject('name', 'Wrong name\u001e\u001f');
      await seedField(
        db,
        'f-serial',
        recordId: 'r1',
        fieldKey: 'serial',
        raw: 'SN000123',
      );
      final ProjectRepositoryImpl repository = ProjectRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final ProjectRecordRow row =
          (await repository
                  .watchRecords('p1', statuses: const <String>['captured'])
                  .first)
              .single;
      final ProjectRecordFieldValue name = row.fields.firstWhere(
        (ProjectRecordFieldValue field) => field.fieldKey == 'name',
      );
      expect(name.approved, '');
      expect(name.raw, 'Wrong name\u001e\u001f');
      expect(row.fields.last.approved, isNull);
      expect(projectRecordTitle(row), 'SN000123');
      expect(
        recordEditEntries(template: null, row: row).first.initial,
        isEmpty,
      );
      final ProjectRecordDetail? detail = await repository
          .watchRecord('r1')
          .first;
      expect(detail?.row.fields.first.approved, '');
      expect(detail?.row.fields.last.approved, isNull);
    },
  );

  test('an absent final value still falls back in record queries', () async {
    await seedField(
      db,
      'f-condition',
      recordId: 'r1',
      fieldKey: 'condition',
      raw: 'Faulty',
      refined: 'Good',
    );
    final RecordQueries queries = RecordQueries(db: db);
    final RecordEntry entry = (await queries.watchEntry('r1').first)!;
    expect(entry.valueOf('condition')?.display, 'Good');
    final Result<RecordFacets> facets = await queries.facets('p1');
    expect((facets as Success<RecordFacets>).value.conditions, <String>[
      'Good',
    ]);
    expect(
      await queries
          .watchCount('p1', const RecordFilter(conditions: <String>{'Good'}))
          .first,
      1,
    );
  });

  test(
    'an explicit import correction can fill a rejected empty parameter',
    () async {
      await reject('condition', 'Faulty');
      final RecordImportStoreImpl store = RecordImportStoreImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final Result<void> written = await store.write(
        projectId: 'p1',
        templateId: 't1',
        rows: const <ImportWrite>[
          (
            row: 1,
            match: ImportMatch.merge,
            existingId: 'r1',
            values: <String, String>{'condition': 'Good'},
          ),
        ],
        batchSize: 1,
        onBatch: (_) {},
        token: CancellationToken(),
      );
      expect(written, isA<Success<void>>());
      final RecordField stored = await db.select(db.recordFields).getSingle();
      expect(stored.valueRaw, 'Faulty');
      expect(stored.valueRefined, 'Good');
      expect(stored.valueFinal, isNull);
    },
  );
}
