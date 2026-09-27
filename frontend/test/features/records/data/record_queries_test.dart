import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/data/record_queries.dart';
import 'package:tapture/features/records/domain/domain.dart';

import '../../../core/db/record_rows.dart' show seedCaption;
import '../fakes/record_results.dart';
import 'record_read_seeds.dart';

void main() {
  late AppDatabase db;
  late RecordQueries queries;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 20, 8));
  final IdService ids = UuidV7Service.sequence(clock);

  setUp(() async {
    db = AppDatabase.memory();
    queries = RecordQueries(db: db);
    await seedProjectRow(db, 'p1', name: 'Hospital', folder: 'north');
    await seedProjectRow(db, 'p2', name: 'Depot', folder: 'depot');
    await seedTemplateRow(
      db,
      't1',
      name: 'Assets',
      fields: <String>['model', 'serial', 'condition'],
      identity: <String>['serial'],
    );
    await seedTemplateRow(
      db,
      't2',
      name: 'Rooms',
      fields: <String>['model', 'location'],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<String>> page({
    String projectId = 'p1',
    RecordFilter filter = RecordFilter.none,
    RecordSort sort = const RecordSort(ascending: true),
    int offset = 0,
    int limit = 100,
  }) async {
    final List<RecordSummary> rows = await queries
        .watchPage(
          projectId,
          filter: filter,
          sort: sort,
          offset: offset,
          limit: limit,
        )
        .first;
    return <String>[for (final RecordSummary row in rows) row.id];
  }

  Future<int> count([
    RecordFilter filter = RecordFilter.none,
    String projectId = 'p1',
  ]) {
    return queries.watchCount(projectId, filter).first;
  }

  Future<RecordSummary> rowOf(String id) async {
    final List<RecordSummary> rows = await queries
        .watchPage(
          'p1',
          filter: const RecordFilter(
            statuses: <RecordStatus>{
              RecordStatus.draft,
              RecordStatus.captured,
              RecordStatus.needsReview,
              RecordStatus.approved,
              RecordStatus.archived,
            },
          ),
          sort: const RecordSort(ascending: true),
          offset: 0,
          limit: 100,
        )
        .first;
    return rows.singleWhere((RecordSummary row) => row.id == id);
  }

  group('one record', () {
    test('a missing record reads as null, not a failure', () async {
      expect(okOf(await queries.byId('missing')), isNull);
      expect(await queries.watchEntry('missing').first, isNull);
    });

    test('a deleted record is still read, and its status says so', () async {
      await seedRecordRow(db, 'r1', status: 'deleted');
      await seedTomb(db, 'records', 'r1');
      expect(okOf(await queries.byId('r1'))?.status, RecordStatus.deleted);
      expect(
        (await queries.watchEntry('r1').first)?.status,
        RecordStatus.deleted,
      );
    });

    test('the watched record emits again after its status moves', () async {
      await seedRecordRow(db, 'r1');
      final Future<void> moved = expectLater(
        queries.watchEntry('r1').map((RecordEntry? entry) => entry?.status),
        emitsThrough(RecordStatus.needsReview),
      );
      await writeRecordStatus(
        db,
        recordId: 'r1',
        status: 'needsReview',
        previousStatus: 'captured',
        clock: clock,
        deviceId: 'device-a',
      );
      await moved;
    });

    test('the watched record emits again after a value is refined', () async {
      await seedRecordRow(db, 'r1');
      await seedValue(db, 'f1', recordId: 'r1', fieldKey: 'model', raw: 'A1');
      final Future<void> refined = expectLater(
        queries
            .watchEntry('r1')
            .map((RecordEntry? entry) => entry?.valueOf('model')?.display),
        emitsThrough('A2'),
      );
      await writeRecordFieldRefined(
        db,
        id: 'f1',
        valueRefined: 'A2',
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      await refined;
    });

    test('a photo replaced by a live edit shows the edit until the edit is '
        'removed', () async {
      await seedRecordRow(db, 'r1');
      await seedPhotoRow(db, 'original', recordId: 'r1');
      await seedPhotoRow(db, 'edit', recordId: 'r1', derivedFrom: 'original');
      List<String> photos(RecordEntry? entry) => <String>[
        for (final RecordPhoto photo in entry!.photos) photo.id,
      ];
      expect(photos(okOf(await queries.byId('r1'))), <String>['edit']);
      await seedTomb(db, 'photos', 'edit');
      expect(photos(okOf(await queries.byId('r1'))), <String>['original']);
    });

    test('a database that cannot be read gives a storage failure', () async {
      final AppDatabase closed = AppDatabase.memory();
      final RecordQueries broken = RecordQueries(db: closed);
      await closed.customStatement('DROP TABLE records');
      expect(failureOf(await broken.byId('r1')), isA<StorageFailure>());
      await expectLater(
        broken.watchEntry('r1'),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(
        broken.watchPage(
          'p1',
          filter: RecordFilter.none,
          sort: RecordSort.newestFirst,
          offset: 0,
          limit: 10,
        ),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(
        broken.watchCount('p1', RecordFilter.none),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(broken.watchBin(), emitsError(isA<StorageFailure>()));
      expect(failureOf(await broken.facets('p1')), isA<StorageFailure>());
      await closed.close();
    });
  });

  group('each filter alone', () {
    test('no status lists every status but archived and deleted', () async {
      for (final RecordStatus status in RecordStatus.values) {
        await seedRecordRow(db, status.stored, status: status.stored);
      }
      await seedTomb(db, 'records', 'deleted');
      expect((await page()).toSet(), <String>{
        for (final RecordStatus status in RecordStatus.values)
          if (status != RecordStatus.archived && status != RecordStatus.deleted)
            status.stored,
      });
      expect(await count(), RecordStatus.values.length - 2);
    });

    test('chosen statuses list only those; archived only when asked; '
        'deleted never', () async {
      for (final RecordStatus status in RecordStatus.values) {
        await seedRecordRow(db, status.stored, status: status.stored);
      }
      await seedTomb(db, 'records', 'deleted');
      const RecordFilter chosen = RecordFilter(
        statuses: <RecordStatus>{RecordStatus.captured, RecordStatus.approved},
      );
      expect((await page(filter: chosen)).toSet(), <String>{
        'captured',
        'approved',
      });
      final RecordFilter archived = RecordFilter.forStatus(
        RecordStatus.archived,
      );
      expect(await page(filter: archived), <String>['archived']);
      expect(await count(archived), 1);
      final RecordFilter deleted = RecordFilter.forStatus(RecordStatus.deleted);
      expect(await page(filter: deleted), isEmpty);
      expect(await count(deleted), 0);
    });

    test(
      'a legacy status spelling is listed under its canonical name',
      () async {
        await seedRecordRow(db, 'r1', status: 'NEEDS_REVIEW');
        expect(
          await page(filter: RecordFilter.forStatus(RecordStatus.needsReview)),
          <String>['r1'],
        );
      },
    );

    test('a record removed with its project is never listed', () async {
      await seedRecordRow(db, 'r1');
      await seedRecordRow(db, 'r2');
      await seedTomb(
        db,
        'records',
        'r2',
        reason: RecordQueries.projectDeletedReason,
      );
      expect(await page(), <String>['r1']);
      expect(await count(), 1);
    });

    test('another project\'s records are never listed', () async {
      await seedRecordRow(db, 'r1');
      await seedRecordRow(db, 'r2', projectId: 'p2');
      expect(await page(), <String>['r1']);
      expect(await page(projectId: 'p2'), <String>['r2']);
      expect(await count(RecordFilter.none, 'p2'), 1);
    });

    test('templates match any chosen template', () async {
      await seedRecordRow(db, 'r1');
      await seedRecordRow(db, 'r2', templateId: 't2');
      await seedRecordRow(db, 'r3', templateId: 't3');
      expect(
        await page(filter: const RecordFilter(templateIds: <String>{'t2'})),
        <String>['r2'],
      );
      expect(
        await page(
          filter: const RecordFilter(templateIds: <String>{'t1', 't3'}),
        ),
        <String>['r1', 'r3'],
      );
    });

    test('context matches the snapshot value at each chosen level', () async {
      await seedRecordRow(
        db,
        'north-1',
        context: <String, String>{'site': 'North', 'room': 'R1'},
      );
      await seedRecordRow(
        db,
        'north-2',
        context: <String, String>{'site': 'North', 'room': 'R2'},
      );
      await seedRecordRow(
        db,
        'east',
        context: <String, String>{'site': 'East', 'room': 'R1'},
      );
      await seedRecordRow(db, 'none');
      await seedRecordRow(db, 'broken', context: '{not json');
      expect(
        await page(
          filter: const RecordFilter(
            context: <String, Set<String>>{
              'site': <String>{'North'},
            },
          ),
        ),
        <String>['north-1', 'north-2'],
      );
      expect(
        await page(
          filter: const RecordFilter(
            context: <String, Set<String>>{
              'site': <String>{'North', 'East'},
            },
          ),
        ),
        <String>['north-1', 'north-2', 'east'],
      );
      expect(
        await page(
          filter: const RecordFilter(
            context: <String, Set<String>>{
              'site': <String>{'North'},
              'room': <String>{'R1'},
            },
          ),
        ),
        <String>['north-1'],
      );
    });

    test('context also matches the context writer\'s snapshot shape and any '
        'key spelling', () async {
      await seedRecordRow(
        db,
        'nested',
        context: <String, Object?>{
          'levels': <Object?>[
            <String, Object?>{'fieldKey': 'site', 'order': 0},
          ],
          'values': <String, String>{'site': 'North'},
          'pinned': <String, String>{'inspector': 'Ada'},
        },
      );
      await seedRecordRow(
        db,
        'quoted',
        context: <String, String>{'block "A"': 'yes'},
      );
      expect(
        await page(
          filter: const RecordFilter(
            context: <String, Set<String>>{
              'site': <String>{'North'},
              'inspector': <String>{'Ada'},
            },
          ),
        ),
        <String>['nested'],
      );
      expect(
        await page(
          filter: const RecordFilter(
            context: <String, Set<String>>{
              'block "A"': <String>{'yes'},
            },
          ),
        ),
        <String>['quoted'],
      );
    });

    test(
      'the capture range is inclusive at both ends, to the second',
      () async {
        final DateTime first = DateTime.utc(2026, 9, 1, 10);
        final DateTime second = DateTime.utc(2026, 9, 2, 10);
        final DateTime third = DateTime.utc(2026, 9, 3, 10);
        await seedRecordRow(db, 'first', capturedAt: first);
        await seedRecordRow(db, 'second', capturedAt: second);
        await seedRecordRow(db, 'third', capturedAt: third);
        expect(await page(filter: RecordFilter(capturedFrom: second)), <String>[
          'second',
          'third',
        ]);
        expect(await page(filter: RecordFilter(capturedTo: second)), <String>[
          'first',
          'second',
        ]);
        expect(
          await page(
            filter: RecordFilter(capturedFrom: second, capturedTo: second),
          ),
          <String>['second'],
        );
        expect(
          await page(
            filter: RecordFilter(
              capturedFrom: second.add(const Duration(milliseconds: 500)),
            ),
          ),
          <String>['third'],
        );
        expect(
          await page(
            filter: RecordFilter(
              capturedTo: second.subtract(const Duration(milliseconds: 500)),
            ),
          ),
          <String>['first'],
        );
        expect(
          await page(filter: RecordFilter(capturedFrom: second.toLocal())),
          <String>['second', 'third'],
        );
      },
    );

    test('operators match who captured the record', () async {
      await seedRecordRow(db, 'r1', capturedBy: 'device-a');
      await seedRecordRow(db, 'r2', capturedBy: 'device-b');
      await seedRecordRow(db, 'r3', capturedBy: 'device-c');
      expect(
        await page(
          filter: const RecordFilter(
            operators: <String>{'device-b', 'device-c'},
          ),
        ),
        <String>['r2', 'r3'],
      );
    });

    test('conditions match what the live condition fields display', () async {
      await seedRecordRow(db, 'good');
      await seedValue(
        db,
        'f1',
        recordId: 'good',
        fieldKey: 'condition',
        raw: 'good',
      );
      await seedRecordRow(db, 'graded');
      await seedValue(
        db,
        'f2',
        recordId: 'graded',
        fieldKey: 'condition_grade',
        raw: 'good',
        approved: 'poor',
      );
      await seedRecordRow(db, 'retired');
      await seedValue(
        db,
        'f3',
        recordId: 'retired',
        fieldKey: 'condition',
        raw: 'poor',
        retiredAt: DateTime.utc(2026, 9),
      );
      await seedRecordRow(db, 'removed');
      await seedValue(
        db,
        'f4',
        recordId: 'removed',
        fieldKey: 'condition',
        raw: 'poor',
      );
      await seedTomb(db, 'record_fields', 'f4');
      await seedRecordRow(db, 'other-key');
      await seedValue(
        db,
        'f5',
        recordId: 'other-key',
        fieldKey: 'notes',
        raw: 'poor',
      );
      expect(
        await page(filter: const RecordFilter(conditions: <String>{'poor'})),
        <String>['graded'],
      );
      expect(
        await page(
          filter: const RecordFilter(conditions: <String>{'good', 'poor'}),
        ),
        <String>['good', 'graded'],
      );
    });

    test('the photos flag needs a live photo', () async {
      await seedRecordRow(db, 'with');
      await seedPhotoRow(db, 'ph1', recordId: 'with');
      await seedRecordRow(db, 'removed');
      await seedPhotoRow(db, 'ph2', recordId: 'removed');
      await seedTomb(db, 'photos', 'ph2');
      await seedRecordRow(db, 'without');
      expect(
        await page(
          filter: const RecordFilter(flags: <RecordFlag>{RecordFlag.hasPhotos}),
        ),
        <String>['with'],
      );
    });

    test(
      'the duplicate flag needs an unresolved, live pair on either side',
      () async {
        for (final String id in <String>[
          'left',
          'right',
          'resolved',
          'removed',
          'plain',
        ]) {
          await seedRecordRow(db, id);
        }
        await seedDuplicate(db, 'd1', left: 'left', right: 'right');
        await seedDuplicate(
          db,
          'd2',
          left: 'resolved',
          right: 'plain',
          status: 'resolved',
        );
        await seedDuplicate(db, 'd3', left: 'removed', right: 'plain');
        await seedTomb(db, 'duplicates', 'd3');
        expect(
          await page(
            filter: const RecordFilter(
              flags: <RecordFlag>{RecordFlag.hasDuplicate},
            ),
          ),
          <String>['left', 'right'],
        );
      },
    );

    test('the conflict flag needs an unresolved conflict on the record, its '
        'values or its photos', () async {
      for (final String id in <String>[
        'on-record',
        'on-value',
        'on-photo',
        'resolved',
        'plain',
      ]) {
        await seedRecordRow(db, id);
      }
      await seedValue(db, 'fv', recordId: 'on-value', fieldKey: 'serial');
      await seedPhotoRow(db, 'pv', recordId: 'on-photo');
      await seedConflict(
        db,
        'c1',
        entityType: 'records',
        entityId: 'on-record',
      );
      await seedConflict(db, 'c2', entityType: 'record_fields', entityId: 'fv');
      await seedConflict(db, 'c3', entityType: 'photos', entityId: 'pv');
      await seedConflict(
        db,
        'c4',
        entityType: 'records',
        entityId: 'resolved',
        resolution: 'mine',
      );
      expect(
        await page(
          filter: const RecordFilter(
            flags: <RecordFlag>{RecordFlag.hasConflict},
          ),
        ),
        <String>['on-record', 'on-value', 'on-photo'],
      );
    });

    test('the variance flag needs an unresolved variance', () async {
      await seedRecordRow(db, 'open');
      await seedRecordRow(db, 'resolved');
      await seedVariance(db, 'v1', recordId: 'open');
      await seedVariance(
        db,
        'v2',
        recordId: 'resolved',
        resolvedAt: DateTime.utc(2026, 9, 2),
      );
      expect(
        await page(
          filter: const RecordFilter(
            flags: <RecordFlag>{RecordFlag.hasVariance},
          ),
        ),
        <String>['open'],
      );
    });

    test(
      'the evidence flag needs a live value whose evidence is gone',
      () async {
        await seedRecordRow(db, 'flagged');
        await seedValue(
          db,
          'f1',
          recordId: 'flagged',
          fieldKey: 'serial',
          evidenceRemovedAt: DateTime.utc(2026, 9, 2),
        );
        await seedRecordRow(db, 'removed');
        await seedValue(
          db,
          'f2',
          recordId: 'removed',
          fieldKey: 'serial',
          evidenceRemovedAt: DateTime.utc(2026, 9, 2),
        );
        await seedTomb(db, 'record_fields', 'f2');
        await seedRecordRow(db, 'plain');
        expect(
          await page(
            filter: const RecordFilter(
              flags: <RecordFlag>{RecordFlag.evidenceRemoved},
            ),
          ),
          <String>['flagged'],
        );
      },
    );

    test('the merged flag needs a merge history line, not a value keyed '
        'merge', () async {
      await seedRecordRow(db, 'inserted');
      await seedAudit(
        db,
        'a1',
        entityId: 'inserted',
        at: DateTime.utc(2026, 9, 2),
        action: 'created',
        fieldKey: 'merge',
        next: 'inserted',
      );
      await seedRecordRow(db, 'updated');
      await seedAudit(
        db,
        'a2',
        entityId: 'updated',
        at: DateTime.utc(2026, 9, 2),
        fieldKey: 'merge',
        next: 'updated',
      );
      await seedRecordRow(db, 'value');
      await seedAudit(
        db,
        'a3',
        entityId: 'value',
        at: DateTime.utc(2026, 9, 2),
        fieldKey: 'merge',
        next: 'no',
      );
      expect(
        await page(
          filter: const RecordFilter(
            flags: <RecordFlag>{RecordFlag.mergedFromBundle},
          ),
        ),
        <String>['inserted', 'updated'],
      );
    });

    test('several flags must all hold', () async {
      await seedRecordRow(db, 'both');
      await seedPhotoRow(db, 'ph1', recordId: 'both');
      await seedVariance(db, 'v1', recordId: 'both');
      await seedRecordRow(db, 'photo-only');
      await seedPhotoRow(db, 'ph2', recordId: 'photo-only');
      const RecordFilter both = RecordFilter(
        flags: <RecordFlag>{RecordFlag.hasPhotos, RecordFlag.hasVariance},
      );
      expect(await page(filter: both), <String>['both']);
      expect(await count(both), 1);
    });
  });

  test('every dimension combines with AND', () async {
    Future<void> candidate(
      String id, {
      String templateId = 't1',
      String status = 'captured',
      String site = 'North',
      String capturedBy = 'device-a',
      DateTime? capturedAt,
      String condition = 'good',
      bool photo = true,
      String model = 'Pump',
    }) async {
      await seedRecordRow(
        db,
        id,
        templateId: templateId,
        status: status,
        context: <String, String>{'site': site},
        capturedBy: capturedBy,
        capturedAt: capturedAt ?? DateTime.utc(2026, 9, 5),
      );
      await seedValue(
        db,
        'model-$id',
        recordId: id,
        fieldKey: 'model',
        raw: model,
      );
      await seedValue(
        db,
        'condition-$id',
        recordId: id,
        fieldKey: 'condition',
        raw: condition,
      );
      if (photo) {
        await seedPhotoRow(db, 'photo-$id', recordId: id);
      }
    }

    await candidate('match');
    await candidate('other-template', templateId: 't2');
    await candidate('other-status', status: 'approved');
    await candidate('other-site', site: 'East');
    await candidate('other-operator', capturedBy: 'device-b');
    await candidate('too-early', capturedAt: DateTime.utc(2026, 8, 1));
    await candidate('other-condition', condition: 'poor');
    await candidate('no-photo', photo: false);
    await candidate('other-model', model: 'Fan');
    final RecordFilter all = RecordFilter(
      statuses: const <RecordStatus>{RecordStatus.captured},
      templateIds: const <String>{'t1'},
      context: const <String, Set<String>>{
        'site': <String>{'North'},
      },
      capturedFrom: DateTime.utc(2026, 9),
      capturedTo: DateTime.utc(2026, 9, 30),
      operators: const <String>{'device-a'},
      conditions: const <String>{'good'},
      flags: const <RecordFlag>{RecordFlag.hasPhotos},
      search: 'pump',
    );
    expect(await page(filter: all), <String>['match']);
    expect(await count(all), 1);
    expect(await count(all.withoutCriteria()), 8);
    expect(await count(all.withoutSearch()), 2);
  });

  group('ordering and paging', () {
    test('number, capture date and name each sort both ways, ties broken by '
        'id in the same direction', () async {
      final DateTime early = DateTime.utc(2026, 9, 1);
      final DateTime late = DateTime.utc(2026, 9, 2);
      Future<void> named(
        String id, {
        required int number,
        required DateTime at,
        required String model,
      }) async {
        await seedRecordRow(db, id, number: number, capturedAt: at);
        await seedValue(
          db,
          'model-$id',
          recordId: id,
          fieldKey: 'model',
          raw: model,
        );
      }

      await named('c', number: 2, at: late, model: 'alpha');
      await named('a', number: 2, at: early, model: 'Charlie');
      await named('b', number: 1, at: late, model: 'Alpha');
      await named('d', number: 3, at: early, model: 'bravo');
      final Map<RecordSortKey, List<String>> ascending =
          <RecordSortKey, List<String>>{
            RecordSortKey.number: <String>['b', 'a', 'c', 'd'],
            RecordSortKey.capturedAt: <String>['a', 'd', 'b', 'c'],
            RecordSortKey.name: <String>['b', 'c', 'd', 'a'],
          };
      for (final MapEntry<RecordSortKey, List<String>> expected
          in ascending.entries) {
        expect(
          await page(sort: RecordSort(key: expected.key, ascending: true)),
          expected.value,
          reason: '${expected.key.stored} ascending',
        );
        expect(
          await page(sort: RecordSort(key: expected.key)),
          expected.value.reversed.toList(),
          reason: '${expected.key.stored} descending',
        );
      }
    });

    test('a record with no name sorts before every named one', () async {
      await seedRecordRow(db, 'named');
      await seedValue(db, 'f1', recordId: 'named', fieldKey: 'model', raw: 'A');
      await seedRecordRow(db, 'unnamed');
      expect(
        await page(
          sort: const RecordSort(key: RecordSortKey.name, ascending: true),
        ),
        <String>['unnamed', 'named'],
      );
    });

    test('pages of every order meet without overlap or gap', () async {
      for (int index = 0; index < 23; index++) {
        final String id = 'r${index.toString().padLeft(2, '0')}';
        await seedRecordRow(
          db,
          id,
          number: index % 7,
          capturedAt: DateTime.utc(2026, 9, 1 + index % 5),
          status: index.isEven ? 'captured' : 'needsReview',
        );
        await seedValue(
          db,
          'f-$id',
          recordId: id,
          fieldKey: 'model',
          raw: 'Model ${index % 4}',
        );
      }
      await seedRecordRow(db, 'archived', status: 'archived');
      for (final RecordSortKey key in RecordSortKey.values) {
        for (final bool ascending in <bool>[true, false]) {
          final RecordSort sort = RecordSort(key: key, ascending: ascending);
          final List<String> whole = await page(sort: sort);
          final List<String> paged = <String>[
            for (int offset = 0; offset < 30; offset += 5)
              ...await page(sort: sort, offset: offset, limit: 5),
          ];
          expect(whole, hasLength(23), reason: sort.toString());
          expect(paged, whole, reason: sort.toString());
          expect(paged.toSet(), hasLength(23), reason: sort.toString());
        }
      }
      expect(await count(), 23);
    });

    test(
      'an empty page is asked for with a zero limit or past the end',
      () async {
        await seedRecordRow(db, 'r1');
        await seedRecordRow(db, 'r2');
        expect(await page(limit: 0), isEmpty);
        expect(await page(offset: 2, limit: 5), isEmpty);
        expect(await page(offset: -3, limit: 1), <String>['r1']);
      },
    );
  });

  group('list rows', () {
    test(
      'a row carries number, name, identifier, status and capture time',
      () async {
        await seedRecordRow(
          db,
          'r1',
          number: 7,
          status: 'approved',
          capturedAt: DateTime.utc(2026, 9, 3, 12),
        );
        await seedValue(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'model',
          raw: 'Hoist',
        );
        await seedValue(
          db,
          'f2',
          recordId: 'r1',
          fieldKey: 'serial',
          raw: 'H-9',
        );
        final RecordSummary row = await rowOf('r1');
        expect(row.projectId, 'p1');
        expect(row.templateId, 't1');
        expect(row.number, 7);
        expect(row.name, 'Hoist');
        expect(row.identifier, 'H-9');
        expect(row.status, RecordStatus.approved);
        expect(row.capturedAt, DateTime.utc(2026, 9, 3, 12));
        expect(row.thumb, isNull);
        expect(row.photoCount, 0);
        expect(row.flags, isEmpty);
      },
    );

    test('the context label is the deepest level the snapshot sets', () async {
      await seedContextLevel(
        db,
        projectId: 'p1',
        level: 0,
        fieldKey: 'site',
        label: 'Site',
      );
      await seedContextLevel(
        db,
        projectId: 'p1',
        level: 1,
        fieldKey: 'building',
        label: 'Building',
      );
      await seedContextLevel(
        db,
        projectId: 'p1',
        level: 2,
        fieldKey: 'room',
        label: 'Room',
      );
      await seedRecordRow(
        db,
        'deep',
        context: <String, String>{'room': 'R12', 'site': 'North'},
      );
      await seedRecordRow(
        db,
        'shallow',
        context: <String, String>{'site': 'North', 'building': '  '},
      );
      await seedRecordRow(
        db,
        'undeclared',
        context: <String, String>{'zone': 'Z1', 'area': 'A2'},
      );
      await seedRecordRow(
        db,
        'nested',
        context: <String, Object?>{
          'levels': <Object?>[],
          'values': <String, String>{'room': 'R3', 'site': 'East'},
          'pinned': <String, String>{},
        },
      );
      await seedRecordRow(db, 'none');
      expect((await rowOf('deep')).contextLabel, 'R12');
      expect((await rowOf('shallow')).contextLabel, 'North');
      expect((await rowOf('undeclared')).contextLabel, 'A2');
      expect((await rowOf('nested')).contextLabel, 'R3');
      expect((await rowOf('none')).contextLabel, '');
    });

    test('the thumbnail is the first live photo, stored where the thumbnail '
        'service looks', () async {
      await seedRecordRow(db, 'r1');
      await seedPhotoRow(db, 'later', recordId: 'r1', sortOrder: 2);
      await seedPhotoRow(
        db,
        'first',
        recordId: 'r1',
        sortOrder: 1,
        rotation: 180,
        sha256: 'abc123',
      );
      await seedPhotoRow(db, 'gone', recordId: 'r1', sortOrder: 0);
      await seedTomb(db, 'photos', 'gone');
      await seedCaption(
        db,
        'cap',
        ownerType: 'photo',
        ownerId: 'first',
        text: 'Plate',
      );
      final RecordSummary row = await rowOf('r1');
      expect(
        row.thumb,
        const RecordPhoto(
          id: 'first',
          sha256: 'abc123',
          storagePath: 'projects/north/photos/first.jpg',
          quarterTurns: 2,
          caption: 'Plate',
          sortOrder: 1,
          photoType: 'front',
        ),
      );
      expect(row.photoCount, 2);
      expect(row.has(RecordFlag.hasPhotos), isTrue);
    });

    test('the page and the count emit again after a write', () async {
      await seedRecordRow(db, 'r1');
      final RecordFilter review = RecordFilter.forStatus(
        RecordStatus.needsReview,
      );
      expect(await page(filter: review), isEmpty);
      expect(await count(review), 0);
      final Future<void> listed = expectLater(
        queries
            .watchPage(
              'p1',
              filter: review,
              sort: RecordSort.newestFirst,
              offset: 0,
              limit: 10,
            )
            .map(
              (List<RecordSummary> rows) => <String>[
                for (final RecordSummary row in rows) row.id,
              ],
            ),
        emitsThrough(<String>['r1']),
      );
      final Future<void> counted = expectLater(
        queries.watchCount('p1', review),
        emitsThrough(1),
      );
      await writeRecordStatus(
        db,
        recordId: 'r1',
        status: 'needsReview',
        previousStatus: 'captured',
        clock: clock,
        deviceId: 'device-a',
      );
      await listed;
      await counted;
    });
  });

  test('a row\'s flags follow a write to the audit table', () async {
    await seedRecordRow(db, 'r1');
    final Future<void> merged = expectLater(
      queries
          .watchPage(
            'p1',
            filter: RecordFilter.none,
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 10,
          )
          .map((List<RecordSummary> rows) => rows.single.flags),
      emitsThrough(<RecordFlag>{RecordFlag.mergedFromBundle}),
    );
    await appendAudit(
      db,
      entityType: 'records',
      entityId: 'r1',
      action: AuditAction.created,
      fieldKey: 'merge',
      newValue: 'inserted',
      reason: 'site-b.tapture',
      clock: clock,
      device: 'device-a',
    );
    await merged;
  });

  group('facets', () {
    Future<void> seedFacetRecords() async {
      await seedTemplateRow(db, 't3', name: 'Vehicles');
      await seedContextLevel(
        db,
        projectId: 'p1',
        level: 0,
        fieldKey: 'site',
        label: 'Site',
      );
      await seedContextLevel(
        db,
        projectId: 'p1',
        level: 1,
        fieldKey: 'room',
        label: '',
      );
      await seedDeviceProfile(
        db,
        deviceId: 'device-local',
        operatorName: 'Ada',
      );
      await seedRecordRow(
        db,
        'a',
        context: <String, String>{'site': 'North', 'room': 'R1'},
        capturedBy: 'device-local',
      );
      await seedValue(
        db,
        'fa',
        recordId: 'a',
        fieldKey: 'condition',
        raw: 'good',
      );
      await seedRecordRow(
        db,
        'b',
        templateId: 't2',
        status: 'approved',
        context: <String, Object?>{
          'levels': <Object?>[],
          'values': <String, String>{'site': 'East'},
          'pinned': <String, String>{},
        },
        capturedBy: 'device-b',
      );
      await seedValue(
        db,
        'fb',
        recordId: 'b',
        fieldKey: 'condition_grade',
        raw: 'x',
        approved: 'fair',
      );
      await seedRecordRow(
        db,
        'c',
        status: 'archived',
        context: <String, String>{'site': 'North', 'zone': 'Z9'},
        capturedBy: 'device-b',
      );
      await seedValue(
        db,
        'fc',
        recordId: 'c',
        fieldKey: 'condition',
        raw: 'poor',
        retiredAt: DateTime.utc(2026, 9),
      );
      await seedRecordRow(
        db,
        'd',
        templateId: 't3',
        status: 'deleted',
        context: <String, String>{'site': 'West'},
        capturedBy: 'device-c',
      );
      await seedTomb(db, 'records', 'd');
      await seedValue(
        db,
        'fd',
        recordId: 'd',
        fieldKey: 'condition',
        raw: 'bad',
      );
      await seedRecordRow(
        db,
        'e',
        templateId: 't3',
        context: <String, String>{'site': 'South'},
        capturedBy: 'device-e',
      );
      await seedTomb(
        db,
        'records',
        'e',
        reason: RecordQueries.projectDeletedReason,
      );
      await seedRecordRow(
        db,
        'f',
        projectId: 'p2',
        context: <String, String>{'site': 'Depot'},
        capturedBy: 'device-f',
      );
    }

    test('offer what the live records use, labelled', () async {
      await seedFacetRecords();
      final RecordFacets facets = okOf(await queries.facets('p1'));
      expect(facets.templates, <({String id, String name})>[
        (id: 't1', name: 'Assets'),
        (id: 't2', name: 'Rooms'),
      ]);
      expect(
        <(String, String, List<String>)>[
          for (final ({String key, String label, List<String> values}) level
              in facets.contextLevels)
            (level.key, level.label, level.values),
        ].map(((String, String, List<String>) level) => level.toString()),
        <String>[
          ('site', 'Site', <String>['East', 'North']).toString(),
          ('room', 'room', <String>['R1']).toString(),
          ('zone', 'zone', <String>['Z9']).toString(),
        ],
      );
      expect(facets.operators, <({String id, String label})>[
        (id: 'device-local', label: 'Ada'),
        (id: 'device-b', label: 'device-b'),
      ]);
      expect(facets.conditions, <String>['fair', 'good']);
      expect(facets.statuses, <RecordStatus>{
        RecordStatus.captured,
        RecordStatus.approved,
        RecordStatus.archived,
      });
    });

    test(
      'this device is labelled with the operator the caller names',
      () async {
        await seedFacetRecords();
        final RecordQueries named = RecordQueries(
          db: db,
          localOperator: () => 'Grace',
        );
        final RecordFacets facets = okOf(await named.facets('p1'));
        expect(facets.operators, <({String id, String label})>[
          (id: 'device-b', label: 'device-b'),
          (id: 'device-local', label: 'Grace'),
        ]);
        final RecordQueries blank = RecordQueries(
          db: db,
          localOperator: () => '  ',
        );
        expect(okOf(await blank.facets('p1')).operators.first.label, 'Ada');
      },
    );

    test('a project with no records offers nothing', () async {
      await seedFacetRecords();
      expect(okOf(await queries.facets('p-empty')).isEmpty, isTrue);
    });
  });

  group('history', () {
    Future<void> audit(
      String id,
      int minute, {
      String entityType = 'records',
      String entityId = 'h1',
      String action = 'updated',
      String? fieldKey,
      String? previous,
      String? next,
      String? reason,
    }) {
      return seedAudit(
        db,
        id,
        entityType: entityType,
        entityId: entityId,
        action: action,
        fieldKey: fieldKey,
        previous: previous,
        next: next,
        reason: reason,
        operator: 'Ada',
        at: DateTime.utc(2026, 9, 1, 8, minute),
      );
    }

    test('reads the record\'s, its photos\' and its captions\' lines in time '
        'order', () async {
      await seedRecordRow(db, 'h1');
      await seedPhotoRow(db, 'ph1', recordId: 'h1');
      await seedPhotoRow(db, 'ph-other', recordId: 'h2');
      await audit('a05', 0, action: 'created', next: 'captured');
      await audit(
        'a02',
        0,
        action: 'created',
        fieldKey: 'model',
        next: 'Hoist',
      );
      await audit(
        'a10',
        1,
        fieldKey: 'status',
        previous: 'captured',
        next: 'needsReview',
      );
      await audit(
        'a11',
        2,
        entityType: 'photos',
        entityId: 'ph1',
        action: 'created',
      );
      await audit('a12', 2, fieldKey: 'photo', next: 'added', reason: 'ph1');
      await audit(
        'a13',
        3,
        entityType: 'captions',
        action: 'created',
        fieldKey: 'caption',
        next: 'By the door',
      );
      await audit(
        'a14',
        4,
        entityType: 'captions',
        entityId: 'ph1',
        action: 'updated',
        fieldKey: 'caption',
        next: 'Plate',
      );
      await audit(
        'a15',
        5,
        fieldKey: 'processing',
        next: 'completed',
        reason: '{"job":"j1"}',
      );
      await audit(
        'a16',
        6,
        fieldKey: 'model',
        previous: 'Hoist',
        next: 'Crane',
      );
      await audit(
        'a17',
        7,
        fieldKey: 'condition',
        previous: 'false',
        next: 'true',
        reason: 'evidenceRemoved',
      );
      await audit('a18', 8, fieldKey: 'templateId', previous: 't1', next: 't2');
      await audit(
        'a19',
        8,
        fieldKey: 'serial',
        previous: 'false',
        next: 'true',
        reason: 'retired',
      );
      await audit('a20', 9, fieldKey: 'export', next: 'v3', reason: 'bundle');
      await audit(
        'a21',
        10,
        action: 'created',
        fieldKey: 'merge',
        next: 'inserted',
        reason: 'site-b.tapture',
      );
      await audit(
        'a22',
        11,
        entityType: 'photos',
        entityId: 'ph1',
        action: 'deleted',
      );
      await audit('a23', 11, fieldKey: 'photo', next: 'removed', reason: 'ph1');
      // Lines of other records and their photos stay out.
      await audit('b01', 1, entityId: 'h2', fieldKey: 'model', next: 'Fan');
      await audit(
        'b02',
        1,
        entityType: 'photos',
        entityId: 'ph-other',
        action: 'created',
      );
      await audit(
        'b03',
        1,
        entityType: 'captions',
        entityId: 'h2',
        action: 'created',
        fieldKey: 'caption',
      );

      final List<RecordHistoryEvent> lines = await queries
          .watchHistory('h1')
          .first;
      expect(
        <(String, RecordHistoryKind)>[
          for (final RecordHistoryEvent line in lines) (line.id, line.kind),
        ],
        <(String, RecordHistoryKind)>[
          ('a02', RecordHistoryKind.valueChanged),
          ('a05', RecordHistoryKind.created),
          ('a10', RecordHistoryKind.statusChanged),
          ('a11', RecordHistoryKind.photoAdded),
          ('a12', RecordHistoryKind.photoAdded),
          ('a13', RecordHistoryKind.captionChanged),
          ('a14', RecordHistoryKind.captionChanged),
          ('a15', RecordHistoryKind.processed),
          ('a16', RecordHistoryKind.valueChanged),
          ('a17', RecordHistoryKind.evidenceRemoved),
          ('a18', RecordHistoryKind.templateChanged),
          ('a19', RecordHistoryKind.retired),
          ('a20', RecordHistoryKind.exported),
          ('a21', RecordHistoryKind.merged),
          ('a22', RecordHistoryKind.photoRemoved),
          ('a23', RecordHistoryKind.photoRemoved),
        ],
      );
      final RecordHistoryEvent edit = lines.firstWhere(
        (RecordHistoryEvent line) => line.id == 'a16',
      );
      expect(edit.fieldKey, 'model');
      expect(edit.previous, 'Hoist');
      expect(edit.next, 'Crane');
      expect(edit.operator, 'Ada');
      expect(edit.device, 'device-a');
      expect(edit.at, DateTime.utc(2026, 9, 1, 8, 6));
    });

    test(
      'a template field keyed like a marker reads as a value edit',
      () async {
        await seedTemplateRow(
          db,
          't9',
          fields: <String>['status', 'export', 'merge'],
        );
        await seedRecordRow(db, 'h1', templateId: 't9');
        await seedValue(
          db,
          'fs',
          recordId: 'h1',
          fieldKey: 'status',
          raw: 'In service',
        );
        await seedValue(
          db,
          'fe',
          recordId: 'h1',
          fieldKey: 'export',
          raw: 'no',
        );
        await seedValue(db, 'fm', recordId: 'h1', fieldKey: 'merge', raw: 'no');
        await audit(
          'a1',
          0,
          action: 'created',
          fieldKey: 'status',
          next: 'In service',
        );
        await audit(
          'a2',
          1,
          fieldKey: 'status',
          previous: 'In service',
          next: 'Retired',
        );
        await audit(
          'a3',
          2,
          fieldKey: 'status',
          previous: 'captured',
          next: 'needsReview',
        );
        await audit('a4', 3, fieldKey: 'export', previous: 'no', next: 'yes');
        await audit('a5', 4, fieldKey: 'export', next: 'v2', reason: 'bundle');
        await audit('a6', 5, fieldKey: 'merge', previous: 'no', next: 'yes');
        await audit(
          'a7',
          6,
          fieldKey: 'templateId',
          previous: 't1',
          next: 't9',
        );
        expect(
          <RecordHistoryKind>[
            for (final RecordHistoryEvent line
                in await queries.watchHistory('h1').first)
              line.kind,
          ],
          <RecordHistoryKind>[
            RecordHistoryKind.valueChanged,
            RecordHistoryKind.valueChanged,
            RecordHistoryKind.statusChanged,
            RecordHistoryKind.valueChanged,
            RecordHistoryKind.exported,
            RecordHistoryKind.valueChanged,
            RecordHistoryKind.templateChanged,
          ],
        );
      },
    );

    test('a record with no lines reads as an empty history', () async {
      expect(await queries.watchHistory('missing').first, isEmpty);
    });

    test('the history emits again after a line is written', () async {
      await seedRecordRow(db, 'h1');
      final Future<void> grew = expectLater(
        queries
            .watchHistory('h1')
            .map(
              (List<RecordHistoryEvent> lines) => <String?>[
                for (final RecordHistoryEvent line in lines) line.fieldKey,
              ],
            ),
        emitsThrough(<String?>['serial']),
      );
      await appendAudit(
        db,
        entityType: 'records',
        entityId: 'h1',
        action: AuditAction.updated,
        fieldKey: 'serial',
        previousValue: 'A',
        newValue: 'B',
        clock: clock,
        device: 'device-a',
      );
      await grew;
    });
  });

  group('recycle bin', () {
    test('lists deleted records newest deletion first, with project and '
        'reason', () async {
      await seedRecordRow(db, 'b1', status: 'deleted', number: 1);
      await seedValue(
        db,
        'f1',
        recordId: 'b1',
        fieldKey: 'model',
        raw: 'Hoist',
      );
      await seedTomb(
        db,
        'records',
        'b1',
        reason: 'Duplicate',
        deletedAt: DateTime.utc(2026, 9, 10),
      );
      await seedRecordRow(db, 'b3', status: 'deleted');
      await seedTomb(
        db,
        'records',
        'b3',
        reason: 'Wrong site',
        deletedAt: DateTime.utc(2026, 9, 12),
      );
      await seedRecordRow(db, 'b2', status: 'deleted');
      await seedTomb(
        db,
        'records',
        'b2',
        reason: 'Wrong site',
        deletedAt: DateTime.utc(2026, 9, 12),
      );
      final List<DeletedRecord> bin = await queries.watchBin().first;
      expect(bin.map((DeletedRecord row) => row.id), <String>[
        'b2',
        'b3',
        'b1',
      ]);
      final DeletedRecord hoist = bin.last;
      expect(hoist.projectName, 'Hospital');
      expect(hoist.reason, 'Duplicate');
      expect(hoist.deletedAt, DateTime.utc(2026, 9, 10));
      expect(hoist.summary.status, RecordStatus.deleted);
      expect(hoist.summary.name, 'Hoist');
      expect(hoist.summary.number, 1);
    });

    test('leaves out records removed with their project and records that '
        'are not deleted', () async {
      await seedRecordRow(db, 'kept', status: 'deleted');
      await seedTomb(db, 'records', 'kept');
      await seedRecordRow(db, 'project-reason', status: 'deleted');
      await seedTomb(
        db,
        'records',
        'project-reason',
        reason: RecordQueries.projectDeletedReason,
      );
      await seedRecordRow(
        db,
        'in-gone-project',
        projectId: 'p2',
        status: 'deleted',
      );
      await seedTomb(db, 'records', 'in-gone-project');
      await seedTomb(db, 'projects', 'p2');
      await seedRecordRow(db, 'no-tombstone', status: 'deleted');
      await seedRecordRow(db, 'live-tombstoned');
      await seedTomb(db, 'records', 'live-tombstoned');
      expect(
        (await queries.watchBin().first).map((DeletedRecord row) => row.id),
        <String>['kept'],
      );
    });

    test('a delete shows in the bin at once', () async {
      await seedRecordRow(db, 'r1');
      final Future<void> binned = expectLater(
        queries.watchBin().map(
          (List<DeletedRecord> rows) => <String>[
            for (final DeletedRecord row in rows) row.id,
          ],
        ),
        emitsThrough(<String>['r1']),
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
      await binned;
      expect(await page(), isEmpty);
      expect(await count(), 0);
    });
  });

  test('values stay unwritten by a read', () async {
    await seedRecordRow(db, 'r1');
    await seedValue(
      db,
      'f1',
      recordId: 'r1',
      fieldKey: 'model',
      raw: 'A',
      refined: 'B',
    );
    final QueryRow before = await db
        .customSelect('SELECT rev, updated_at FROM record_fields')
        .getSingle();
    okOf(await queries.byId('r1'));
    await queries
        .watchPage(
          'p1',
          filter: const RecordFilter(search: 'model'),
          sort: RecordSort.newestFirst,
          offset: 0,
          limit: 5,
        )
        .first;
    okOf(await queries.facets('p1'));
    final QueryRow after = await db
        .customSelect('SELECT rev, updated_at FROM record_fields')
        .getSingle();
    expect(after.data, before.data);
    expect(
      await db
          .customSelect('SELECT COUNT(*) AS n FROM audit_log')
          .map((QueryRow row) => row.read<int>('n'))
          .getSingle(),
      0,
    );
  });
}
