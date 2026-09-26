import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  TemplateChoiceNeeded needed(ProcessingFixture fixture) {
    return TemplateChoiceNeeded(
      recordId: fixture.record.id,
      projectId: fixture.project.id,
      shortlist: const <({String templateId, String label})>[
        (templateId: 'pump', label: 'Pump'),
        (templateId: 'motor', label: 'Motor'),
      ],
      modelMayDecide: true,
    );
  }

  Future<ProcessingJob> job(ProcessingFixture fixture) async {
    final String id =
        (await ProcessingRepositoryImpl(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
          settings: SettingsStore.fake(),
        ).enqueue(fixture.record.id)).fold(
          (Failure failure) => throw StateError(failure.message),
          (String value) => value,
        );
    return ProcessingJob(id: id, recordId: fixture.record.id);
  }

  test(
    'the model picks from the shortlist, and the answer is stored',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final ScriptedExtraction provider = ScriptedExtraction(<String>[
        '{"fields":{"template":{"value":"motor","confidence":0.8}}}',
      ]);
      final ProcessingStageWorker worker = fixture.worker(provider: provider);

      final String? chosen = await worker.templateAssist(
        await job(fixture),
        needed(fixture),
      );

      expect(chosen, 'motor');
      final ExtractFieldsRequestView sent = provider.requests.single.view;
      expect(sent.options, <String>['Pump', 'Motor']);
      expect(sent.images, isEmpty, reason: 'text only');
      final ProcessingResult stored = await fixture.db
          .select(fixture.db.processingResults)
          .getSingle();
      expect(stored.rawResponse, contains('motor'));
      expect(stored.parsedOk, isTrue);
      expect(stored.requestSummary, contains('"kind":"online"'));
    },
  );

  test('an answer off the shortlist leaves it to the operator', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final ProcessingStageWorker worker = fixture.worker(
      provider: ScriptedExtraction(<String>[
        '{"fields":{"template":{"value":"Boiler","confidence":0.9}}}',
      ]),
    );
    expect(
      await worker.templateAssist(await job(fixture), needed(fixture)),
      isNull,
    );
  });

  test('a failed call leaves it to the operator', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final ProcessingStageWorker worker = fixture.worker(
      provider: ScriptedExtraction(
        const <String>[],
        failure: const NetworkFailure(message: 'Offline.'),
      ),
    );
    expect(
      await worker.templateAssist(await job(fixture), needed(fixture)),
      isNull,
    );
  });

  test('offline by choice or AI off asks no model', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[
      '{"fields":{"template":{"value":"Motor","confidence":0.9}}}',
    ]);
    final ProcessingStageWorker offline = fixture.worker(
      provider: provider,
      settings: SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.offlineByChoice.name: true},
      ),
    );
    expect(
      await offline.templateAssist(await job(fixture), needed(fixture)),
      isNull,
    );

    await fixture.setProjectSettings('{"aiEnabled":false}');
    final ProcessingStageWorker aiOff = fixture.worker(provider: provider);
    expect(
      await aiOff.templateAssist(
        const ProcessingJob(id: 'job-1', recordId: ''),
        needed(fixture),
      ),
      isNull,
    );
    expect(provider.requests, isEmpty);
  });

  test('with no provider available no model is asked', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    expect(
      await fixture.worker().templateAssist(
        await job(fixture),
        needed(fixture),
      ),
      isNull,
    );
  });
}

/// What an extraction request carried, read back for assertions.
typedef ExtractFieldsRequestView = ({
  List<String> options,
  List<String> images,
});

extension on Object {
  ExtractFieldsRequestView get view {
    final dynamic request = this;
    final List<Map<String, Object?>> schema =
        request.fieldSchema as List<Map<String, Object?>>;
    return (
      options: <String>[
        for (final Object? option in schema.single['options']! as List<Object?>)
          option! as String,
      ],
      images: request.imagePaths as List<String>,
    );
  }
}
