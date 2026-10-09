import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';
import 'package:tapture/features/templates/domain/template_versioning.dart';
import 'package:tapture/features/templates/presentation/template_duplicate_action.dart';

import '../../../support/factories.dart';
import '../template_repository_contract.dart';

void main() {
  late AppDatabase db;
  late TemplateRepositoryImpl repo;

  final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
  final FixedClock clock = FixedClock(t0);

  setUp(() {
    db = AppDatabase.memory();
    repo = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
  });

  tearDown(() async {
    await db.close();
  });

  runTemplateRepositoryContract(() => repo);

  test(
    'a configured local address survives SQL restart and immutable version history',
    () async {
      final TemplateDef first = _ok(
        await repo.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'address',
                label: 'Address',
                type: FieldType.text,
                autoFill: AutoFill.localAddress,
              ),
            ],
          ),
        ),
      );
      final TemplateDef second = _ok(
        await repo.save(first.copyWith(name: 'Renamed')),
      );
      final TemplateRepositoryImpl reopened = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      );
      final TemplateDef loaded = _ok(await reopened.byId(first.id))!;
      expect(loaded, second);
      expect(loaded.fields.single.autoFill, AutoFill.localAddress);
      expect(
        TemplateVersioning.shapeFor(
          loaded,
          first.version,
        )!.fields.single.autoFill,
        AutoFill.localAddress,
      );
      final TemplateField row = await db.select(db.templateFields).getSingle();
      expect(jsonDecode(row.validation), <String, Object?>{
        '_tapture': <String, Object?>{'autoFill': 'LOCAL_ADDRESS'},
      });
    },
  );

  for (final Object declaration in <Object>[
    'FUTURE_SOURCE',
    'NOW',
    false,
    <String, Object?>{'provider': 'future'},
    'LOCAL_ADDRESS',
  ]) {
    test(
      'unrelated saves retain stored opaque $declaration through restart and captured versions',
      () async {
        final TemplateDef initial = _ok(
          await repo.save(
            aTemplate(
              fields: const <FieldDef>[
                FieldDef(
                  fieldKey: 'address',
                  label: 'Address',
                  type: FieldType.number,
                ),
                FieldDef(
                  fieldKey: 'instant',
                  label: 'Instant',
                  type: FieldType.text,
                  autoFill: AutoFill.now,
                ),
              ],
            ).copyWith(identityFieldKeys: const <String>['address']),
          ),
        );
        await (db.update(
          db.templateFields,
        )..where((row) => row.fieldKey.equals('address'))).write(
          TemplateFieldsCompanion(
            autoFill: const Value<bool>(true),
            validation: Value<String>(
              jsonEncode(<String, Object?>{
                '_tapture': <String, Object?>{
                  'autoFill': declaration,
                  if (declaration == 'NOW') 'autoFillTop': 'FUTURE_TOP',
                },
              }),
            ),
          ),
        );
        final TemplateDef stored = _ok(await repo.byId(initial.id))!;
        final TemplateDef edited = _ok(
          await repo.save(
            stored.copyWith(
              name: 'Renamed',
              fields: <FieldDef>[
                stored.fields.last,
                stored.fields.first.copyWith(
                  label: 'Renamed address',
                  validation: <String, Object?>{
                    ...stored.fields.first.validation,
                    'min': 2,
                  },
                ),
              ],
            ),
          ),
        );
        final TemplateRepositoryImpl reopened = TemplateRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        );
        final TemplateDef loaded = _ok(await reopened.byId(edited.id))!;
        final FieldDef address = loaded.fields.singleWhere(
          (field) => field.fieldKey == 'address',
        );
        expect(address.autoFill, isNull);
        expect(address.validation, <String, Object?>{
          'min': 2,
          '_tapture': <String, Object?>{
            'autoFill': declaration,
            if (declaration == 'NOW') 'autoFillTop': 'FUTURE_TOP',
          },
        });
        expect(loaded.fields.first.autoFill, AutoFill.now);
        expect(loaded.identityFieldKeys, <String>['address']);
        final TemplateDef original = TemplateVersioning.shapeFor(
          loaded,
          initial.version,
        )!;
        expect(original.fields.first.autoFill, isNull);
        expect(original.fields.first.validation['_tapture'], <String, Object?>{
          'autoFill': declaration,
          if (declaration == 'NOW') 'autoFillTop': 'FUTURE_TOP',
        });
        expect(original.fields.last.autoFill, AutoFill.now);
      },
    );
  }

  for (final FieldDef invalid in <FieldDef>[
    const FieldDef(
      fieldKey: 'bad',
      label: 'Bad',
      type: FieldType.number,
      autoFill: AutoFill.localAddress,
    ),
    const FieldDef(
      fieldKey: 'bad',
      label: 'Bad',
      type: FieldType.text,
      validation: <String, Object?>{
        '_tapture': <String, Object?>{'autoFill': 'FUTURE_SOURCE'},
      },
    ),
    const FieldDef(
      fieldKey: 'bad',
      label: 'Bad',
      type: FieldType.text,
      validation: <String, Object?>{
        '_tapture': <String, Object?>{'autoFillTop': 'FUTURE_SOURCE'},
      },
    ),
  ]) {
    test(
      'a new invalid source ${invalid.autoFill ?? invalid.validation} changes no SQL rows or history',
      () async {
        final before = await db.select(db.templates).get();
        final audit = await db.select(db.auditLog).get();
        expect(
          await repo.save(aTemplate(fields: <FieldDef>[invalid])),
          isA<FailureResult<TemplateDef>>().having(
            (FailureResult<TemplateDef> result) => result.failure,
            'failure',
            isA<ValidationFailure>(),
          ),
        );
        expect(await db.select(db.templates).get(), before);
        expect(await db.select(db.templateFields).get(), isEmpty);
        expect(await db.select(db.auditLog).get(), audit);
      },
    );
  }

  test(
    'replacing a source with a new opaque declaration is refused atomically',
    () async {
      final TemplateDef initial = _ok(
        await repo.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
                autoFill: AutoFill.now,
              ),
            ],
          ),
        ),
      );
      final TemplateDef changed = initial.copyWith(
        fields: <FieldDef>[
          FieldDef(
            fieldKey: initial.fields.first.fieldKey,
            label: initial.fields.first.label,
            type: initial.fields.first.type,
            validation: const <String, Object?>{
              '_tapture': <String, Object?>{'autoFill': 'FUTURE_SOURCE'},
            },
          ),
        ],
      );
      final before = await db.select(db.templates).get();
      final fields = await db.select(db.templateFields).get();
      final audit = await db.select(db.auditLog).get();
      expect(await repo.save(changed), isA<FailureResult<TemplateDef>>());
      expect(await db.select(db.templates).get(), before);
      expect(await db.select(db.templateFields).get(), fields);
      expect(await db.select(db.auditLog).get(), audit);
    },
  );

  test(
    'malformed immutable history remains raw and unresolved after a name edit',
    () async {
      final TemplateDef first = _ok(await repo.save(aTemplate()));
      final Map<String, Object?> invalid = <String, Object?>{
        'schema_version': 1,
        'name': 42,
        'fields': <Object>[],
      };
      await db
          .update(db.templates)
          .write(
            TemplatesCompanion(
              detection: Value<String>(
                jsonEncode(<String, Object?>{
                  '_tapture_versions': <String, Object?>{'77': invalid},
                }),
              ),
            ),
          );
      final TemplateDef stored = _ok(await repo.byId(first.id))!;
      final TemplateDef edited = _ok(
        await repo.save(stored.copyWith(name: 'Edited')),
      );
      expect((edited.detection['_tapture_versions']! as Map)['77'], invalid);
      expect(TemplateVersioning.shapeFor(edited, 77), isNull);
    },
  );

  test('failed restore rolls back every lifted child tombstone', () async {
    final TemplateDef stored = _ok(
      await repo.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'note', label: 'Note', type: FieldType.text),
          ],
        ),
      ),
    );
    _ok(await repo.delete(stored.id, reason: 'Delete for Undo'));
    final before = await db.select(db.tombstones).get();
    await db.customStatement(
      "CREATE TRIGGER fail_template_restore BEFORE UPDATE ON templates BEGIN SELECT RAISE(ABORT, 'restore failed'); END",
    );
    expect(await repo.restore(stored.id), isA<FailureResult<void>>());
    expect(await db.select(db.tombstones).get(), before);
    expect(_ok(await repo.byId(stored.id)), isNull);
  });

  test(
    'library attachment has fresh child IDs and survives source deletion and Undo',
    () async {
      const TemplateDef draft = TemplateDef(
        id: '',
        templateKey: 'library',
        name: 'Library',
        version: 1,
        fields: <FieldDef>[
          FieldDef(fieldKey: 'active', label: 'Active', type: FieldType.text),
          FieldDef(fieldKey: 'retired', label: 'Retired', type: FieldType.text),
        ],
        identityFieldKeys: <String>[],
        rows: <TemplateRow>[
          TemplateRow(identifier: 'row', label: 'Row', outputRowNumber: 1),
        ],
        sourceFilePath: 'raw/template.xlsx',
      );
      final TemplateDef library = _ok(await repo.save(draft));
      final TemplateDef edited = _ok(
        await repo.save(
          library.copyWith(fields: <FieldDef>[library.fields.first]),
        ),
      );
      final TemplateDef attached = _ok(
        await repo.save(
          TemplateDuplicateAction.draftFrom(
            edited,
          ).copyWith(projectId: 'project-1'),
        ),
      );
      final fields = await db.select(db.templateFields).get();
      final rows = await db.select(db.templateRows).get();
      expect(
        fields
            .where((row) => row.templateId == attached.id)
            .map((row) => row.id)
            .toSet()
            .intersection(
              fields
                  .where((row) => row.templateId == edited.id)
                  .map((row) => row.id)
                  .toSet(),
            ),
        isEmpty,
      );
      expect(
        rows.where((row) => row.templateId == attached.id).single.id,
        isNot(rows.where((row) => row.templateId == edited.id).single.id),
      );
      final String detectionBefore = (await db.select(db.templates).get())
          .firstWhere((row) => row.id == edited.id)
          .detection;
      _ok(await repo.delete(edited.id, reason: 'Remove library source'));
      expect(_ok(await repo.byId(attached.id)), attached);
      _ok(await repo.restore(edited.id));
      final TemplateDef restored = _ok(await repo.byId(edited.id))!;
      expect(restored, edited);
      expect(restored.fields.map((field) => field.fieldKey), <String>[
        'active',
      ]);
      expect(
        (await db.select(db.templates).get())
            .firstWhere((row) => row.id == edited.id)
            .detection,
        detectionBefore,
      );
      expect(
        (await db.select(db.tombstones).get()).where(
          (row) => row.entityType == 'template_fields',
        ),
        hasLength(1),
      );
      expect(_ok(await repo.byId(attached.id)), attached);
    },
  );

  test('save round-trips every §12.2 attribute against the database', () async {
    const FieldDef field = FieldDef(
      fieldKey: 'serial_number',
      label: 'Serial number',
      type: FieldType.longText,
      requiredness: Requiredness.recommended,
      defaultValue: 'n/a',
      unit: 'kg',
      helpText: 'Stamped on the plate.',
      inputMode: InputMode.manualOnly,
      stickable: true,
      contextLevel: 2,
      autoFill: AutoFill.today,
      refine: true,
      options: <Object>[
        <String, Object?>{'code': 'A', 'label': 'Excellent'},
        'Other',
      ],
      group: 'identity',
      outputColumn: 'B',
      requiredWhen: 'fault_present == true',
      hidden: true,
      identity: true,
      validation: <String, Object?>{
        'pattern': r'^[A-Z0-9-]+$',
        'message': 'Use letters, digits or a hyphen.',
      },
      lookup: <String, Object?>{'datasetId': 'suppliers', 'keyColumn': 'name'},
    );
    const TemplateRow row = TemplateRow(
      identifier: 'm-1',
      label: 'Blood Pressure Machine',
      outputRowNumber: 12,
      aliases: <String>['BP machine'],
      metadata: <String, Object?>{'room': 'ward-2'},
      foundStatus: 'found',
    );
    final TemplateDef stored = _ok(
      await repo.save(
        aTemplate(
          templateKey: 'equipment_asset',
          fields: <FieldDef>[field],
          identityFieldKeys: <String>['serial_number'],
          rows: <TemplateRow>[row],
        ).copyWith(
          kind: 'equipment',
          source: 'imported',
          sourceFilePath: 'templates/equipment.xlsx',
          sheetName: 'Register',
          headerRow: 2,
          detection: const <String, Object?>{'min_columns': 4},
        ),
      ),
    );

    expect(stored.templateKey, 'equipment_asset');
    expect(stored.kind, 'equipment');
    expect(stored.source, 'imported');
    expect(stored.sourceFilePath, 'templates/equipment.xlsx');
    expect(stored.sheetName, 'Register');
    expect(stored.headerRow, 2);
    expect(stored.detection, <String, Object?>{'min_columns': 4});
    expect(stored.identityFieldKeys, <String>['serial_number']);
    expect(stored.fields.single, field.copyWith(sortOrder: 0));
    expect(stored.rows.single, row);

    final TemplateDef? loaded = _ok(await repo.byId(stored.id));
    expect(loaded, stored);
  });

  test('a removed field is gone on the next read', () async {
    final TemplateDef first = _ok(
      await repo.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(fieldKey: 'make', label: 'Make', type: FieldType.text),
          ],
        ),
      ),
    );
    final TemplateDef second = _ok(
      await repo.save(first.copyWith(fields: <FieldDef>[first.fields.first])),
    );
    expect(second.fields.map((FieldDef field) => field.fieldKey), <String>[
      'serial',
    ]);
  });

  test(
    'an edit keeps the previous version resolvable through shapeFor',
    () async {
      final TemplateDef first = _ok(
        await repo.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
              ),
            ],
          ),
        ),
      );
      final TemplateDef second = _ok(
        await repo.save(
          first.copyWith(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial number',
                type: FieldType.number,
              ),
              FieldDef(
                fieldKey: 'colour',
                label: 'Colour',
                type: FieldType.text,
              ),
            ],
          ),
        ),
      );

      final TemplateDef loaded = _ok(await repo.byId(first.id))!;
      final TemplateDef? captured = TemplateVersioning.shapeFor(
        loaded,
        first.version,
      );

      expect(second.version, greaterThan(first.version));
      expect(loaded.version, second.version);
      expect(captured, isNotNull);
      expect(captured!.version, first.version);
      expect(
        captured.fields.map((FieldDef field) => (field.fieldKey, field.label)),
        <(String, String)>[('serial', 'Serial')],
      );
      expect(captured.fields.single.type, FieldType.text);
    },
  );

  test('a shipped template is not listed on a project watch', () async {
    final TemplateDef draft = aTemplate(name: 'Library');
    _ok(
      await repo.save(
        TemplateDef(
          id: draft.id,
          templateKey: draft.templateKey,
          name: draft.name,
          version: draft.version,
          fields: draft.fields,
          identityFieldKeys: draft.identityFieldKeys,
          rows: draft.rows,
          kind: draft.kind,
          source: 'shipped',
        ),
      ),
    );
    expect(await repo.watchByProject('p1').first, isEmpty);
    expect(_ok(await repo.byId(draft.id))?.projectId, isNull);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
