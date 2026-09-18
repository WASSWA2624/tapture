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
    expect(find.text(Copy.feedbackWhich), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, {bool seed = false}) async {
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
        category: FeedbackCategory.general,
        message: 'The list is slow',
        context: aFeedbackEntry().context,
      ),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        feedbackClockProvider.overrideWith((Ref _) => clock),
        feedbackRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const DownloadFeedbackScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
