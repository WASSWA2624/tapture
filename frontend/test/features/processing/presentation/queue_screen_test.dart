import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';
import 'package:tapture/features/processing/presentation/processing_controller.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';
import 'package:tapture/features/processing/presentation/queue_screen.dart';

import '../../../support/fakes/fake_processing_repository.dart';

void main() {
  testWidgets('an undecided template opens the choice sheet and applies the '
      'chosen id', (WidgetTester tester) async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(id: 'job-1', recordId: 'record-1'),
    );
    final List<TemplateChoice> applied = <TemplateChoice>[];
    const QueueSnapshot snapshot = (
      unprocessed: 0,
      queued: 1,
      failed: 0,
      requestsToday: 0,
      imagesToday: 0,
      requestCap: 20,
      groups: <QueueGroup>[],
      failures: <ProcessingJob>[],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          queueSnapshotProvider.overrideWith(
            (Ref ref) => Stream<QueueSnapshot>.value(snapshot),
          ),
          processingRepositoryProvider.overrideWith((_) => repository),
          processingStageWorkProvider.overrideWith((_) {
            return (
              JobStage stage,
              ProcessingJob _,
              CancellationToken _,
            ) async {
              if (stage == JobStage.detect && applied.isEmpty) {
                throw const TemplateChoiceNeeded(
                  recordId: 'record-1',
                  projectId: 'project-1',
                  shortlist: <({String templateId, String label})>[
                    (templateId: 'pump', label: 'Pump'),
                    (templateId: 'motor', label: 'Motor'),
                  ],
                );
              }
            };
          }),
          processingTemplateChoiceProvider.overrideWith((_) {
            return (TemplateChoiceNeeded _, TemplateChoice choice) async {
              applied.add(choice);
              return const Success<void>(null);
            };
          }),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const QueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.queueProcessAll));
    await _pumpUntil(tester, find.text('Motor').hitTestable());
    expect(find.text(Copy.templateChoiceTitle), findsOneWidget);
    await tester.tap(find.text('Motor'));
    await _pumpUntil(tester, find.text(Copy.queueSummary(1, 0)));

    expect(applied, <TemplateChoice>[(templateId: 'motor', pin: true)]);
  });
}

/// Pumps frames until [finder] matches. A running step spins forever, so
/// the screen never settles while a batch is open.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 100 && finder.evaluate().isEmpty; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(finder, findsWidgets);
}
