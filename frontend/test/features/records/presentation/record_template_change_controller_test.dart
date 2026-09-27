import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_template_change_controller.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';
import '../fakes/record_results.dart';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

void main() {
  late FakeRecordRepository records;
  late FakeTemplateRepository templates;
  late ProviderContainer container;

  setUp(() {
    records = FakeRecordRepository();
    templates = FakeTemplateRepository();
    container = ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
    );
    records
      ..seedTemplate('template-1', name: 'Pump', fieldKeys: <String>['serial'])
      ..seedTemplate(
        'template-2',
        name: 'Motor',
        fieldKeys: <String>['serial', 'rating'],
      )
      ..seedEntry(
        aRecordEntry(
          id: 'record-1',
          templateId: 'template-1',
          status: RecordStatus.approved,
          fields: const <String, String>{'serial': 'SN-1', 'model': 'X200'},
          source: 'ocr',
        ),
      );
  });

  tearDown(() {
    container.dispose();
    records.dispose();
    templates.dispose();
  });

  RecordTemplateChangeController controller() {
    return container.read(
      recordTemplateChangeControllerProvider('record-1').notifier,
    );
  }

  RecordTemplateChangeState state() {
    return container.read(recordTemplateChangeControllerProvider('record-1'));
  }

  /// Keeps the auto-dispose controller alive for the test, as the sheet
  /// watching it does.
  void listen() {
    final ProviderSubscription<RecordTemplateChangeState> subscription =
        container.listen(
          recordTemplateChangeControllerProvider('record-1'),
          (RecordTemplateChangeState? _, RecordTemplateChangeState _) {},
        );
    addTearDown(subscription.close);
  }

  test('starts with no template chosen, nothing running and no failure', () {
    listen();
    expect(state().targetId, isNull);
    expect(state().applying, isFalse);
    expect(state().failure, isNull);
  });

  test('applying before a template is chosen fails validation and writes '
      'nothing', () async {
    listen();
    final Result<void> result = await controller().apply();

    expect(failureOf(result), isA<ValidationFailure>());
    expect(records.writes, isEmpty);
  });

  test('choosing a template remembers it', () {
    listen();
    controller().choose('template-2');

    expect(state().targetId, 'template-2');
  });

  test('apply moves the record, retires what the template lacks and sends '
      'an approved record back to review', () async {
    listen();
    controller().choose('template-2');

    final Result<void> result = await controller().apply();

    expect(result, isA<Success<void>>());
    final RecordEntry moved = records.entryOf('record-1')!;
    expect(moved.templateId, 'template-2');
    expect(moved.valueOf('model')!.retired, isTrue);
    expect(moved.valueOf('model')!.display, 'X200');
    expect(moved.status, RecordStatus.needsReview);
    expect(state().applying, isFalse);
    expect(state().failure, isNull);
    expect(state().targetId, 'template-2');
  });

  test('a failed apply keeps the chosen template and says why, and choosing '
      'again clears the failure', () async {
    listen();
    records.failuresById['record-1'] = _locked;
    controller().choose('template-2');

    final Result<void> result = await controller().apply();

    expect(failureOf(result), _locked);
    expect(state().failure, _locked);
    expect(state().targetId, 'template-2');
    expect(state().applying, isFalse);
    expect(records.entryOf('record-1')!.templateId, 'template-1');

    controller()
      ..choose('template-1')
      ..choose('template-2');
    expect(state().failure, isNull);
  });

  test('the plan is read from the record store without writing', () async {
    final TemplateChangePlan plan = await container.read(
      recordTemplateChangePlanProvider((
        recordId: 'record-1',
        templateId: 'template-2',
      )).future,
    );

    expect(plan.mapped, <String>['serial']);
    expect(plan.retired, <String>['model']);
    expect(plan.added, <String>['rating']);
    expect(records.writes, isEmpty);
  });

  test('a plan the store refuses is an error, not an empty plan', () async {
    await expectLater(
      container.read(
        recordTemplateChangePlanProvider((
          recordId: 'record-1',
          templateId: 'template-1',
        )).future,
      ),
      throwsA(isA<Failure>()),
    );
  });

  test(
    'the choices are the project templates the template store lists',
    () async {
      await templates.save(aTemplate(id: 'template-1', name: 'Pump'));
      await templates.save(aTemplate(id: 'template-2', name: 'Motor'));
      await templates.save(
        aTemplate(id: 'elsewhere', name: 'Other', projectId: 'project-2'),
      );

      // Watched, as the sheet watches it, so the stream stays open.
      final ProviderSubscription<AsyncValue<List<TemplateDef>>> watched =
          container.listen(
            recordTemplateChangeChoicesProvider('project-1'),
            (
              AsyncValue<List<TemplateDef>>? _,
              AsyncValue<List<TemplateDef>> _,
            ) {},
          );
      addTearDown(watched.close);
      final List<TemplateDef> listed = await container.read(
        recordTemplateChangeChoicesProvider('project-1').future,
      );

      expect(listed.map((TemplateDef t) => t.id), <String>[
        'template-1',
        'template-2',
      ]);
    },
  );
}
