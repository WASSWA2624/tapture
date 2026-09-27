import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';
import 'package:tapture/features/cloud/presentation/upload_history_screen.dart';

void main() {
  final List<UploadAttempt> attempts = <UploadAttempt>[
    _attempt('older', DateTime.utc(2026, 9, 27), 'succeeded', 'dest-a'),
    _attempt('newer', DateTime.utc(2026, 9, 28), 'failed', 'dest-b'),
    _attempt('stuck', DateTime.utc(2026, 9, 26), 'interrupted', 'dest-a'),
    _attempt('stopped', DateTime.utc(2026, 9, 25), 'cancelled', 'dest-b'),
  ];

  testWidgets('empty, populated and failed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UploadHistoryScreen(attempts: <UploadAttempt>[])),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: UploadHistoryScreen(attempts: attempts)),
    );
    expect(find.text('newer'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('newer')).dy,
      lessThan(tester.getTopLeft(find.text('older')).dy),
    );
    expect(
      find.byKey(const ValueKey<String>('upload-retry-newer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('upload-retry-stuck')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('upload-retry-older')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('upload-retry-stopped')),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UploadHistoryScreen(
          attempts: attempts,
          destinationFilter: 'dest-a',
        ),
      ),
    );
    expect(find.text('newer'), findsNothing);
    expect(find.text('older'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: UploadHistoryScreen(
          failure: StorageFailure(
            message: 'The uploads could not be read.',
            recoveryAction: 'Try again.',
          ),
        ),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

UploadAttempt _attempt(
  String name,
  DateTime started,
  String outcome,
  String destinationId,
) {
  return (
    id: name,
    destinationId: destinationId,
    destinationLabel: destinationId,
    filePath: '$name.zip',
    remoteName: name,
    folder: 'inbox',
    byteSize: 12,
    startedAt: started,
    endedAt: null,
    outcome: outcome,
    failureReason: outcome == 'failed'
        ? 'The destination did not finish the upload.'
        : null,
    offset: 0,
  );
}
