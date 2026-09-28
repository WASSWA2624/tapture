import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/template_migration_repository_impl.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';

void main() {
  late AppDatabase db;
  late TemplateMigrationRepositoryImpl migrations;
  late TemplateRepositoryImpl templates;
  late TemplateDef first;
  late TemplateDef second;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 28));

  setUp(() async {
    db = await seededDatabase(records: 2);
    migrations = TemplateMigrationRepositoryImpl(db: db, clock: clock);
    templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'test',
      ids: UuidV7Service.sequence(clock),
    );
    final Template header = await db.select(db.templates).getSingle();
    first = (await templates.byId(header.id) as Success<TemplateDef?>).value!;
    first =
        (await templates.save(
                  first.copyWith(
                    fields: const <FieldDef>[
                      FieldDef(
                        fieldKey: 'old',
                        label: 'Old',
                        type: FieldType.text,
                      ),
                    ],
                  ),
                )
                as Success<TemplateDef>)
            .value;
    await db
        .update(db.records)
        .write(RecordsCompanion(templateVersion: Value<int>(first.version)));
    for (final RecordRow record in await db.select(db.records).get()) {
      expect(
        await insertRecordField(
          db,
          row: RecordFieldsCompanion(
            recordId: Value<String>(record.id),
            fieldKey: const Value<String>('old'),
            valueRaw: const Value<String>('original'),
            valueRefined: const Value<String>('proposal'),
            valueFinal: const Value<String>('approved'),
            source: const Value<String>('typed'),
          ),
          clock: clock,
          deviceId: 'test',
          ids: UuidV7Service(clock),
        ),
        isA<Success<RecordField>>(),
      );
    }
    second =
        (await templates.save(
                  first.copyWith(
                    fields: const <FieldDef>[
                      FieldDef(
                        fieldKey: 'new',
                        label: 'New',
                        type: FieldType.number,
                      ),
                    ],
                  ),
                )
                as Success<TemplateDef>)
            .value;
  });

  tearDown(() async => db.close());

  test(
    'migration retires removed fields atomically and preserves raw, proposed and approved evidence',
    () async {
      final List<CapturedTemplateRecord> before = await migrations
          .watch(first.id)
          .first;
      expect(before, hasLength(2));
      expect(
        before.every((record) => record.templateVersion == first.version),
        isTrue,
      );
      expect(await migrations.watch('another-template').first, isEmpty);
      expect(
        await migrations.migrate(template: second, reviewed: before),
        isA<Success<void>>(),
      );
      final List<CapturedTemplateRecord> after = await migrations
          .watch(first.id)
          .first;
      expect(
        after.every((record) => record.templateVersion == second.version),
        isTrue,
      );
      for (final RecordField field in await db.select(db.recordFields).get()) {
        expect(field.retiredAt?.toUtc(), clock.nowUtc());
        expect(
          (field.valueRaw, field.valueRefined, field.valueFinal),
          ('original', 'proposal', 'approved'),
        );
      }
      final List<AuditLogData> audit = await (db.select(
        db.auditLog,
      )..where((row) => row.fieldKey.equals('template_version'))).get();
      expect(audit, hasLength(2));
    },
  );

  test(
    'a failing second record rolls back versions, retired flags and audit',
    () async {
      final List<CapturedTemplateRecord> before = await migrations
          .watch(first.id)
          .first;
      final String rejected = before.last.id.replaceAll("'", "''");
      await db.customStatement(
        "CREATE TRIGGER reject_migration BEFORE UPDATE OF template_version ON records WHEN NEW.id = '$rejected' BEGIN SELECT RAISE(ABORT, 'fixture'); END",
      );
      expect(
        await migrations.migrate(template: second, reviewed: before),
        isA<FailureResult<void>>(),
      );
      final List<CapturedTemplateRecord> after = await migrations
          .watch(first.id)
          .first;
      expect(
        after.every((record) => record.templateVersion == first.version),
        isTrue,
      );
      expect(after.every((record) => record.retired.isEmpty), isTrue);
      expect(
        await (db.select(
          db.auditLog,
        )..where((row) => row.fieldKey.equals('template_version'))).get(),
        isEmpty,
      );
    },
  );

  test(
    'a stale reviewed version changes nothing and asks for another review',
    () async {
      final List<CapturedTemplateRecord> before = await migrations
          .watch(first.id)
          .first;
      await templates.save(second.copyWith(name: 'Changed after preview'));
      final Result<void> result = await migrations.migrate(
        template: second,
        reviewed: before,
      );
      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.recoveryAction,
        contains('Review'),
      );
      expect(
        (await migrations.watch(first.id).first).every(
          (record) => record.templateVersion == first.version,
        ),
        isTrue,
      );
    },
  );

  test(
    'a record that moved after the review is refused and nothing moves',
    () async {
      final List<CapturedTemplateRecord> before = await migrations
          .watch(first.id)
          .first;
      await (db.update(db.records)
            ..where(($RecordsTable row) => row.id.equals(before.last.id)))
          .write(const RecordsCompanion(templateVersion: Value<int>(99)));

      final Result<void> result = await migrations.migrate(
        template: second,
        reviewed: before,
      );

      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.recoveryAction,
        contains('Review'),
      );
      final RecordRow untouched =
          await (db.select(db.records)
                ..where(($RecordsTable row) => row.id.equals(before.first.id)))
              .getSingle();
      expect(untouched.templateVersion, first.version);
      expect(
        await (db.select(db.auditLog)..where(
              ($AuditLogTable row) => row.fieldKey.equals('template_version'),
            ))
            .get(),
        isEmpty,
      );
    },
  );
}
