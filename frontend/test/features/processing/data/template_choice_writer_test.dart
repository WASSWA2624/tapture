import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/templates.dart';
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
