import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/templates/data/shipped_template_loader.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/templates.dart'
    show AutoFill, FieldDef, InputMode, TemplateDef, TemplateVersioning;

import '../../../support/factories.dart';

void main() {
  test(
    'the actual inherited shape fills capture metadata beside unchanged templates',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      fixture.expectSourceLess(fixture.shipped);
      fixture.expectSourceLess(fixture.template);
      final List<Map<String, Object?>> templatesBefore = <Map<String, Object?>>[
        for (final Template row
            in await fixture.db.select(fixture.db.templates).get())
          row.toJson(),
      ];
      final List<Map<String, Object?>> fieldsBefore = <Map<String, Object?>>[
        for (final TemplateField row
            in await fixture.db.select(fixture.db.templateFields).get())
          row.toJson(),
      ];

      final String id = (await fixture.writer().persist(
        fixture.session(),
      )).getOrThrow();
      await fixture.expectAutomatic(id);
      expect(<Map<String, Object?>>[
        for (final Template row
            in await fixture.db.select(fixture.db.templates).get())
          row.toJson(),
      ], templatesBefore);
      expect(<Map<String, Object?>>[
        for (final TemplateField row
            in await fixture.db.select(fixture.db.templateFields).get())
          row.toJson(),
      ], fieldsBefore);
      for (final MapEntry<String, String> asset in fixture.assets.entries) {
        expect(
          await File(asset.key).readAsString(),
          asset.value,
          reason: asset.key,
        );
      }
      final Map<String, RecordField> fields = await fixture.fields(id);
      for (final String key in <String>[
        'record_uid',
        'template_key',
        'captured_by_user_id',
        'created_at',
      ]) {
        expect(fields.containsKey(key), isFalse, reason: key);
      }
      final RecordRow record = await fixture.record(id);
      expect(record.capturedAt.toUtc(), _saveInstant);
      expect(record.capturedBy, _device);
      expect(record.recordNumber, 1);
      expect(record.templateVersion, fixture.template.version);
    },
  );

  test(
    'an existing customized copy keeps source-less bindings after reload',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final TemplateDef customized = (await fixture.templates.save(
        fixture.template.copyWith(name: 'Customized equipment capture'),
      )).getOrThrow();
      final TemplateDef reloaded = (await fixture.templates.byId(
        customized.id,
      )).getOrThrow()!;
      fixture.expectSourceLess(reloaded);
      final String id = (await fixture.writer().persist(
        fixture.session(version: reloaded.version),
      )).getOrThrow();
      await fixture.expectAutomatic(id);
      expect(
        (await fixture.templates.byId(customized.id)).getOrThrow(),
        reloaded,
      );
    },
  );

  test(
    'a pinned older source-less shape fills even after the current modes change',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final TemplateDef changed = (await fixture.templates.save(
        fixture.template.copyWith(
          fields: <FieldDef>[
            for (final FieldDef field in fixture.template.fields)
              if (_metadataKeys.contains(field.fieldKey))
                field.copyWith(inputMode: InputMode.manualOnly)
              else
                field,
          ],
        ),
      )).getOrThrow();
      final TemplateDef pinned = TemplateVersioning.shapeFor(
        changed,
        fixture.template.version,
      )!;
      fixture.expectSourceLess(pinned);
      final String oldId = (await fixture.writer().persist(
        fixture.session(),
      )).getOrThrow();
      await fixture.expectAutomatic(oldId);
      final String currentId = (await fixture.writer().persist(
        fixture.session(id: 'current-shape', version: changed.version),
      )).getOrThrow();
      expect(
        (await fixture.fields(currentId)).keys,
        isNot(anyElement(isIn(_metadataKeys))),
      );
      expect((await fixture.templates.byId(changed.id)).getOrThrow(), changed);
    },
  );

  test(
    'date filling can be disabled without changing actual capture attribution',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final String id =
          (await fixture
                  .writer(autoFillDates: false)
                  .persist(fixture.session()))
              .getOrThrow();
      final Map<String, RecordField> fields = await fixture.fields(id);
      expect(fields.containsKey('captured_date'), isFalse);
      expect(fields.containsKey('captured_time'), isFalse);
      expect(fields['device_id']?.valueRaw, _device);
      expect(fields['device_id']?.source, 'AUTO');
      final RecordRow record = await fixture.record(id);
      expect(record.capturedAt.toUtc(), _saveInstant);
      expect(record.capturedBy, _device);
    },
  );

  test(
    'typed and context metadata retain priority and provenance over fallback',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final String id = (await fixture.writer().persist(
        fixture.session(
          context: const <String, String>{
            'captured_date': '2001-02-03',
            'captured_time': '04:05:06',
          },
          values: const <String, Object?>{'captured_date': '2002-03-04'},
        ),
      )).getOrThrow();
      final Map<String, RecordField> fields = await fixture.fields(id);
      expect(fields['captured_date']?.valueRaw, '2002-03-04');
      expect(fields['captured_date']?.source, 'TYPED');
      expect(fields['captured_time']?.valueRaw, '04:05:06');
      expect(fields['captured_time']?.source, 'CONTEXT');
      expect(fields['device_id']?.valueRaw, _device);
      expect(fields['device_id']?.source, 'AUTO');
      expect((await fixture.record(id)).capturedAt.toUtc(), _saveInstant);
    },
  );

  test(
    'an explicit default and source on the copied fields suppress fallback',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final TemplateDef configured = (await fixture.templates.save(
        fixture.template.copyWith(
          fields: <FieldDef>[
            for (final FieldDef field in fixture.template.fields)
              switch (field.fieldKey) {
                'captured_date' => field.copyWith(defaultValue: '2003-04-05'),
                'captured_time' => field.copyWith(autoFill: AutoFill.context),
                _ => field,
              },
          ],
        ),
      )).getOrThrow();
      final String id = (await fixture.writer().persist(
        fixture.session(version: configured.version),
      )).getOrThrow();
      final Map<String, RecordField> fields = await fixture.fields(id);
      expect(fields['captured_date']?.valueRaw, '2003-04-05');
      expect(fields['captured_date']?.source, 'AUTO');
      expect(fields.containsKey('captured_time'), isFalse);
      expect(fields['device_id']?.valueRaw, _device);
    },
  );

  test(
    'retry preserves first-save values, identity and history after clock and device changes',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final CaptureSession session = fixture.session();
      final String id = (await fixture.writer().persist(session)).getOrThrow();
      final RecordRow before = await fixture.record(id);
      final Map<String, RecordField> fieldsBefore = await fixture.fields(id);
      final List<AuditLogData> auditBefore = await fixture.db
          .select(fixture.db.auditLog)
          .get();
      final String retried =
          (await fixture
                  .writer(
                    clock: FixedClock(
                      _saveInstant.add(const Duration(days: 1)),
                    ),
                    deviceId: 'changed-device',
                  )
                  .persist(session))
              .getOrThrow();
      expect(retried, id);
      expect(await fixture.record(id), before);
      expect(await fixture.fields(id), fieldsBefore);
      expect(await fixture.db.select(fixture.db.auditLog).get(), auditBefore);
      expect(await fixture.db.select(fixture.db.records).get(), hasLength(1));
    },
  );

  test(
    'an unknown legacy capture shape never borrows current fallback bindings',
    () async {
      final _MetadataFixture fixture = await _MetadataFixture.open();
      final String id = (await fixture.writer().persist(
        fixture.session(version: 0),
      )).getOrThrow();
      expect(
        (await fixture.fields(id)).keys,
        isNot(anyElement(isIn(_metadataKeys))),
      );
      expect((await fixture.record(id)).templateVersion, 0);
    },
  );
}

final DateTime _saveInstant = DateTime.utc(2026, 10, 9, 7, 4, 5);
const String _device = 'capture-device';
const Set<String> _metadataKeys = <String>{
  'captured_date',
  'captured_time',
  'device_id',
};

final class _MetadataFixture {
  const _MetadataFixture({
    required this.db,
    required this.project,
    required this.clock,
    required this.ids,
    required this.templates,
    required this.shipped,
    required this.template,
    required this.assets,
  });

  final AppDatabase db;
  final Project project;
  final FixedClock clock;
  final UuidV7Service ids;
  final TemplateRepositoryImpl templates;
  final TemplateDef shipped;
  final TemplateDef template;
  final Map<String, String> assets;

  static Future<_MetadataFixture> open() async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final Project project = await db.select(db.projects).getSingle();
    final FixedClock clock = FixedClock(_saveInstant);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: _device,
      ids: ids,
    );
    final Map<String, String> assets = <String, String>{};
    final ShippedTemplateLoader loader = ShippedTemplateLoader(
      templates: templates,
      readAsset: (String path) async {
        final String text = await File(path).readAsString();
        assets[path] = text;
        return text;
      },
    );
    final TemplateDef shipped = (await loader.template(
      'ast_equipment_master_inventory',
    )).getOrThrow();
    final TemplateDef template = (await loader.copyToProject(
      templateKey: shipped.templateKey,
      projectId: project.id,
      name: 'Equipment capture',
    )).getOrThrow();
    return _MetadataFixture(
      db: db,
      project: project,
      clock: clock,
      ids: ids,
      templates: templates,
      shipped: shipped,
      template: template,
      assets: assets,
    );
  }

  CaptureRecordWriter writer({
    Clock? clock,
    String deviceId = _device,
    bool autoFillDates = true,
  }) => CaptureRecordWriter(
    db: db,
    clock: clock ?? this.clock,
    deviceId: deviceId,
    ids: ids,
    autoFillDates: () => autoFillDates,
  );

  CaptureSession session({
    String id = 'inherited-metadata',
    int? version,
    Map<String, String> context = const <String, String>{},
    Map<String, Object?> values = const <String, Object?>{},
  }) => CaptureSession(
    id: id,
    projectId: project.id,
    templateId: template.id,
    templateVersion: version ?? template.version,
    contextSnapshot: context,
    captions: const <String, String>{'': 'Equipment observation'},
    values: values,
  );

  Future<RecordRow> record(String id) =>
      (db.select(db.records)..where((row) => row.id.equals(id))).getSingle();

  Future<Map<String, RecordField>> fields(String id) async =>
      <String, RecordField>{
        for (final RecordField field in await (db.select(
          db.recordFields,
        )..where((row) => row.recordId.equals(id))).get())
          field.fieldKey: field,
      };

  void expectSourceLess(TemplateDef shape) {
    for (final String key in _metadataKeys) {
      final FieldDef field = shape.fields.singleWhere(
        (FieldDef field) => field.fieldKey == key,
      );
      expect(field.group, 'record_admin', reason: key);
      expect(field.inputMode, InputMode.auto, reason: key);
      expect(field.autoFill, isNull, reason: key);
      expect(field.defaultValue, isNull, reason: key);
    }
  }

  Future<void> expectAutomatic(String id) async {
    final Map<String, RecordField> saved = await fields(id);
    final DateTime local = _saveInstant.toLocal();
    expect(
      saved['captured_date']?.valueRaw,
      DateFormat('yyyy-MM-dd', 'en_US').format(local),
    );
    expect(
      saved['captured_time']?.valueRaw,
      DateFormat('HH:mm:ss', 'en_US').format(local),
    );
    expect(saved['device_id']?.valueRaw, _device);
    for (final String key in _metadataKeys) {
      expect(saved[key]?.source, 'AUTO', reason: key);
      expect(saved[key]?.valueRefined, isNull, reason: key);
      expect(saved[key]?.valueFinal, isNull, reason: key);
    }
  }
}
