import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/data/template_choice_writer.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  /// Reads the fixture's plate as [text], then runs detection and returns
  /// its question, if any.
  Future<TemplateChoiceNeeded?> detect(
    ProcessingFixture fixture,
    String text, {
    SettingsStore? settings,
  }) async {
    final ProcessingStageWorker worker = fixture.worker(
      ocr: CountingOcr(text),
      settings: settings,
    );
    final ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: fixture.record.id,
    );
    await worker.perform(JobStage.prepare, job);
    await worker.perform(JobStage.onDevice, job);
    return worker.perform(JobStage.detect, job);
  }

  test('a project with one template keeps it without scoring', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await detect(fixture, 'PUMP FLOW SN458923');
    expect((await fixture.storedRecord()).templateId, fixture.template.id);
  });

  test('a template picked by hand at capture is kept', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.addTemplate(
      'Pump',
      detection: '{"keywords":["pump","flow"]}',
    );
    await fixture.setProjectSettings('{"templateChoice":"manual"}');
    await detect(fixture, 'PUMP FLOW SN458923');
    expect((await fixture.storedRecord()).templateId, fixture.template.id);
  });

  test('a confident local score moves the record, with no model', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template pump = await fixture.addTemplate(
      'Pump',
      detection:
          r'{"keywords":["pump","flow"],"identifier_patterns":["SN\\d{6}"]}',
    );
    await detect(fixture, 'PUMP FLOW SN458923');
    final RecordRow stored = await fixture.storedRecord();
    expect(stored.templateId, pump.id);
    expect(stored.rev, greaterThan(fixture.record.rev));
    final List<AuditLogData> audit = await fixture.db
        .select(fixture.db.auditLog)
        .get();
    expect(
      audit.where((AuditLogData row) => row.fieldKey == 'templateId'),
      isNotEmpty,
    );
  });

  test('a template pinned to the room short-circuits scoring', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Template motor = await fixture.addTemplate('Motor');
    await fixture.addTemplate(
      'Pump',
      detection: '{"keywords":["pump","flow"]}',
    );
    await fixture.setContext('{"room":"Plant room","site":"Mulago"}');
    final String pinKey = TemplateChoiceWriter.pinKeyFor(
      '{"site":"Mulago","room":"Plant room"}',
    )!;
    await fixture.setProjectSettings(
      '{"templatePins":{"$pinKey":"${motor.id}"}}',
    );
    await detect(fixture, 'PUMP FLOW');
    expect((await fixture.storedRecord()).templateId, motor.id);
  });

  test(
    'an inconclusive score asks, model first, with the room to pin to',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.setDetection(fixture.template.id, '{"keywords":["pump"]}');
      await fixture.addTemplate('Motor', detection: '{"keywords":["motor"]}');
      await fixture.setContext('{"room":"Plant room"}');

      expect(
        await detect(fixture, 'pump motor'),
        isA<TemplateChoiceNeeded>()
            .having((TemplateChoiceNeeded n) => n.modelMayDecide, 'model', true)
            .having(
              (TemplateChoiceNeeded n) => n.pinKey,
              'pinKey',
              'room=Plant room',
            )
            .having(
              (TemplateChoiceNeeded n) =>
                  n.shortlist.map((option) => option.label).toSet(),
              'labels',
              <String>{'Seeded template', 'Motor'},
            ),
      );
      expect((await fixture.storedRecord()).templateId, fixture.template.id);
    },
  );

  test('with no signal the capture template stands', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.addTemplate('Motor', detection: '{"keywords":["motor"]}');
    await detect(fixture, 'illegible');
    expect((await fixture.storedRecord()).templateId, fixture.template.id);
  });
}
