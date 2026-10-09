import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/field_evidence.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_relocation.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/consent_stamp.dart';
import 'package:tapture/core/speech/finished_utterance.dart';
import 'package:tapture/core/speech/transcript_segment.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/data/capture_device_sources.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/auto_fields.dart';
import 'package:tapture/features/capture/domain/capture_session.dart'
    as capture;
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/quality/domain/identity_hash.dart';
import 'package:tapture/features/templates/data/template_mapper.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show TranscriptOwnerKind, TranscriptRepositoryImpl;

import '../../../core/db/record_rows.dart' show searchRecords;
import '../../../support/factories.dart';

void main() {
  test(
    'save samples before its first await and never waits for a pending device read',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final TemplateDef template = await _localAddressTemplate(db, clock, ids);
      final capture.CaptureSession session = capture.CaptureSession(
        id: 'pending-address-save',
        projectId: template.projectId!,
        templateId: template.id,
        templateVersion: template.version,
        contextSnapshot: const <String, String>{},
      );
      final Completer<PlatformFacts> facts = Completer<PlatformFacts>();
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: clock,
        readFacts: () => facts.future,
      );
      addTearDown(source.dispose);
      source.bind(session, template.fields);
      int samples = 0;
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'app-id',
        ids: ids,
        localAddress: (capture.CaptureSession candidate) {
          samples += 1;
          expect(candidate.id, session.id);
          return source.snapshot(candidate);
        },
      );
      final Future<Result<String>> saving = writer.persist(session);
      expect(
        samples,
        1,
        reason: 'The callback runs before any database await.',
      );
      final String id = _ok(await saving);
      expect(
        facts.isCompleted,
        isFalse,
        reason: 'Saving never waits for enumeration.',
      );
      final List<RecordField> before = await db.select(db.recordFields).get();
      expect(
        before.map((RecordField field) => field.fieldKey),
        isNot(contains('network_address')),
      );
      expect(
        before
            .singleWhere(
              (RecordField field) => field.fieldKey == 'sibling_device',
            )
            .valueRaw,
        'app-id',
      );
      final Future<void> completed = source.changes.firstWhere(
        (_) => source.snapshot(session) != null,
      );
      facts.complete(const PlatformFacts.fake(addresses: <String>['10.0.0.2']));
      await completed;
      expect(_ok(await writer.persist(session)), id);
      expect(await db.select(db.recordFields).get(), before);
      expect((await db.select(db.records).get()).length, 1);
    },
  );

  test(
    'first-save local sample freezes while typed context and null clears remain authoritative',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final TemplateDef template = await _localAddressTemplate(db, clock, ids);
      final capture.CaptureSession session = capture.CaptureSession(
        id: 'fresh-address-save',
        projectId: template.projectId!,
        templateId: template.id,
        templateVersion: template.version,
        contextSnapshot: const <String, String>{
          'context_address': 'Context retained',
        },
        values: const <String, Object?>{
          'typed_address': 'Manual retained',
          'clear_address': null,
        },
        valueSources: const <String, String>{
          'typed_address': 'TYPED',
          'clear_address': 'TYPED',
        },
      );
      String? sample = '10.0.0.2';
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'app-id',
        ids: ids,
        localAddress: (_) => sample,
      );
      final String id = _ok(await writer.persist(session));
      final List<RecordField> initial = await db.select(db.recordFields).get();
      RecordField field(String key) =>
          initial.singleWhere((RecordField field) => field.fieldKey == key);
      expect(field('network_address').valueRaw, '10.0.0.2');
      expect(field('network_address').source, 'AUTO');
      expect(field('typed_address').valueRaw, 'Manual retained');
      expect(field('typed_address').source, 'TYPED');
      expect(field('clear_address').valueRaw, isNull);
      expect(field('clear_address').source, 'TYPED');
      expect(field('context_address').valueRaw, 'Context retained');
      expect(field('context_address').source, 'CONTEXT');
      final List<AuditLogData> audit = await db.select(db.auditLog).get();
      sample = '10.0.0.99';
      expect(_ok(await writer.persist(session)), id);
      expect(await db.select(db.recordFields).get(), initial);
      expect(await db.select(db.auditLog).get(), audit);
      expect((await db.select(db.records).getSingle()).recordNumber, 1);
    },
  );

  test(
    'an unavailable snapshot callback leaves capture and sibling automation usable',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final TemplateDef template = await _localAddressTemplate(db, clock, ids);
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'app-id',
        ids: ids,
        localAddress: (_) => throw StateError('unavailable'),
      );
      _ok(
        await writer.persist(
          capture.CaptureSession(
            id: 'error-address-save',
            projectId: template.projectId!,
            templateId: template.id,
            templateVersion: template.version,
            contextSnapshot: const <String, String>{},
          ),
        ),
      );
      final List<RecordField> fields = await db.select(db.recordFields).get();
      expect(
        fields.map((RecordField field) => field.fieldKey),
        isNot(contains('network_address')),
      );
      expect(
        fields
            .singleWhere(
              (RecordField field) => field.fieldKey == 'sibling_device',
            )
            .valueRaw,
        'app-id',
      );
    },
  );
  test(
    'automatic previews allocate nothing and first save freezes its later source sample',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final DateTime previewAt = DateTime.utc(2026, 10, 8, 23, 58, 1);
      final DateTime saveAt = previewAt.add(
        const Duration(days: 1, minutes: 3),
      );
      final FixedClock previewClock = FixedClock(previewAt);
      final FixedClock saveClock = FixedClock(saveAt);
      final UuidV7Service ids = UuidV7Service.sequence(saveClock);
      final TemplateDef template = await _automaticPreviewTemplate(
        db,
        saveClock,
        ids,
      );
      final capture.CaptureSession session = capture.CaptureSession(
        id: 'preview-first-save',
        projectId: template.projectId!,
        templateId: template.id,
        templateVersion: template.version,
        contextSnapshot: const <String, String>{'area': 'Kampala'},
      );
      Map<String, Object?> preview(Clock clock) => AutoFields.forTemplate(
        fields: template.fields,
        nowUtc: clock.nowUtc(),
        operatorName: 'Ada',
        deviceId: 'app-device-id',
        sequence: null,
        context: session.contextSnapshot,
        location: session.location,
      );

      final Map<String, Object?> early = preview(previewClock);
      final Map<String, Object?> later = preview(saveClock);
      expect(early['capture_instant'], previewAt.toIso8601String());
      expect(later['capture_instant'], saveAt.toIso8601String());
      expect(later['captured_date'], isNot(early['captured_date']));
      expect(later['captured_time'], isNot(early['captured_time']));
      expect(early, isNot(contains('batch_number')));
      expect(later, isNot(contains('batch_number')));
      expect(session.values, isEmpty);
      expect(session.valueSources, isEmpty);
      expect(await db.select(db.records).get(), isEmpty);
      expect(await db.select(db.recordFields).get(), isEmpty);

      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: saveClock,
        deviceId: 'app-device-id',
        ids: ids,
        operatorName: () => ' Ada ',
      );
      final String recordId = _ok(await writer.persist(session));
      final RecordRow stored = await db.select(db.records).getSingle();
      final Map<String, RecordField> fields = <String, RecordField>{
        for (final RecordField field in await db.select(db.recordFields).get())
          field.fieldKey: field,
      };
      expect(stored.capturedAt.toUtc(), saveAt);
      expect(stored.capturedBy, 'app-device-id');
      expect(stored.recordNumber, 1);
      expect(fields['capture_instant']?.valueRaw, later['capture_instant']);
      expect(fields['captured_date']?.valueRaw, later['captured_date']);
      expect(fields['captured_time']?.valueRaw, later['captured_time']);
      expect(fields['operator_label']?.valueRaw, 'Ada');
      expect(fields['device_id']?.valueRaw, 'app-device-id');
      expect(fields['batch_number']?.valueRaw, '1');
      for (final String key in <String>[
        'capture_instant',
        'captured_date',
        'captured_time',
        'operator_label',
        'device_id',
        'batch_number',
      ]) {
        expect(fields[key]?.source, 'AUTO', reason: key);
      }
      expect(fields['area']?.valueRaw, 'Kampala');
      expect(fields['area']?.source, 'CONTEXT');
      final List<AuditLogData> audit = await db.select(db.auditLog).get();

      final FixedClock retryClock = FixedClock(
        saveAt.add(const Duration(days: 2)),
      );
      final CaptureRecordWriter retry = CaptureRecordWriter(
        db: db,
        clock: retryClock,
        deviceId: 'different-app-device-id',
        ids: UuidV7Service.sequence(retryClock),
        operatorName: () => 'Later operator',
        autoFillDates: () => false,
      );
      expect(
        _ok(
          await retry.persist(
            session.copyWith(
              contextSnapshot: const <String, String>{'area': 'Gulu'},
              values: const <String, Object?>{'captured_date': '2000-01-01'},
              valueSources: const <String, String>{'captured_date': 'TYPED'},
            ),
          ),
        ),
        recordId,
      );
      expect(await db.select(db.records).getSingle(), stored);
      expect(await db.select(db.recordFields).get(), fields.values.toList());
      expect(await db.select(db.auditLog).get(), audit);
      expect(
        _ok(await retry.load(recordId)).contextSnapshot,
        session.contextSnapshot,
      );
    },
  );

  test(
    'typed overrides and explicit null clears retain their source ahead of previews and context',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9, 8, 20));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final TemplateDef template = await _automaticPreviewTemplate(
        db,
        clock,
        ids,
      );
      final capture.CaptureSession session = capture.CaptureSession(
        id: 'preview-overrides',
        projectId: template.projectId!,
        templateId: template.id,
        templateVersion: template.version,
        contextSnapshot: const <String, String>{
          'area': 'Inherited area',
          'clear_context': 'Inherited value',
        },
        values: const <String, Object?>{
          'captured_date': '2026-01-02',
          'capture_instant': null,
          'area': 'Typed area',
          'clear_context': null,
        },
        valueSources: const <String, String>{
          'captured_date': 'TYPED',
          'capture_instant': 'TYPED',
          'area': 'TYPED',
          'clear_context': 'TYPED',
        },
      );
      final Map<String, Object?> preview = AutoFields.forTemplate(
        fields: template.fields,
        nowUtc: clock.nowUtc(),
        operatorName: 'Ada',
        deviceId: 'app-device-id',
        sequence: null,
        context: session.contextSnapshot,
        location: null,
      );
      expect(preview['capture_instant'], isNotNull);
      expect(preview['captured_date'], isNot('2026-01-02'));
      expect(preview['area'], 'Inherited area');
      expect(preview['clear_context'], 'Inherited value');

      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'app-device-id',
        ids: ids,
        operatorName: () => 'Ada',
      );
      final String recordId = _ok(await writer.persist(session));
      final Map<String, RecordField> fields = <String, RecordField>{
        for (final RecordField field in await db.select(db.recordFields).get())
          field.fieldKey: field,
      };
      for (final String key in session.values.keys) {
        expect(fields[key]?.valueRaw, session.values[key], reason: key);
        expect(fields[key]?.source, 'TYPED', reason: key);
        expect(fields[key]?.valueRefined, isNull, reason: key);
        expect(fields[key]?.valueFinal, isNull, reason: key);
      }
      expect(fields['device_id']?.valueRaw, 'app-device-id');
      expect(fields['device_id']?.source, 'AUTO');
      final RecordRow stored = await db.select(db.records).getSingle();
      expect(stored.capturedAt.toUtc(), clock.nowUtc());
      expect(stored.capturedBy, 'app-device-id');
      expect(
        _ok(await writer.load(recordId)).contextSnapshot,
        session.contextSnapshot,
      );
      final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'app-device-id',
        ids: ids,
      );
      expect(_ok(await templates.byId(template.id)), template);
      expect(session.contextSnapshot['area'], 'Inherited area');
      expect(session.contextSnapshot['clear_context'], 'Inherited value');
    },
  );

  test(
    'capture uses its historical defaults and identity after an edit',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 30));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'version-test',
        ids: ids,
      );
      final Template row = await db.select(db.templates).getSingle();
      final TemplateDef initial = _ok(await templates.byId(row.id))!;
      final TemplateDef captured = _ok(
        await templates.save(
          initial.copyWith(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
              ),
              FieldDef(
                fieldKey: 'old_default',
                label: 'Old default',
                type: FieldType.text,
                defaultValue: 'captured default',
              ),
            ],
            identityFieldKeys: const <String>['serial'],
          ),
        ),
      );
      final TemplateDef current = _ok(
        await templates.save(
          captured.copyWith(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'replacement',
                label: 'Replacement',
                type: FieldType.text,
              ),
              FieldDef(
                fieldKey: 'new_default',
                label: 'New default',
                type: FieldType.text,
                defaultValue: 'latest default',
              ),
            ],
            identityFieldKeys: const <String>['replacement'],
          ),
        ),
      );
      expect(current.version, greaterThan(captured.version));
      const Map<String, Object?> values = <String, Object?>{
        'serial': 'OLD-42',
        'replacement': 'NEW-10',
      };
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'version-test',
        ids: ids,
      );
      final String id = _ok(
        await writer.createRecord(
          capture.CaptureSession(
            id: 'historical-shape',
            projectId: row.projectId!,
            templateId: row.id,
            templateVersion: captured.version,
            contextSnapshot: const <String, String>{},
            values: values,
          ),
        ),
      );
      final RecordRow record = await db.select(db.records).getSingle();
      expect(record.templateVersion, captured.version);
      expect(
        record.identityHash,
        storedIdentityHash(
          recordId: id,
          values: values,
          identityKeys: const <String>['serial'],
        ),
      );
      final Map<String, String?> fields = <String, String?>{
        for (final RecordField field in await db.select(db.recordFields).get())
          field.fieldKey: field.valueRaw,
      };
      expect(fields['old_default'], 'captured default');
      expect(fields, isNot(contains('new_default')));
      expect(_ok(await writer.load(id)).templateVersion, captured.version);
    },
  );

  test('legacy recovery never invents current defaults or identity', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 30));
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'legacy-test',
      ids: ids,
    );
    final Template row = await db.select(db.templates).getSingle();
    final TemplateDef initial = _ok(await templates.byId(row.id))!;
    _ok(
      await templates.save(
        initial.copyWith(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(
              fieldKey: 'new_default',
              label: 'New default',
              type: FieldType.text,
              defaultValue: 'latest default',
            ),
          ],
          identityFieldKeys: const <String>['serial'],
        ),
      ),
    );
    final capture.CaptureSession recovered = capture.CaptureSession.fromJson(
      <String, Object?>{
        'id': 'legacy-recovery',
        'projectId': row.projectId,
        'templateId': row.id,
        'contextSnapshot': <String, String>{'country': 'Uganda'},
        'values': <String, Object?>{'serial': 'OLD-42'},
      },
    );
    expect(recovered.templateVersion, 0);
    final CaptureRecordWriter writer = CaptureRecordWriter(
      db: db,
      clock: clock,
      deviceId: 'legacy-test',
      ids: ids,
    );
    final String id = _ok(await writer.createRecord(recovered));
    final RecordRow record = await db.select(db.records).getSingle();
    expect(record.templateVersion, 0);
    expect(
      record.identityHash,
      storedIdentityHash(
        recordId: id,
        values: recovered.values,
        identityKeys: const <String>[],
      ),
    );
    final List<RecordField> fields = await db.select(db.recordFields).get();
    expect(fields.any((field) => field.fieldKey == 'new_default'), isFalse);
    expect(
      fields.singleWhere((field) => field.fieldKey == 'serial').valueRaw,
      'OLD-42',
    );
    expect(_ok(await writer.load(id)).templateVersion, 0);
  });

  test(
    'a captured template version survives a later edit and reload',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      await (db.update(db.templates)
            ..where((row) => row.id.equals(template.id)))
          .write(const TemplatesCompanion(version: Value<int>(2)));
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 30));
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'version-test',
        ids: UuidV7Service.sequence(clock),
      );
      final String id = _ok(
        await writer.createRecord(
          capture.CaptureSession(
            id: 'captured-version',
            projectId: project.id,
            templateId: template.id,
            templateVersion: 1,
            contextSnapshot: const <String, String>{},
          ),
        ),
      );
      expect(
        (await (db.select(
          db.records,
        )..where((row) => row.id.equals(id))).getSingle()).templateVersion,
        1,
      );
      expect(_ok(await writer.load(id)).templateVersion, 1);
    },
  );
  test(
    'captured consent remains attributable record evidence with an audit event',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final DateTime at = DateTime.utc(2026, 9, 30, 8);
      final FixedClock clock = FixedClock(at);
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      final Map<String, String> stamp = ConsentStamp(
        by: 'Ada',
        at: at,
      ).toJson();
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
        operatorName: () => 'Ada',
      );
      final String recordId = _ok(
        await writer.persist(
          _session(
            projectId: project.id,
            templateId: template.id,
            now: at,
          ).copyWith(values: <String, Object?>{'consent': stamp}),
        ),
      );
      final RecordField field =
          await (db.select(db.recordFields)..where(
                ($RecordFieldsTable row) => row.fieldKey.equals('consent'),
              ))
              .getSingle();
      expect(ConsentStamp.parse(field.valueRaw)?.by, 'Ada');
      expect(ConsentStamp.parse(field.valueRaw)?.at, at);
      final AuditLogData event = (await db.select(db.auditLog).get())
          .singleWhere(
            (AuditLogData row) =>
                row.entityId == recordId && row.fieldKey == 'consent',
          );
      expect(event.operator, 'Ada');
      expect(ConsentStamp.parse(event.newValue)?.at, at);
    },
  );

  test(
    'one transaction freezes raw capture evidence and is idempotent',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final DateTime now = DateTime.utc(2026, 9, 23, 16, 35);
      final FixedClock clock = FixedClock(now);
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      final capture.CaptureSession session = _session(
        projectId: project.id,
        templateId: template.id,
        now: now,
      );

      expect(_ok(await writer.persist(session)), session.id);
      // A retry after a committed record but failed recovery checkpoint is a
      // no-op, not a second set of immutable captions or fields.
      expect(_ok(await writer.persist(session)), session.id);

      final RecordRow record = await db.select(db.records).getSingle();
      expect(record.id, session.id);
      expect(record.status, RecordStatus.captured.stored);
      expect(record.contextJson, '{"country":"Uganda"}');

      final Photo photo = await db.select(db.photos).getSingle();
      expect(photo.recordId, record.id);
      expect(photo.relativePath, 'photos/photo-1.jpg');
      expect(photo.sha256, 'photo-sha');

      final captions = await db.select(db.captions).get();
      expect(captions, hasLength(2));
      expect(
        captions.map((row) => row.textRaw),
        containsAll(<String>['Record note', 'Photo note']),
      );

      final fields = await db.select(db.recordFields).get();
      expect(fields, hasLength(2));
      expect(
        fields.singleWhere((row) => row.fieldKey == 'country').source,
        'CONTEXT',
      );
      expect(
        fields.singleWhere((row) => row.fieldKey == 'serial').valueRaw,
        'SN-42',
      );

      final Attachment attachment = await db.select(db.attachments).getSingle();
      expect(attachment.durationMs, 1250);
      expect(await db.select(db.attachmentOwners).get(), hasLength(2));
    },
  );

  test(
    'a capture writes the record its own created entry, once and first',
    () async {
      final _Saved saved = await _saved();
      // A retry of the committed session writes nothing more.
      final capture.CaptureSession again = _session(
        projectId: saved.projectId,
        templateId: saved.templateId,
        now: saved.now,
      );
      expect(_ok(await saved.writer.persist(again)), saved.recordId);

      final List<AuditLogData> rows = await saved.db
          .select(saved.db.auditLog)
          .get();
      final List<AuditLogData> created = <AuditLogData>[
        for (final AuditLogData row in rows)
          if (row.entityType == 'records' &&
              row.entityId == saved.recordId &&
              row.fieldKey == null)
            row,
      ];
      expect(created, hasLength(1));
      expect(created.single.action, AuditAction.created);
      expect(created.single.newValue, RecordStatus.captured.stored);
      expect(created.single.reason, 'capture');
      expect(created.single.device, 'device-a');
      expect(created.single.at.toUtc(), saved.now);
      // The field rows follow it, so the history reads capture first.
      final List<AuditLogData> forRecord = <AuditLogData>[
        for (final AuditLogData row in rows)
          if (row.entityType == 'records' && row.entityId == saved.recordId)
            row,
      ];
      expect(forRecord.first, created.single);
    },
  );

  test(
    'a photo write failure rolls the previously inserted record back',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final DateTime now = DateTime.utc(2026, 9, 23, 16, 35);
      final FixedClock clock = FixedClock(now);
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      final capture.CaptureSession invalid = _session(
        projectId: project.id,
        templateId: template.id,
        now: now,
        photoPath: '/outside/photo.jpg',
      );

      expect(await writer.persist(invalid), isA<FailureResult<String>>());
      expect(await db.select(db.records).get(), isEmpty);
      expect(await db.select(db.auditLog).get(), isEmpty);
      expect(await db.select(db.photos).get(), isEmpty);
      expect(await db.select(db.captions).get(), isEmpty);
      expect(await db.select(db.recordFields).get(), isEmpty);
    },
  );

  test('a record saved with no typing carries AUTO captured-at, date, time, '
      'operator and device', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final DateTime now = DateTime.utc(2026, 9, 29, 7, 4, 5);
    final FixedClock clock = FixedClock(now);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final Project project = await db.select(db.projects).getSingle();
    final Template template = await db.select(db.templates).getSingle();
    final Map<String, AutoFill> automatic = <String, AutoFill>{
      'captured_at': AutoFill.now,
      'date': AutoFill.today,
      'time': AutoFill.time,
      'operator': AutoFill.operator,
      'device': AutoFill.device,
    };
    for (final MapEntry<String, AutoFill> entry in automatic.entries) {
      _ok(
        await upsertTemplateField(
          db,
          row: TemplateMapper.fieldToRow(
            FieldDef(
              fieldKey: entry.key,
              label: entry.key,
              type: FieldType.text,
              autoFill: entry.value,
            ),
            templateId: template.id,
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
    }
    final CaptureRecordWriter writer = CaptureRecordWriter(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      operatorName: () => 'Ada',
    );

    final String recordId = _ok(
      await writer.persist(
        capture.CaptureSession(
          id: 'untyped',
          projectId: project.id,
          templateId: template.id,
          contextSnapshot: const <String, String>{},
          photos: <PhotoDraft>[
            PhotoDraft(
              id: 'only-photo',
              projectId: project.id,
              captureSessionId: 'untyped',
              relativePath: 'photos/_unfiled/only-photo.jpg',
              sha256: 'only-sha',
              capturedAt: now,
            ),
          ],
        ),
      ),
    );

    final Map<String, RecordField> fields = <String, RecordField>{
      for (final RecordField row in await db.select(db.recordFields).get())
        if (row.recordId == recordId) row.fieldKey: row,
    };
    for (final String key in automatic.keys) {
      expect(fields[key]?.source, 'AUTO', reason: key);
    }
    final DateTime local = now.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    expect(fields['captured_at']?.valueRaw, '2026-09-29T07:04:05.000Z');
    expect(
      fields['date']?.valueRaw,
      '${local.year}-${two(local.month)}-${two(local.day)}',
    );
    expect(
      fields['time']?.valueRaw,
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}',
    );
    expect(fields['operator']?.valueRaw, 'Ada');
    expect(fields['device']?.valueRaw, 'device-a');
    final RecordRow record = await db.select(db.records).getSingle();
    expect(record.capturedAt.toUtc(), now);
    expect(record.capturedBy, 'device-a');
    // The operator is on the capture's own history row whatever the
    // template asks for.
    final AuditLogData created = (await db.select(db.auditLog).get())
        .firstWhere(
          (AuditLogData row) =>
              row.entityType == 'records' &&
              row.entityId == recordId &&
              row.fieldKey == null,
        );
    expect(created.operator, 'Ada');
    expect(created.device, 'device-a');
  });

  test('twenty parallel captures get record numbers 1..20', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final DateTime now = DateTime.utc(2026, 9, 29, 8);
    final FixedClock clock = FixedClock(now);
    final CaptureRecordWriter writer = CaptureRecordWriter(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    );
    final Project project = await db.select(db.projects).getSingle();
    final Template template = await db.select(db.templates).getSingle();

    final List<Result<String>> saved = await Future.wait(
      <Future<Result<String>>>[
        for (int index = 0; index < 20; index++)
          writer.persist(
            capture.CaptureSession(
              id: 'rapid-$index',
              projectId: project.id,
              templateId: template.id,
              contextSnapshot: const <String, String>{},
              photos: <PhotoDraft>[
                PhotoDraft(
                  id: 'rapid-photo-$index',
                  projectId: project.id,
                  captureSessionId: 'rapid-$index',
                  relativePath: 'photos/_unfiled/rapid-photo-$index.jpg',
                  sha256: 'rapid-sha-$index',
                  capturedAt: now,
                ),
              ],
            ),
          ),
      ],
    );

    expect(saved.whereType<Success<String>>(), hasLength(20));
    final List<int?> numbers = <int?>[
      for (final RecordRow row in await db.select(db.records).get())
        row.recordNumber,
    ]..sort((int? a, int? b) => a!.compareTo(b!));
    expect(numbers, <int>[for (int number = 1; number <= 20; number++) number]);
  });

  test('persist files derivation and rotation of each photo', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final DateTime now = DateTime.utc(2026, 9, 29, 8);
    final FixedClock clock = FixedClock(now);
    final CaptureRecordWriter writer = CaptureRecordWriter(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    );
    final Project project = await db.select(db.projects).getSingle();
    final Template template = await db.select(db.templates).getSingle();
    final PhotoDraft original = PhotoDraft(
      id: 'original',
      projectId: project.id,
      captureSessionId: 'derived-session',
      relativePath: 'photos/_unfiled/original.jpg',
      sha256: 'original-sha',
      capturedAt: now,
    );

    // No draft rows were written before: the save alone files both.
    _ok(
      await writer.persist(
        capture.CaptureSession(
          id: 'derived-session',
          projectId: project.id,
          templateId: template.id,
          contextSnapshot: const <String, String>{},
          photos: <PhotoDraft>[
            original,
            original.copyWith(
              id: 'crop',
              relativePath: 'photos/_unfiled/crop.png',
              sha256: 'crop-sha',
              derivedFrom: 'original',
              rotationDegrees: 90,
            ),
          ],
        ),
      ),
    );

    final Map<String, Photo> rows = <String, Photo>{
      for (final Photo row in await db.select(db.photos).get()) row.id: row,
    };
    expect(rows['crop']?.derivedFrom, 'original');
    expect(rows['crop']?.rotationDegrees, 90);
    expect(rows['original']?.derivedFrom, isNull);
    expect(rows['original']?.sha256, 'original-sha');
  });

  test(
    'a captured photo lands in photos/Kampala/Kasubi-HC-IV/Theatre',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture-capture-tree-',
      );
      addTearDown(() => documents.deleteSync(recursive: true));
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: documents,
      );
      final DateTime now = DateTime.utc(2026, 9, 29, 8);
      final FixedClock clock = FixedClock(now);
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      _ok(
        await ContextRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ).saveHierarchy(project.id, const <ContextLevel>[
          ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
          ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
          ContextLevel(fieldKey: 'department', order: 2, label: 'Department'),
        ]),
      );
      // The shutter wrote the photo before any level was chosen.
      final PhotoDraft photo = PhotoDraft(
        id: 'ph1',
        projectId: project.id,
        captureSessionId: 'tree-session',
        originalFilename: 'ph1.jpg',
        storedFilename: 'ph1.jpg',
        relativePath: 'photos/_unfiled/ph1.jpg',
        sha256: '',
        capturedAt: now,
      );
      final PhotoDraft drafted = _ok(
        await DriftPhotoRepository(
          db: db,
          writer: FileWriter(storageRoot: storage),
          reader: FileReader(storageRoot: storage),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
          storageRoot: storage,
        ).saveDraft(photo, bytes: Uint8List.fromList(<int>[4, 2])),
      );
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        relocation: FileRelocation(
          db: db,
          storageRoot: storage,
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      _ok(
        await writer.persist(
          capture.CaptureSession(
            id: 'tree-session',
            projectId: project.id,
            templateId: template.id,
            contextSnapshot: const <String, String>{
              'district': 'Kampala',
              'facility': 'Kasubi HC IV',
              'department': 'Theatre',
            },
            photos: <PhotoDraft>[drafted],
          ),
        ),
      );

      final Photo row = await db.select(db.photos).getSingle();
      expect(row.relativePath, 'photos/Kampala/Kasubi-HC-IV/Theatre/ph1.jpg');
      final String projectDir =
          '${_ok(await storage.resolve()).path}/projects/${project.folderName}';
      expect(
        File(
          '$projectDir/photos/Kampala/Kasubi-HC-IV/Theatre/ph1.jpg',
        ).readAsBytesSync(),
        <int>[4, 2],
      );
      expect(File('$projectDir/photos/_unfiled/ph1.jpg').existsSync(), isFalse);
    },
  );

  test('load returns the saved record as an edit session', () async {
    final _Saved saved = await _saved();

    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );

    expect(edit.editing, isTrue);
    expect(edit.id, saved.recordId);
    expect(edit.recordId, saved.recordId);
    expect(edit.storageKey, 'edit:${saved.recordId}');
    expect(edit.projectId, saved.projectId);
    expect(edit.templateId, saved.templateId);
    expect(edit.contextSnapshot, const <String, String>{'country': 'Uganda'});
    expect(edit.photos.map((PhotoDraft p) => p.id), <String>['photo-1']);
    expect(edit.photos.single.recordId, saved.recordId);
    expect(edit.photos.single.hasCaption, isTrue);
    expect(edit.captions, const <String, String>{
      '': 'Record note',
      'photo-1': 'Photo note',
    });
    expect(edit.audio.single.id, 'audio-1');
    expect(edit.audio.single.photoIds, const <String>['photo-1']);
    expect(edit.values, isEmpty);

    expect(
      await saved.writer.load('missing'),
      isA<FailureResult<capture.CaptureSession>>(),
    );
  });

  test('update files, tombstones and refines only what changed', () async {
    final _Saved saved = await _saved();
    final AppDatabase db = saved.db;
    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );
    final RecordRow before = await db.select(db.records).getSingle();
    final List<RecordField> fieldsBefore = await db
        .select(db.recordFields)
        .get();
    // A photo added during the edit is a draft row off the record.
    final PhotoDraft added = await _draft(saved, 'photo-2');

    _ok(
      await saved.writer.update(
        edit.copyWith(
          photos: <PhotoDraft>[added.copyWith(sortOrder: 1)],
          captions: const <String, String>{
            '': 'Record note, boiler room',
            'photo-2': 'Gauge',
          },
          isDirty: true,
        ),
      ),
    );

    final Photo filed = await (db.select(
      db.photos,
    )..where((row) => row.id.equals('photo-2'))).getSingle();
    expect(filed.recordId, saved.recordId);
    expect(filed.sortOrder, 1);
    final List<Tombstone> tombstones = await db.select(db.tombstones).get();
    expect(tombstones.single.entityId, 'photo-1');
    // The removed photo's row stays, so its file is kept for the purge job.
    expect(
      await (db.select(
        db.photos,
      )..where((row) => row.id.equals('photo-1'))).getSingleOrNull(),
      isNotNull,
    );

    final Caption record =
        await (db.select(db.captions)..where(
              (row) => row.ownerType.equalsValue(CaptionOwnerType.record),
            ))
            .getSingle();
    expect(record.textRaw, 'Record note');
    expect(record.textRefined, 'Record note, boiler room');
    final Caption gauge = await (db.select(
      db.captions,
    )..where((row) => row.ownerId.equals('photo-2'))).getSingle();
    expect(gauge.textRaw, 'Gauge');
    expect(gauge.textRefined, isNull);

    final List<RecordField> fieldsAfter = await db
        .select(db.recordFields)
        .get();
    expect(
      fieldsAfter.map((RecordField f) => '${f.fieldKey}=${f.valueRaw}'),
      fieldsBefore.map((RecordField f) => '${f.fieldKey}=${f.valueRaw}'),
    );
    final RecordRow after = await db.select(db.records).getSingle();
    expect(after.rev, before.rev + 1);
    expect(after.status, before.status);
    expect(after.templateId, before.templateId);
    expect(after.contextJson, before.contextJson);

    final capture.CaptureSession reloaded = _ok(
      await saved.writer.load(saved.recordId),
    );
    expect(reloaded.photos.map((PhotoDraft p) => p.id), <String>['photo-2']);
    expect(reloaded.captions[''], 'Record note, boiler room');
    expect(reloaded.captions['photo-2'], 'Gauge');
  });

  test('a failing update rolls every change back', () async {
    final _Saved saved = await _saved();
    final AppDatabase db = saved.db;
    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );
    final RecordRow before = await db.select(db.records).getSingle();

    final Result<void> result = await saved.writer.update(
      edit.copyWith(
        photos: <PhotoDraft>[
          PhotoDraft(
            id: 'photo-bad',
            projectId: saved.projectId,
            relativePath: '/outside/photo.jpg',
            sha256: 'bad-sha',
          ),
        ],
        captions: const <String, String>{'': 'Changed'},
      ),
    );

    expect(result, isA<FailureResult<void>>());
    expect(await db.select(db.tombstones).get(), isEmpty);
    final Caption record =
        await (db.select(db.captions)..where(
              (row) => row.ownerType.equalsValue(CaptionOwnerType.record),
            ))
            .getSingle();
    expect(record.textRefined, isNull);
    expect((await db.select(db.records).getSingle()).rev, before.rev);
    expect(
      await (db.select(
        db.photos,
      )..where((row) => row.id.equals('photo-bad'))).getSingleOrNull(),
      isNull,
    );
  });

  test('only an edit session can update a record', () async {
    final _Saved saved = await _saved();
    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );
    expect(
      await saved.writer.update(edit.copyWith(editing: false)),
      isA<FailureResult<void>>(),
    );
  });

  group('a photo removed from a saved record', () {
    test('flags the values it was the only evidence for and keeps them, '
        'while values still seen on a live photo and typed values stay '
        'unflagged', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      final AppDatabase db = saved.db;
      // model was read only from photo-1; rating from both photos; maker
      // only from photo-2; serial was typed, even though a region of
      // photo-1 shows it.
      final String model = await _readValue(saved, 'model', 'X200', <String>[
        'photo-1',
      ]);
      final String rating = await _readValue(saved, 'rating', '5 kW', <String>[
        'photo-1',
        'photo-2',
      ]);
      final String maker = await _readValue(saved, 'maker', 'Acme', <String>[
        'photo-2',
      ]);
      final String serial = (await _fieldByKey(db, 'serial')).id;
      await _linkEvidence(saved, serial, 'photo-1');
      final int valuesBefore = (await db.select(db.recordFields).get()).length;

      await _removePhoto(saved, 'photo-1');

      final RecordField flagged = await _fieldById(db, model);
      expect(flagged.evidenceRemovedAt?.toUtc(), saved.now);
      // Flagged, never deleted: the value and its text are all still there.
      expect(flagged.valueRaw, 'X200');
      expect(flagged.source, 'ocr');
      expect(await db.select(db.recordFields).get(), hasLength(valuesBefore));
      expect((await _fieldById(db, rating)).evidenceRemovedAt, isNull);
      expect((await _fieldById(db, maker)).evidenceRemovedAt, isNull);
      expect((await _fieldById(db, serial)).evidenceRemovedAt, isNull);
      expect((await _fieldById(db, serial)).valueRaw, 'SN-42');
      // Its evidence rows stay too, so the history can say what was seen.
      expect(
        await (db.select(
          db.fieldEvidence,
        )..where((row) => row.recordFieldId.equals(model))).get(),
        hasLength(1),
      );

      final List<AuditLogData> flags = <AuditLogData>[
        for (final AuditLogData row in await db.select(db.auditLog).get())
          if (row.reason == evidenceRemovedAuditReason) row,
      ];
      expect(flags, hasLength(1));
      expect(flags.single.entityType, 'records');
      expect(flags.single.entityId, saved.recordId);
      expect(flags.single.fieldKey, 'model');
      expect(flags.single.previousValue, 'false');
      expect(flags.single.newValue, 'true');
    });

    test('flags a value once every photo it was read from is gone', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      final String rating = await _readValue(saved, 'rating', '5 kW', <String>[
        'photo-1',
        'photo-2',
      ]);

      await _removePhoto(saved, 'photo-1');
      expect((await _fieldById(saved.db, rating)).evidenceRemovedAt, isNull);

      await _removePhoto(saved, 'photo-2');
      final RecordField flagged = await _fieldById(saved.db, rating);
      expect(flagged.evidenceRemovedAt, isNotNull);
      expect(flagged.valueRaw, '5 kW');
    });

    test('keeps a value live when an edited copy of its photo is filed in '
        'the same edit', () async {
      final _Saved saved = await _saved();
      final String model = await _readValue(saved, 'model', 'X200', <String>[
        'photo-1',
      ]);
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );
      final PhotoDraft cropped = await _draft(
        saved,
        'photo-1-crop',
        derivedFrom: 'photo-1',
      );

      _ok(
        await saved.writer.update(
          edit.copyWith(photos: <PhotoDraft>[cropped], isDirty: true),
        ),
      );

      expect(
        (await _tombstonedPhotos(saved.db)).single,
        'photo-1',
        reason: 'the original left the record',
      );
      expect((await _fieldById(saved.db, model)).evidenceRemovedAt, isNull);
    });

    test('writes a history row for every photo added and removed', () async {
      final _Saved saved = await _saved();
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );
      final PhotoDraft added = await _draft(saved, 'photo-2');

      _ok(
        await saved.writer.update(
          edit.copyWith(photos: <PhotoDraft>[added], isDirty: true),
        ),
      );

      final List<AuditLogData> photos = await _photoAudit(saved);
      expect(
        <String>[
          for (final AuditLogData row in photos)
            '${row.newValue}:${row.reason}',
        ],
        <String>['removed:photo-1', 'added:photo-2'],
      );
      for (final AuditLogData row in photos) {
        expect(row.entityType, 'records');
        expect(row.entityId, saved.recordId);
        expect(row.action, AuditAction.updated);
        expect(row.previousValue, isNull);
        expect(row.device, 'device-a');
        expect(row.at.toUtc(), saved.now);
      }
    });

    test('an edit that only changes a caption writes no photo history and '
        'flags nothing', () async {
      final _Saved saved = await _saved();
      final String model = await _readValue(saved, 'model', 'X200', <String>[
        'photo-1',
      ]);
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );

      _ok(
        await saved.writer.update(
          edit.copyWith(
            captions: const <String, String>{
              '': 'Record note, pump room',
              'photo-1': 'Photo note',
            },
            isDirty: true,
          ),
        ),
      );

      expect(await _photoAudit(saved), isEmpty);
      expect((await _fieldById(saved.db, model)).evidenceRemovedAt, isNull);
    });
  });

  group('the status after a saved record is edited', () {
    test('an approved record whose photos change goes back to review, with '
        'the move in its history', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      await _approve(saved);
      final RecordRow before = await saved.db
          .select(saved.db.records)
          .getSingle();

      await _removePhoto(saved, 'photo-2');

      final RecordRow after = await saved.db
          .select(saved.db.records)
          .getSingle();
      expect(after.status, RecordStatus.needsReview.stored);
      expect(after.rev, greaterThan(before.rev));
      // Leaving approved keeps who approved it, for the history.
      expect(after.approvedAt, isNotNull);
      final AuditLogData moved = (await _statusAudit(saved)).last;
      expect(moved.previousValue, RecordStatus.approved.stored);
      expect(moved.newValue, RecordStatus.needsReview.stored);
      expect(moved.reason, isNotEmpty);
      expect(moved.device, 'device-a');
    });

    test(
      'an approved record whose caption changes goes back to review',
      () async {
        final _Saved saved = await _saved();
        await _approve(saved);
        final capture.CaptureSession edit = _ok(
          await saved.writer.load(saved.recordId),
        );

        _ok(
          await saved.writer.update(
            edit.copyWith(
              captions: <String, String>{...edit.captions, '': 'Checked again'},
              isDirty: true,
            ),
          ),
        );

        expect(
          (await saved.db.select(saved.db.records).getSingle()).status,
          RecordStatus.needsReview.stored,
        );
      },
    );

    test('an approved record saved without a change stays approved', () async {
      final _Saved saved = await _saved();
      await _approve(saved);
      final int statusRows = (await _statusAudit(saved)).length;
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );

      _ok(await saved.writer.update(edit.copyWith(isDirty: true)));

      expect(
        (await saved.db.select(saved.db.records).getSingle()).status,
        RecordStatus.approved.stored,
      );
      expect(await _statusAudit(saved), hasLength(statusRows));
      expect(await _photoAudit(saved), isEmpty);
    });

    test('a record that is not approved keeps its status', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      final int statusRows = (await _statusAudit(saved)).length;

      await _removePhoto(saved, 'photo-2');

      expect(
        (await saved.db.select(saved.db.records).getSingle()).status,
        RecordStatus.captured.stored,
      );
      expect(await _statusAudit(saved), hasLength(statusRows));
    });

    test(
      'a failing edit rolls back its photo history, flags and status',
      () async {
        final _Saved saved = await _saved();
        final String model = await _readValue(saved, 'model', 'X200', <String>[
          'photo-1',
        ]);
        await _approve(saved);
        final int auditBefore =
            (await saved.db.select(saved.db.auditLog).get()).length;
        final capture.CaptureSession edit = _ok(
          await saved.writer.load(saved.recordId),
        );

        final Result<void> result = await saved.writer.update(
          edit.copyWith(
            photos: <PhotoDraft>[
              PhotoDraft(
                id: 'photo-bad',
                projectId: saved.projectId,
                relativePath: '/outside/photo.jpg',
                sha256: 'bad-sha',
              ),
            ],
          ),
        );

        expect(result, isA<FailureResult<void>>());
        expect(await _tombstonedPhotos(saved.db), isEmpty);
        expect((await _fieldById(saved.db, model)).evidenceRemovedAt, isNull);
        expect(
          (await saved.db.select(saved.db.records).getSingle()).status,
          RecordStatus.approved.stored,
        );
        expect(
          await saved.db.select(saved.db.auditLog).get(),
          hasLength(auditBefore),
        );
      },
    );
  });

  group('a live caption transcript (task 125)', () {
    late AppDatabase db;
    late TranscriptRepositoryImpl transcripts;
    late CaptureRecordWriter writer;
    late Project project;
    late Template template;

    setUp(() async {
      db = await seededDatabase();
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 4, 9));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      transcripts = TranscriptRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      project = await db.select(db.projects).getSingle();
      template = await db.select(db.templates).getSingle();
    });

    tearDown(() => db.close());

    /// A capture transcript of take `audio-1`, linked to it as the caption
    /// recorder links it at stop, with [words] heard.
    Future<String> heard(List<String> words) async {
      final String id = _ok(
        await transcripts.begin((
          projectId: project.id,
          ownerKind: TranscriptOwnerKind.capture,
          ownerId: null,
          attachmentId: null,
          audioPath: 'projects/${project.folderName}/audio/audio-1.wav',
          title: '',
          languageTag: 'en',
          modelId: 'tiny-q5_1',
          startedAt: DateTime.utc(2026, 10, 4, 9),
        )),
      ).id;
      _ok(
        await transcripts.appendUtterance(
          id,
          FinishedUtterance(
            utteranceId: 1,
            fromSample: 0,
            toSample: 32000,
            segments: <TranscriptSegment>[
              TranscriptSegment(
                id: 1,
                utteranceId: 1,
                startSample: 0,
                endSample: 32000,
                text: words.join(' '),
                languageTag: 'en',
                modelId: 'tiny-q5_1',
              ),
            ],
          ),
        ),
      );
      _ok(await transcripts.linkAttachment(id, 'audio-1'));
      return id;
    }

    capture.CaptureSession withTake() => capture.CaptureSession(
      id: 'session-live',
      projectId: project.id,
      templateId: template.id,
      contextSnapshot: const <String, String>{},
      audio: <AudioDraft>[
        AudioDraft(
          id: 'audio-1',
          projectId: project.id,
          relativePath: 'audio/audio-1.wav',
          mimeType: 'audio/wav',
          fileSize: 64044,
          sha256: 'take-sha',
          durationMs: 2000,
        ),
      ],
    );

    test('a transcript completed before the save is in the record document '
        'once the record holds its audio', () async {
      final String transcript = await heard(<String>['corroded', 'flange']);
      _ok(
        await transcripts.complete(
          transcript,
          duration: const Duration(seconds: 2),
          languageTag: 'en',
          modelId: 'tiny-q5_1',
        ),
      );
      expect(await searchRecords(db, 'corroded'), isEmpty);

      final String recordId = _ok(await writer.createRecord(withTake()));

      expect(await searchRecords(db, 'corroded'), <String>[recordId]);
      expect(await searchRecords(db, 'flange'), <String>[recordId]);
    });

    test('a transcript still draining at the save is found once it '
        'completes', () async {
      final String transcript = await heard(<String>['seized', 'bearing']);

      final String recordId = _ok(await writer.createRecord(withTake()));
      expect(
        await searchRecords(db, 'seized'),
        isEmpty,
        reason: 'a live transcript is not indexed',
      );

      _ok(
        await transcripts.complete(
          transcript,
          duration: const Duration(seconds: 2),
          languageTag: 'en',
          modelId: 'tiny-q5_1',
        ),
      );
      expect(await searchRecords(db, 'seized'), <String>[recordId]);
      expect(
        (await transcripts.watchRecord(recordId).first).single.id,
        transcript,
      );
    });
  });
}

/// [_saved] with a second photo, photo-2, filed on the record by an edit.
Future<_Saved> _savedWithTwoPhotos() async {
  final _Saved saved = await _saved();
  final capture.CaptureSession edit = _ok(
    await saved.writer.load(saved.recordId),
  );
  final PhotoDraft second = await _draft(saved, 'photo-2');
  _ok(
    await saved.writer.update(
      edit.copyWith(
        photos: <PhotoDraft>[...edit.photos, second.copyWith(sortOrder: 1)],
        isDirty: true,
      ),
    ),
  );
  return saved;
}

/// Saves an edit of [saved]'s record without the photo [photoId].
Future<void> _removePhoto(_Saved saved, String photoId) async {
  final capture.CaptureSession edit = _ok(
    await saved.writer.load(saved.recordId),
  );
  _ok(
    await saved.writer.update(
      edit.copyWith(
        photos: <PhotoDraft>[
          for (final PhotoDraft photo in edit.photos)
            if (photo.id != photoId) photo,
        ],
        isDirty: true,
      ),
    ),
  );
}

/// A value processing read as [text] for [fieldKey] from [photoIds]: an OCR
/// row with one photo evidence row per photo. Returns the value's id.
Future<String> _readValue(
  _Saved saved,
  String fieldKey,
  String text,
  List<String> photoIds,
) async {
  final FixedClock clock = FixedClock(saved.now);
  final RecordField value = _ok(
    await insertRecordField(
      saved.db,
      // Explicit ids: a fresh id sequence repeats the writer's own ids.
      row: RecordFieldsCompanion(
        id: Value<String>('value-$fieldKey'),
        recordId: Value<String>(saved.recordId),
        fieldKey: Value<String>(fieldKey),
        valueRaw: Value<String?>(text),
        source: const Value<String>('ocr'),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    ),
  );
  for (final String photoId in photoIds) {
    await _linkEvidence(saved, value.id, photoId);
  }
  return value.id;
}

/// Links value [recordFieldId] to a region of photo [photoId].
Future<void> _linkEvidence(
  _Saved saved,
  String recordFieldId,
  String photoId,
) async {
  final FixedClock clock = FixedClock(saved.now);
  _ok(
    await insertFieldEvidence(
      saved.db,
      row: FieldEvidenceCompanion(
        id: Value<String>('evidence-$recordFieldId-$photoId'),
        recordFieldId: Value<String>(recordFieldId),
        sourceType: const Value<FieldEvidenceSource>(FieldEvidenceSource.photo),
        photoId: Value<String?>(photoId),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    ),
  );
}

/// Approves [saved]'s record, as a reviewer would.
Future<void> _approve(_Saved saved) async {
  final RecordRow record = await saved.db.select(saved.db.records).getSingle();
  await saved.db.transaction(() {
    return writeRecordStatus(
      saved.db,
      recordId: saved.recordId,
      status: RecordStatus.approved.stored,
      previousStatus: record.status,
      clock: FixedClock(saved.now),
      deviceId: 'device-a',
      operator: 'Ada',
      reason: 'approve',
    );
  });
}

Future<RecordField> _fieldById(AppDatabase db, String id) {
  return (db.select(
    db.recordFields,
  )..where((row) => row.id.equals(id))).getSingle();
}

Future<RecordField> _fieldByKey(AppDatabase db, String fieldKey) {
  return (db.select(
    db.recordFields,
  )..where((row) => row.fieldKey.equals(fieldKey))).getSingle();
}

Future<List<String>> _tombstonedPhotos(AppDatabase db) async {
  return <String>[
    for (final Tombstone row in await db.select(db.tombstones).get())
      if (row.entityType == 'photos') row.entityId,
  ];
}

/// [saved]'s record-level photo history rows, in the order written.
Future<List<AuditLogData>> _photoAudit(_Saved saved) {
  return _auditFor(saved, 'photo');
}

/// [saved]'s record-level status history rows, in the order written.
Future<List<AuditLogData>> _statusAudit(_Saved saved) {
  return _auditFor(saved, 'status');
}

Future<List<AuditLogData>> _auditFor(_Saved saved, String fieldKey) async {
  return <AuditLogData>[
    for (final AuditLogData row
        in await saved.db.select(saved.db.auditLog).get())
      if (row.entityType == 'records' &&
          row.entityId == saved.recordId &&
          row.fieldKey == fieldKey)
        row,
  ];
}

typedef _Saved = ({
  AppDatabase db,
  CaptureRecordWriter writer,
  String recordId,
  String projectId,
  String templateId,
  DateTime now,
});

/// A database holding one saved record from [_session].
Future<_Saved> _saved() async {
  final AppDatabase db = await seededDatabase();
  addTearDown(db.close);
  final DateTime now = DateTime.utc(2026, 9, 23, 16, 35);
  final FixedClock clock = FixedClock(now);
  final CaptureRecordWriter writer = CaptureRecordWriter(
    db: db,
    clock: clock,
    deviceId: 'device-a',
    ids: UuidV7Service.sequence(clock),
  );
  final Project project = await db.select(db.projects).getSingle();
  final Template template = await db.select(db.templates).getSingle();
  final String recordId = _ok(
    await writer.persist(
      _session(projectId: project.id, templateId: template.id, now: now),
    ),
  );
  return (
    db: db,
    writer: writer,
    recordId: recordId,
    projectId: project.id,
    templateId: template.id,
    now: now,
  );
}

/// A photo written during an edit: a row with its file, not yet filed.
/// [derivedFrom] makes it an edited copy of that photo.
Future<PhotoDraft> _draft(
  _Saved saved,
  String id, {
  String? derivedFrom,
}) async {
  final PhotoDraft photo = PhotoDraft(
    id: id,
    projectId: saved.projectId,
    captureSessionId: saved.recordId,
    originalFilename: '$id.jpg',
    storedFilename: '$id.jpg',
    relativePath: 'photos/$id.jpg',
    sha256: '$id-sha',
    fileSize: 1024,
    capturedAt: saved.now,
    derivedFrom: derivedFrom,
  );
  final FixedClock clock = FixedClock(saved.now);
  _ok(
    await upsertPhoto(
      saved.db,
      row: PhotosCompanion(
        id: Value<String>(photo.id),
        projectId: Value<String>(photo.projectId),
        captureSessionId: Value<String>(photo.captureSessionId),
        originalFilename: Value<String>(photo.originalFilename),
        storedFilename: Value<String>(photo.storedFilename),
        relativePath: Value<String>(photo.relativePath),
        photoType: Value<String>(photo.photoType),
        sortOrder: Value<int>(photo.sortOrder),
        width: Value<int>(photo.width),
        height: Value<int>(photo.height),
        sha256: Value<String>(photo.sha256),
        fileSize: Value<int>(photo.fileSize),
        mimeType: Value<String>(photo.mimeType),
        capturedAt: Value<DateTime>(saved.now),
        derivedFrom: Value<String?>(derivedFrom),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    ),
  );
  return photo;
}

capture.CaptureSession _session({
  required String projectId,
  required String templateId,
  required DateTime now,
  String photoPath = 'photos/photo-1.jpg',
}) {
  return capture.CaptureSession(
    id: 'session-1',
    projectId: projectId,
    templateId: templateId,
    contextSnapshot: const <String, String>{'country': 'Uganda'},
    photos: <PhotoDraft>[
      PhotoDraft(
        id: 'photo-1',
        projectId: projectId,
        captureSessionId: 'session-1',
        originalFilename: 'IMG_0001.jpg',
        storedFilename: 'photo-1.jpg',
        relativePath: photoPath,
        sha256: 'photo-sha',
        fileSize: 2048,
        width: 1600,
        height: 1200,
        capturedAt: now,
        hasCaption: true,
      ),
    ],
    audio: <AudioDraft>[
      AudioDraft(
        id: 'audio-1',
        projectId: projectId,
        relativePath: 'audio/audio-1.wav',
        mimeType: 'audio/wav',
        fileSize: 4096,
        sha256: 'audio-sha',
        durationMs: 1250,
        photoIds: const <String>['photo-1'],
      ),
    ],
    captions: const <String, String>{
      '': 'Record note',
      'photo-1': 'Photo note',
    },
    values: const <String, Object?>{'serial': 'SN-42'},
    isDirty: true,
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

Future<TemplateDef> _automaticPreviewTemplate(
  AppDatabase db,
  Clock clock,
  UuidV7Service ids,
) async {
  final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
    db: db,
    clock: clock,
    deviceId: 'app-device-id',
    ids: ids,
  );
  final Template row = await db.select(db.templates).getSingle();
  final TemplateDef initial = _ok(await templates.byId(row.id))!;
  return _ok(
    await templates.save(
      initial.copyWith(
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'capture_instant',
            label: 'Capture instant',
            type: FieldType.dateTime,
            autoFill: AutoFill.now,
          ),
          FieldDef(
            fieldKey: 'captured_date',
            label: 'Captured date',
            type: FieldType.date,
            group: 'record_admin',
            inputMode: InputMode.auto,
          ),
          FieldDef(
            fieldKey: 'captured_time',
            label: 'Captured time',
            type: FieldType.time,
            group: 'record_admin',
            inputMode: InputMode.auto,
          ),
          FieldDef(
            fieldKey: 'operator_label',
            label: 'Operator',
            type: FieldType.text,
            autoFill: AutoFill.operator,
          ),
          FieldDef(
            fieldKey: 'device_id',
            label: 'App device identifier',
            type: FieldType.text,
            group: 'record_admin',
            inputMode: InputMode.auto,
          ),
          FieldDef(
            fieldKey: 'batch_number',
            label: 'Batch number',
            type: FieldType.number,
            autoFill: AutoFill.sequence,
          ),
          FieldDef(
            fieldKey: 'area',
            label: 'Area',
            type: FieldType.text,
            autoFill: AutoFill.context,
          ),
          FieldDef(
            fieldKey: 'clear_context',
            label: 'Clear context',
            type: FieldType.text,
            autoFill: AutoFill.context,
          ),
        ],
      ),
    ),
  );
}

Future<TemplateDef> _localAddressTemplate(
  AppDatabase db,
  Clock clock,
  UuidV7Service ids,
) async {
  final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
    db: db,
    clock: clock,
    deviceId: 'app-id',
    ids: ids,
  );
  final Template row = await db.select(db.templates).getSingle();
  final TemplateDef initial = _ok(await templates.byId(row.id))!;
  return _ok(
    await templates.save(
      initial.copyWith(
        fields: <FieldDef>[
          for (final String key in <String>[
            'network_address',
            'typed_address',
            'clear_address',
            'context_address',
          ])
            FieldDef(
              fieldKey: key,
              label: key,
              type: FieldType.text,
              autoFill: AutoFill.localAddress,
            ),
          const FieldDef(
            fieldKey: 'sibling_device',
            label: 'App identity',
            type: FieldType.text,
            autoFill: AutoFill.device,
          ),
        ],
      ),
    ),
  );
}
