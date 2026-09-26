import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/processing/presentation/failed_jobs_screen.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';

void main() {
  QueueSnapshot withFailures(int count) {
    return (
      unprocessed: 0,
      queued: 0,
      failed: count,
      requestsToday: 0,
      imagesToday: 0,
      requestCap: 20,
      groups: const <QueueGroup>[],
      failures: <ProcessingJob>[
        for (var i = 0; i < count; i++)
          ProcessingJob(
            id: 'job-$i',
            recordId: 'record-$i',
            status: JobStatus.failed,
            lastError: 'Reason $i',
          ),
      ],
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Stream<QueueSnapshot> snapshot, {
    Future<void> Function(String jobId)? onRetry,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          queueSnapshotProvider.overrideWith((Ref ref) => snapshot),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: FailedJobsScreen(onRetry: onRetry),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no failures shows the empty state', (WidgetTester tester) async {
    await pump(tester, Stream<QueueSnapshot>.value(withFailures(0)));

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.queueFailedEmptyHeadline), findsOneWidget);
  });

  testWidgets('a queue that cannot be read shows the failure', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      Stream<QueueSnapshot>.error(
        const StorageFailure(
          message: 'The queue could not be read.',
          recoveryAction: 'Try again.',
        ),
      ),
    );

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The queue could not be read.'), findsOneWidget);
  });

  testWidgets('each failure shows its reason and retries its own job', (
    WidgetTester tester,
  ) async {
    final List<String> retried = <String>[];
    await pump(
      tester,
      Stream<QueueSnapshot>.value(withFailures(2)),
      onRetry: (String jobId) async => retried.add(jobId),
    );

    expect(find.text('Reason 0'), findsOneWidget);
    expect(find.text('Reason 1'), findsOneWidget);

    // The last retry belongs to the second job.
    final Finder second = find.text(Copy.queueRetry).last;
    await tester.ensureVisible(second);
    await tester.pumpAndSettle();
    await tester.tap(second);
    await tester.pumpAndSettle();

    expect(retried, <String>['job-1']);
  });

  testWidgets('a long list builds only what is on screen', (
    WidgetTester tester,
  ) async {
    await pump(tester, Stream<QueueSnapshot>.value(withFailures(200)));

    expect(find.text('Reason 0'), findsOneWidget);
    expect(find.text('Reason 199', skipOffstage: false), findsNothing);
  });
}
