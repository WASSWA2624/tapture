import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/data/record_writes.dart'
    show RecordWrites;
import 'package:tapture/features/records/records.dart';

import '../../../core/db/record_rows.dart'
    show searchDoc, searchRecords, seedCaption;
import '../fakes/record_results.dart';
import '../record_repository_contract.dart';
import 'record_read_seeds.dart';

void main() {
  group('the default record store, before main wires the database', () {
    late ProviderContainer container;
    late RecordRepository repo;

    setUp(() {
      container = ProviderContainer();
      repo = container.read(recordRepositoryProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('reads nothing and never fails a read', () async {
      expect(await repo.watchEntry('r1').first, isNull);
      expect(okOf(await repo.byId('r1')), isNull);
      expect(
        await repo
            .watchPage(
              'p1',
              filter: RecordFilter.none,
              sort: RecordSort.newestFirst,
              offset: 0,
              limit: 50,
            )
            .first,
        isEmpty,
      );
      expect(await repo.watchCount('p1', RecordFilter.none).first, 0);
      expect(okOf(await repo.facets('p1')).isEmpty, isTrue);
      expect(await repo.watchHistory('r1').first, isEmpty);
      expect(await repo.watchBin().first, isEmpty);
    });

    test('refuses every write with a storage failure that says why', () async {
      final List<Result<Object?>> writes = <Result<Object?>>[
        await repo.save((
          projectId: 'p1',
          templateId: 't1',
          fields: const <String, String>{},
          context: const <String, String>{},
        )),
        await repo.transition('r1', RecordStatus.approved),
        await repo.editValues('r1', const <RecordValueEdit>[
          (fieldKey: 'serial', value: 'A1'),
        ]),
        await repo.planTemplateChange('r1', 't2'),
        await repo.changeTemplate('r1', 't2'),
        await repo.delete('r1', reason: 'Deleted by the operator.'),
        await repo.restore('r1'),
      ];
      for (final Result<Object?> written in writes) {
        final Failure failure = failureOf(written);
        expect(failure, isA<StorageFailure>());
        expect(failure.message, 'Records are not available yet.');
        expect(failure.recoveryAction, isNotEmpty);
      }
    });

    test('is one instance for the life of the scope', () {
      expect(container.read(recordRepositoryProvider), same(repo));
    });
  });

  group('the Drift record store keeps the repository contract', () {
    late AppDatabase db;
    late RecordRepositoryImpl store;
    int seeded = 0;

    setUp(() {
      db = AppDatabase.memory();
      store = _store(
        db,
        clock: FixedClock(DateTime.utc(2026, 9, 18, 9)),
        deviceId: 'device-test',
        operator: 'Test operator',
      );
      seeded = 0;
    });

    tearDown(() async {
      await db.close();
    });

    runRecordRepositoryContract(
      () => store,
      seedRecord: (RecordRepository _, RecordSeed seed) {
        seeded++;
        return _seedContractRecord(db, 'seed-$seeded', seed);
      },
      seedTemplate: (RecordRepository _, TemplateSeed seed) {
        return seedTemplateRow(
          db,
          seed.id,
          projectId: seed.projectId,
          name: seed.name,
          fields: seed.fieldKeys,
        );
      },
    );
  });

  group('a record read back through the store', () {
    final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
    late AppDatabase db;
    late RecordRepositoryImpl store;

    setUp(() async {
      db = AppDatabase.memory();
      store = _store(db, clock: FixedClock(t0));
      await seedProjectRow(
        db,
        'project-1',
        name: 'Plant room',
        folder: 'plant',
      );
      await seedTemplateRow(
        db,
        'template-1',
        projectId: 'project-1',
        name: 'Assets',
        fields: <String>['model', 'serial', 'condition'],
        identity: <String>['serial'],
      );
      await seedTemplateRow(
        db,
        'template-2',
        projectId: 'project-1',
        name: 'Rooms',
        fields: <String>['model', 'location'],
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// Asserts that every read of [expected.id] maps back to [expected]: the
    /// one-off read, the watched read and, while it is listed, its page row.
    Future<void> readsBackAs(RecordEntry expected, {bool listed = true}) async {
      expect(okOf(await store.byId(expected.id)), expected);
      expect(await store.watchEntry(expected.id).first, expected);
      final List<RecordSummary> rows = await store
          .watchPage(
            expected.projectId,
            filter: RecordFilter.none,
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 10,
          )
          .first;
      expect(
        rows,
        listed ? <RecordSummary>[expected.toSummary()] : isEmpty,
        reason: 'the list row maps the same record',
      );
    }

    test(
      'a record saved by hand reads back whole after every write the store makes',
      () async {
        final RecordEntry saved = okOf(
          await store.save((
            projectId: 'project-1',
            templateId: 'template-1',
            fields: const <String, String>{'model': 'Hoist', 'serial': 'H-9'},
            context: const <String, String>{'site': 'North', 'room': 'Plant'},
          )),
        );
        final RecordEntry created = RecordEntry(
          id: saved.id,
          projectId: 'project-1',
          templateId: 'template-1',
          number: 1,
          name: 'Hoist',
          identifier: 'H-9',
          status: RecordStatus.draft,
          values: const <RecordValue>[
            RecordValue(
              fieldKey: 'model',
              raw: 'Hoist',
              source: RecordWrites.typedSource,
            ),
            RecordValue(
              fieldKey: 'serial',
              raw: 'H-9',
              source: RecordWrites.typedSource,
            ),
          ],
          context: const <String, String>{'site': 'North', 'room': 'Plant'},
          capturedAt: t0,
          capturedBy: 'device-a',
          updatedAt: t0,
          processingMode: RecordWrites.manualSource,
          source: RecordWrites.manualSource,
        );
        expect(saved, created, reason: 'save returns what a read finds');
        await readsBackAs(created);

        okOf(
          await store.editValues(saved.id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Crane'),
            (fieldKey: 'location', value: 'Bay 4'),
          ]),
        );
        final RecordEntry edited = created.copyWith(
          name: 'Crane',
          values: const <RecordValue>[
            RecordValue(
              fieldKey: 'model',
              raw: 'Hoist',
              refined: 'Crane',
              verified: true,
            ),
            RecordValue(
              fieldKey: 'serial',
              raw: 'H-9',
              source: RecordWrites.typedSource,
            ),
            RecordValue(fieldKey: 'location', raw: 'Bay 4', verified: true),
          ],
        );
        await readsBackAs(edited);

        okOf(await store.transition(saved.id, RecordStatus.needsReview));
        okOf(await store.transition(saved.id, RecordStatus.approved));
        final RecordEntry approved = edited.copyWith(
          status: RecordStatus.approved,
          approvedAt: t0,
          approvedBy: 'Ada',
        );
        await readsBackAs(approved);

        okOf(await store.changeTemplate(saved.id, 'template-2'));
        final RecordEntry moved = approved.copyWith(
          templateId: 'template-2',
          identifier: '',
          status: RecordStatus.needsReview,
          values: const <RecordValue>[
            RecordValue(
              fieldKey: 'model',
              raw: 'Hoist',
              refined: 'Crane',
              verified: true,
            ),
            RecordValue(fieldKey: 'location', raw: 'Bay 4', verified: true),
            RecordValue(
              fieldKey: 'serial',
              raw: 'H-9',
              source: RecordWrites.typedSource,
              retired: true,
            ),
          ],
        );
        await readsBackAs(moved);

        okOf(await store.delete(saved.id, reason: 'Duplicate'));
        final RecordEntry binned = moved.copyWith(status: RecordStatus.deleted);
        await readsBackAs(binned, listed: false);
        expect(await store.watchBin().first, <DeletedRecord>[
          DeletedRecord(
            summary: binned.toSummary(),
            deletedAt: t0,
            projectName: 'Plant room',
            reason: 'Duplicate',
          ),
        ]);

        okOf(await store.restore(saved.id));
        await readsBackAs(moved);
        expect(await store.watchBin().first, isEmpty);

        final List<RecordHistoryEvent> lines = await store
            .watchHistory(saved.id)
            .first;
        expect(lines.first.kind, RecordHistoryKind.created);
        expect(
          <String?>[
            for (final RecordHistoryEvent line in lines)
              if (line.kind == RecordHistoryKind.statusChanged) line.next,
          ],
          <String>[
            'needsReview',
            'approved',
            'needsReview',
            'deleted',
            'needsReview',
          ],
        );
        final RecordHistoryEvent rename = lines.singleWhere(
          (RecordHistoryEvent line) =>
              line.kind == RecordHistoryKind.valueChanged &&
              line.fieldKey == 'model' &&
              line.next == 'Crane',
        );
        expect(rename.previous, 'Hoist');
        expect(rename.operator, 'Ada');
        expect(rename.device, 'device-a');
        expect(
          lines.map((RecordHistoryEvent line) => line.kind),
          containsAll(<RecordHistoryKind>[
            RecordHistoryKind.templateChanged,
            RecordHistoryKind.retired,
          ]),
        );
      },
    );

    test('a captured record with photos, captions and flags reads back whole, '
        'and so does its recycle-bin row', () async {
      final DateTime captured = DateTime.utc(2026, 9, 16, 14, 30);
      await seedRecordRow(
        db,
        'r1',
        projectId: 'project-1',
        templateId: 'template-1',
        // A peer's legacy spelling; the schema stores it canonically.
        status: 'NEEDS_REVIEW',
        capturedAt: captured,
        capturedBy: 'device-b',
        context: const <String, String>{'site': 'North'},
        processingMode: 'online',
      );
      await seedValue(
        db,
        'r1-model',
        recordId: 'r1',
        fieldKey: 'model',
        raw: 'Autoclave',
        refined: 'Steam autoclave',
        source: 'extraction',
        confidence: 0.82,
        band: 'medium',
        verified: true,
        provider: 'openai',
        model: 'gpt-vision',
        method: 'vision',
      );
      await seedValue(
        db,
        'r1-serial',
        recordId: 'r1',
        fieldKey: 'serial',
        raw: 'SN-1',
        approved: 'SN-001',
        confidence: 0.97,
        band: 'high',
        createdAt: 2,
      );
      await seedPhotoRow(
        db,
        'ph-b',
        recordId: 'r1',
        projectId: 'project-1',
        sortOrder: 1,
      );
      await seedPhotoRow(
        db,
        'ph-a',
        recordId: 'r1',
        projectId: 'project-1',
        rotation: 90,
        photoType: 'plate',
      );
      await seedCaption(
        db,
        'cap-a',
        ownerType: 'photo',
        ownerId: 'ph-a',
        text: 'plate',
        refined: 'Rating plate',
      );
      await seedCaption(
        db,
        'cap-r1',
        ownerType: 'record',
        ownerId: 'r1',
        text: 'Beside the sink',
      );
      await seedRecordRow(
        db,
        'r2',
        projectId: 'project-1',
        templateId: 'template-1',
        capturedAt: captured,
      );
      await seedDuplicate(
        db,
        'dup-1',
        left: 'r2',
        right: 'r1',
        projectId: 'project-1',
      );

      final RecordEntry expected = RecordEntry(
        id: 'r1',
        projectId: 'project-1',
        templateId: 'template-1',
        number: 1,
        name: 'Steam autoclave',
        identifier: 'SN-001',
        status: RecordStatus.needsReview,
        values: const <RecordValue>[
          RecordValue(
            fieldKey: 'model',
            raw: 'Autoclave',
            refined: 'Steam autoclave',
            source: 'extraction',
            confidence: 0.82,
            band: 'medium',
            verified: true,
            provider: 'openai',
            model: 'gpt-vision',
            method: 'vision',
          ),
          RecordValue(
            fieldKey: 'serial',
            raw: 'SN-1',
            approved: 'SN-001',
            source: 'ocr',
            confidence: 0.97,
            band: 'high',
          ),
        ],
        photos: const <RecordPhoto>[
          RecordPhoto(
            id: 'ph-a',
            sha256: 'sha-ph-a',
            storagePath: 'projects/plant/photos/ph-a.jpg',
            quarterTurns: 1,
            caption: 'Rating plate',
            photoType: 'plate',
          ),
          RecordPhoto(
            id: 'ph-b',
            sha256: 'sha-ph-b',
            storagePath: 'projects/plant/photos/ph-b.jpg',
            sortOrder: 1,
            photoType: 'front',
          ),
        ],
        caption: 'Beside the sink',
        context: const <String, String>{'site': 'North'},
        flags: const <RecordFlag>{
          RecordFlag.hasPhotos,
          RecordFlag.hasDuplicate,
        },
        capturedAt: captured,
        capturedBy: 'device-b',
        updatedAt: captured,
        processingMode: 'online',
      );
      expect(okOf(await store.byId('r1')), expected);
      expect(await store.watchEntry('r1').first, expected);
      final List<RecordSummary> rows = await store
          .watchPage(
            'project-1',
            filter: const RecordFilter(search: 'autoclave'),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 10,
          )
          .first;
      expect(rows, <RecordSummary>[expected.toSummary()]);

      okOf(await store.delete('r1', reason: 'Wrong site'));
      expect(await store.watchBin().first, <DeletedRecord>[
        DeletedRecord(
          summary: expected.copyWith(status: RecordStatus.deleted).toSummary(),
          deletedAt: t0,
          projectName: 'Plant room',
          reason: 'Wrong site',
        ),
      ]);
    });
  });

  group('editing, adding or deleting a record updates its search entry in the '
      'same transaction', () {
    late AppDatabase db;
    late RecordRepositoryImpl store;

    setUp(() async {
      db = AppDatabase.memory();
      store = _store(db, clock: FixedClock(DateTime.utc(2026, 9, 17, 8)));
      await seedTemplateRow(
        db,
        'template-1',
        projectId: 'project-1',
        name: 'Assets',
        fields: <String>['model', 'serial'],
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// Ids of project-1's listed records that a search for [text] finds.
    Future<List<String>> found(String text) async {
      final List<RecordSummary> rows = await store
          .watchPage(
            'project-1',
            filter: RecordFilter(search: text),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 50,
          )
          .first;
      return <String>[for (final RecordSummary row in rows) row.id];
    }

    Future<String> saved(Map<String, String> fields) async {
      return okOf(
        await store.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: fields,
          context: const <String, String>{},
        )),
      ).id;
    }

    test('an added record is found at once, and a failed add leaves '
        'nothing behind to find', () async {
      await _failWhen(db, 'record_fields', "NEW.field_key = 'serial'");
      final Failure failure = failureOf(
        await store.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist', 'serial': 'H-9'},
          context: const <String, String>{},
        )),
      );
      expect(failure, isA<StorageFailure>());
      expect(await _count(db, 'records'), 0);
      expect(await _count(db, 'record_search_docs'), 0);
      expect(await searchRecords(db, 'hoist'), isEmpty);
      expect(await _pendingDocuments(db), 0);
      await db.customStatement('DROP TRIGGER forced_failure_record_fields');

      final Future<void> listed = expectLater(
        store
            .watchPage(
              'project-1',
              filter: const RecordFilter(search: 'hoist'),
              sort: RecordSort.newestFirst,
              offset: 0,
              limit: 50,
            )
            .map((List<RecordSummary> rows) => rows.length),
        emitsInOrder(<int>[0, 1]),
      );
      final String id = await saved(const <String, String>{
        'model': 'Hoist',
        'serial': 'H-9',
      });
      await listed;
      expect(await found('hoist'), <String>[id]);
      expect(await searchRecords(db, 'hoist'), <String>[id]);
      expect((await searchDoc(db, id))?.name, 'Hoist');
      expect(await _pendingDocuments(db), 0);
    });

    test('an edit is found by its new text and no longer by the text it '
        'replaced, while the raw capture stays findable', () async {
      final String id = await saved(const <String, String>{'model': 'Hoist'});
      okOf(
        await store.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Crane'),
        ]),
      );
      expect(await found('crane'), <String>[id]);

      okOf(
        await store.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Gantry'),
        ]),
      );
      expect(await found('gantry'), <String>[id]);
      expect(await found('crane'), isEmpty);
      expect(await searchRecords(db, 'crane'), isEmpty);
      expect(
        await found('hoist'),
        <String>[id],
        reason: 'the raw value is evidence and stays in the index',
      );
      expect((await searchDoc(db, id))?.name, 'Gantry');

      okOf(
        await store.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'serial', value: 'SN-4589'),
        ]),
      );
      expect(await found('4589'), <String>[id]);
      expect(await _pendingDocuments(db), 0);
    });

    test('an edit is in the index before its transaction commits, and a '
        'rollback takes both back', () async {
      final String id = await saved(const <String, String>{'model': 'Hoist'});
      okOf(
        await store.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Gantry'),
        ]),
      );
      late final List<String> winchDuring;
      late final List<String> gantryDuring;
      late final String? nameDuring;
      final Result<void> rolledBack = await runInTransaction<void>(
        db,
        () async {
          final Result<void> edited = await store.editValues(
            id,
            const <RecordValueEdit>[(fieldKey: 'model', value: 'Winch')],
          );
          if (edited is FailureResult<void>) {
            throw edited.failure;
          }
          winchDuring = await searchRecords(db, 'winch');
          gantryDuring = await searchRecords(db, 'gantry');
          nameDuring = (await searchDoc(db, id))?.name;
          throw const StorageFailure(
            message: 'Stopped on purpose.',
            recoveryAction: 'Nothing to do.',
          );
        },
      );
      expect(failureOf(rolledBack).message, 'Stopped on purpose.');
      expect(winchDuring, <String>[id], reason: 'indexed before the commit');
      expect(gantryDuring, isEmpty, reason: 'the replaced edit left at once');
      expect(nameDuring, 'Winch');
      expect(await searchRecords(db, 'winch'), isEmpty);
      expect(await searchRecords(db, 'gantry'), <String>[id]);
      expect(await found('winch'), isEmpty);
      expect(await found('gantry'), <String>[id]);
      expect(okOf(await store.byId(id))?.valueOf('model')?.display, 'Gantry');
      expect((await searchDoc(db, id))?.name, 'Gantry');
    });

    test('a failed edit changes neither the value, the status nor the '
        'search entry', () async {
      final String id = await saved(const <String, String>{'model': 'Gantry'});
      okOf(await store.transition(id, RecordStatus.needsReview));
      okOf(await store.transition(id, RecordStatus.approved));
      // The edit writes the value and its audit line, then fails on the
      // status line that sends the record back to review.
      await _failWhen(
        db,
        'audit_log',
        "NEW.field_key = 'status' AND NEW.new_value = 'needsReview'",
      );
      expect(
        failureOf(
          await store.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Winch'),
          ]),
        ),
        isA<StorageFailure>(),
      );
      final RecordEntry entry = okOf(await store.byId(id))!;
      expect(entry.status, RecordStatus.approved);
      expect(entry.valueOf('model')?.display, 'Gantry');
      expect(await found('winch'), isEmpty);
      expect(await found('gantry'), <String>[id]);
      expect(await _pendingDocuments(db), 0);
    });

    test('a deleted record leaves the search, keeps its document for the '
        'restore, and is found again once restored', () async {
      final String id = await saved(const <String, String>{'model': 'Hoist'});
      final String other = await saved(const <String, String>{
        'model': 'Hoist crane',
      });
      expect((await found('hoist')).toSet(), <String>{id, other});

      okOf(await store.delete(id, reason: 'Duplicate'));
      expect(await found('hoist'), <String>[other]);
      expect(
        await store
            .watchCount('project-1', const RecordFilter(search: 'hoist'))
            .first,
        1,
      );
      expect(
        await searchRecords(db, 'hoist'),
        unorderedEquals(<String>[id, other]),
        reason: 'a binned record keeps its document so a restore finds it',
      );

      okOf(await store.restore(id));
      expect((await found('hoist')).toSet(), <String>{id, other});
    });

    test('a failed delete leaves the record listed and found', () async {
      final String id = await saved(const <String, String>{'model': 'Hoist'});
      await _failWhen(db, 'tombstones', "NEW.entity_type = 'records'");
      expect(
        failureOf(await store.delete(id, reason: 'Duplicate')),
        isA<StorageFailure>(),
      );
      expect(okOf(await store.byId(id))?.status, RecordStatus.draft);
      expect(await found('hoist'), <String>[id]);
      expect(await store.watchBin().first, isEmpty);
    });
  });

  group('a store whose database cannot be used', () {
    test('fails every read and write instead of throwing', () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final RecordRepositoryImpl store = _store(
        db,
        clock: FixedClock(DateTime.utc(2026, 9, 17, 8)),
      );
      await seedTemplateRow(db, 'template-1', projectId: 'project-1');
      await db.customStatement('DROP TABLE records');
      await db.customStatement('DROP TABLE audit_log');

      expect(failureOf(await store.byId('r1')), isA<StorageFailure>());
      await expectLater(
        store.watchEntry('r1'),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(
        store.watchPage(
          'project-1',
          filter: RecordFilter.none,
          sort: RecordSort.newestFirst,
          offset: 0,
          limit: 10,
        ),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(
        store.watchCount('project-1', RecordFilter.none),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(
        store.watchHistory('r1'),
        emitsError(isA<StorageFailure>()),
      );
      await expectLater(store.watchBin(), emitsError(isA<StorageFailure>()));
      expect(failureOf(await store.facets('project-1')), isA<StorageFailure>());

      final List<Result<Object?>> writes = <Result<Object?>>[
        await store.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist'},
          context: const <String, String>{},
        )),
        await store.transition('r1', RecordStatus.approved),
        await store.editValues('r1', const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Crane'),
        ]),
        await store.planTemplateChange('r1', 'template-2'),
        await store.changeTemplate('r1', 'template-2'),
        await store.delete('r1', reason: 'Duplicate'),
        await store.restore('r1'),
      ];
      for (final Result<Object?> written in writes) {
        expect(failureOf(written), isA<StorageFailure>());
      }
    });
  });

  group('the provider main overrides', () {
    test('serves the Drift store to everything that reads it', () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await seedTemplateRow(
        db,
        'template-1',
        projectId: 'project-1',
        fields: <String>['model'],
      );
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          recordRepositoryProvider.overrideWith((Ref _) {
            return RecordRepositoryImpl(
              db: db,
              clock: clock,
              deviceId: 'device-a',
              ids: UuidV7Service.sequence(clock),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final RecordRepository repo = container.read(recordRepositoryProvider);
      expect(repo, isA<RecordRepositoryImpl>());
      expect(container.read(recordRepositoryProvider), same(repo));
      final RecordEntry saved = okOf(
        await repo.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist'},
          context: const <String, String>{},
        )),
      );
      expect(await repo.watchCount('project-1', RecordFilter.none).first, 1);
      expect(okOf(await repo.byId(saved.id))?.name, 'Hoist');
    });

    test('stamps the device profile operator when main names none', () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await seedTemplateRow(
        db,
        'template-1',
        projectId: 'project-1',
        fields: <String>['model'],
      );
      await seedDeviceProfile(db, deviceId: 'device-a', operatorName: 'Grace');
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
      final RecordRepositoryImpl store = RecordRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final RecordEntry saved = okOf(
        await store.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist'},
          context: const <String, String>{},
        )),
      );
      okOf(await store.transition(saved.id, RecordStatus.needsReview));
      okOf(await store.transition(saved.id, RecordStatus.approved));
      expect(okOf(await store.byId(saved.id))?.approvedBy, 'Grace');
      final RecordFacets facets = okOf(await store.facets('project-1'));
      expect(facets.operators, <({String id, String label})>[
        (id: 'device-a', label: 'Grace'),
      ]);
    });
  });
}

/// The Drift store over [db], stamped with [clock] and [deviceId], new ids
/// in sequence, and [operator] as the operator.
RecordRepositoryImpl _store(
  AppDatabase db, {
  required Clock clock,
  String deviceId = 'device-a',
  String operator = 'Ada',
}) {
  return RecordRepositoryImpl(
    db: db,
    clock: clock,
    deviceId: deviceId,
    ids: UuidV7Service.sequence(clock),
    operatorName: () => operator,
  );
}

/// Writes [seed] as record [id] through the database, the way capture and a
/// merge leave it (domain open issue 1): a `records` row in the seed's
/// canonical status (the schema's trigger numbers it), one `record_fields`
/// row per field carrying the seed's source, the live photos filed on it
/// (each with its own content hash) and its record caption.
Future<String> _seedContractRecord(
  AppDatabase db,
  String id,
  RecordSeed seed,
) async {
  await seedRecordRow(
    db,
    id,
    projectId: seed.projectId,
    templateId: seed.templateId,
    status: seed.status.stored,
    capturedAt: seed.capturedAt ?? RecordSeed.seedInstant,
    capturedBy: seed.capturedBy,
    context: seed.context,
  );
  int order = 0;
  for (final MapEntry<String, String> field in seed.fields.entries) {
    order++;
    await seedValue(
      db,
      '$id-${field.key}',
      recordId: id,
      fieldKey: field.key,
      raw: field.value,
      source: seed.source,
      createdAt: order,
    );
  }
  for (int index = 0; index < seed.photos; index++) {
    await seedPhotoRow(
      db,
      '$id-photo-$index',
      recordId: id,
      projectId: seed.projectId,
      sortOrder: index,
    );
  }
  if (seed.caption.isNotEmpty) {
    await seedCaption(
      db,
      '$id-caption',
      ownerType: 'record',
      ownerId: id,
      text: seed.caption,
    );
  }
  return id;
}

/// Makes every insert into [table] matching [when] fail, so a write breaks
/// part-way through.
Future<void> _failWhen(AppDatabase db, String table, String when) {
  return db.customStatement(
    'CREATE TEMP TRIGGER forced_failure_$table BEFORE INSERT ON $table '
    "WHEN $when BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
  );
}

/// How many rows [table] holds.
Future<int> _count(AppDatabase db, String table) async {
  final QueryRow row = await db
      .customSelect('SELECT COUNT(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}

/// Search documents still waiting for a deferred rebuild; zero once every
/// write has committed or rolled back.
Future<int> _pendingDocuments(AppDatabase db) async {
  return await _count(db, 'record_search_pending') +
      await _count(db, 'record_search_hold');
}
