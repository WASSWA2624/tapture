import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_snapshot.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/data/stage_support.dart';
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

      final ProcessingJob queued = await job(fixture);
      final String? chosen = await worker.templateAssist(
        queued,
        needed(fixture),
      );

      expect(chosen, 'motor');
      final ExtractFieldsRequestView sent = provider.requests.single.view;
      expect(sent.options, <String>['Pump', 'Motor']);
      expect(sent.images, isEmpty, reason: 'text only');
      final List<ProcessingResult> responses = await fixture.db
          .select(fixture.db.processingResults)
          .get();
      final ProcessingResult stored = responses.singleWhere(
        (row) => row.parsedOk,
      );
      expect(
        responses.where(
          (row) =>
              StageSupport.summaryValue(row.requestSummary, 'kind') ==
              'attempt',
        ),
        hasLength(1),
      );
      expect(stored.rawResponse, contains('motor'));
      expect(stored.parsedOk, isTrue);
      expect(stored.requestSummary, contains('"kind":"online"'));
      expect(
        provider.requests.single.idempotencyKey,
        matches(RegExp(r'^[a-f0-9]{64}$')),
      );
      expect(provider.requests.single.approvedMaxCost, 0);
      expect(
        await worker.templateAssist(
          queued.copyWith(requestGeneration: 1),
          needed(fixture),
        ),
        'motor',
      );
      expect(provider.requests, hasLength(1));
      await fixture.setContext('{"room":"Plant"}');
      expect(
        await worker.templateAssist(
          queued.copyWith(requestGeneration: 1),
          needed(fixture),
        ),
        'motor',
      );
      expect(provider.requests, hasLength(2));
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

  test('cancelled template assistance sends nothing', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final ScriptedExtraction service = ScriptedExtraction(<String>[
      '{"fields":{}}',
    ]);
    final CancellationToken token = CancellationToken()..cancel();
    expect(
      await fixture
          .worker(provider: service)
          .templateAssist(await job(fixture), needed(fixture), token),
      isNull,
    );
    expect(service.requests, isEmpty);
  });

  test(
    'an edit during cache lookup prevents a stale assisted choice',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final _RacingProvider service = _RacingProvider();
      final ProcessingStageWorker worker = fixture.worker(provider: service);
      final ProcessingJob queued = await job(fixture);
      expect(await worker.templateAssist(queued, needed(fixture)), 'motor');
      Future<void>? changed;
      service.onAvailability = () {
        changed ??= fixture.setContext(
          '{"room":"Updated during cache lookup"}',
        );
      };
      expect(await worker.templateAssist(queued, needed(fixture)), isNull);
      await changed;
      expect(service.delegate.requests, hasLength(1));
    },
  );

  test(
    'an edit after assistance is guarded again when applying the choice',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final Template motor = await fixture.addTemplate('Motor');
      final bundle = await fixture.bundle();
      final TemplateChoiceNeeded question = TemplateChoiceNeeded(
        recordId: fixture.record.id,
        projectId: fixture.project.id,
        shortlist: <({String templateId, String label})>[
          (templateId: motor.id, label: 'Motor'),
        ],
        sourceRevision: await ProcessingSnapshot.sourceRevision(
          bundle,
          privacyRevision: '',
        ),
        recordRevision: bundle.record.rev,
        modelMayDecide: true,
      );
      final ProcessingStageWorker worker = fixture.worker(
        provider: _RacingProvider(),
      );
      expect(
        await worker.templateAssist(await job(fixture), question),
        motor.id,
      );
      await fixture.setContext('{"room":"Edited before choice application"}');
      final Result<void> applied = await worker.templateChoice(question, (
        templateId: motor.id,
        pin: false,
      ));
      expect(applied, isA<FailureResult<void>>());
      expect((applied as FailureResult<void>).failure, isA<CancelledFailure>());
      expect((await fixture.storedRecord()).templateId, fixture.template.id);
    },
  );
}

final class _RacingProvider implements AiService {
  final ScriptedExtraction delegate = ScriptedExtraction(<String>[
    '{"fields":{"template":{"value":"Motor","confidence":0.8}}}',
  ]);
  void Function()? onAvailability;

  @override
  bool get isAvailable {
    onAvailability?.call();
    return true;
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) => delegate.extractFields(request);
  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) =>
      delegate.refineText(request);
  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) =>
      delegate.transcribe(request);
  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) =>
      delegate.readText(request);
}

/// What an extraction request carried, read back for assertions.
typedef ExtractFieldsRequestView = ({
  List<String> options,
  List<String> images,
});

extension on ExtractFieldsRequest {
  ExtractFieldsRequestView get view {
    final List<Map<String, Object?>> schema = fieldSchema;
    return (
      options: <String>[
        for (final Object? option in schema.single['options']! as List<Object?>)
          option! as String,
      ],
      images: imagePaths,
    );
  }
}
