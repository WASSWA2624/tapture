import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';

import '../fakes/fake_record_repository.dart';
import '../fakes/record_results.dart';
import '../record_repository_contract.dart';

/// Writes [seed] into the fake the way the contract describes it.
Future<String> seedFake(RecordRepository repo, RecordSeed seed) async {
  final FakeRecordRepository fake = repo as FakeRecordRepository;
  final String id = 'seed-${fake.count + 1}';
  final DateTime at = seed.capturedAt ?? RecordSeed.seedInstant;
  return fake.seedEntry(
    RecordEntry(
      id: id,
      projectId: seed.projectId,
      templateId: seed.templateId,
      status: seed.status,
      capturedAt: at,
      capturedBy: seed.capturedBy,
      updatedAt: at,
      values: <RecordValue>[
        for (final MapEntry<String, String> field in seed.fields.entries)
          RecordValue(
            fieldKey: field.key,
            raw: field.value,
            source: seed.source,
          ),
      ],
      photos: <RecordPhoto>[
        for (int index = 0; index < seed.photos; index++)
          RecordPhoto(
            id: '$id-photo-$index',
            sha256: '$id-sha-$index',
            storagePath: 'photos/$id/$index.jpg',
            sortOrder: index,
          ),
      ],
      caption: seed.caption,
      context: Map<String, String>.of(seed.context),
    ),
  );
}

const StorageFailure _broken = StorageFailure(
  message: 'The records could not be read.',
  recoveryAction: 'Try again.',
);

void main() {
  late FakeRecordRepository fake;

  setUp(() {
    fake = FakeRecordRepository();
  });

  tearDown(() {
    fake.dispose();
  });

  runRecordRepositoryContract(
    () => fake,
    seedRecord: seedFake,
    seedTemplate: (RecordRepository repo, TemplateSeed seed) async {
      (repo as FakeRecordRepository).seedTemplate(
        seed.id,
        name: seed.name,
        fieldKeys: seed.fieldKeys,
      );
    },
  );

  group('the fake', () {
    test('a read failure errors every stream and fails every read', () async {
      final String id = await seedFake(fake, const RecordSeed());
      fake.readFailure = _broken;
      await expectLater(fake.watchEntry(id), emitsError(same(_broken)));
      await expectLater(
        fake.watchPage(
          'project-1',
          filter: RecordFilter.none,
          sort: RecordSort.newestFirst,
          offset: 0,
          limit: 10,
        ),
        emitsError(same(_broken)),
      );
      await expectLater(fake.watchBin(), emitsError(same(_broken)));
      expect(failureOf(await fake.byId(id)), same(_broken));
      expect(failureOf(await fake.facets('project-1')), same(_broken));
    });

    test('a write failure fails every write and changes nothing', () async {
      final String id = await seedFake(fake, const RecordSeed());
      fake.writeFailure = _broken;
      expect(
        failureOf(await fake.transition(id, RecordStatus.needsReview)),
        same(_broken),
      );
      expect(failureOf(await fake.delete(id, reason: 'x')), same(_broken));
      expect(
        failureOf(
          await fake.save((
            projectId: 'project-1',
            templateId: 'template-1',
            fields: const <String, String>{},
            context: const <String, String>{},
          )),
        ),
        same(_broken),
      );
      expect(fake.entryOf(id)?.status, RecordStatus.captured);
      expect(fake.writes, isEmpty);
    });

    test('a per-record failure leaves the other records writable', () async {
      final List<String> ids = fake.seedMany(3);
      fake.failuresById[ids[1]] = _broken;
      final List<bool> outcomes = <bool>[
        for (final String id in ids)
          (await fake.delete(id, reason: 'Bulk')) is! FailureResult<void>,
      ];
      expect(outcomes, <bool>[true, false, true]);
      expect(fake.entryOf(ids[1])?.status, RecordStatus.captured);
      expect(
        fake.writes.map((({String method, String id}) write) => write.id),
        <String>[ids[0], ids[2]],
      );
    });

    test('ten thousand rows page without materialising a screen', () async {
      final List<String> ids = fake.seedMany(10000);
      expect(ids, hasLength(10000));
      expect(
        await fake.watchCount('project-1', RecordFilter.none).first,
        10000,
      );
      final List<RecordSummary> first = await fake
          .watchPage(
            'project-1',
            filter: RecordFilter.none,
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 50,
          )
          .first;
      expect(first, hasLength(50));
      expect(first.first.number, 10000);
      expect(first.first.name, 'Record 10000');
      final List<RecordSummary> last = await fake
          .watchPage(
            'project-1',
            filter: RecordFilter.none,
            sort: RecordSort.newestFirst,
            offset: 9990,
            limit: 50,
          )
          .first;
      expect(last.map((RecordSummary row) => row.number), <int>[
        10,
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        1,
      ]);
      final List<RecordSummary> found = await fake
          .watchPage(
            'project-1',
            filter: const RecordFilter(search: 'Record 4242'),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 50,
          )
          .first;
      expect(found.single.number, 4242);
    });

    test(
      'a seeded deletion sits in the bin and restores to its status',
      () async {
        fake
          ..clock = FixedClock(DateTime.utc(2026, 9, 27))
          ..seedProjectName('project-1', 'Hospital audit');
        final String id = fake.seedDeleted(
          RecordEntry(
            id: 'record-9',
            projectId: 'project-1',
            templateId: 'template-1',
            status: RecordStatus.approved,
            capturedAt: DateTime.utc(2026, 9),
            capturedBy: 'device-test',
            updatedAt: DateTime.utc(2026, 9),
          ),
          deletedAt: DateTime.utc(2026, 9, 20),
          reason: 'Duplicate',
          previous: RecordStatus.approved,
        );
        final DeletedRecord binned = (await fake.watchBin().first).single;
        expect(binned.projectName, 'Hospital audit');
        expect(binned.reason, 'Duplicate');
        expect(
          binned.daysLeft(now: fake.clock.nowUtc(), retentionDays: 30),
          23,
        );
        okOf(await fake.restore(id));
        expect(fake.entryOf(id)?.status, RecordStatus.approved);
        expect(fake.isTombstoned(id), isFalse);
      },
    );

    test(
      'records removed with their project are hidden and never binned',
      () async {
        fake.seedEntry(
          RecordEntry(
            id: 'record-p',
            projectId: 'project-1',
            templateId: 'template-1',
            status: RecordStatus.deleted,
            capturedAt: DateTime.utc(2026, 9),
            capturedBy: 'device-test',
            updatedAt: DateTime.utc(2026, 9),
          ),
          reason: FakeRecordRepository.projectDeletedReason,
        );
        expect(fake.isTombstoned('record-p'), isTrue);
        expect(await fake.watchBin().first, isEmpty);
        expect(await fake.watchCount('project-1', RecordFilter.none).first, 0);
      },
    );

    test('seeded facets replace the derived ones', () async {
      const RecordFacets seeded = RecordFacets(conditions: <String>['good']);
      fake.seedFacets('project-1', seeded);
      expect(okOf(await fake.facets('project-1')), seeded);
    });

    test(
      'labels name context levels and operators in derived facets',
      () async {
        fake
          ..contextLevelLabels['site'] = 'Site'
          ..operatorLabels['device-a'] = 'Ada';
        await seedFake(
          fake,
          const RecordSeed(
            context: <String, String>{'site': 'North'},
            capturedBy: 'device-a',
          ),
        );
        final RecordFacets facets = okOf(await fake.facets('project-1'));
        expect(facets.contextLevels.single.label, 'Site');
        expect(facets.operators.single.label, 'Ada');
      },
    );

    test('extra search text stands in for transcripts and OCR', () async {
      final String id = await seedFake(fake, const RecordSeed());
      fake.seedSearchText(id, 'Transcribed: pressure relief valve');
      final List<RecordSummary> rows = await fake
          .watchPage(
            'project-1',
            filter: const RecordFilter(search: 'relief'),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: 10,
          )
          .first;
      expect(rows.single.id, id);
    });

    test(
      'a template change logs a retired line per value it retires',
      () async {
        fake
          ..seedTemplate('template-1', fieldKeys: <String>['model', 'serial'])
          ..seedTemplate('template-2', fieldKeys: <String>['model']);
        final String id = await seedFake(
          fake,
          const RecordSeed(
            fields: <String, String>{'model': 'Hoist', 'serial': 'H-1'},
          ),
        );
        okOf(await fake.changeTemplate(id, 'template-2'));
        final RecordHistoryEvent retired = fake
            .historyOf(id)
            .singleWhere(
              (RecordHistoryEvent line) =>
                  line.kind == RecordHistoryKind.retired,
            );
        expect(retired.fieldKey, 'serial');
        expect(retired.previous, 'false');
        expect(retired.next, 'true');
        expect(retired.reason, 'retired');
      },
    );

    test('writes after dispose still apply without emitting', () async {
      final String id = await seedFake(fake, const RecordSeed());
      fake.dispose();
      okOf(await fake.transition(id, RecordStatus.needsReview));
      expect(fake.entryOf(id)?.status, RecordStatus.needsReview);
    });
  });
}
