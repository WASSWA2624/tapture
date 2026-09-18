import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/download_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/download_feedback_screen.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';

import '../../../support/factories.dart';

void main() {
  testWidgets('an empty store shows the empty state', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.feedbackEmptyHeadline), findsOneWidget);
  });

  testWidgets('matching entries are listed for download', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    expect(find.text('FBK0000001'), findsOneWidget);
    expect(find.text(Copy.feedbackMatching(1, 1)), findsOneWidget);
    expect(find.text(Copy.feedbackDownloadCount(1)), findsOneWidget);
    expect(find.text(Copy.feedbackSearch), findsWidgets);
    expect(find.text(Copy.feedbackMoreFilters(0)), findsOneWidget);
  });

  testWidgets('search and the type row lead; the rest folds away', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    expect(find.text(Copy.feedbackCategoryGeneral), findsOneWidget);
    expect(find.text(Copy.feedbackCategoryImprovement), findsNothing);
    expect(find.text(Copy.feedbackScreens), findsNothing);
    expect(find.text(Copy.feedbackFrom), findsNothing);

    await tester.tap(find.text(Copy.feedbackMoreFilters(0)));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackScreens), findsOneWidget);
    expect(find.text(Copy.feedbackFrom), findsOneWidget);
    expect(find.text(Copy.feedbackFewerFilters), findsOneWidget);

    await tester.tap(find.text(Copy.feedbackFewerFilters));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackScreens), findsNothing);
  });

  testWidgets('a type chip narrows the list and Clear filters widens it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    await tester.tap(find.text(Copy.feedbackCategoryError));
    await tester.pumpAndSettle();
    expect(find.text('FBK0000001'), findsNothing);
    expect(find.text(Copy.feedbackMatching(0, 1)), findsOneWidget);
    expect(find.text(Copy.feedbackDownloadCount(0)), findsOneWidget);

    await tester.tap(find.text(Copy.feedbackClearFilters));
    await tester.pumpAndSettle();
    expect(find.text('FBK0000001'), findsOneWidget);
    expect(find.text(Copy.feedbackClearFilters), findsNothing);
  });

  testWidgets('an entry saved as Improvement can still be found', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true, category: FeedbackCategory.improvement);
    await tester.tap(find.text(Copy.feedbackCategoryImprovement));
    await tester.pumpAndSettle();
    expect(find.text('FBK0000001'), findsOneWidget);
  });

  testWidgets('closing the screen forgets its filters', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pump(tester, seed: true);
    await tester.tap(find.text(Copy.feedbackCategoryError));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    expect(container.exists(downloadFeedbackControllerProvider), isFalse);
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool seed = false,
  FeedbackCategory category = FeedbackCategory.general,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final FixedClock clock = FixedClock(
    DateTime.utc(2026, 9, 18, 7, 2),
    offset: const Duration(hours: 3),
  );
  final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
    clock: clock,
  );
  if (seed) {
    _ok(
      await repo.add(
        category: category,
        message: 'The list is slow',
        context: aFeedbackEntry().context,
      ),
    );
  }
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      feedbackClockProvider.overrideWith((Ref _) => clock),
      feedbackRepositoryProvider.overrideWith((Ref _) => repo),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const DownloadFeedbackScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
