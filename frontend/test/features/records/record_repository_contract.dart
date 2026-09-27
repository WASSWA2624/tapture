import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';

import 'fakes/record_results.dart';

/// One record the contract needs on the device before a test runs.
///
/// The fake holds it in memory; the Drift test writes the rows through the
/// database (a `records` row in [status], one `record_fields` row per entry
/// of [fields] with [source], [photos] live photo rows filed on it, and a
/// record caption when [caption] is set), so both run the same checks.
final class RecordSeed {
  /// Describes a record. The defaults give a captured record in
  /// `project-1` on `template-1` with no values.
  const RecordSeed({
    this.projectId = 'project-1',
    this.templateId = 'template-1',
    this.status = RecordStatus.captured,
    this.fields = const <String, String>{},
    this.source = 'ocr',
    this.context = const <String, String>{},
    this.capturedAt,
    this.capturedBy = 'device-test',
    this.photos = 0,
    this.caption = '',
  });

  /// Project the record belongs to.
  final String projectId;

  /// Template the record is filled against.
  final String templateId;

  /// Status the record starts in.
  final RecordStatus status;

  /// Raw values by field key, in order.
  final Map<String, String> fields;

  /// Stored source of every value in [fields].
  final String source;

  /// Context snapshot, level key to value, outermost first.
  final Map<String, String> context;

  /// When the record was captured; [seedInstant] when null.
  final DateTime? capturedAt;

  /// Who captured it (`records.captured_by`).
  final String capturedBy;

  /// How many live photos are filed on it.
  final int photos;

  /// The record-level caption, or empty for none.
  final String caption;

  /// The capture instant a seed without one gets.
  static final DateTime seedInstant = DateTime.utc(2026, 9, 17, 8);
}

/// One template the contract needs: [fieldKeys] are plain visible text
/// fields in that order (so the first one with a value names the record),
/// none of them an identity field.
final class TemplateSeed {
  /// Describes a template.
  const TemplateSeed({
    required this.id,
    this.projectId = 'project-1',
    this.name = '',
    this.fieldKeys = const <String>[],
  });

  /// Merge id of the template.
  final String id;

  /// Project the template belongs to.
  final String projectId;

  /// Name the facets show for it.
  final String name;

  /// Its field keys, in sort order.
  final List<String> fieldKeys;
}

/// Writes one [RecordSeed] and returns the new record's id.
typedef RecordSeeder =
    Future<String> Function(RecordRepository repo, RecordSeed seed);

/// Writes one [TemplateSeed].
typedef TemplateSeeder =
    Future<void> Function(RecordRepository repo, TemplateSeed seed);

/// The semantics every [RecordRepository] honours (FE-STATE-10, DESIGN §2):
/// reads return the record whole; transitions are validated and write
/// nothing when illegal; edits write refined values with an audit line and
/// send an approved record back to review; a template change retires
/// instead of deleting; a delete is a tombstone that hides the record from
/// lists and shows it in the bin until a restore brings it back.
///
/// [create] returns the repository under test. [seedRecord] and
/// [seedTemplate] put rows in place the way that implementation stores them.
void runRecordRepositoryContract(
  RecordRepository Function() create, {
  required RecordSeeder seedRecord,
  required TemplateSeeder seedTemplate,
}) {
  /// The repository with the two templates most tests use.
  Future<RecordRepository> ready() async {
    final RecordRepository repo = create();
    await seedTemplate(
      repo,
      const TemplateSeed(
        id: 'template-1',
        name: 'Assets',
        fieldKeys: <String>['model', 'serial', 'condition'],
      ),
    );
    await seedTemplate(
      repo,
      const TemplateSeed(
        id: 'template-2',
        name: 'Rooms',
        fieldKeys: <String>['model', 'location'],
      ),
    );
    return repo;
  }

  Future<String> seed(RecordRepository repo, [RecordSeed? spec]) {
    return seedRecord(repo, spec ?? const RecordSeed());
  }

  Future<RecordEntry> read(RecordRepository repo, String id) async {
    final RecordEntry? entry = okOf(await repo.byId(id));
    if (entry == null) {
      throw TestFailure('Record $id is not on the device.');
    }
    return entry;
  }

  Future<List<String>> page(
    RecordRepository repo, {
    String projectId = 'project-1',
    RecordFilter filter = RecordFilter.none,
    RecordSort sort = RecordSort.newestFirst,
    int offset = 0,
    int limit = 50,
  }) async {
    final List<RecordSummary> rows = await repo
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

  Future<int> count(
    RecordRepository repo, [
    RecordFilter filter = RecordFilter.none,
  ]) {
    return repo.watchCount('project-1', filter).first;
  }

  Future<List<RecordHistoryEvent>> history(RecordRepository repo, String id) {
    return repo.watchHistory(id).first;
  }

  List<RecordHistoryEvent> statusLines(List<RecordHistoryEvent> lines) {
    return <RecordHistoryEvent>[
      for (final RecordHistoryEvent line in lines)
        if (line.kind == RecordHistoryKind.statusChanged) line,
    ];
  }

  group('reading one record', () {
    test('byId of a missing record is Success(null), not a throw', () async {
      final RecordRepository repo = await ready();
      expect(okOf(await repo.byId('missing')), isNull);
      expect(await repo.watchEntry('missing').first, isNull);
    });

    test('a record reads back whole in one call', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(
          status: RecordStatus.needsReview,
          fields: <String, String>{'model': 'Autoclave', 'serial': 'SN-1'},
          context: <String, String>{'site': 'North', 'room': 'Theatre'},
          capturedBy: 'device-a',
          photos: 2,
        ),
      );
      final RecordEntry entry = await read(repo, id);
      expect(entry.id, id);
      expect(entry.projectId, 'project-1');
      expect(entry.templateId, 'template-1');
      expect(entry.status, RecordStatus.needsReview);
      expect(entry.number, isNotNull);
      expect(entry.capturedBy, 'device-a');
      expect(entry.capturedAt.isAtSameMomentAs(RecordSeed.seedInstant), isTrue);
      expect(entry.valueOf('model')?.display, 'Autoclave');
      expect(entry.valueOf('model')?.raw, 'Autoclave');
      expect(entry.valueOf('serial')?.valueSource, ValueSource.ocr);
      expect(entry.context, <String, String>{
        'site': 'North',
        'room': 'Theatre',
      });
      expect(entry.photos, hasLength(2));
      expect(entry.flags, contains(RecordFlag.hasPhotos));
      expect(entry.name, 'Autoclave');
      expect(await repo.watchEntry(id).first, entry);
    });

    test('watchEntry emits again after the record changes', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      final Future<void> moved = expectLater(
        repo.watchEntry(id).map((RecordEntry? entry) => entry?.status),
        emitsThrough(RecordStatus.needsReview),
      );
      okOf(await repo.transition(id, RecordStatus.needsReview));
      await moved;
    });
  });

  group('save', () {
    test('a record made by hand starts as a draft with its values', () async {
      final RecordRepository repo = await ready();
      final RecordEntry saved = okOf(
        await repo.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist', 'serial': 'H-9'},
          context: const <String, String>{'site': 'North'},
        )),
      );
      expect(saved.status, RecordStatus.draft);
      expect(saved.valueOf('model')?.display, 'Hoist');
      expect(saved.valueOf('serial')?.display, 'H-9');
      expect(saved.context, <String, String>{'site': 'North'});
      expect(saved.number, isNotNull);
      expect((await read(repo, saved.id)).status, RecordStatus.draft);
      expect(await page(repo), <String>[saved.id]);
    });

    test('saved records are numbered in order within their project', () async {
      final RecordRepository repo = await ready();
      final String first = await seed(repo);
      final RecordEntry second = okOf(
        await repo.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist'},
          context: const <String, String>{},
        )),
      );
      expect(second.number!, greaterThan((await read(repo, first)).number!));
    });

    test('a draft without a project or template fails validation', () async {
      final RecordRepository repo = await ready();
      for (final RecordDraft draft in <RecordDraft>[
        (
          projectId: '',
          templateId: 'template-1',
          fields: const <String, String>{},
          context: const <String, String>{},
        ),
        (
          projectId: 'project-1',
          templateId: ' ',
          fields: const <String, String>{},
          context: const <String, String>{},
        ),
      ]) {
        final Failure failure = failureOf(await repo.save(draft));
        expect(failure, isA<ValidationFailure>());
        expect(failure.recoveryAction, isNotEmpty);
      }
      expect(await page(repo), isEmpty);
    });

    test('a save writes a created line to the history', () async {
      final RecordRepository repo = await ready();
      final RecordEntry saved = okOf(
        await repo.save((
          projectId: 'project-1',
          templateId: 'template-1',
          fields: const <String, String>{'model': 'Hoist'},
          context: const <String, String>{},
        )),
      );
      final List<RecordHistoryEvent> lines = await history(repo, saved.id);
      expect(
        lines.map((RecordHistoryEvent line) => line.kind),
        contains(RecordHistoryKind.created),
      );
    });
  });

  group('transition', () {
    test('an illegal move fails validation and writes nothing', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      final List<RecordHistoryEvent> before = await history(repo, id);
      final Failure failure = failureOf(
        await repo.transition(id, RecordStatus.approved),
      );
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, isNotEmpty);
      expect(failure.recoveryAction, isNotEmpty);
      expect((await read(repo, id)).status, RecordStatus.captured);
      expect(await history(repo, id), hasLength(before.length));
    });

    test('a move to the same status fails validation', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      expect(
        failureOf(await repo.transition(id, RecordStatus.captured)),
        isA<ValidationFailure>(),
      );
    });

    test('a legal move changes the status and writes a status line', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      okOf(
        await repo.transition(id, RecordStatus.needsReview, reason: 'Check'),
      );
      expect((await read(repo, id)).status, RecordStatus.needsReview);
      final RecordHistoryEvent line = statusLines(await history(repo, id)).last;
      expect(line.previous, 'captured');
      expect(line.next, 'needsReview');
    });

    test(
      'the manual path is draft, needsReview, approved and nothing else',
      () async {
        final RecordRepository repo = await ready();
        final RecordEntry saved = okOf(
          await repo.save((
            projectId: 'project-1',
            templateId: 'template-1',
            fields: const <String, String>{'model': 'Hoist'},
            context: const <String, String>{},
          )),
        );
        okOf(await repo.transition(saved.id, RecordStatus.needsReview));
        okOf(await repo.transition(saved.id, RecordStatus.approved));
        final RecordEntry approved = await read(repo, saved.id);
        expect(approved.status, RecordStatus.approved);
        expect(approved.approvedAt, isNotNull);
        final List<String?> path = <String?>[
          for (final RecordHistoryEvent line in statusLines(
            await history(repo, saved.id),
          ))
            line.next,
        ];
        expect(path, <String>['needsReview', 'approved']);
      },
    );

    test('moves into or out of deleted belong to delete and restore', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      expect(
        failureOf(await repo.transition(id, RecordStatus.deleted)),
        isA<ValidationFailure>(),
      );
      expect((await read(repo, id)).status, RecordStatus.captured);
      expect(await repo.watchBin().first, isEmpty);
      okOf(await repo.delete(id, reason: 'Duplicate'));
      expect(
        failureOf(await repo.transition(id, RecordStatus.captured)),
        isA<ValidationFailure>(),
      );
      expect((await read(repo, id)).status, RecordStatus.deleted);
    });

    test('a move on a missing record is a StorageFailure', () async {
      final RecordRepository repo = await ready();
      expect(
        failureOf(await repo.transition('missing', RecordStatus.queued)),
        isA<StorageFailure>(),
      );
    });
  });

  group('editValues', () {
    test(
      'an edit is refined, manual, verified and audited from what showed',
      () async {
        final RecordRepository repo = await ready();
        final String id = await seed(
          repo,
          const RecordSeed(
            status: RecordStatus.approved,
            fields: <String, String>{'model': 'Autoclave', 'serial': 'SN-1'},
          ),
        );
        okOf(
          await repo.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
          ]),
        );
        final RecordEntry edited = await read(repo, id);
        final RecordValue model = edited.valueOf('model')!;
        expect(model.display, 'Sterilizer');
        expect(model.refined, 'Sterilizer');
        expect(model.raw, 'Autoclave');
        expect(model.valueSource, ValueSource.manual);
        expect(model.verified, isTrue);
        expect(edited.valueOf('serial')?.display, 'SN-1');
        expect(edited.status, RecordStatus.needsReview);
        final List<RecordHistoryEvent> lines = await history(repo, id);
        final RecordHistoryEvent change = lines.lastWhere(
          (RecordHistoryEvent line) =>
              line.kind == RecordHistoryKind.valueChanged,
        );
        expect(change.fieldKey, 'model');
        expect(change.previous, 'Autoclave');
        expect(change.next, 'Sterilizer');
        final RecordHistoryEvent status = statusLines(lines).last;
        expect(status.previous, 'approved');
        expect(status.next, 'needsReview');
      },
    );

    test('an edit of a record under review keeps its status', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(
          status: RecordStatus.needsReview,
          fields: <String, String>{'model': 'Autoclave'},
        ),
      );
      okOf(
        await repo.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Sterilizer'),
        ]),
      );
      expect((await read(repo, id)).status, RecordStatus.needsReview);
    });

    test('an edit of a field with no value adds it', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(fields: <String, String>{'model': 'Autoclave'}),
      );
      okOf(
        await repo.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'serial', value: 'SN-7'),
        ]),
      );
      final RecordValue serial = (await read(repo, id)).valueOf('serial')!;
      expect(serial.display, 'SN-7');
      expect(serial.valueSource, ValueSource.manual);
    });

    test('an edit that changes nothing writes nothing', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(
          status: RecordStatus.approved,
          fields: <String, String>{'model': 'Autoclave'},
        ),
      );
      final int lines = (await history(repo, id)).length;
      okOf(
        await repo.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Autoclave'),
        ]),
      );
      expect((await read(repo, id)).status, RecordStatus.approved);
      expect(await history(repo, id), hasLength(lines));
    });

    test('a deleted record refuses edits until it is restored', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(fields: <String, String>{'model': 'Autoclave'}),
      );
      okOf(await repo.delete(id, reason: 'Duplicate'));
      expect(
        failureOf(
          await repo.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
          ]),
        ),
        isA<ValidationFailure>(),
      );
      expect((await read(repo, id)).valueOf('model')?.display, 'Autoclave');
    });

    test('an edit of a missing record is a StorageFailure', () async {
      final RecordRepository repo = await ready();
      expect(
        failureOf(
          await repo.editValues('missing', const <RecordValueEdit>[
            (fieldKey: 'model', value: 'x'),
          ]),
        ),
        isA<StorageFailure>(),
      );
    });
  });

  group('template change', () {
    Future<String> onFirst(RecordRepository repo, RecordStatus status) {
      return seed(
        repo,
        RecordSeed(
          status: status,
          fields: const <String, String>{
            'model': 'Autoclave',
            'serial': 'SN-1',
            'condition': 'good',
          },
        ),
      );
    }

    test(
      'the plan maps, retires and adds by field key and changes nothing',
      () async {
        final RecordRepository repo = await ready();
        final String id = await onFirst(repo, RecordStatus.approved);
        final TemplateChangePlan plan = okOf(
          await repo.planTemplateChange(id, 'template-2'),
        );
        expect(plan.fromTemplateId, 'template-1');
        expect(plan.toTemplateId, 'template-2');
        expect(plan.mapped, <String>['model']);
        expect(plan.retired.toSet(), <String>{'serial', 'condition'});
        expect(plan.added, <String>['location']);
        expect(plan.restored, isEmpty);
        final RecordEntry entry = await read(repo, id);
        expect(entry.templateId, 'template-1');
        expect(entry.status, RecordStatus.approved);
      },
    );

    test(
      'unmapped values are kept as retired and approved goes to review',
      () async {
        final RecordRepository repo = await ready();
        final String id = await onFirst(repo, RecordStatus.approved);
        okOf(await repo.changeTemplate(id, 'template-2'));
        final RecordEntry moved = await read(repo, id);
        expect(moved.templateId, 'template-2');
        expect(moved.status, RecordStatus.needsReview);
        expect(moved.values, hasLength(3));
        expect(moved.valueOf('model')?.retired, isFalse);
        expect(moved.valueOf('serial')?.retired, isTrue);
        expect(moved.valueOf('serial')?.display, 'SN-1');
        expect(moved.valueOf('condition')?.retired, isTrue);
        expect(
          (await history(repo, id)).map((RecordHistoryEvent line) => line.kind),
          contains(RecordHistoryKind.templateChanged),
        );
      },
    );

    test('changing back brings the retired values back', () async {
      final RecordRepository repo = await ready();
      final String id = await onFirst(repo, RecordStatus.needsReview);
      okOf(await repo.changeTemplate(id, 'template-2'));
      final TemplateChangePlan back = okOf(
        await repo.planTemplateChange(id, 'template-1'),
      );
      expect(back.restored.toSet(), <String>{'serial', 'condition'});
      expect(back.retired, isEmpty);
      okOf(await repo.changeTemplate(id, 'template-1'));
      final RecordEntry entry = await read(repo, id);
      expect(entry.templateId, 'template-1');
      expect(entry.retiredValues, isEmpty);
      expect(entry.valueOf('serial')?.display, 'SN-1');
    });

    test('moving to the template in use fails validation', () async {
      final RecordRepository repo = await ready();
      final String id = await onFirst(repo, RecordStatus.captured);
      expect(
        failureOf(await repo.planTemplateChange(id, 'template-1')),
        isA<ValidationFailure>(),
      );
      expect(
        failureOf(await repo.changeTemplate(id, 'template-1')),
        isA<ValidationFailure>(),
      );
    });

    test(
      'moving to a template not on the device fails and changes nothing',
      () async {
        final RecordRepository repo = await ready();
        final String id = await onFirst(repo, RecordStatus.approved);
        failureOf(await repo.changeTemplate(id, 'template-missing'));
        final RecordEntry entry = await read(repo, id);
        expect(entry.templateId, 'template-1');
        expect(entry.status, RecordStatus.approved);
        expect(entry.retiredValues, isEmpty);
      },
    );
  });

  group('delete and restore', () {
    test('a delete tombstones the record, hides it and bins it', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(
          status: RecordStatus.approved,
          fields: <String, String>{'model': 'Autoclave'},
        ),
      );
      okOf(await repo.delete(id, reason: 'Duplicate'));
      final RecordEntry deleted = await read(repo, id);
      expect(deleted.status, RecordStatus.deleted);
      expect(deleted.valueOf('model')?.display, 'Autoclave');
      expect((await repo.watchEntry(id).first)?.status, RecordStatus.deleted);
      expect(await page(repo), isEmpty);
      expect(await count(repo), 0);
      final DeletedRecord binned = (await repo.watchBin().first).single;
      expect(binned.id, id);
      expect(binned.reason, 'Duplicate');
      expect(binned.summary.status, RecordStatus.deleted);
    });

    test(
      'a deleted record is not listed even when its status is asked for',
      () async {
        final RecordRepository repo = await ready();
        final String id = await seed(repo);
        okOf(await repo.delete(id, reason: 'Duplicate'));
        final RecordFilter asked = RecordFilter.forStatus(RecordStatus.deleted);
        expect(await page(repo, filter: asked), isEmpty);
        expect(await count(repo, asked), 0);
      },
    );

    test('a restore returns the previous status and leaves the bin', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(status: RecordStatus.approved),
      );
      okOf(await repo.delete(id, reason: 'Duplicate'));
      okOf(await repo.restore(id));
      expect((await read(repo, id)).status, RecordStatus.approved);
      expect(await repo.watchBin().first, isEmpty);
      expect(await page(repo), <String>[id]);
      final List<RecordHistoryEvent> lines = statusLines(
        await history(repo, id),
      );
      expect(
        <String?>[
          for (final RecordHistoryEvent line in lines) line.next,
        ].sublist(lines.length - 2),
        <String>['deleted', 'approved'],
      );
    });

    test('a delete needs a reason', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      expect(
        failureOf(await repo.delete(id, reason: '  ')),
        isA<ValidationFailure>(),
      );
      expect(await page(repo), <String>[id]);
      expect(await repo.watchBin().first, isEmpty);
    });

    test(
      'deleting twice fails validation; a missing record is storage',
      () async {
        final RecordRepository repo = await ready();
        final String id = await seed(repo);
        okOf(await repo.delete(id, reason: 'Duplicate'));
        expect(
          failureOf(await repo.delete(id, reason: 'Again')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await repo.delete('missing', reason: 'Gone')),
          isA<StorageFailure>(),
        );
      },
    );

    test('restoring a record not in the bin fails validation', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      expect(failureOf(await repo.restore(id)), isA<ValidationFailure>());
      expect(failureOf(await repo.restore('missing')), isA<StorageFailure>());
      expect((await read(repo, id)).status, RecordStatus.captured);
    });

    test('the bin lists deleted records from every project', () async {
      final RecordRepository repo = await ready();
      final String first = await seed(repo);
      final String second = await seed(
        repo,
        const RecordSeed(projectId: 'project-2'),
      );
      okOf(await repo.delete(first, reason: 'Duplicate'));
      okOf(await repo.delete(second, reason: 'Wrong site'));
      final List<DeletedRecord> bin = await repo.watchBin().first;
      expect(bin.map((DeletedRecord row) => row.id).toSet(), <String>{
        first,
        second,
      });
    });
  });

  group('watchPage and watchCount', () {
    test('newest number first, paged by offset and limit', () async {
      final RecordRepository repo = await ready();
      final List<String> ids = <String>[
        for (int index = 0; index < 5; index++) await seed(repo),
      ];
      expect(await page(repo, limit: 2), <String>[ids[4], ids[3]]);
      expect(await page(repo, offset: 2, limit: 2), <String>[ids[2], ids[1]]);
      expect(await page(repo, offset: 4, limit: 2), <String>[ids[0]]);
      expect(await page(repo, offset: 5, limit: 2), isEmpty);
      expect(await count(repo), 5);
    });

    test('number, capture date and name each sort both ways', () async {
      final RecordRepository repo = await ready();
      final String charlie = await seed(
        repo,
        RecordSeed(
          fields: const <String, String>{'model': 'Charlie'},
          capturedAt: DateTime.utc(2026, 9, 2),
        ),
      );
      final String alpha = await seed(
        repo,
        RecordSeed(
          fields: const <String, String>{'model': 'alpha'},
          capturedAt: DateTime.utc(2026, 9, 3),
        ),
      );
      final String bravo = await seed(
        repo,
        RecordSeed(
          fields: const <String, String>{'model': 'Bravo'},
          capturedAt: DateTime.utc(2026, 9, 1),
        ),
      );
      final Map<RecordSortKey, List<String>> ascending =
          <RecordSortKey, List<String>>{
            RecordSortKey.number: <String>[charlie, alpha, bravo],
            RecordSortKey.capturedAt: <String>[bravo, charlie, alpha],
            RecordSortKey.name: <String>[alpha, bravo, charlie],
          };
      for (final MapEntry<RecordSortKey, List<String>> expected
          in ascending.entries) {
        expect(
          await page(
            repo,
            sort: RecordSort(key: expected.key, ascending: true),
          ),
          expected.value,
          reason: '${expected.key.stored} ascending',
        );
        expect(
          await page(repo, sort: RecordSort(key: expected.key)),
          expected.value.reversed.toList(),
          reason: '${expected.key.stored} descending',
        );
      }
    });

    test('archived records are listed only when asked for', () async {
      final RecordRepository repo = await ready();
      final String live = await seed(repo);
      final String archived = await seed(
        repo,
        const RecordSeed(status: RecordStatus.archived),
      );
      expect(await page(repo), <String>[live]);
      final RecordFilter asked = RecordFilter.forStatus(RecordStatus.archived);
      expect(await page(repo, filter: asked), <String>[archived]);
      expect(await count(repo), 1);
      expect(await count(repo, asked), 1);
    });

    test(
      'status, template, operator and date filters combine with AND',
      () async {
        final RecordRepository repo = await ready();
        final String first = await seed(
          repo,
          RecordSeed(capturedBy: 'device-a', capturedAt: DateTime.utc(2026, 9)),
        );
        final String second = await seed(
          repo,
          RecordSeed(
            templateId: 'template-2',
            capturedBy: 'device-b',
            capturedAt: DateTime.utc(2026, 9, 10),
          ),
        );
        final String third = await seed(
          repo,
          RecordSeed(
            status: RecordStatus.needsReview,
            capturedBy: 'device-a',
            capturedAt: DateTime.utc(2026, 9, 20),
          ),
        );
        const RecordFilter onFirst = RecordFilter(
          templateIds: <String>{'template-1'},
        );
        expect(await page(repo, filter: onFirst), <String>[third, first]);
        expect(
          await page(
            repo,
            filter: onFirst.copyWith(
              statuses: <RecordStatus>{RecordStatus.captured},
            ),
          ),
          <String>[first],
        );
        expect(
          await page(
            repo,
            filter: RecordFilter(
              operators: const <String>{'device-a'},
              capturedFrom: DateTime.utc(2026, 9, 5),
            ),
          ),
          <String>[third],
        );
        expect(
          await page(
            repo,
            filter: RecordFilter(capturedTo: DateTime.utc(2026, 9, 10)),
          ),
          <String>[second, first],
        );
        expect(
          await count(
            repo,
            const RecordFilter(operators: <String>{'device-b'}),
          ),
          1,
        );
      },
    );

    test(
      'context and condition filters match the snapshot and values',
      () async {
        final RecordRepository repo = await ready();
        final String north = await seed(
          repo,
          const RecordSeed(
            fields: <String, String>{'model': 'Hoist', 'condition': 'good'},
            context: <String, String>{'site': 'North'},
          ),
        );
        final String east = await seed(
          repo,
          const RecordSeed(
            fields: <String, String>{'model': 'Lift', 'condition': 'poor'},
            context: <String, String>{'site': 'East'},
          ),
        );
        expect(
          await page(
            repo,
            filter: const RecordFilter(
              context: <String, Set<String>>{
                'site': <String>{'North'},
              },
            ),
          ),
          <String>[north],
        );
        expect(
          await page(
            repo,
            filter: const RecordFilter(conditions: <String>{'poor'}),
          ),
          <String>[east],
        );
        expect(
          await page(
            repo,
            filter: const RecordFilter(
              context: <String, Set<String>>{
                'site': <String>{'North'},
              },
              conditions: <String>{'poor'},
            ),
          ),
          isEmpty,
        );
      },
    );

    test('the photos flag lists only records with photos', () async {
      final RecordRepository repo = await ready();
      final String withPhoto = await seed(repo, const RecordSeed(photos: 1));
      await seed(repo);
      expect(
        await page(
          repo,
          filter: const RecordFilter(flags: <RecordFlag>{RecordFlag.hasPhotos}),
        ),
        <String>[withPhoto],
      );
      final RecordSummary row =
          (await repo
                  .watchPage(
                    'project-1',
                    filter: RecordFilter.none,
                    sort: RecordSort.newestFirst,
                    offset: 1,
                    limit: 1,
                  )
                  .first)
              .single;
      expect(row.id, withPhoto);
      expect(row.photoCount, 1);
      expect(row.thumb, isNotNull);
      expect(row.has(RecordFlag.hasPhotos), isTrue);
    });

    test('search finds text inside values and captions', () async {
      final RecordRepository repo = await ready();
      final String autoclave = await seed(
        repo,
        const RecordSeed(fields: <String, String>{'model': 'Autoclave'}),
      );
      final String centrifuge = await seed(
        repo,
        const RecordSeed(
          fields: <String, String>{'model': 'Centrifuge'},
          caption: 'Next to the sink',
        ),
      );
      expect(
        await page(repo, filter: const RecordFilter(search: 'clave')),
        <String>[autoclave],
      );
      expect(
        await page(repo, filter: const RecordFilter(search: 'toclav')),
        <String>[autoclave],
      );
      expect(
        await page(repo, filter: const RecordFilter(search: 'sink')),
        <String>[centrifuge],
      );
      expect(
        await count(repo, const RecordFilter(search: 'centrifuge sink')),
        1,
      );
      expect(
        await count(repo, const RecordFilter(search: 'zz')),
        2,
        reason: 'a word too short to index narrows nothing',
      );
    });

    test('search finds an edited value straight after the edit', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(fields: <String, String>{'model': 'Centrifuge'}),
      );
      okOf(
        await repo.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Sterilizer'),
        ]),
      );
      expect(
        await page(repo, filter: const RecordFilter(search: 'steril')),
        <String>[id],
      );
    });

    test('the page emits again after a write', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(repo);
      final RecordFilter review = RecordFilter.forStatus(
        RecordStatus.needsReview,
      );
      final Future<void> listed = expectLater(
        repo
            .watchPage(
              'project-1',
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
        emitsThrough(<String>[id]),
      );
      final Future<void> counted = expectLater(
        repo.watchCount('project-1', review),
        emitsThrough(1),
      );
      okOf(await repo.transition(id, RecordStatus.needsReview));
      await listed;
      await counted;
    });

    test("another project's records are never listed", () async {
      final RecordRepository repo = await ready();
      await seed(repo, const RecordSeed(projectId: 'project-2'));
      expect(await page(repo), isEmpty);
      expect(await count(repo), 0);
      expect(await page(repo, projectId: 'project-2'), hasLength(1));
    });
  });

  group('facets', () {
    test('facets offer what the live records use', () async {
      final RecordRepository repo = await ready();
      await seedTemplate(
        repo,
        const TemplateSeed(id: 'template-3', name: 'Vehicles'),
      );
      await seed(
        repo,
        const RecordSeed(
          fields: <String, String>{'condition': 'good'},
          context: <String, String>{'site': 'North'},
          capturedBy: 'device-a',
        ),
      );
      await seed(
        repo,
        const RecordSeed(
          templateId: 'template-2',
          status: RecordStatus.approved,
          fields: <String, String>{'model': 'Lift'},
          context: <String, String>{'site': 'East'},
          capturedBy: 'device-b',
        ),
      );
      await seed(
        repo,
        const RecordSeed(
          fields: <String, String>{'condition': 'poor'},
          capturedBy: 'device-a',
        ),
      );
      final String gone = await seed(
        repo,
        const RecordSeed(
          templateId: 'template-3',
          fields: <String, String>{'condition': 'faulty'},
          context: <String, String>{'site': 'West'},
          capturedBy: 'device-c',
        ),
      );
      okOf(await repo.delete(gone, reason: 'Duplicate'));
      final RecordFacets facets = okOf(await repo.facets('project-1'));
      expect(
        <String, String>{
          for (final ({String id, String name}) template in facets.templates)
            template.id: template.name,
        },
        <String, String>{'template-1': 'Assets', 'template-2': 'Rooms'},
      );
      final ({String key, String label, List<String> values}) site = facets
          .contextLevels
          .singleWhere(
            (({String key, String label, List<String> values}) level) =>
                level.key == 'site',
          );
      expect(site.values.toSet(), <String>{'North', 'East'});
      expect(
        facets.operators
            .map((({String id, String label}) row) => row.id)
            .toSet(),
        <String>{'device-a', 'device-b'},
      );
      expect(facets.conditions.toSet(), <String>{'good', 'poor'});
      expect(facets.statuses, <RecordStatus>{
        RecordStatus.captured,
        RecordStatus.approved,
      });
    });

    test('a project with no records offers nothing', () async {
      final RecordRepository repo = await ready();
      expect(okOf(await repo.facets('project-empty')).isEmpty, isTrue);
    });
  });

  group('history', () {
    test('history reads oldest first, one line per change', () async {
      final RecordRepository repo = await ready();
      final String id = await seed(
        repo,
        const RecordSeed(fields: <String, String>{'model': 'Hoist'}),
      );
      okOf(await repo.transition(id, RecordStatus.needsReview));
      okOf(
        await repo.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Crane'),
        ]),
      );
      okOf(await repo.transition(id, RecordStatus.approved));
      final List<RecordHistoryEvent> lines = await history(repo, id);
      final List<RecordHistoryKind> kinds = <RecordHistoryKind>[
        for (final RecordHistoryEvent line in lines)
          if (line.kind == RecordHistoryKind.statusChanged ||
              line.kind == RecordHistoryKind.valueChanged)
            line.kind,
      ];
      expect(kinds.sublist(kinds.length - 3), <RecordHistoryKind>[
        RecordHistoryKind.statusChanged,
        RecordHistoryKind.valueChanged,
        RecordHistoryKind.statusChanged,
      ]);
      for (int index = 1; index < lines.length; index++) {
        expect(lines[index].at.isBefore(lines[index - 1].at), isFalse);
      }
      expect(lines.last.device, isNotEmpty);
    });

    test('a record with no history reads as an empty list', () async {
      final RecordRepository repo = await ready();
      expect(await history(repo, 'missing'), isEmpty);
    });
  });
}
