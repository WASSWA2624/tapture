// The ten thousand record seed can take tens of seconds on a loaded
// machine; every test and setUpAll here gets three minutes.
@Timeout(Duration(minutes: 3))
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/data/record_queries.dart';
import 'package:tapture/features/records/data/record_search.dart';
import 'package:tapture/features/records/domain/domain.dart';

import '../../../core/db/record_rows.dart' show seedCaption;
import 'record_read_seeds.dart';

void main() {
  group('RecordSearch', () {
    test('keeps the folded words of three characters or more', () {
      final RecordSearch search = RecordSearch('  Café PUMP at  SN-4589 ');
      expect(search.words, <String>['cafe', 'pump', '4589']);
      expect(search.narrows, isTrue);
    });

    test('drops words the trigram index cannot match, digits included', () {
      expect(RecordSearch('a1 zz 07').words, isEmpty);
      expect(RecordSearch('a1 zz 07').narrows, isFalse);
      expect(RecordSearch('').narrows, isFalse);
      expect(RecordSearch.none.narrows, isFalse);
    });

    test('drops the connectives a description carries', () {
      expect(RecordSearch('the pump and the valve').words, <String>[
        'pump',
        'valve',
      ]);
    });

    test('quotes each word as a prefix phrase and ANDs them by spaces', () {
      expect(RecordSearch('pump serial').match, '"pump"* "serial"*');
      expect(RecordSearch.none.match, '');
    });

    test('binds the match expression as its only argument', () {
      final RecordSearch search = RecordSearch('grundfos pump');
      expect(search.variables, hasLength(1));
      expect(search.variables.single.value, '"grundfos"* "pump"*');
    });

    test('reaches the index through an IN subquery, never a join', () {
      final RecordSearch search = RecordSearch('pump');
      final String byRecord = search.recordCondition('r.id');
      final String byDoc = search.docCondition('sd.doc');
      expect(
        byRecord,
        'r.id IN (SELECT found.record_id FROM record_search_docs found '
        'WHERE found.doc IN (SELECT rowid FROM record_search '
        'WHERE record_search MATCH ?))',
      );
      expect(
        byDoc,
        'sd.doc IN (SELECT rowid FROM record_search '
        'WHERE record_search MATCH ?)',
      );
      for (final String sql in <String>[byRecord, byDoc]) {
        expect(sql.toUpperCase(), isNot(contains('JOIN')));
        expect('?'.allMatches(sql), hasLength(1));
      }
    });

    test('two searches for the same words are equal', () {
      expect(RecordSearch('Pump  valve'), RecordSearch('pump valve'));
      expect(RecordSearch('pump'), isNot(RecordSearch('valve')));
      expect(RecordSearch('pump').hashCode, RecordSearch('PUMP').hashCode);
      expect(RecordSearch('pump valve').toString(), 'RecordSearch(2 words)');
    });
  });

  group('search through the records list', () {
    late AppDatabase db;
    late RecordQueries queries;

    setUp(() async {
      db = AppDatabase.memory();
      queries = RecordQueries(db: db);
      await seedProjectRow(db, 'p1', folder: 'north');
      await seedTemplateRow(
        db,
        't1',
        fields: <String>['model', 'serial', 'notes'],
        identity: <String>['serial'],
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> found(String text, {String projectId = 'p1'}) async {
      final List<RecordSummary> rows = await queries
          .watchPage(
            projectId,
            filter: RecordFilter(search: text),
            sort: const RecordSort(ascending: true),
            offset: 0,
            limit: 50,
          )
          .first;
      return <String>[for (final RecordSummary row in rows) row.id];
    }

    test('finds a record by a fragment of any stage of a value', () async {
      await seedRecordRow(db, 'r1');
      await seedValue(
        db,
        'f1',
        recordId: 'r1',
        fieldKey: 'model',
        raw: 'Autoclave',
        refined: 'Steam sterilizer',
        approved: 'Tuttnauer 3870',
      );
      await seedRecordRow(db, 'r2');
      await seedValue(
        db,
        'f2',
        recordId: 'r2',
        fieldKey: 'model',
        raw: 'Hoist',
      );

      expect(await found('toclav'), <String>['r1']);
      expect(await found('sterili'), <String>['r1']);
      expect(await found('3870'), <String>['r1']);
      expect(await found('hoist'), <String>['r2']);
      expect(await found('crane'), isEmpty);
    });

    test('every word must match, in any value of the record', () async {
      await seedRecordRow(db, 'r1');
      await seedValue(db, 'f1', recordId: 'r1', fieldKey: 'model', raw: 'Pump');
      await seedValue(
        db,
        'f2',
        recordId: 'r1',
        fieldKey: 'serial',
        raw: 'SN-4589',
      );
      await seedRecordRow(db, 'r2');
      await seedValue(db, 'f3', recordId: 'r2', fieldKey: 'model', raw: 'Pump');

      expect(await found('pump 4589'), <String>['r1']);
      expect(await found('pump'), <String>['r1', 'r2']);
      expect(
        await queries
            .watchCount('p1', const RecordFilter(search: 'pump'))
            .first,
        2,
      );
    });

    test('folds case and accents on both sides', () async {
      await seedRecordRow(db, 'r1');
      await seedValue(
        db,
        'f1',
        recordId: 'r1',
        fieldKey: 'notes',
        raw: 'Café TERRACE',
      );
      expect(await found('cafe terrace'), <String>['r1']);
      expect(await found('CAFÉ'), <String>['r1']);
    });

    test(
      'finds a record by its own caption and its photos\' captions',
      () async {
        await seedRecordRow(db, 'r1');
        await seedCaption(
          db,
          'c1',
          ownerType: 'record',
          ownerId: 'r1',
          text: 'Next to the sink',
        );
        await seedRecordRow(db, 'r2');
        await seedPhotoRow(db, 'ph2', recordId: 'r2');
        await seedCaption(
          db,
          'c2',
          ownerType: 'photo',
          ownerId: 'ph2',
          text: 'Rating plate',
          refined: 'Rating plate, rusted',
        );

        expect(await found('sink'), <String>['r1']);
        expect(await found('rusted'), <String>['r2']);
      },
    );

    test(
      'finds a record by a transcript, and not by other responses',
      () async {
        await seedRecordRow(db, 'r1');
        await seedTranscript(
          db,
          'res1',
          recordId: 'r1',
          text: 'the chiller hums loudly',
        );
        await seedRecordRow(db, 'r2');
        await seedTranscript(
          db,
          'res2',
          recordId: 'r2',
          text: 'chiller proposal',
          kind: 'extraction',
        );

        expect(await found('chiller'), <String>['r1']);
        expect(await found('hums loudly'), <String>['r1']);
      },
    );

    test('finds a record by the OCR text of its live photos only', () async {
      await seedRecordRow(db, 'r1');
      await seedPhotoRow(db, 'ph1', recordId: 'r1', sha256: 'hash-1');
      await seedOcr(db, 'hash-1', 'MODEL XR-2201 SERIAL 99812');
      await seedRecordRow(db, 'r2');
      await seedPhotoRow(db, 'ph2', recordId: 'r2', sha256: 'hash-2');
      await seedOcr(db, 'hash-2', 'MODEL QZ-7713');
      await seedTomb(db, 'photos', 'ph2');

      expect(await found('xr-2201'), <String>['r1']);
      expect(await found('99812'), <String>['r1']);
      expect(await found('7713'), isEmpty);
    });

    test('a word too short to index narrows nothing', () async {
      await seedRecordRow(db, 'r1');
      await seedRecordRow(db, 'r2');
      expect(await found('zz'), <String>['r1', 'r2']);
      expect(
        await queries.watchCount('p1', const RecordFilter(search: 'a1')).first,
        2,
      );
    });

    test('a name-ordered page searches by document the same way', () async {
      await seedRecordRow(db, 'r1');
      await seedValue(db, 'f1', recordId: 'r1', fieldKey: 'model', raw: 'Pump');
      await seedRecordRow(db, 'r2');
      await seedValue(db, 'f2', recordId: 'r2', fieldKey: 'model', raw: 'Fan');
      final List<RecordSummary> rows = await queries
          .watchPage(
            'p1',
            filter: const RecordFilter(search: 'pump'),
            sort: const RecordSort(key: RecordSortKey.name, ascending: true),
            offset: 0,
            limit: 10,
          )
          .first;
      expect(rows.map((RecordSummary row) => row.id), <String>['r1']);
    });

    test('the search is confined to the project asked for', () async {
      await seedProjectRow(db, 'p2');
      await seedRecordRow(db, 'r1');
      await seedValue(db, 'f1', recordId: 'r1', fieldKey: 'model', raw: 'Pump');
      await seedRecordRow(db, 'r2', projectId: 'p2');
      await seedValue(db, 'f2', recordId: 'r2', fieldKey: 'model', raw: 'Pump');
      expect(await found('pump'), <String>['r1']);
      expect(await found('pump', projectId: 'p2'), <String>['r2']);
    });
  });

  group('index maintenance observed through the list', () {
    late AppDatabase db;
    late RecordQueries queries;
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
    final IdService ids = UuidV7Service.sequence(clock);

    setUp(() async {
      db = AppDatabase.memory();
      queries = RecordQueries(db: db);
      await seedProjectRow(db, 'p1');
      await seedTemplateRow(db, 't1', fields: <String>['model', 'serial']);
    });

    tearDown(() async {
      await db.close();
    });

    Stream<List<String>> watched(String text) {
      return queries
          .watchPage(
            'p1',
            filter: RecordFilter(search: text),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 50,
          )
          .map(
            (List<RecordSummary> rows) => <String>[
              for (final RecordSummary row in rows) row.id,
            ],
          );
    }

    Future<RecordField> insertValue(
      String recordId,
      String fieldKey,
      String text,
    ) async {
      final Result<RecordField> written = await insertRecordField(
        db,
        row: RecordFieldsCompanion.insert(
          recordId: recordId,
          fieldKey: fieldKey,
          valueRaw: Value<String>(text),
          source: 'TYPED',
          createdAt: clock.nowUtc(),
          updatedAt: clock.nowUtc(),
          updatedByDevice: 'device-a',
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      return (written as Success<RecordField>).value;
    }

    Future<void> insertRecord(String id) async {
      final Result<RecordRow> written = await upsertRecord(
        db,
        row: RecordsCompanion.insert(
          id: Value<String>(id),
          createdAt: clock.nowUtc(),
          updatedAt: clock.nowUtc(),
          updatedByDevice: 'device-a',
          projectId: 'p1',
          templateId: 't1',
          status: 'captured',
          processingMode: 'manual',
          contextJson: '{}',
          identityHash: 'hash-$id',
          source: 'capture',
          capturedAt: clock.nowUtc(),
          capturedBy: 'device-a',
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      expect(written, isA<Success<RecordRow>>());
    }

    test('a record inserted with its values is found at once', () async {
      final Future<void> listed = expectLater(
        watched('grundfos'),
        emitsThrough(<String>['r1']),
      );
      await insertRecord('r1');
      await insertValue('r1', 'model', 'Grundfos CR 10');
      await listed;
    });

    test('an edited value is found by its new text and still by its raw '
        'text', () async {
      await insertRecord('r1');
      final RecordField value = await insertValue('r1', 'model', 'Autoclave');
      expect(await watched('sterilizer').first, isEmpty);

      final Future<void> edited = expectLater(
        watched('sterilizer'),
        emitsThrough(<String>['r1']),
      );
      await writeRecordFieldRefined(
        db,
        id: value.id,
        valueRefined: 'Sterilizer',
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      await edited;
      expect(await watched('autoclave').first, <String>['r1']);
    });

    test('an operator edit is found straight after it', () async {
      await insertRecord('r1');
      final RecordField value = await insertValue('r1', 'serial', 'SN-100');
      final Future<void> edited = expectLater(
        watched('sn-200'),
        emitsThrough(<String>['r1']),
      );
      await writeRecordFieldEdit(db, id: value.id, value: 'SN-200');
      await edited;
    });

    test('a deleted value is no longer found', () async {
      await insertRecord('r1');
      final RecordField value = await insertValue('r1', 'model', 'Centrifuge');
      expect(await watched('centrifuge').first, <String>['r1']);

      final Future<void> removed = expectLater(
        watched('centrifuge'),
        emitsThrough(isEmpty),
      );
      await softDeleteRecordField(
        db,
        id: value.id,
        reason: 'Wrong field',
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      await removed;
    });

    test('a caption written later is found', () async {
      await insertRecord('r1');
      final Future<void> captioned = expectLater(
        watched('leaking'),
        emitsThrough(<String>['r1']),
      );
      await insertCaption(
        db,
        row: CaptionsCompanion.insert(
          ownerType: CaptionOwnerType.record,
          ownerId: 'r1',
          textRaw: 'Leaking at the flange',
          inputMode: CaptionInputMode.typed,
          createdAt: clock.nowUtc(),
          updatedAt: clock.nowUtc(),
          updatedByDevice: 'device-a',
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      await captioned;
    });

    test('a deleted record leaves the list and a restore brings it back to '
        'the search', () async {
      await insertRecord('r1');
      await insertValue('r1', 'model', 'Compressor');
      expect(await watched('compressor').first, <String>['r1']);

      final Future<void> hidden = expectLater(
        watched('compressor'),
        emitsThrough(isEmpty),
      );
      await db.transaction(() async {
        await writeRecordStatus(
          db,
          recordId: 'r1',
          status: 'deleted',
          previousStatus: 'captured',
          clock: clock,
          deviceId: 'device-a',
        );
        await writeTombstone(
          db,
          entityType: 'records',
          entityId: 'r1',
          reason: 'Duplicate',
          clock: clock,
          deviceId: 'device-a',
        );
      });
      await hidden;

      final Future<void> back = expectLater(
        watched('compressor'),
        emitsThrough(<String>['r1']),
      );
      await db.transaction(() async {
        await removeTombstone(db, entityType: 'records', entityId: 'r1');
        await writeRecordStatus(
          db,
          recordId: 'r1',
          status: 'captured',
          previousStatus: 'deleted',
          clock: clock,
          deviceId: 'device-a',
        );
      });
      await back;
    });
  });

  // FE-PERF-01 (search answers in under 300 ms), FE-PERF-06 (budgets are
  // measured against a realistically seeded database) and FE-TEST-09
  // (the budget is asserted, not assumed): ten thousand records with five
  // values each, captions on a third, photos on half and OCR text on a
  // quarter, seeded in one deferred-indexing transaction (task 014 DoD
  // "a search over ten thousand records returns in under 300 milliseconds").
  group('ten thousand records', () {
    late AppDatabase db;
    late RecordQueries queries;
    const int records = 10000;
    const int budgetMs = 300;

    setUpAll(() async {
      db = AppDatabase.memory();
      queries = RecordQueries(db: db);
      await seedProjectRow(db, 'p1', folder: 'hospital');
      await seedTemplateRow(
        db,
        't1',
        name: 'Assets',
        fields: <String>['name', 'serial', 'location', 'condition', 'notes'],
        identity: <String>['serial'],
      );
      await RecordSchema.deferIndexing(db, () => _seedTenThousand(db));
    });

    tearDownAll(() async {
      await db.close();
    });

    /// The median of three timed runs of [run], after one untimed warm-up.
    Future<int> medianMs(Future<void> Function(int run) run) async {
      await run(-1);
      final List<int> runs = <int>[];
      for (int index = 0; index < 3; index++) {
        final Stopwatch watch = Stopwatch()..start();
        await run(index);
        watch.stop();
        runs.add(watch.elapsedMilliseconds);
      }
      runs.sort();
      printOnFailure('runs in ms: $runs');
      return runs[1];
    }

    test('the seed holds ten thousand indexed records', () async {
      final QueryRow row = await db
          .customSelect(
            'SELECT (SELECT COUNT(*) FROM records) AS records, '
            '(SELECT COUNT(*) FROM record_fields) AS fields, '
            '(SELECT COUNT(*) FROM record_search_docs) AS docs, '
            '(SELECT COUNT(*) FROM record_search) AS indexed, '
            '(SELECT COUNT(*) FROM record_search_pending) AS pending',
          )
          .getSingle();
      expect(row.read<int>('records'), records);
      expect(row.read<int>('fields'), records * 5);
      expect(row.read<int>('docs'), records);
      expect(row.read<int>('indexed'), records);
      expect(row.read<int>('pending'), 0);
    });

    test(
      'a search answers its first page and its count in under 300 ms',
      () async {
        // Serial SN<n> sits on record n - 1000; every one of these is listed
        // by default (none is archived). A different serial per run keeps
        // each run a fresh query.
        const List<int> serials = <int>[3001, 4589, 7312, 2204];
        String serialOf(int run) => 'SN${serials[run + 1]}';

        final int pageMs = await medianMs((int run) async {
          final List<RecordSummary> rows = await queries
              .watchPage(
                'p1',
                filter: RecordFilter(search: serialOf(run)),
                sort: RecordSort.newestFirst,
                offset: 0,
                limit: 50,
              )
              .first;
          expect(rows, hasLength(1));
          expect(rows.single.identifier, serialOf(run));
        });
        final int countMs = await medianMs((int run) async {
          expect(
            await queries
                .watchCount('p1', RecordFilter(search: serialOf(run)))
                .first,
            1,
          );
        });

        expect(pageMs, lessThan(budgetMs), reason: 'search page');
        expect(countMs, lessThan(budgetMs), reason: 'search count');
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'a broad search ordered by name answers in under 300 ms',
      () async {
        final int pageMs = await medianMs((int run) async {
          final List<RecordSummary> rows = await queries
              .watchPage(
                'p1',
                filter: const RecordFilter(search: 'pump'),
                sort: const RecordSort(key: RecordSortKey.name),
                offset: 0,
                limit: 50 + run + 1,
              )
              .first;
          expect(rows, hasLength(50 + run + 1));
        });
        expect(pageMs, lessThan(budgetMs));
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    for (final RecordSortKey key in RecordSortKey.values) {
      for (final bool ascending in <bool>[true, false]) {
        test(
          'a first page ordered by ${key.stored} '
          '${ascending ? 'ascending' : 'descending'} answers in under 300 ms',
          () async {
            // A different page size per run keeps each run a fresh query.
            final int pageMs = await medianMs((int run) async {
              final List<RecordSummary> rows = await queries
                  .watchPage(
                    'p1',
                    filter: RecordFilter.none,
                    sort: RecordSort(key: key, ascending: ascending),
                    offset: 0,
                    limit: 50 + run + 1,
                  )
                  .first;
              expect(rows, hasLength(50 + run + 1));
            });
            final int countMs = await medianMs((int run) async {
              await queries
                  .watchCount(
                    'p1',
                    RecordFilter(
                      statuses: <RecordStatus>{
                        RecordStatus.captured,
                        RecordStatus.values[run + 2],
                      },
                    ),
                  )
                  .first;
            });
            expect(pageMs, lessThan(budgetMs), reason: 'page');
            expect(countMs, lessThan(budgetMs), reason: 'count');
          },
          timeout: const Timeout(Duration(minutes: 3)),
        );
      }
    }

    test(
      'a page deep in the list and a filtered page answer in under 300 ms',
      () async {
        final int deepMs = await medianMs((int run) async {
          final List<RecordSummary> rows = await queries
              .watchPage(
                'p1',
                filter: RecordFilter.none,
                sort: RecordSort.newestFirst,
                offset: 8900 + run,
                limit: 50,
              )
              .first;
          expect(rows, hasLength(50));
        });
        final int filteredMs = await medianMs((int run) async {
          final List<RecordSummary> rows = await queries
              .watchPage(
                'p1',
                filter: const RecordFilter(
                  context: <String, Set<String>>{
                    'site': <String>{'North', 'East'},
                  },
                  operators: <String>{'device-a'},
                  conditions: <String>{'good'},
                  flags: <RecordFlag>{RecordFlag.hasPhotos},
                ),
                sort: const RecordSort(key: RecordSortKey.capturedAt),
                offset: 0,
                limit: 50 + run + 1,
              )
              .first;
          expect(rows, isNotEmpty);
        });
        expect(deepMs, lessThan(budgetMs), reason: 'deep page');
        expect(filteredMs, lessThan(budgetMs), reason: 'filtered page');
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Ten thousand records `r00001`… in project p1: status mostly captured
/// (every tenth archived, some under review or approved), two operators,
/// a site and room context, five values (name, serial `SN<1000 + n>`,
/// location, condition, notes), a caption on every third, a photo on every
/// second and OCR text on every fourth.
Future<void> _seedTenThousand(AppDatabase db) async {
  const String numbers =
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < 10000) ';
  const String merge = "1, 1, 'device-a', 1";
  await db.customStatement(
    '${numbers}INSERT INTO records (id, created_at, updated_at, '
    'updated_by_device, rev, project_id, template_id, status, '
    'processing_mode, context_json, identity_hash, source, captured_at, '
    "captured_by) SELECT printf('r%05d', i), $merge, 'p1', 't1', "
    "CASE i % 10 WHEN 0 THEN 'archived' WHEN 1 THEN 'needsReview' "
    "WHEN 2 THEN 'approved' ELSE 'captured' END, 'manual', "
    "json_object('site', CASE i % 4 WHEN 0 THEN 'North' WHEN 1 THEN 'East' "
    "WHEN 2 THEN 'South' ELSE 'West' END, 'room', printf('Room %d', i % 40)), "
    "printf('hash-%d', i), 'capture', 1788000000 + i * 37, "
    "CASE i % 3 WHEN 0 THEN 'device-b' ELSE 'device-a' END FROM n",
  );
  final Map<String, String> values = <String, String>{
    'name':
        "CASE i % 8 WHEN 0 THEN 'Centrifugal pump' WHEN 1 THEN 'Autoclave' "
        "WHEN 2 THEN 'Air handling unit' WHEN 3 THEN 'Fire extinguisher' "
        "WHEN 4 THEN 'Distribution board' WHEN 5 THEN 'Chiller' "
        "WHEN 6 THEN 'Booster pump' ELSE 'Standby generator' END",
    'serial': "printf('SN%d', 1000 + i)",
    'location':
        "printf('Block %s, floor %d, room %d', char(65 + i % 6), i % 5, "
        'i % 40)',
    'condition':
        "CASE i % 5 WHEN 0 THEN 'poor' WHEN 1 THEN 'fair' ELSE 'good' END",
    'notes':
        "printf('Inspected on round %d; label %s', i % 12, "
        "CASE i % 2 WHEN 0 THEN 'faded' ELSE 'legible' END)",
  };
  for (final MapEntry<String, String> value in values.entries) {
    await db.customStatement(
      '${numbers}INSERT INTO record_fields (id, created_at, updated_at, '
      'updated_by_device, rev, record_id, field_key, value_raw, source, '
      "verified) SELECT printf('f%05d-${value.key}', i), $merge, "
      "printf('r%05d', i), '${value.key}', ${value.value}, 'ocr', 0 FROM n",
    );
  }
  await db.customStatement(
    '${numbers}INSERT INTO captions (id, created_at, updated_at, '
    'updated_by_device, rev, owner_type, owner_id, text_raw, input_mode) '
    "SELECT printf('c%05d', i), $merge, 'record', printf('r%05d', i), "
    "'Mounted beside the east wall, isolator within reach', 'typed' "
    'FROM n WHERE i % 3 = 0',
  );
  await db.customStatement(
    '${numbers}INSERT INTO photos (id, created_at, updated_at, '
    'updated_by_device, rev, project_id, record_id, capture_session_id, '
    'original_filename, stored_filename, relative_path, photo_type, '
    'sort_order, width, height, file_size, mime_type, sha256, captured_at) '
    "SELECT printf('ph%05d', i), $merge, 'p1', printf('r%05d', i), "
    "'session-1', 'photo.jpg', printf('ph%05d.jpg', i), "
    "printf('photos/ph%05d.jpg', i), 'front', 0, 4000, 3000, 2400000, "
    "'image/jpeg', printf('sha%05d', i), 1788000000 + i * 37 "
    'FROM n WHERE i % 2 = 0',
  );
  await db.customStatement(
    '${numbers}INSERT INTO ocr_cache (id, created_at, updated_at, '
    'updated_by_device, rev, content_hash, perceptual_hash, '
    "recognised_text, blocks_json) SELECT printf('o%05d', i), $merge, "
    "printf('sha%05d', i), printf('p%05d', i), "
    "printf('MODEL XR-%d SERIAL SN%d 230V 50HZ', i % 97, 1000 + i), '[]' "
    'FROM n WHERE i % 4 = 0',
  );
}
