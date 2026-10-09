import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
import 'package:tapture/features/processing/data/stage_support.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, InputMode;

import '../../../support/factories.dart';
import '../../../support/processing_fixture.dart';

void main() {
  test(
    'a stored known primary with unsupported companion remains excluded in the pinned processing shape',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.addField(
        'protected',
        autoFill: true,
        validation:
            '{"_tapture":{"autoFill":"NOW","autoFillTop":"FUTURE_TOP"}}',
      );
      await fixture.addField('ordinary');
      final TemplateRepositoryImpl repository = TemplateRepositoryImpl(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
      );
      final before = (await repository.byId(fixture.template.id)).getOrThrow()!;
      expect(before.fields.first.autoFill, isNull);
      await repository.save(before.copyWith(name: 'Renamed'));
      final RecordBundle bundle = await fixture.bundle();
      expect(bundle.templateResolved, isTrue);
      expect(
        StageSupport.extractionFields(bundle).map((field) => field.fieldKey),
        <String>['ordinary'],
      );
      final TemplateField protected = bundle.fields.singleWhere(
        (field) => field.fieldKey == 'protected',
      );
      expect(
        (jsonDecode(protected.validation) as Map)['_tapture'],
        <String, Object?>{'autoFill': 'NOW', 'autoFillTop': 'FUTURE_TOP'},
      );
      expect(bundle.photos, hasLength(1));
    },
  );
  for (final Object declaration in <Object>[
    'FUTURE_SOURCE',
    <String, Object?>{'provider': 'future'},
    'LOCAL_ADDRESS',
  ]) {
    test(
      'a pinned stored $declaration field remains unavailable without hiding eligible siblings',
      () async {
        final ProcessingFixture fixture = await ProcessingFixture.open();
        await fixture.addField(
          'protected',
          type: 'number',
          autoFill: true,
          validation: jsonEncode(<String, Object?>{
            '_tapture': <String, Object?>{'autoFill': declaration},
          }),
        );
        await fixture.addField('ordinary');
        final TemplateRepositoryImpl repository = TemplateRepositoryImpl(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
        );
        final before = (await repository.byId(
          fixture.template.id,
        )).getOrThrow()!;
        final after = (await repository.save(
          before.copyWith(name: 'Renamed'),
        )).getOrThrow();
        final RecordBundle bundle = await fixture.bundle();
        expect(bundle.templateResolved, isTrue);
        expect(bundle.template.version, before.version);
        expect(bundle.currentTemplate!.version, after.version);
        expect(
          StageSupport.extractionFields(bundle).map((field) => field.fieldKey),
          <String>['ordinary'],
        );
        final TemplateField protected = bundle.fields.singleWhere(
          (field) => field.fieldKey == 'protected',
        );
        expect(
          (jsonDecode(protected.validation) as Map)['_tapture'],
          containsPair('autoFill', declaration),
        );
        expect(bundle.photos, hasLength(1));
      },
    );
  }
  test(
    'a malformed full captured snapshot remains unresolved with its evidence intact',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.addField('ordinary');
      await fixture.db
          .update(fixture.db.templates)
          .write(
            TemplatesCompanion(
              version: const Value<int>(2),
              detection: Value<String>(
                jsonEncode(<String, Object?>{
                  '_tapture_versions': <String, Object?>{
                    '1': <String, Object?>{
                      'schema_version': 1,
                      'name': 42,
                      'fields': <Object>[],
                    },
                  },
                }),
              ),
            ),
          );
      final RecordBundle bundle = await fixture.bundle();
      expect(bundle.templateResolved, isFalse);
      expect(StageSupport.extractionFields(bundle), isEmpty);
      expect(bundle.photos, hasLength(1));
    },
  );
  test(
    'the captured version keeps its own source policies after a template edit',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.addField('old_automatic', inputMode: 'AUTO');
      await fixture.addField('old_ordinary');
      final TemplateRepositoryImpl repository = TemplateRepositoryImpl(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
      );
      final before = (await repository.byId(fixture.template.id)).getOrThrow()!;
      final after = (await repository.save(
        before.copyWith(
          fields: <FieldDef>[
            for (final FieldDef field in before.fields)
              field.copyWith(
                inputMode: field.fieldKey == 'old_automatic'
                    ? InputMode.any
                    : InputMode.auto,
              ),
          ],
        ),
      )).getOrThrow();
      expect(after.version, greaterThan(before.version));
      final RecordBundle captured = await fixture.bundle();
      expect(captured.templateResolved, isTrue);
      expect(captured.template.version, before.version);
      expect(captured.currentTemplate!.version, after.version);
      expect(
        StageSupport.extractionFields(captured).map((field) => field.fieldKey),
        <String>['old_ordinary'],
      );
      await fixture.db
          .update(fixture.db.records)
          .write(RecordsCompanion(templateVersion: Value<int>(after.version)));
      expect(
        StageSupport.extractionFields(
          await fixture.bundle(),
        ).map((field) => field.fieldKey),
        <String>['old_automatic'],
      );
    },
  );

  for (final int version in <int>[0, 77]) {
    test(
      'an unavailable captured version $version keeps evidence without guessing sources',
      () async {
        final ProcessingFixture fixture = await ProcessingFixture.open();
        await fixture.addField('current_only', required: true);
        await fixture.setContext('{"current_only":"Local context"}');
        await fixture.db
            .update(fixture.db.records)
            .write(RecordsCompanion(templateVersion: Value<int>(version)));
        if (version == 0) {
          await fixture.db
              .update(fixture.db.templates)
              .write(const TemplatesCompanion(version: Value<int>(0)));
        }
        final RecordBundle bundle = await fixture.bundle();
        expect(bundle.templateResolved, isFalse);
        expect(bundle.photos, hasLength(1));
        expect(bundle.record.contextJson, contains('Local context'));
        expect(bundle.fields.single.fieldKey, 'current_only');
        expect(StageSupport.extractionFields(bundle), isEmpty);
        expect(StageSupport.extractionContext(bundle), isEmpty);
        expect(bundle.rows, isEmpty);
      },
    );
  }

  test('a record loads with its project, template and photos', () async {
    final AppDatabase db = await seededDatabase(records: 2);
    addTearDown(db.close);
    final RecordRow record = (await db.select(db.records).get()).first;

    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);

    expect(bundle.record.id, record.id);
    expect(bundle.project.id, record.projectId);
    expect(bundle.template.id, record.templateId);
    expect(bundle.photos.map((Photo photo) => photo.recordId), <String?>[
      record.id,
    ]);
    expect(bundle.fields, isEmpty);
    expect(bundle.rows, isEmpty);
    expect(bundle.captions, isEmpty);
    expect(bundle.audio, isEmpty);
    expect(bundle.existing, isEmpty);
  });

  test('a record that is gone is a storage failure', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);

    await expectLater(
      RecordBundleLoader(db: db).load('missing'),
      throwsA(isA<StorageFailure>()),
    );
  });

  test('a record whose template is gone is a validation failure', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final RecordRow record = await db.select(db.records).getSingle();
    await (db.update(db.records)
          ..where(($RecordsTable table) => table.id.equals(record.id)))
        .write(const RecordsCompanion(templateId: Value<String>('gone')));

    await expectLater(
      RecordBundleLoader(db: db).load(record.id),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('only the photos the record shows now are read, in tray order, so a '
      'removed photo is never processed again', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final RecordRow record = await db.select(db.records).getSingle();
    final Photo seeded = await db.select(db.photos).getSingle();
    await _photo(db, record, 'removed', sortOrder: 1);
    await _photo(db, record, 'original', sortOrder: 2);
    await _photo(db, record, 'edited', sortOrder: 3, derivedFrom: 'original');
    await writeTombstone(
      db,
      entityType: 'photos',
      entityId: 'removed',
      reason: 'Removed while editing the record.',
    );

    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);

    // The removed photo is gone, and the original is read as its edit.
    expect(bundle.photos.map((Photo photo) => photo.id), <String>[
      seeded.id,
      'edited',
    ]);

    await removeTombstone(db, entityType: 'photos', entityId: 'removed');
    final RecordBundle restored = await RecordBundleLoader(
      db: db,
    ).load(record.id);
    expect(restored.photos.map((Photo photo) => photo.id), <String>[
      seeded.id,
      'removed',
      'edited',
    ]);
  });

  test('captions are read for the record and the photos it shows, never '
      'for a removed photo or once tombstoned', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final RecordRow record = await db.select(db.records).getSingle();
    await _photo(db, record, 'removed', sortOrder: 1);
    await _photo(db, record, 'original', sortOrder: 2);
    await _photo(db, record, 'edited', sortOrder: 3, derivedFrom: 'original');
    await _caption(db, 'record-note', CaptionOwnerType.record, record.id);
    await _caption(db, 'withdrawn-note', CaptionOwnerType.record, record.id);
    await _caption(db, 'removed-note', CaptionOwnerType.photo, 'removed');
    await _caption(db, 'original-note', CaptionOwnerType.photo, 'original');
    await _caption(db, 'edited-note', CaptionOwnerType.photo, 'edited');
    await writeTombstone(
      db,
      entityType: 'photos',
      entityId: 'removed',
      reason: 'Removed while editing the record.',
    );
    await writeTombstone(
      db,
      entityType: 'captions',
      entityId: 'withdrawn-note',
      reason: 'Withdrawn.',
    );

    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);

    expect(
      bundle.captions.map((Caption caption) => caption.id),
      unorderedEquals(<String>['record-note', 'edited-note']),
    );
  });
}

/// Files photo [id] on [record] at [sortOrder]; [derivedFrom] makes it an
/// edited copy of that photo.
Future<void> _photo(
  AppDatabase db,
  RecordRow record,
  String id, {
  required int sortOrder,
  String? derivedFrom,
}) async {
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 18));
  final Result<Photo> written = await upsertPhoto(
    db,
    row: PhotosCompanion(
      id: Value<String>(id),
      projectId: Value<String>(record.projectId),
      recordId: Value<String?>(record.id),
      captureSessionId: const Value<String>('session-seed'),
      originalFilename: Value<String>('$id.jpg'),
      storedFilename: Value<String>('$id.jpg'),
      relativePath: Value<String>('photos/${record.id}/$id.jpg'),
      photoType: const Value<String>('front'),
      sortOrder: Value<int>(sortOrder),
      width: const Value<int>(1600),
      height: const Value<int>(1200),
      fileSize: const Value<int>(2048),
      mimeType: const Value<String>('image/jpeg'),
      sha256: Value<String>('$id-sha'),
      capturedAt: Value<DateTime>(clock.nowUtc()),
      derivedFrom: Value<String?>(derivedFrom),
    ),
    clock: clock,
    deviceId: 'device-test',
    ids: UuidV7Service.sequence(clock),
  );
  expect(written, isA<Success<Photo>>());
}

/// Writes caption [id] on [ownerId].
Future<void> _caption(
  AppDatabase db,
  String id,
  CaptionOwnerType ownerType,
  String ownerId,
) async {
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 18));
  final Result<Caption> written = await insertCaption(
    db,
    row: CaptionsCompanion(
      id: Value<String>(id),
      ownerType: Value<CaptionOwnerType>(ownerType),
      ownerId: Value<String>(ownerId),
      textRaw: Value<String>('Text of $id'),
      inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
    ),
    clock: clock,
    deviceId: 'device-test',
    ids: UuidV7Service.sequence(clock),
  );
  expect(written, isA<Success<Caption>>());
}
