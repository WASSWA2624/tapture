import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';
import 'package:tapture/features/cloud/presentation/upload_controller.dart';
import 'package:tapture/features/cloud/presentation/upload_history_controller.dart';
import 'package:tapture/features/cloud/presentation/upload_history_screen.dart';

import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  final List<UploadAttempt> attempts = <UploadAttempt>[
    _attempt('older', DateTime.utc(2026, 9, 27), 'succeeded', 'dest-a'),
    _attempt('newer', DateTime.utc(2026, 9, 28), 'failed', 'dest-b'),
    _attempt('stuck', DateTime.utc(2026, 9, 26), 'interrupted', 'dest-a'),
    _attempt('stopped', DateTime.utc(2026, 9, 25), 'cancelled', 'dest-b'),
  ];

  testWidgets('an empty history offers the empty state', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const <UploadAttempt>[]);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('attempts are newest first and only failed rows retry', (
    WidgetTester tester,
  ) async {
    await _pump(tester, attempts);
    expect(find.text('newer'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('newer')).dy,
      lessThan(tester.getTopLeft(find.text('older')).dy),
    );
    await _expectRetry(tester, 'newer', present: true);
    await _expectRetry(tester, 'stuck', present: true);
    await _expectRetry(tester, 'older', present: false);
    await _expectRetry(tester, 'stopped', present: false);
  });

  testWidgets('a destination filter hides the other destination', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pump(tester, attempts);
    container.read(uploadHistoryControllerProvider.notifier).filterBy('dest-a');
    await tester.pumpAndSettle();
    expect(find.text('newer'), findsNothing);
    expect(find.text('older'), findsOneWidget);
  });

  testWidgets('a failed read shows the error state', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      attempts,
      error: const StorageFailure(
        message: 'The uploads could not be read.',
        recoveryAction: 'Try again.',
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'compact upload keeps metadata and failure actions reachable ${cell.description}',
      (WidgetTester tester) async {
        await _pump(tester, <UploadAttempt>[attempts[1]], cell: cell);
        expect(
          tester.widget<AppPage>(find.byType(AppPage)).layout,
          AppPageLayout.compact,
        );
        expect(
          tester.widget<AppListTile>(find.byType(AppListTile)).wrapText,
          isTrue,
        );
        final Finder actions = find.byKey(
          const ValueKey<String>('upload-actions-newer'),
        );
        await tester.ensureVisible(actions);
        await tester.pumpAndSettle();
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[actions],
          ),
          isEmpty,
        );
        await _expectRetry(tester, 'newer', present: true);
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
    );
  }
}

Future<void> _expectRetry(
  WidgetTester tester,
  String id, {
  required bool present,
}) async {
  await tester.tap(find.byKey(ValueKey<String>('upload-actions-$id')));
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey<String>('upload-retry-$id')),
    present ? findsOneWidget : findsNothing,
  );
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  List<UploadAttempt> attempts, {
  Failure? error,
  ScreenMatrix? cell,
}) async {
  if (cell != null) {
    tester.view.physicalSize = cell.size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      uploadAttemptsProvider.overrideWith(
        (Ref _) => error == null
            ? Stream<List<UploadAttempt>>.value(attempts)
            : Stream<List<UploadAttempt>>.error(error),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(
          brightness: cell?.brightness ?? Brightness.light,
          outdoor: cell?.outdoor ?? false,
        ),
        home: const UploadHistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
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
    localizedFailure: null,
    offset: 0,
  );
}
