import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/data/record_mapper.dart';
import 'package:tapture/features/records/data/record_queries.dart';
import 'package:tapture/features/records/domain/domain.dart';

import '../../../core/db/record_rows.dart' show seedCaption, seedRow;
import '../fakes/record_results.dart';
import 'record_read_seeds.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  /// One row holding [columns] as the query returned them.
  Future<QueryRow> rowOf(Map<String, Object?> columns) async {
    final List<String> names = columns.keys.toList();
    return db
        .customSelect(
          'SELECT ${[for (final String name in names) '? AS $name'].join(', ')}',
          variables: <Variable<Object>>[
            for (final String name in names) _variable(columns[name]),
          ],
        )
        .getSingle();
  }

  group('a record read back whole', () {
    final DateTime captured = DateTime.utc(2026, 9, 1, 9, 30);
    final DateTime updated = DateTime.utc(2026, 9, 3, 14);
    final DateTime approvedAt = DateTime.utc(2026, 9, 2, 10);
    final DateTime flaggedAt = DateTime.utc(2026, 9, 2, 12);

    Future<void> seedWholeRecord() async {
      await seedProjectRow(db, 'p1', name: 'Hospital', folder: 'hospital');
      await seedTemplateRow(
        db,
        't1',
        name: 'Assets',
        fields: <String>['model', 'serial', 'condition'],
        identity: <String>['serial'],
      );
      await seedRow(db, 'template_rows', <String, Object?>{
        'id': 'row-7',
        'template_id': 't1',
        'output_row_number': 7,
        'identifier': 'A-07',
        'label': 'Theatre autoclave',
      });
      await seedRecordRow(
        db,
        'r1',
        templateRowId: 'row-7',
        status: 'NEEDS_REVIEW',
        capturedAt: captured,
        capturedBy: 'device-a',
        context: <String, String>{'site': 'North', 'room': 'Theatre 2'},
        number: 42,
        processingMode: 'online',
        source: 'capture',
        updatedAt: updated,
        approvedAt: approvedAt,
        approvedBy: 'Ada',
      );
      // Written out of field order, to prove the template orders them.
      await seedValue(
        db,
        'f-condition',
        recordId: 'r1',
        fieldKey: 'condition',
        raw: 'good',
        source: 'TYPED',
        evidenceRemovedAt: flaggedAt,
      );
      await seedValue(
        db,
        'f-model',
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
        'f-serial',
        recordId: 'r1',
        fieldKey: 'serial',
        raw: 'SN-1',
        approved: 'SN-001',
        confidence: 0.97,
        band: 'high',
        method: 'local-ocr',
      );
      await seedValue(
        db,
        'f-colour',
        recordId: 'r1',
        fieldKey: 'colour',
        raw: 'white',
        source: 'TYPED',
        retiredAt: flaggedAt,
        createdAt: 2,
      );
      await seedValue(
        db,
        'f-notes',
        recordId: 'r1',
        fieldKey: 'notes',
        raw: 'removed later',
        createdAt: 3,
      );
      await seedTomb(db, 'record_fields', 'f-notes');
      // Two live photos (sort order decides), one removed, one replaced by
      // a live edited copy.
      await seedPhotoRow(db, 'ph-b', recordId: 'r1', sortOrder: 1);
      await seedPhotoRow(
        db,
        'ph-a',
        recordId: 'r1',
        sortOrder: 0,
        rotation: 270,
        photoType: 'plate',
      );
      await seedPhotoRow(db, 'ph-gone', recordId: 'r1', sortOrder: 2);
      await seedTomb(db, 'photos', 'ph-gone');
      await seedPhotoRow(db, 'ph-original', recordId: 'r1', sortOrder: 3);
      await seedPhotoRow(
        db,
        'ph-edit',
        recordId: 'r1',
        sortOrder: 3,
        rotation: 90,
        derivedFrom: 'ph-original',
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
        'cap-old',
        ownerType: 'record',
        ownerId: 'r1',
        text: 'First note',
      );
      await seedCaption(
        db,
        'cap-new',
        ownerType: 'record',
        ownerId: 'r1',
        text: 'Beside the sink',
        createdAt: 5,
      );
      await seedCaption(
        db,
        'cap-removed',
        ownerType: 'record',
        ownerId: 'r1',
        text: 'Withdrawn',
        createdAt: 9,
      );
      await seedTomb(db, 'captions', 'cap-removed');
      await seedAudio(db, 'clip-1', recordId: 'r1');
      await seedAudio(db, 'clip-2', recordId: 'r1');
      await seedAudit(
        db,
        'a-export-1',
        entityId: 'r1',
        at: DateTime.utc(2026, 9, 4),
        fieldKey: 'export',
        next: 'v1',
        reason: 'bundle,xlsx',
      );
      await seedAudit(
        db,
        'a-export-2',
        entityId: 'r1',
        at: DateTime.utc(2026, 9, 6),
        fieldKey: 'export',
        next: 'v2',
        reason: 'bundle,xlsx',
      );
      await seedAudit(
        db,
        'a-merge',
        entityId: 'r1',
        at: DateTime.utc(2026, 9, 5),
        action: 'created',
        fieldKey: 'merge',
        next: 'inserted',
        reason: 'site-b.tapture',
      );
      await seedRecordRow(db, 'r2', number: 43);
      await seedDuplicate(db, 'dup-1', left: 'r2', right: 'r1');
      await seedConflict(
        db,
        'conflict-1',
        entityType: 'record_fields',
        entityId: 'f-serial',
      );
      await seedVariance(db, 'var-1', recordId: 'r1');
    }

    test('maps every field of the record, its values and its photos', () async {
      await seedWholeRecord();
      final RecordEntry? entry = okOf(await RecordQueries(db: db).byId('r1'));

      expect(
        entry,
        RecordEntry(
          id: 'r1',
          projectId: 'p1',
          templateId: 't1',
          templateRowId: 'row-7',
          number: 42,
          name: 'Steam autoclave',
          identifier: 'SN-001',
          status: RecordStatus.needsReview,
          values: <RecordValue>[
            const RecordValue(
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
            const RecordValue(
              fieldKey: 'serial',
              raw: 'SN-1',
              approved: 'SN-001',
              source: 'ocr',
              confidence: 0.97,
              band: 'high',
              method: 'local-ocr',
            ),
            const RecordValue(
              fieldKey: 'condition',
              raw: 'good',
              source: 'TYPED',
              evidenceRemoved: true,
            ),
            const RecordValue(
              fieldKey: 'colour',
              raw: 'white',
              source: 'TYPED',
              retired: true,
            ),
          ],
          photos: const <RecordPhoto>[
            RecordPhoto(
              id: 'ph-a',
              sha256: 'sha-ph-a',
              storagePath: 'projects/hospital/photos/ph-a.jpg',
              quarterTurns: 3,
              caption: 'Rating plate',
              photoType: 'plate',
            ),
            RecordPhoto(
              id: 'ph-b',
              sha256: 'sha-ph-b',
              storagePath: 'projects/hospital/photos/ph-b.jpg',
              sortOrder: 1,
              photoType: 'front',
            ),
            RecordPhoto(
              id: 'ph-edit',
              sha256: 'sha-ph-edit',
              storagePath: 'projects/hospital/photos/ph-edit.jpg',
              quarterTurns: 1,
              sortOrder: 3,
              photoType: 'front',
            ),
          ],
          caption: 'Beside the sink',
          audioClips: 2,
          context: const <String, String>{'site': 'North', 'room': 'Theatre 2'},
          flags: const <RecordFlag>{
            RecordFlag.hasPhotos,
            RecordFlag.hasDuplicate,
            RecordFlag.hasConflict,
            RecordFlag.hasVariance,
            RecordFlag.evidenceRemoved,
            RecordFlag.mergedFromBundle,
          },
          capturedAt: captured,
          capturedBy: 'device-a',
          updatedAt: updated,
          approvedAt: approvedAt,
          approvedBy: 'Ada',
          exportedAt: DateTime.utc(2026, 9, 6),
          processingMode: 'online',
        ),
      );
      expect(entry!.capturedAt.isUtc, isTrue);
      expect(entry.valueOf('model')!.valueSource, ValueSource.aiVision);
      expect(entry.valueOf('serial')!.display, 'SN-001');
      expect(entry.retiredValues.single.fieldKey, 'colour');
      expect(entry.contextLabel, 'Theatre 2');
    });

    test('the watched record equals the one read once', () async {
      await seedWholeRecord();
      final RecordQueries queries = RecordQueries(db: db);
      final RecordEntry? once = okOf(await queries.byId('r1'));
      expect(await queries.watchEntry('r1').first, once);
    });

    test(
      'its list row carries the same number, name, thumb and flags',
      () async {
        await seedWholeRecord();
        final RecordQueries queries = RecordQueries(db: db);
        final RecordEntry entry = okOf(await queries.byId('r1'))!;
        final RecordSummary row =
            (await queries
                    .watchPage(
                      'p1',
                      filter: RecordFilter.none,
                      sort: const RecordSort(ascending: true),
                      offset: 0,
                      limit: 1,
                    )
                    .first)
                .single;
        expect(row, entry.toSummary());
        expect(row.thumb?.id, 'ph-a');
        expect(row.photoCount, 3);
      },
    );

    test('a record with nothing but its row reads with empty parts', () async {
      await seedRecordRow(db, 'bare', capturedAt: captured);
      final RecordEntry entry = okOf(await RecordQueries(db: db).byId('bare'))!;
      expect(entry.values, isEmpty);
      expect(entry.photos, isEmpty);
      expect(entry.caption, '');
      expect(entry.audioClips, 0);
      expect(entry.context, isEmpty);
      expect(entry.flags, isEmpty);
      expect(entry.name, '');
      expect(entry.identifier, '');
      expect(entry.number, 1);
      expect(entry.approvedAt, isNull);
      expect(entry.approvedBy, isNull);
      expect(entry.exportedAt, isNull);
      expect(entry.templateRowId, isNull);
    });
  });

  group('status', () {
    test('reads every stored spelling of a status', () {
      expect(RecordMapper.status('needsReview'), RecordStatus.needsReview);
      expect(RecordMapper.status('NEEDS_REVIEW'), RecordStatus.needsReview);
      expect(RecordMapper.status(' approved '), RecordStatus.approved);
      for (final RecordStatus status in RecordStatus.values) {
        expect(RecordMapper.status(status.stored), status);
      }
    });

    test('an unknown or missing status reads as captured', () {
      expect(RecordMapper.status('shipped'), RecordStatus.captured);
      expect(RecordMapper.status(null), RecordStatus.captured);
      expect(RecordMapper.unknownStatus, RecordStatus.captured);
    });
  });

  group('context', () {
    test('reads capture\'s flat snapshot in stored order', () {
      final Map<String, String> context = RecordMapper.context(
        jsonEncode(<String, String>{'site': 'North', 'room': 'R1'}),
      );
      expect(context, <String, String>{'site': 'North', 'room': 'R1'});
      expect(context.keys, <String>['site', 'room']);
    });

    test('reads the context writer\'s values with pinned values over them', () {
      final Map<String, String> context = RecordMapper.context(
        jsonEncode(<String, Object?>{
          'levels': <Object?>[
            <String, Object?>{'fieldKey': 'site', 'order': 0},
          ],
          'values': <String, String>{'site': 'North', 'room': 'R1'},
          'pinned': <String, String>{'room': 'R2', 'inspector': 'Ada'},
        }),
      );
      expect(context, <String, String>{
        'site': 'North',
        'room': 'R2',
        'inspector': 'Ada',
      });
    });

    test('keeps text values only', () {
      expect(
        RecordMapper.context('{"site":"North","floor":3,"open":true,"x":null}'),
        <String, String>{'site': 'North'},
      );
    });

    test('malformed or non-object JSON reads as no context', () {
      expect(RecordMapper.context(null), isEmpty);
      expect(RecordMapper.context(''), isEmpty);
      expect(RecordMapper.context('{not json'), isEmpty);
      expect(RecordMapper.context('["North"]'), isEmpty);
      expect(RecordMapper.context('"North"'), isEmpty);
    });
  });

  test('a rotation in degrees reads as clockwise quarter turns', () {
    expect(RecordMapper.quarterTurns(null), 0);
    expect(RecordMapper.quarterTurns(0), 0);
    expect(RecordMapper.quarterTurns(90), 1);
    expect(RecordMapper.quarterTurns(180), 2);
    expect(RecordMapper.quarterTurns(270), 3);
    expect(RecordMapper.quarterTurns(360), 0);
    expect(RecordMapper.quarterTurns(-90), 3);
    expect(RecordMapper.quarterTurns(45), 0);
  });

  group('rows', () {
    test(
      'a value keeps its captured, refined and approved stages apart',
      () async {
        final RecordValue value = RecordMapper.value(
          await rowOf(<String, Object?>{
            'field_key': 'serial',
            'value_raw': 'SN-1',
            'value_refined': 'SN-01',
            'value_final': 'SN-001',
            'source': 'ocr',
            'confidence': 1,
            'confidence_band': 'high',
            'verified': 0,
            'evidence_removed_at': null,
            'retired_at': 5,
            'provider': null,
            'model': null,
            'method': null,
          }),
        );
        expect(value.raw, 'SN-1');
        expect(value.refined, 'SN-01');
        expect(value.approved, 'SN-001');
        expect(value.display, 'SN-001');
        expect(value.confidence, 1.0);
        expect(value.verified, isFalse);
        expect(value.evidenceRemoved, isFalse);
        expect(value.retired, isTrue);
      },
    );

    test('a value with nothing captured reads as empty, not null', () async {
      final RecordValue value = RecordMapper.value(
        await rowOf(<String, Object?>{
          'field_key': 'notes',
          'value_raw': null,
          'value_refined': null,
          'value_final': null,
          'source': null,
          'confidence': null,
          'confidence_band': null,
          'verified': null,
          'evidence_removed_at': null,
          'retired_at': null,
          'provider': null,
          'model': null,
          'method': null,
        }),
      );
      expect(value.raw, '');
      expect(value.hasValue, isFalse);
      expect(value.source, RecordValue.manualSource);
    });

    test('flags are the flag columns that hold 1', () async {
      final Set<RecordFlag> flags = RecordMapper.flags(
        await rowOf(<String, Object?>{
          'flag_photos': 1,
          'flag_duplicate': 0,
          'flag_conflict': null,
          'flag_variance': 1,
          'flag_evidence': 0,
          'flag_merged': 0,
        }),
      );
      expect(flags, <RecordFlag>{RecordFlag.hasPhotos, RecordFlag.hasVariance});
      expect(RecordMapper.flagColumns.keys, RecordFlag.values);
    });

    test('a history row maps its time, markers and people', () async {
      final RecordHistoryEvent event = RecordMapper.historyEvent(
        await rowOf(<String, Object?>{
          'id': 'a1',
          'at': 1788000000,
          'entity_type': 'records',
          'action': 'updated',
          'field_key': 'status',
          'previous_value': 'captured',
          'new_value': 'needsReview',
          'reason': 'Check',
          'operator': 'Ada',
          'device': 'device-a',
          'has_field': 0,
          'known_template': 0,
        }),
      );
      expect(
        event,
        RecordHistoryEvent(
          id: 'a1',
          at: DateTime.fromMillisecondsSinceEpoch(
            1788000000 * 1000,
            isUtc: true,
          ),
          kind: RecordHistoryKind.statusChanged,
          operator: 'Ada',
          device: 'device-a',
          fieldKey: 'status',
          previous: 'captured',
          next: 'needsReview',
          reason: 'Check',
        ),
      );
    });
  });

  group('history kinds', () {
    RecordHistoryKind kindOf({
      String entityType = 'records',
      String action = 'updated',
      String? fieldKey,
      String? previous,
      String? next,
      String? reason,
      bool hasField = false,
      bool knownTemplate = false,
    }) {
      return RecordMapper.historyKind(
        entityType: entityType,
        action: action,
        fieldKey: fieldKey,
        previous: previous,
        next: next,
        reason: reason,
        hasField: hasField,
        knownTemplate: knownTemplate,
      );
    }

    test('without a clashing field every marker keeps its kind', () {
      expect(
        kindOf(fieldKey: 'status', previous: 'x', next: 'y'),
        RecordHistoryKind.statusChanged,
      );
      expect(kindOf(fieldKey: 'templateId'), RecordHistoryKind.templateChanged);
      expect(
        kindOf(fieldKey: 'photo', next: 'removed'),
        RecordHistoryKind.photoRemoved,
      );
      expect(kindOf(fieldKey: 'processing'), RecordHistoryKind.processed);
      expect(kindOf(fieldKey: 'export'), RecordHistoryKind.exported);
      expect(kindOf(fieldKey: 'merge'), RecordHistoryKind.merged);
      expect(kindOf(action: 'created'), RecordHistoryKind.created);
      expect(kindOf(fieldKey: 'serial'), RecordHistoryKind.valueChanged);
      expect(
        kindOf(entityType: 'captions', fieldKey: 'caption'),
        RecordHistoryKind.captionChanged,
      );
      expect(
        kindOf(entityType: 'photos', action: 'created'),
        RecordHistoryKind.photoAdded,
      );
    });

    test('a field keyed like a marker is read as a value unless the row has '
        'the marker\'s shape', () {
      // Value edits of fields that happen to be keyed like the markers.
      expect(
        kindOf(fieldKey: 'status', next: 'In service', hasField: true),
        RecordHistoryKind.valueChanged,
      );
      expect(
        kindOf(
          action: 'created',
          fieldKey: 'status',
          next: 'approved',
          hasField: true,
        ),
        RecordHistoryKind.valueChanged,
      );
      expect(
        kindOf(fieldKey: 'templateId', next: 'T-9', hasField: true),
        RecordHistoryKind.valueChanged,
      );
      expect(
        kindOf(fieldKey: 'photo', next: 'yes', hasField: true),
        RecordHistoryKind.valueChanged,
      );
      expect(
        kindOf(
          fieldKey: 'processing',
          next: 'completed',
          reason: 'typed',
          hasField: true,
        ),
        RecordHistoryKind.valueChanged,
      );
      expect(
        kindOf(fieldKey: 'export', next: 'monthly', hasField: true),
        RecordHistoryKind.valueChanged,
      );
      expect(
        kindOf(fieldKey: 'merge', next: 'no', hasField: true),
        RecordHistoryKind.valueChanged,
      );

      // The record-level rows themselves, on the same record.
      expect(
        kindOf(
          fieldKey: 'status',
          previous: 'captured',
          next: 'needsReview',
          hasField: true,
        ),
        RecordHistoryKind.statusChanged,
      );
      expect(
        kindOf(fieldKey: 'templateId', hasField: true, knownTemplate: true),
        RecordHistoryKind.templateChanged,
      );
      expect(
        kindOf(fieldKey: 'photo', next: 'added', hasField: true),
        RecordHistoryKind.photoAdded,
      );
      expect(
        kindOf(
          fieldKey: 'processing',
          next: 'failed',
          reason: '{"job":"j1"}',
          hasField: true,
        ),
        RecordHistoryKind.processed,
      );
      expect(
        kindOf(fieldKey: 'export', next: 'v12', hasField: true),
        RecordHistoryKind.exported,
      );
      expect(
        kindOf(
          action: 'created',
          fieldKey: 'merge',
          next: 'inserted',
          hasField: true,
        ),
        RecordHistoryKind.merged,
      );
    });

    test('a clashing field\'s flag lines keep their flag kind', () {
      expect(
        kindOf(
          fieldKey: 'status',
          previous: 'false',
          next: 'true',
          reason: 'retired',
          hasField: true,
        ),
        RecordHistoryKind.retired,
      );
      expect(
        kindOf(
          fieldKey: 'export',
          previous: 'false',
          next: 'true',
          reason: 'evidenceRemoved',
          hasField: true,
        ),
        RecordHistoryKind.evidenceRemoved,
      );
    });
  });
}

Variable<Object> _variable(Object? value) {
  return switch (value) {
    final int number => Variable<int>(number),
    final double number => Variable<double>(number),
    final String text => Variable<String>(text),
    _ => const Variable<Object>(null),
  };
}
