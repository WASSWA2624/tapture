import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/delete_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/delete_feedback_screen.dart';
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

  testWidgets('cancel on the confirm leaves the entry', (
    WidgetTester tester,
  ) async {
    final FeedbackRepositoryImpl repo = await _pump(tester, seed: true);
    await _reveal(tester, find.textContaining('FBK0000001'));
    await tester.tap(find.textContaining('FBK0000001'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.feedbackDeleteCount(1)));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDeleteTitle(1)), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect((await repo.watch().first).single.reference, 'FBK0000001');
  });

  testWidgets('confirm deletes the ticked entries and their screenshots', (
    WidgetTester tester,
  ) async {
    final FeedbackRepositoryImpl repo = await _pump(
      tester,
      seed: true,
      withScreenshot: true,
    );
    final String id = (await repo.watch().first).single.id;
    expect(_ok(await repo.screenshots(id)), <Uint8List>[aFeedbackPng]);
    await _reveal(tester, find.textContaining('FBK0000001'));
    await tester.tap(find.textContaining('FBK0000001'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.feedbackDeleteCount(1)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.feedbackDeleteCount(1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(await repo.watch().first, isEmpty);
    expect(_ok(await repo.screenshots(id)), isEmpty);
    expect(find.text(Copy.feedbackDeleted(1)), findsOneWidget);
  });

  testWidgets('select all is a checkbox that ticks every match', (
    WidgetTester tester,
  ) async {
    await _pump(tester, seed: true);
    final Finder selectAll = find.byKey(
      const ValueKey<String>('feedback-select-all'),
    );
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(of: selectAll, matching: find.byType(Checkbox)),
          )
          .value,
      isFalse,
    );
    await tester.tap(selectAll);
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDeleteCount(1)), findsOneWidget);
  });

  testWidgets('rows are numbered and ticking one keeps its number', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      entries: <({FeedbackCategory category, String message})>[
        (category: FeedbackCategory.general, message: 'The list is slow'),
        (category: FeedbackCategory.error, message: 'Crash on save'),
      ],
    );
    final Finder older = find.text(
      Copy.feedbackEntryTitle('2', 'FBK0000001', 'The list is slow'),
    );
    expect(older, findsOneWidget);
    await _reveal(tester, older);
    await tester.tap(older);
    await tester.pumpAndSettle();
    expect(older, findsOneWidget);
    expect(find.text(Copy.feedbackDeleteCount(1)), findsOneWidget);
  });

  testWidgets('numbers restart at 1 after a filter', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      entries: <({FeedbackCategory category, String message})>[
        (category: FeedbackCategory.general, message: 'The list is slow'),
        (category: FeedbackCategory.error, message: 'Crash on save'),
      ],
    );
    expect(
      find.text(Copy.feedbackEntryTitle('2', 'FBK0000001', 'The list is slow')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AppCheckboxGroup<FeedbackCategory>),
        matching: find.text(Copy.feedbackCategoryGeneral),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.feedbackEntryTitle('1', 'FBK0000001', 'The list is slow')),
      findsOneWidget,
    );
    expect(find.textContaining('FBK0000002'), findsNothing);
  });

  testWidgets('close pops the route', (WidgetTester tester) async {
    await _pump(tester, seed: true, asRoute: true);
    expect(find.byType(DeleteFeedbackScreen), findsOneWidget);
    await tester.tap(find.byTooltip(Copy.close));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteFeedbackScreen), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  test('undo still restores after the screen has closed', () async {
    final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
      clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
    );
    final FeedbackEntry entry = _ok(
      await repo.add(
        category: FeedbackCategory.error,
        message: 'Undo me',
        context: aFeedbackEntry().context,
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        feedbackRepositoryProvider.overrideWith((Ref _) => repo),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<Object?> screen = container.listen(
      deleteFeedbackControllerProvider,
      (Object? _, Object? _) {},
    );
    final DeleteFeedbackController controller = container.read(
      deleteFeedbackControllerProvider.notifier,
    );
    controller.toggle(entry.id);
    final List<RemovedFeedback> removed = _ok(
      await controller.removeSelected(),
    );
    screen.close();
    await container.pump();
    expect(container.exists(deleteFeedbackControllerProvider), isFalse);
    _ok(await controller.restore(removed));
    expect((await repo.watch().first).single.message, 'Undo me');
  });
}

Future<FeedbackRepositoryImpl> _pump(
  WidgetTester tester, {
  bool seed = false,
  bool withScreenshot = false,
  bool asRoute = false,
  List<({FeedbackCategory category, String message})>? entries,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 18, 7, 2));
  final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
    clock: clock,
  );
  final List<({FeedbackCategory category, String message})>? toAdd =
      entries ??
      (seed
          ? <({FeedbackCategory category, String message})>[
              (category: FeedbackCategory.general, message: 'The list is slow'),
            ]
          : null);
  if (toAdd != null) {
    for (final ({FeedbackCategory category, String message}) row in toAdd) {
      _ok(
        await repo.add(
          category: row.category,
          message: row.message,
          context: aFeedbackEntry().context,
          screenshots: <Uint8List>[if (withScreenshot) aFeedbackPng],
        ),
      );
    }
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
        home: asRoute
            ? Builder(
                builder: (BuildContext context) {
                  return Scaffold(
                    body: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext _) {
                              return const DeleteFeedbackScreen();
                            },
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              )
            : const DeleteFeedbackScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (asRoute) {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }
  return repo;
}

Future<void> _reveal(WidgetTester tester, Finder finder) {
  return tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
