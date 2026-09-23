import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/processing/presentation/egress_preview_dialog.dart';
import 'package:tapture/features/processing/presentation/failed_jobs_screen.dart';
import 'package:tapture/features/processing/presentation/process_actions.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';
import 'package:tapture/features/processing/presentation/queue_screen.dart';
import 'package:tapture/features/processing/presentation/template_choice_sheet.dart';
import 'package:tapture/features/settings/presentation/provider_test_action.dart';

void main() {
  testWidgets('egress preview shows empty and failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EgressPreviewDialog(imageCount: 0, payloadBytes: 0),
      ),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.egressEmptyHeadline), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: EgressPreviewDialog(
          imageCount: 2,
          payloadBytes: 10,
          failure: NetworkFailure(),
        ),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('template choice shows empty and failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TemplateChoiceSheet(options: <String>[])),
      ),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TemplateChoiceSheet(
            options: <String>['Equipment'],
            failure: ProviderFailure(message: 'Could not load templates.'),
          ),
        ),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('provider test shows empty and failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProviderTestAction())),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProviderTestAction(failure: NetworkFailure())),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.apiKeyNetworkFailed), findsNothing);
  });

  testWidgets('queue groups and counts come from the snapshot', (
    WidgetTester tester,
  ) async {
    const QueueSnapshot snapshot = (
      unprocessed: 38,
      queued: 12,
      failed: 2,
      requestsToday: 3,
      imagesToday: 8,
      requestCap: 20,
      groups: <QueueGroup>[
        (label: 'Kasubi HC IV / Theatre', records: 12),
        (label: 'Mulago / Ward 4A', records: 17),
      ],
      failures: <ProcessingJob>[],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          queueSnapshotProvider.overrideWith(
            (Ref ref) => Stream<QueueSnapshot>.value(snapshot),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const QueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('38'), findsOneWidget);
    expect(find.text(Copy.queueUsage(3, 8, 20)), findsOneWidget);
    expect(find.text('Kasubi HC IV / Theatre'), findsOneWidget);
    expect(find.text('Mulago / Ward 4A'), findsOneWidget);
  });

  testWidgets('process actions show progress, cancel and the summary', (
    WidgetTester tester,
  ) async {
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProcessActions(
            running: true,
            steps: const <ProgressStep>[
              ProgressStep(label: 'Preparing images', state: StepState.done),
              ProgressStep(
                label: 'Extracting fields',
                state: StepState.running,
              ),
            ],
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );
    expect(find.byType(AppProgressSteps), findsOneWidget);
    await tester.tap(find.text(Copy.queueCancel));
    expect(cancelled, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProcessActions(
            steps: <ProgressStep>[],
            succeeded: 3,
            failed: 1,
          ),
        ),
      ),
    );
    expect(find.text(Copy.queueSummary(3, 1)), findsOneWidget);
  });

  testWidgets('failed jobs show an empty list', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          queueSnapshotProvider.overrideWith(
            (Ref ref) => Stream<QueueSnapshot>.value(emptyQueueSnapshot),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const FailedJobsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('failed jobs show the stored reason', (
    WidgetTester tester,
  ) async {
    const QueueSnapshot failed = (
      unprocessed: 0,
      queued: 0,
      failed: 1,
      requestsToday: 0,
      imagesToday: 0,
      requestCap: 20,
      groups: <QueueGroup>[],
      failures: <ProcessingJob>[
        ProcessingJob(
          id: 'job-1',
          recordId: 'record-1',
          status: JobStatus.failed,
          lastError: '401 authentication failed',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          queueSnapshotProvider.overrideWith(
            (Ref ref) => Stream<QueueSnapshot>.value(failed),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const FailedJobsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('401 authentication failed', skipOffstage: false),
      findsWidgets,
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
