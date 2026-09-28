import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/template_choice_writer.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';
import 'package:tapture/features/projects/projects.dart' show ProjectSettings;

import '../../../support/processing_fixture.dart';

void main() {
  TemplateChoiceWriter writerFor(ProcessingFixture fixture) {
    return TemplateChoiceWriter(
      db: fixture.db,
      clock: fixture.clock,
      deviceId: 'device-a',
      ids: fixture.ids,
    );
  }

  Future<Project> project(ProcessingFixture fixture) {
    return fixture.db.select(fixture.db.projects).getSingle();
  }

  TemplateChoiceNeeded question(ProcessingFixture fixture, {String? pinKey}) {
    return TemplateChoiceNeeded(
      recordId: fixture.record.id,
      projectId: fixture.project.id,
      shortlist: const <({String templateId, String label})>[],
      pinKey: pinKey,
    );
  }

  test('the pin key covers the whole context in a stable order', () {
    expect(
      TemplateChoiceWriter.pinKeyFor('{"site":"Mulago","room":"Plant room"}'),
      TemplateChoiceWriter.pinKeyFor('{"room":"Plant room","site":"Mulago"}'),
    );
    expect(
      TemplateChoiceWriter.pinKeyFor('{"room":"Plant room"}'),
      'room=Plant room',
    );
    expect(TemplateChoiceWriter.pinKeyFor('{}'), isNull);
    expect(TemplateChoiceWriter.pinKeyFor('not json'), isNull);
  });

  test('a choice moves the record and a pin answers the room', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template motor = await fixture.addTemplate('Motor');
    final TemplateChoiceWriter writer = writerFor(fixture);

    final Result<void> applied = await writer.apply(
      question(fixture, pinKey: 'room=Plant room'),
      (templateId: motor.id, pin: true),
    );

    expect(applied, isA<Success<void>>());
    expect((await fixture.storedRecord()).templateId, motor.id);
    final Project pinned = await project(fixture);
    expect(TemplateChoiceWriter.pinned(pinned, 'room=Plant room'), motor.id);
    expect(TemplateChoiceWriter.pinned(pinned, 'room=Store'), isNull);
    expect(pinned.rev, fixture.project.rev + 1);
    expect(pinned.updatedByDevice, 'device-a');
  });

  test('a new pin keeps the other project settings and pins', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.setProjectSettings(
      '{"aiEnabled":false,"templatePins":{"room=Store":"${fixture.template.id}"}}',
    );
    final Template motor = await fixture.addTemplate('Motor');

    await writerFor(fixture).apply(
      question(fixture, pinKey: 'room=Plant room'),
      (templateId: motor.id, pin: true),
    );

    final ProjectSettings settings = ProjectSettings.decode(
      (await project(fixture)).settings,
    );
    expect(settings.aiEnabled, isFalse);
    expect(settings.templatePins, <String, String>{
      'room=Store': fixture.template.id,
      'room=Plant room': motor.id,
    });
  });

  test('a choice without a pin stores no pin', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template motor = await fixture.addTemplate('Motor');
    final TemplateChoiceWriter writer = writerFor(fixture);

    await writer.apply(question(fixture, pinKey: 'room=Plant room'), (
      templateId: motor.id,
      pin: false,
    ));

    expect(
      ProjectSettings.decode((await project(fixture)).settings).templatePins,
      isNull,
    );
  });

  test('a move takes the target version and drops the row', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template motor = await fixture.addTemplate('Motor');
    final TemplateRow row = await fixture.addRow('Pump room');
    await (fixture.db.update(fixture.db.templates)
          ..where(($TemplatesTable table) => table.id.equals(motor.id)))
        .write(const TemplatesCompanion(version: Value<int>(4)));
    await (fixture.db.update(fixture.db.records)
          ..where(($RecordsTable table) => table.id.equals(fixture.record.id)))
        .write(
          RecordsCompanion(
            templateVersion: const Value<int>(3),
            templateRowId: Value<String?>(row.id),
            rowMatchStrategy: const Value<String?>('exact'),
            rowMatchScore: const Value<double?>(1),
          ),
        );

    await writerFor(
      fixture,
    ).setTemplate(fixture.record.id, motor.id, reason: 'pinned');

    final RecordRow stored = await fixture.storedRecord();
    expect(stored.templateId, motor.id);
    expect(stored.templateVersion, 4);
    expect(stored.templateRowId, isNull);
    expect(stored.rowMatchStrategy, isNull);
    expect(stored.rowMatchScore, isNull);
    final List<AuditLogData> audit = await fixture.db
        .select(fixture.db.auditLog)
        .get();
    final AuditLogData rowAudit = audit.singleWhere(
      (AuditLogData entry) => entry.fieldKey == 'templateRowId',
    );
    expect(rowAudit.previousValue, row.id);
    expect(rowAudit.newValue, isNull);
    expect(
      audit.where((AuditLogData entry) => entry.fieldKey == 'templateId'),
      hasLength(1),
    );
  });

  test('a chosen template sets its current version', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template motor = await fixture.addTemplate('Motor');
    await (fixture.db.update(fixture.db.templates)
          ..where(($TemplatesTable table) => table.id.equals(motor.id)))
        .write(const TemplatesCompanion(version: Value<int>(2)));
    await (fixture.db.update(fixture.db.records)
          ..where(($RecordsTable table) => table.id.equals(fixture.record.id)))
        .write(const RecordsCompanion(templateVersion: Value<int>(7)));

    final Result<void> applied = await writerFor(
      fixture,
    ).apply(question(fixture), (templateId: motor.id, pin: false));

    expect(applied, isA<Success<void>>());
    final RecordRow stored = await fixture.storedRecord();
    expect(stored.templateId, motor.id);
    expect(stored.templateVersion, 2);
    expect(stored.templateRowId, isNull);
  });

  test('a move onto a template not on this device writes nothing', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final RecordRow before = await fixture.storedRecord();

    await expectLater(
      writerFor(
        fixture,
      ).setTemplate(fixture.record.id, 'missing-template', reason: 'score'),
      throwsA(isA<StorageFailure>()),
    );

    final RecordRow after = await fixture.storedRecord();
    expect(after.templateId, before.templateId);
    expect(after.templateVersion, before.templateVersion);
    expect(after.rev, before.rev);
  });

  test('a template from another project is refused', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template foreign = (await upsertTemplate(
      fixture.db,
      row: const TemplatesCompanion(
        projectId: Value<String?>('another-project'),
        name: Value<String>('Foreign'),
        kind: Value<String>('equipment'),
        source: Value<String>('built'),
      ),
      clock: fixture.clock,
      deviceId: 'device-a',
      ids: fixture.ids,
    )).fold((_) => throw StateError('seed'), (Template t) => t);
    final TemplateChoiceWriter writer = writerFor(fixture);

    final Result<void> refused = await writer.apply(question(fixture), (
      templateId: foreign.id,
      pin: false,
    ));

    expect(refused, isA<FailureResult<void>>());
    expect((await fixture.storedRecord()).templateId, fixture.template.id);
  });
}
