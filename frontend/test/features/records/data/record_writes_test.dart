import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/data/record_writes.dart';
import 'package:tapture/features/records/domain/domain.dart';

import '../../../core/db/record_rows.dart';
import '../fakes/record_results.dart';

void main() {
  late AppDatabase db;
  late RecordWrites writes;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  RecordWrites writesAs(String Function()? operatorName) {
    return RecordWrites(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(t0)),
      operatorName: operatorName,
    );
  }

  setUp(() async {
    db = AppDatabase.memory();
    writes = writesAs(() => 'Ada');
    await _seedTemplate(
      db,
      'template-1',
      fieldKeys: <String>['model', 'serial', 'condition'],
    );
    await _seedTemplate(
      db,
      'template-2',
      fieldKeys: <String>['model', 'location'],
    );
    await _seedTemplate(
      db,
      'template-elsewhere',
      projectId: 'project-2',
      fieldKeys: <String>['model'],
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// A record in project-1 on [templateId] in [status], with a raw value per
  /// entry of [fields] (value ids `<id>-<key>`, source `ocr`).
  Future<String> record(
    String id, {
    String status = 'captured',
    String templateId = 'template-1',
    String? templateRowId,
    Map<String, String> fields = const <String, String>{},
  }) async {
    await seedRecord(
      db,
      id,
      projectId: 'project-1',
      templateId: templateId,
      templateRowId: templateRowId,
      status: status,
    );
    for (final MapEntry<String, String> field in fields.entries) {
      await seedField(
        db,
        '$id-${field.key}',
        recordId: id,
        fieldKey: field.key,
        raw: field.value,
      );
    }
    return id;
  }

  group('save', () {
    test(
      'a record made by hand is a draft with its typed values, its context and one created line',
      () async {
        final String id = okOf(
          await writes.save((
            projectId: 'project-1',
            templateId: 'template-1',
            fields: const <String, String>{
              'model': 'Hoist',
              'serial': 'H-9',
              ' ': 'no key',
              'condition': '',
            },
            context: const <String, String>{'site': 'North', 'room': 'Plant'},
          )),
        );

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['project_id'], 'project-1');
        expect(row['template_id'], 'template-1');
        expect(row['status'], 'draft');
        expect(row['processing_mode'], RecordWrites.manualSource);
        expect(row['source'], RecordWrites.manualSource);
        expect(jsonDecode(row['context_json']! as String), <String, String>{
          'site': 'North',
          'room': 'Plant',
        });
        expect(
          row['identity_hash'],
          sha256.convert(utf8.encode(id)).toString(),
        );
        expect(row['captured_at'], _seconds(t0));
        expect(row['captured_by'], 'device-a');
        expect(row['record_number'], 1);
        expect(row['rev'], 1);

        final List<Map<String, Object?>> values = await _values(db, id);
        expect(
          <String?>[
            for (final Map<String, Object?> value in values)
              value['field_key'] as String?,
          ],
          <String>['model', 'serial'],
        );
        for (final Map<String, Object?> value in values) {
          expect(value['source'], RecordWrites.typedSource);
          expect(value['verified'], 0);
          expect(value['value_refined'], isNull);
        }
        expect(values.first['value_raw'], 'Hoist');

        final List<Map<String, Object?>> audit = await _audit(db, id);
        expect(audit.first, <String, Object?>{
          'action': 'created',
          'field_key': null,
          'previous_value': null,
          'new_value': 'draft',
          'reason': RecordWrites.manualSource,
          'operator': 'Ada',
          'device': 'device-a',
        });
        expect(
          audit.where((Map<String, Object?> line) => line['field_key'] == null),
          hasLength(1),
        );
        expect(
          <Object?>[
            for (final Map<String, Object?> line in audit.skip(1))
              line['field_key'],
          ],
          <String>['model', 'serial'],
        );
        expect(await _pendingDocuments(db), 0);
      },
    );

    test('saved records take the next number in their own project', () async {
      await seedRecord(
        db,
        'seeded',
        projectId: 'project-1',
        templateId: 'template-1',
      );
      final String first = okOf(await writes.save(_draft()));
      final String second = okOf(await writes.save(_draft()));
      final String elsewhere = okOf(
        await writes.save(
          _draft(projectId: 'project-2', templateId: 'template-elsewhere'),
        ),
      );

      expect(await numberOf(db, 'seeded'), 1);
      expect(await numberOf(db, first), 2);
      expect(await numberOf(db, second), 3);
      expect(await numberOf(db, elsewhere), 1);
    });

    test('a save indexes the record in the same transaction', () async {
      final String id = okOf(
        await writes.save(
          _draft(fields: const <String, String>{'model': 'Hoist'}),
        ),
      );

      expect(await searchRecords(db, 'hoist'), <String>[id]);
      final ({String projectId, String name, String identifier})? doc =
          await searchDoc(db, id);
      expect(doc?.projectId, 'project-1');
      expect(doc?.name, 'Hoist');
      expect(await _pendingDocuments(db), 0);
    });

    test(
      'a draft without a project or template fails validation and writes nothing',
      () async {
        for (final RecordDraft draft in <RecordDraft>[
          _draft(projectId: ''),
          _draft(templateId: '  '),
        ]) {
          final Failure failure = failureOf(await writes.save(draft));
          expect(failure, isA<ValidationFailure>());
          expect(failure.recoveryAction, isNotEmpty);
        }
        expect(await _count(db, 'records'), 0);
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test(
      'a template not on this device, removed, or of another project is refused without a write',
      () async {
        await writeTombstone(
          db,
          entityType: 'templates',
          entityId: 'template-2',
          reason: 'Removed from the project.',
        );

        expect(
          failureOf(await writes.save(_draft(templateId: 'template-missing'))),
          isA<StorageFailure>(),
        );
        expect(
          failureOf(await writes.save(_draft(templateId: 'template-2'))),
          isA<StorageFailure>(),
        );
        expect(
          failureOf(
            await writes.save(_draft(templateId: 'template-elsewhere')),
          ),
          isA<ValidationFailure>(),
        );
        expect(await _count(db, 'records'), 0);
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test('a failed value insert rolls the whole save back', () async {
      await _failWhen(db, 'record_fields', 'NEW.field_key = \'serial\'');

      final Failure failure = failureOf(
        await writes.save(
          _draft(
            fields: const <String, String>{'model': 'Hoist', 'serial': 'H-9'},
          ),
        ),
      );

      expect(failure, isA<StorageFailure>());
      expect(await _count(db, 'records'), 0);
      expect(await _count(db, 'record_fields'), 0);
      expect(await _count(db, 'audit_log'), 0);
      expect(await _count(db, 'record_search_docs'), 0);
      expect(await searchRecords(db, 'hoist'), isEmpty);
      expect(await _pendingDocuments(db), 0);
    });
  });

  group('transition', () {
    test(
      'a legal move writes the status, one revision and one status line',
      () async {
        final String id = await record('r1');

        okOf(
          await writes.transition(
            id,
            RecordStatus.needsReview,
            reason: 'Check',
          ),
        );

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['status'], 'needsReview');
        expect(row['rev'], 2);
        expect(row['updated_at'], _seconds(t0));
        expect(row['updated_by_device'], 'device-a');
        expect(row['approved_at'], isNull);
        expect(await _audit(db, id), <Map<String, Object?>>[
          <String, Object?>{
            'action': 'updated',
            'field_key': 'status',
            'previous_value': 'captured',
            'new_value': 'needsReview',
            'reason': 'Check',
            'operator': 'Ada',
            'device': 'device-a',
          },
        ]);
      },
    );

    test('an illegal move fails validation and writes nothing', () async {
      final String id = await record('r1');
      final Map<String, Object?> before = await _row(db, 'records', id);

      final Failure failure = failureOf(
        await writes.transition(id, RecordStatus.approved),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, isNotEmpty);
      expect(failure.recoveryAction, isNotEmpty);
      expect(await _row(db, 'records', id), before);
      expect(await _count(db, 'audit_log'), 0);
    });

    test(
      'a move to the same status, into deleted or out of deleted fails validation',
      () async {
        final String live = await record('live');
        final String binned = await record('binned', status: 'deleted');
        final Map<String, Object?> liveBefore = await _row(db, 'records', live);
        final Map<String, Object?> binnedBefore = await _row(
          db,
          'records',
          binned,
        );

        for (final Result<void> refused in <Result<void>>[
          await writes.transition(live, RecordStatus.captured),
          await writes.transition(live, RecordStatus.deleted),
          await writes.transition(binned, RecordStatus.captured),
        ]) {
          expect(failureOf(refused), isA<ValidationFailure>());
        }
        expect(await _row(db, 'records', live), liveBefore);
        expect(await _row(db, 'records', binned), binnedBefore);
        expect(await _count(db, 'audit_log'), 0);
        expect(await _count(db, 'tombstones'), 0);
      },
    );

    test('a move on a missing record is a StorageFailure', () async {
      expect(
        failureOf(await writes.transition('missing', RecordStatus.queued)),
        isA<StorageFailure>(),
      );
      expect(await _count(db, 'audit_log'), 0);
    });

    test(
      'a status this app does not know is refused without a write',
      () async {
        final String id = await record('r1', status: 'shelved');

        expect(
          failureOf(await writes.transition(id, RecordStatus.needsReview)),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.moveToBin(id, reason: 'Duplicate')),
          isA<ValidationFailure>(),
        );
        expect(await statusOf(db, id), 'shelved');
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test(
      'the manual path is draft, needsReview, approved with no processing state in the audit trail',
      () async {
        final String id = okOf(
          await writes.save(
            _draft(fields: const <String, String>{'model': 'Hoist'}),
          ),
        );
        okOf(await writes.transition(id, RecordStatus.needsReview));
        okOf(await writes.transition(id, RecordStatus.approved));

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['status'], 'approved');
        expect(row['approved_at'], _seconds(t0));
        expect(row['approved_by'], 'Ada');
        expect(await _statusPath(db, id), <String>['needsReview', 'approved']);

        const Set<String> processing = <String>{
          'captured',
          'queued',
          'processing',
          'extracted',
          'failed',
        };
        for (final Map<String, Object?> line in await _audit(db, id)) {
          expect(processing.contains(line['previous_value']), isFalse);
          expect(processing.contains(line['new_value']), isFalse);
        }
      },
    );

    test(
      'the operator comes from the device profile when none is given, and a blank one stamps none',
      () async {
        await ensureDeviceProfile(
          db,
          deviceId: 'device-a',
          operatorName: 'Grace',
        );
        final String named = await record('named', status: 'needsReview');
        final String blank = await record('blank', status: 'needsReview');

        okOf(await writesAs(null).transition(named, RecordStatus.approved));
        okOf(
          await writesAs(() => '  ').transition(blank, RecordStatus.approved),
        );

        expect((await _row(db, 'records', named))['approved_by'], 'Grace');
        expect((await _audit(db, named)).single['operator'], 'Grace');
        final Map<String, Object?> unnamed = await _row(db, 'records', blank);
        expect(unnamed['approved_at'], _seconds(t0));
        expect(unnamed['approved_by'], isNull);
        expect((await _audit(db, blank)).single['operator'], '');
        expect((await _audit(db, blank)).single['device'], 'device-a');
      },
    );
  });

  group('editValues', () {
    test(
      'editing an approved record sends it to review with the previous and new value audited',
      () async {
        final String id = await record(
          'r1',
          status: 'approved',
          fields: const <String, String>{
            'model': 'Autoclave',
            'serial': 'SN-1',
          },
        );
        await db.customStatement(
          "UPDATE record_fields SET value_final = 'AUTOCLAVE' WHERE id = ?",
          <Object?>['r1-model'],
        );

        okOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
          ]),
        );

        final Map<String, Object?> model = await _row(
          db,
          'record_fields',
          'r1-model',
        );
        expect(model['value_raw'], 'Autoclave');
        expect(model['value_refined'], 'Sterilizer');
        expect(model['value_final'], isNull);
        expect(model['source'], 'manual');
        expect(model['verified'], 1);
        expect(model['verified_by'], 'Ada');
        expect(model['verified_at'], _seconds(t0));
        expect(model['rev'], 2);
        expect((await _row(db, 'record_fields', 'r1-serial'))['rev'], 1);

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['status'], 'needsReview');
        expect(row['rev'], 2);
        expect(await _audit(db, id), <Map<String, Object?>>[
          <String, Object?>{
            'action': 'updated',
            'field_key': 'model',
            'previous_value': 'AUTOCLAVE',
            'new_value': 'Sterilizer',
            'reason': null,
            'operator': 'Ada',
            'device': 'device-a',
          },
          <String, Object?>{
            'action': 'updated',
            'field_key': 'status',
            'previous_value': 'approved',
            'new_value': 'needsReview',
            'reason': RecordWrites.editedReason,
            'operator': 'Ada',
            'device': 'device-a',
          },
        ]);
      },
    );

    test(
      'a failure mid-way leaves the value, status, audit and search index as they were',
      () async {
        final String id = await record(
          'r1',
          status: 'approved',
          fields: const <String, String>{'model': 'Autoclave'},
        );
        final Map<String, Object?> recordBefore = await _row(db, 'records', id);
        final Map<String, Object?> valueBefore = await _row(
          db,
          'record_fields',
          'r1-model',
        );
        final ({String projectId, String name, String identifier})? docBefore =
            await searchDoc(db, id);
        // The value and its audit row are written; the status row then fails.
        await _failWhen(db, 'audit_log', "NEW.field_key = 'status'");

        final Failure failure = failureOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
            (fieldKey: 'serial', value: 'SN-9'),
          ]),
        );

        expect(failure, isA<StorageFailure>());
        expect(await _row(db, 'records', id), recordBefore);
        expect(await _row(db, 'record_fields', 'r1-model'), valueBefore);
        expect(await _values(db, id), hasLength(1));
        expect(await _count(db, 'audit_log'), 0);
        expect(await searchRecords(db, 'steril'), isEmpty);
        expect(await searchRecords(db, 'autoclave'), <String>[id]);
        expect(await searchDoc(db, id), docBefore);
        expect(await _pendingDocuments(db), 0);
      },
    );

    test(
      'an edit under review keeps the status and bumps the record revision',
      () async {
        final String id = await record(
          'r1',
          status: 'needsReview',
          fields: const <String, String>{'model': 'Autoclave'},
        );

        okOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
          ]),
        );

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['status'], 'needsReview');
        expect(row['rev'], 2);
        expect(row['updated_at'], _seconds(t0));
        expect(await _statusPath(db, id), isEmpty);
      },
    );

    test(
      'an edit of a field with no value inserts it as manual and verified',
      () async {
        final String id = await record(
          'r1',
          fields: const <String, String>{'model': 'Autoclave'},
        );

        okOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'serial', value: 'SN-7'),
          ]),
        );

        final Map<String, Object?> serial = (await _values(
          db,
          id,
        )).singleWhere((Map<String, Object?> v) => v['field_key'] == 'serial');
        expect(serial['value_raw'], 'SN-7');
        expect(serial['source'], 'manual');
        expect(serial['verified'], 1);
        expect(serial['verified_by'], 'Ada');
        expect((await _audit(db, id)).single, <String, Object?>{
          'action': 'created',
          'field_key': 'serial',
          'previous_value': null,
          'new_value': 'SN-7',
          'reason': null,
          'operator': 'Ada',
          'device': 'device-a',
        });
      },
    );

    test('an edit that changes nothing writes nothing', () async {
      final String id = await record(
        'r1',
        status: 'approved',
        fields: const <String, String>{'model': 'Autoclave'},
      );
      final Map<String, Object?> recordBefore = await _row(db, 'records', id);
      final Map<String, Object?> valueBefore = await _row(
        db,
        'record_fields',
        'r1-model',
      );

      okOf(
        await writes.editValues(id, const <RecordValueEdit>[
          (fieldKey: 'model', value: 'Autoclave'),
          (fieldKey: 'serial', value: ''),
        ]),
      );
      okOf(await writes.editValues(id, const <RecordValueEdit>[]));

      expect(await _row(db, 'records', id), recordBefore);
      expect(await _row(db, 'record_fields', 'r1-model'), valueBefore);
      expect(await _values(db, id), hasLength(1));
      expect(await _count(db, 'audit_log'), 0);
    });

    test(
      'several edits write one line each and move the status once',
      () async {
        final String id = await record(
          'r1',
          status: 'approved',
          fields: const <String, String>{
            'model': 'Autoclave',
            'serial': 'SN-1',
          },
        );

        okOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
            (fieldKey: 'serial', value: 'SN-2'),
            (fieldKey: 'model', value: 'Steriliser'),
            (fieldKey: 'condition', value: 'good'),
          ]),
        );

        expect(
          <Object?>[
            for (final Map<String, Object?> line in await _audit(db, id))
              '${line['field_key']}: ${line['previous_value']} -> '
                  '${line['new_value']}',
          ],
          <String>[
            'model: Autoclave -> Sterilizer',
            'serial: SN-1 -> SN-2',
            'model: Sterilizer -> Steriliser',
            'condition: null -> good',
            'status: approved -> needsReview',
          ],
        );
        expect((await _row(db, 'records', id))['rev'], 2);
      },
    );

    test(
      'an edited value loses its evidence-removed flag; an untouched one keeps it',
      () async {
        final String id = await record(
          'r1',
          fields: const <String, String>{
            'model': 'Autoclave',
            'serial': 'SN-1',
          },
        );
        await db.customStatement(
          'UPDATE record_fields SET evidence_removed_at = ? WHERE record_id = ?',
          <Object?>[_seconds(t0), id],
        );

        okOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
          ]),
        );

        expect(
          (await _row(db, 'record_fields', 'r1-model'))['evidence_removed_at'],
          isNull,
        );
        expect(
          (await _row(db, 'record_fields', 'r1-serial'))['evidence_removed_at'],
          _seconds(t0),
        );
        final List<Map<String, Object?>> audit = await _audit(db, id);
        expect(
          audit.map((Map<String, Object?> line) => line['reason']),
          <String?>[null, 'evidenceRemoved'],
        );
        expect(audit.last['field_key'], 'model');
        expect(audit.last['previous_value'], 'true');
        expect(audit.last['new_value'], 'false');
      },
    );

    test(
      'a record in the bin, a blank field key and a missing record are refused without a write',
      () async {
        final String binned = await record(
          'binned',
          status: 'deleted',
          fields: const <String, String>{'model': 'Autoclave'},
        );
        final String live = await record(
          'live',
          fields: const <String, String>{'model': 'Autoclave'},
        );

        expect(
          failureOf(
            await writes.editValues(binned, const <RecordValueEdit>[
              (fieldKey: 'model', value: 'Sterilizer'),
            ]),
          ),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(
            await writes.editValues(live, const <RecordValueEdit>[
              (fieldKey: 'model', value: 'Sterilizer'),
              (fieldKey: ' ', value: 'x'),
            ]),
          ),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(
            await writes.editValues('missing', const <RecordValueEdit>[
              (fieldKey: 'model', value: 'x'),
            ]),
          ),
          isA<StorageFailure>(),
        );
        expect(
          (await _row(db, 'record_fields', 'binned-model'))['value_refined'],
          isNull,
        );
        expect(
          (await _row(db, 'record_fields', 'live-model'))['value_refined'],
          isNull,
        );
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test(
      'the search index follows an edit inside the same transaction',
      () async {
        final String id = await record(
          'r1',
          fields: const <String, String>{'model': 'Centrifuge'},
        );
        late List<String> inside;

        final Result<void> undone = await runInTransaction(db, () async {
          okOf(
            await writes.editValues(id, const <RecordValueEdit>[
              (fieldKey: 'model', value: 'Sterilizer'),
            ]),
          );
          inside = await searchRecords(db, 'steril');
          throw const StorageFailure(message: 'Undo the edit.');
        });

        expect(undone, isA<FailureResult<void>>());
        expect(inside, <String>[id]);
        expect(await searchRecords(db, 'steril'), isEmpty);
        expect((await searchDoc(db, id))?.name, 'Centrifuge');

        okOf(
          await writes.editValues(id, const <RecordValueEdit>[
            (fieldKey: 'model', value: 'Sterilizer'),
          ]),
        );
        expect(await searchRecords(db, 'steril'), <String>[id]);
        expect(
          await searchRecords(db, 'centrifuge'),
          <String>[id],
          reason: 'the raw value stays indexed beside the edit',
        );
        expect((await searchDoc(db, id))?.name, 'Sterilizer');
        expect(await _pendingDocuments(db), 0);
      },
    );
  });

  group('template change', () {
    Future<String> onFirst(String status, {String? templateRowId}) {
      return record(
        'r1',
        status: status,
        templateRowId: templateRowId,
        fields: const <String, String>{
          'model': 'Autoclave',
          'serial': 'SN-1',
          'condition': 'good',
        },
      );
    }

    test(
      'the plan maps, retires and adds by field key and writes nothing',
      () async {
        final String id = await onFirst('approved');
        final Map<String, Object?> before = await _row(db, 'records', id);

        final TemplateChangePlan plan = okOf(
          await writes.planTemplateChange(id, 'template-2'),
        );

        expect(plan.fromTemplateId, 'template-1');
        expect(plan.toTemplateId, 'template-2');
        expect(plan.mapped, <String>['model']);
        expect(plan.retired, <String>['serial', 'condition']);
        expect(plan.added, <String>['location']);
        expect(plan.restored, isEmpty);
        expect(await _row(db, 'records', id), before);
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test(
      'a change retires unmapped values, keeps every value, lets go of the row and sends approved to review',
      () async {
        final String id = await onFirst('approved', templateRowId: 'row-7');
        final List<Map<String, Object?>> valuesBefore = await _values(db, id);

        okOf(await writes.changeTemplate(id, 'template-2'));

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['template_id'], 'template-2');
        expect(row['template_row_id'], isNull);
        expect(row['status'], 'needsReview');
        final List<Map<String, Object?>> values = await _values(db, id);
        expect(values, hasLength(3));
        for (int index = 0; index < values.length; index++) {
          expect(values[index]['value_raw'], valuesBefore[index]['value_raw']);
        }
        final Map<String, bool> retired = <String, bool>{
          for (final Map<String, Object?> value in values)
            value['field_key']! as String: value['retired_at'] != null,
        };
        expect(retired, <String, bool>{
          'model': false,
          'serial': true,
          'condition': true,
        });
        expect(await _audit(db, id), <Map<String, Object?>>[
          <String, Object?>{
            'action': 'updated',
            'field_key': RecordWrites.templateAuditKey,
            'previous_value': 'template-1',
            'new_value': 'template-2',
            'reason': RecordWrites.templateChangeAuditReason,
            'operator': 'Ada',
            'device': 'device-a',
          },
          <String, Object?>{
            'action': 'updated',
            'field_key': RecordWrites.templateRowAuditKey,
            'previous_value': 'row-7',
            'new_value': null,
            'reason': RecordWrites.templateChangeAuditReason,
            'operator': 'Ada',
            'device': 'device-a',
          },
          for (final String key in <String>['serial', 'condition'])
            <String, Object?>{
              'action': 'updated',
              'field_key': key,
              'previous_value': 'false',
              'new_value': 'true',
              'reason': 'retired',
              'operator': 'Ada',
              'device': 'device-a',
            },
          <String, Object?>{
            'action': 'updated',
            'field_key': 'status',
            'previous_value': 'approved',
            'new_value': 'needsReview',
            'reason': RecordWrites.templateChangedReason,
            'operator': 'Ada',
            'device': 'device-a',
          },
        ]);
      },
    );

    test('changing back brings the retired values back', () async {
      final String id = await onFirst('needsReview');
      okOf(await writes.changeTemplate(id, 'template-2'));

      final TemplateChangePlan back = okOf(
        await writes.planTemplateChange(id, 'template-1'),
      );
      expect(back.restored, <String>['serial', 'condition']);
      expect(back.retired, isEmpty);
      okOf(await writes.changeTemplate(id, 'template-1'));

      final Map<String, Object?> row = await _row(db, 'records', id);
      expect(row['template_id'], 'template-1');
      expect(row['status'], 'needsReview');
      expect(row['rev'], 3);
      for (final Map<String, Object?> value in await _values(db, id)) {
        expect(value['retired_at'], isNull);
      }
      expect(await _values(db, id), hasLength(3));
    });

    test(
      "the template in use, a missing one, another project's and a deleted record are refused without a write",
      () async {
        final String id = await onFirst('approved');
        final String binned = await record('binned', status: 'deleted');
        final Map<String, Object?> before = await _row(db, 'records', id);

        expect(
          failureOf(await writes.planTemplateChange(id, 'template-1')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.changeTemplate(id, 'template-1')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.changeTemplate(id, 'template-missing')),
          isA<StorageFailure>(),
        );
        expect(
          failureOf(await writes.planTemplateChange(id, 'template-missing')),
          isA<StorageFailure>(),
        );
        expect(
          failureOf(await writes.changeTemplate(id, 'template-elsewhere')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.changeTemplate(binned, 'template-2')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.planTemplateChange('missing', 'template-2')),
          isA<StorageFailure>(),
        );
        expect(await _row(db, 'records', id), before);
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test(
      'a change rebuilds the search document in the same transaction',
      () async {
        final String id = await record(
          'r1',
          fields: const <String, String>{'serial': 'SN-1'},
        );
        expect((await searchDoc(db, id))?.name, 'SN-1');

        okOf(await writes.changeTemplate(id, 'template-2'));

        expect(
          (await searchDoc(db, id))?.name,
          '',
          reason: 'a retired value never names the record',
        );
        expect(
          await searchRecords(db, 'sn-1'),
          <String>[id],
          reason: 'a retired value is still data, so still found',
        );
        expect(await _pendingDocuments(db), 0);
      },
    );

    test('a failure while retiring rolls the whole change back', () async {
      final String id = await onFirst('approved');
      final Map<String, Object?> before = await _row(db, 'records', id);
      final List<Map<String, Object?>> valuesBefore = await _values(db, id);
      await _failWhen(
        db,
        'audit_log',
        "NEW.reason = 'retired' AND NEW.field_key = 'condition'",
      );

      expect(
        failureOf(await writes.changeTemplate(id, 'template-2')),
        isA<StorageFailure>(),
      );

      expect(await _row(db, 'records', id), before);
      expect(await _values(db, id), valuesBefore);
      expect(await _count(db, 'audit_log'), 0);
    });
  });

  group('delete and restore', () {
    test(
      'a delete marks the record deleted and tombstones it, keeping its photos and search document',
      () async {
        final String id = await record(
          'r1',
          status: 'approved',
          fields: const <String, String>{'model': 'Autoclave'},
        );
        await seedPhoto(db, 'ph1', recordId: id, projectId: 'project-1');

        okOf(await writes.moveToBin(id, reason: 'Duplicate'));

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['status'], 'deleted');
        expect(row['rev'], 2);
        expect(await _tombstoneOf(db, 'records', id), <String, Object?>{
          'reason': 'Duplicate',
          'deleted_at': _seconds(t0),
          'deleted_by_device': 'device-a',
        });
        expect(await _audit(db, id), <Map<String, Object?>>[
          <String, Object?>{
            'action': 'updated',
            'field_key': 'status',
            'previous_value': 'approved',
            'new_value': 'deleted',
            'reason': 'Duplicate',
            'operator': 'Ada',
            'device': 'device-a',
          },
        ]);
        expect((await _row(db, 'photos', 'ph1'))['record_id'], id);
        expect(await _tombstoneOf(db, 'photos', 'ph1'), isNull);
        expect(await _values(db, id), hasLength(1));
        expect((await searchDoc(db, id))?.name, 'Autoclave');
        expect(await searchRecords(db, 'autoclave'), <String>[id]);
        expect(await _pendingDocuments(db), 0);
      },
    );

    test(
      'a restore returns the status before the delete, lifts the tombstone and bumps the revision',
      () async {
        final String id = await record(
          'r1',
          status: 'approved',
          fields: const <String, String>{'model': 'Autoclave'},
        );
        okOf(await writes.moveToBin(id, reason: 'Duplicate'));

        okOf(await writes.restore(id));

        final Map<String, Object?> row = await _row(db, 'records', id);
        expect(row['status'], 'approved');
        expect(row['rev'], 3);
        expect(await _tombstoneOf(db, 'records', id), isNull);
        expect(await _statusPath(db, id), <String>['deleted', 'approved']);
        expect(
          (await _audit(db, id)).last['reason'],
          RecordWrites.restoredReason,
        );
        expect(await searchRecords(db, 'autoclave'), <String>[id]);
      },
    );

    test(
      'restore reads the latest delete when a record went round twice',
      () async {
        final String id = await record('r1', status: 'approved');
        okOf(await writes.moveToBin(id, reason: 'Duplicate'));
        okOf(await writes.restore(id));
        okOf(await writes.transition(id, RecordStatus.needsReview));
        okOf(await writes.moveToBin(id, reason: 'Wrong site'));

        okOf(await writes.restore(id));

        expect(await statusOf(db, id), 'needsReview');
        expect(await _statusPath(db, id), <String>[
          'deleted',
          'approved',
          'needsReview',
          'deleted',
          'needsReview',
        ]);
      },
    );

    test(
      'restore lands in review when the trail holds no legal previous status',
      () async {
        final String untraced = await record('untraced', status: 'deleted');
        final String processing = await record('processing', status: 'deleted');
        await appendAudit(
          db,
          entityType: 'records',
          entityId: processing,
          action: AuditAction.updated,
          fieldKey: 'status',
          previousValue: 'processing',
          newValue: 'deleted',
        );

        okOf(await writes.restore(untraced));
        okOf(await writes.restore(processing));

        expect(await statusOf(db, untraced), 'needsReview');
        expect(await statusOf(db, processing), 'needsReview');
      },
    );

    test(
      'a blank reason, a second delete and a missing record are refused without a write',
      () async {
        final String id = await record('r1');
        final String binned = await record('binned', status: 'deleted');

        expect(
          failureOf(await writes.moveToBin(id, reason: '  ')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.moveToBin(binned, reason: 'Again')),
          isA<ValidationFailure>(),
        );
        expect(
          failureOf(await writes.moveToBin('missing', reason: 'Gone')),
          isA<StorageFailure>(),
        );
        expect(await statusOf(db, id), 'captured');
        expect(await _count(db, 'tombstones'), 0);
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test(
      'restoring a record not in the bin fails validation; a missing one is storage',
      () async {
        final String id = await record('r1');

        expect(failureOf(await writes.restore(id)), isA<ValidationFailure>());
        expect(
          failureOf(await writes.restore('missing')),
          isA<StorageFailure>(),
        );
        expect(await statusOf(db, id), 'captured');
        expect(await _count(db, 'audit_log'), 0);
      },
    );

    test('a failed tombstone write rolls the delete back', () async {
      final String id = await record('r1', status: 'approved');
      final Map<String, Object?> before = await _row(db, 'records', id);
      await _failWhen(db, 'tombstones', "NEW.entity_type = 'records'");

      expect(
        failureOf(await writes.moveToBin(id, reason: 'Duplicate')),
        isA<StorageFailure>(),
      );

      expect(await _row(db, 'records', id), before);
      expect(await _count(db, 'audit_log'), 0);
      expect(await _count(db, 'tombstones'), 0);
    });
  });
}

/// A template in [projectId] whose [fieldKeys] are plain visible text fields
/// in that order.
Future<void> _seedTemplate(
  AppDatabase db,
  String id, {
  String projectId = 'project-1',
  required List<String> fieldKeys,
}) async {
  await seedRow(db, 'templates', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'name': id,
    'kind': 'asset',
    'source': 'built',
  });
  for (int index = 0; index < fieldKeys.length; index++) {
    await seedRow(db, 'template_fields', <String, Object?>{
      'id': '$id-${fieldKeys[index]}',
      'template_id': id,
      'field_key': fieldKeys[index],
      'label': fieldKeys[index],
      'type': 'text',
      'sort_order': index,
    });
  }
}

/// A draft on template-1 in project-1 unless told otherwise.
RecordDraft _draft({
  String projectId = 'project-1',
  String templateId = 'template-1',
  Map<String, String> fields = const <String, String>{},
}) {
  return (
    projectId: projectId,
    templateId: templateId,
    fields: fields,
    context: const <String, String>{},
  );
}

/// Makes every insert into [table] matching [when] fail, so a write can be
/// broken part-way through.
Future<void> _failWhen(AppDatabase db, String table, String when) {
  return db.customStatement(
    'CREATE TEMP TRIGGER forced_failure_$table BEFORE INSERT ON $table '
    "WHEN $when BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
  );
}

/// [at] as drift stores a date: whole unix seconds.
int _seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

/// The whole row [id] of [table].
Future<Map<String, Object?>> _row(
  AppDatabase db,
  String table,
  String id,
) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT * FROM $table WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>(id)],
      )
      .getSingle();
  return Map<String, Object?>.of(row.data);
}

/// Every value row of [recordId], in insert order.
Future<List<Map<String, Object?>>> _values(
  AppDatabase db,
  String recordId,
) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT * FROM record_fields WHERE record_id = ? ORDER BY rowid',
        variables: <Variable<Object>>[Variable<String>(recordId)],
      )
      .get();
  return <Map<String, Object?>>[
    for (final QueryRow row in rows) Map<String, Object?>.of(row.data),
  ];
}

/// Record [recordId]'s audit rows, in write order.
Future<List<Map<String, Object?>>> _audit(
  AppDatabase db,
  String recordId,
) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT action, field_key, previous_value, new_value, reason, '
        "operator, device FROM audit_log WHERE entity_type = 'records' "
        'AND entity_id = ? ORDER BY rowid',
        variables: <Variable<Object>>[Variable<String>(recordId)],
      )
      .get();
  return <Map<String, Object?>>[
    for (final QueryRow row in rows) Map<String, Object?>.of(row.data),
  ];
}

/// The new values of record [recordId]'s status audit rows, in order.
Future<List<String?>> _statusPath(AppDatabase db, String recordId) async {
  return <String?>[
    for (final Map<String, Object?> line in await _audit(db, recordId))
      if (line['field_key'] == 'status') line['new_value'] as String?,
  ];
}

/// The tombstone of [entityId] in [entityType], or null.
Future<Map<String, Object?>?> _tombstoneOf(
  AppDatabase db,
  String entityType,
  String entityId,
) async {
  final QueryRow? row = await db
      .customSelect(
        'SELECT reason, deleted_at, deleted_by_device FROM tombstones '
        'WHERE entity_type = ? AND entity_id = ?',
        variables: <Variable<Object>>[
          Variable<String>(entityType),
          Variable<String>(entityId),
        ],
      )
      .getSingleOrNull();
  return row == null ? null : Map<String, Object?>.of(row.data);
}

/// How many rows [table] holds.
Future<int> _count(AppDatabase db, String table) async {
  final QueryRow row = await db
      .customSelect('SELECT COUNT(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}

/// Search documents still waiting for a deferred rebuild; zero once every
/// write has committed.
Future<int> _pendingDocuments(AppDatabase db) async {
  return await _count(db, 'record_search_pending') +
      await _count(db, 'record_search_hold');
}
