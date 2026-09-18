import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
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
    expect(find.textContaining('FBK0000001'), findsOneWidget);
    expect(find.text(Copy.feedbackMatching(1, 1)), findsOneWidget);
    expect(find.text(Copy.feedbackDownloadCount(1)), findsOneWidget);
    expect(find.text(Copy.feedbackSearch), findsWidgets);
    expect(find.byTooltip(Copy.feedbackMoreFilters(0)), findsOneWidget);
  });

  testWidgets('search and the type row lead; the rest folds away', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    expect(find.text(Copy.feedbackCategoryGeneral), findsOneWidget);
    expect(find.text(Copy.feedbackCategoryImprovement), findsNothing);
    expect(find.text(Copy.feedbackScreens), findsNothing);
    expect(find.text(Copy.feedbackFrom), findsNothing);

    await tester.tap(find.byTooltip(Copy.feedbackMoreFilters(0)));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackScreens), findsOneWidget);
    expect(find.text(Copy.feedbackFrom), findsOneWidget);
    expect(find.byTooltip(Copy.feedbackFewerFilters), findsOneWidget);

    await tester.tap(find.byTooltip(Copy.feedbackFewerFilters));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackScreens), findsNothing);
  });

  testWidgets('search keeps the query after debounce and Clear empties it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    await tester.enterText(find.byType(TextField), 'crash');
    await tester.pump(AppConstants.interaction.debounce);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'crash',
    );
    expect(find.textContaining('FBK0000001'), findsNothing);
    expect(find.text(Copy.feedbackMatching(0, 1)), findsOneWidget);

    await tester.tap(find.text(Copy.feedbackClearFilters));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    expect(find.textContaining('FBK0000001'), findsOneWidget);
    expect(find.text(Copy.feedbackClearFilters), findsNothing);
  });

  testWidgets('a type checkbox narrows the list and Clear filters widens it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    await tester.tap(find.text(Copy.feedbackCategoryError));
    await tester.pumpAndSettle();
    expect(find.textContaining('FBK0000001'), findsNothing);
    expect(find.text(Copy.feedbackMatching(0, 1)), findsOneWidget);
    expect(find.text(Copy.feedbackDownloadCount(0)), findsOneWidget);

    await tester.tap(find.text(Copy.feedbackClearFilters));
    await tester.pumpAndSettle();
    expect(find.textContaining('FBK0000001'), findsOneWidget);
    expect(find.text(Copy.feedbackClearFilters), findsNothing);
  });

  testWidgets('the filter toggle counts folded facets in use', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    await tester.tap(find.byTooltip(Copy.feedbackMoreFilters(0)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.feedbackScreenshotWith));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Copy.feedbackFewerFilters));
    await tester.pumpAndSettle();
    expect(find.byTooltip(Copy.feedbackMoreFilters(1)), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('FBK0000001'), findsNothing);
  });

  testWidgets('an entry saved as Improvement can still be found', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true, category: FeedbackCategory.improvement);
    await tester.tap(find.text(Copy.feedbackCategoryImprovement));
    await tester.pumpAndSettle();
    expect(find.textContaining('FBK0000001'), findsOneWidget);
  });

  testWidgets(
    'rows are numbered in list order and show the message beside the ID',
    (WidgetTester tester) async {
      await _pump(
        tester,
        entries: <({FeedbackCategory category, String message})>[
          (category: FeedbackCategory.general, message: 'The list is slow'),
          (category: FeedbackCategory.error, message: 'Crash on save'),
        ],
      );
      expect(
        find.text(Copy.feedbackEntryTitle('1', 'FBK0000002', 'Crash on save')),
        findsOneWidget,
      );
      expect(
        find.text(
          Copy.feedbackEntryTitle('2', 'FBK0000001', 'The list is slow'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a long message is cut to one line with an ellipsis at 360 dp', (
    WidgetTester tester,
  ) async {
    final String message = List<String>.filled(40, 'slow').join(' ');
    await _pump(
      tester,
      entries: <({FeedbackCategory category, String message})>[
        (category: FeedbackCategory.general, message: message),
      ],
      size: const Size(360, 800),
    );
    for (final Size size in <Size>[
      const Size(360, 800),
      const Size(768, 800),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      _expectOneLineTitle(tester, 'FBK0000001');
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(360, 800);
    await tester.pump();
    _expectOneLineTitle(tester, 'FBK0000001');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a message with line breaks reads as one line', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      entries: <({FeedbackCategory category, String message})>[
        (category: FeedbackCategory.general, message: 'Line one\n\nLine  two'),
      ],
    );
    expect(
      find.text(
        Copy.feedbackEntryTitle('1', 'FBK0000001', 'Line one Line two'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('close pops the route', (WidgetTester tester) async {
    await _pump(tester, seed: true, asRoute: true);
    expect(find.byType(DownloadFeedbackScreen), findsOneWidget);
    await tester.tap(find.byTooltip(Copy.close));
    await tester.pumpAndSettle();
    expect(find.byType(DownloadFeedbackScreen), findsNothing);
    expect(find.text('Open'), findsOneWidget);
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

void _expectOneLineTitle(WidgetTester tester, String fragment) {
  final Finder title = find.textContaining(fragment);
  expect(title, findsOneWidget);
  final Text text = tester.widget<Text>(title);
  expect(text.maxLines, 1);
  expect(text.overflow, TextOverflow.ellipsis);
  final double line = (TextPainter(
    text: const TextSpan(text: 'Ag', style: AppText.bodyStrong),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.of(tester.element(title)).textScaler,
  )..layout()).height;
  expect(tester.getSize(title).height, line);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool seed = false,
  bool asRoute = false,
  FeedbackCategory category = FeedbackCategory.general,
  List<({FeedbackCategory category, String message})>? entries,
  Size size = const Size(400, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
  final List<({FeedbackCategory category, String message})>? toAdd =
      entries ??
      (seed
          ? <({FeedbackCategory category, String message})>[
              (category: category, message: 'The list is slow'),
            ]
          : null);
  if (toAdd != null) {
    for (final ({FeedbackCategory category, String message}) row in toAdd) {
      _ok(
        await repo.add(
          category: row.category,
          message: row.message,
          context: aFeedbackEntry().context,
        ),
      );
    }
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
        home: asRoute
            ? Builder(
                builder: (BuildContext context) {
                  return Scaffold(
                    body: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext _) {
                              return const DownloadFeedbackScreen();
                            },
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              )
            : const DownloadFeedbackScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (asRoute) {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }
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
