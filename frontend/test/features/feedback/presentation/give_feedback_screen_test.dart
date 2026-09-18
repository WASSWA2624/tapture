import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_screen.dart';
import 'package:tapture/features/feedback/presentation/open_feedback_flow.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';

void main() {
  testWidgets('an empty message stays on the form', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackMessageRequired), findsWidgets);
    expect(find.byType(AppRadioGroup<FeedbackCategory>), findsOneWidget);
    expect(await harness.repo.watch().first, isEmpty);
  });

  testWidgets('saving writes the entry', (WidgetTester tester) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'The list is slow');
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    final List<FeedbackEntry> rows = await harness.repo.watch().first;
    expect(rows.single.message, 'The list is slow');
    expect(rows.single.category, FeedbackCategory.general);
  });

  testWidgets('other needs a name before it can save', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text(Copy.feedbackCategoryOther));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Still slow');
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackOtherRequired), findsWidgets);
  });

  testWidgets('the four short types sit side by side, without Improvement', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(1200, 900));
    final List<String> labels = <String>[
      Copy.feedbackCategoryGeneral,
      Copy.feedbackCategoryError,
      Copy.feedbackCategorySuggestion,
      Copy.feedbackCategoryOther,
    ];
    final double top = tester.getTopLeft(find.text(labels.first)).dy;
    for (final String label in labels) {
      expect(tester.getTopLeft(find.text(label)).dy, top);
    }
    expect(find.text(Copy.feedbackCategoryImprovement), findsNothing);
    expect(find.text(Copy.feedbackType), findsNothing);
    expect(find.bySemanticsLabel(Copy.feedbackType), findsOneWidget);
    await expectNoA11yIssues(tester);
  });

  testWidgets('types that do not fit one line fall into two even rows', (
    WidgetTester tester,
  ) async {
    // The test font draws every glyph a full em wide, so this is a narrow
    // phone's worth of room for these labels.
    await _pump(tester, size: const Size(440, 800));
    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    double left(String label) => tester.getTopLeft(find.text(label)).dx;
    expect(top(Copy.feedbackCategoryGeneral), top(Copy.feedbackCategoryError));
    expect(
      top(Copy.feedbackCategorySuggestion),
      top(Copy.feedbackCategoryOther),
    );
    expect(
      top(Copy.feedbackCategorySuggestion),
      greaterThan(top(Copy.feedbackCategoryGeneral)),
    );
    expect(
      left(Copy.feedbackCategoryGeneral),
      left(Copy.feedbackCategorySuggestion),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Save stays in reach while the form scrolls', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(360, 480), screenshot: aFeedbackPng);
    final Rect save = tester.getRect(find.text(Copy.feedbackSave));
    expect(save.bottom, lessThanOrEqualTo(480));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text(Copy.feedbackSave)), save);
  });

  testWidgets('the attach switch sits directly above the screenshot', (
    WidgetTester tester,
  ) async {
    await _pump(tester, screenshot: aFeedbackPng);
    final Finder preview = find.bySemanticsLabel(
      Copy.feedbackScreenshotPreview,
    );
    final Finder attach = find.byType(AppSwitchTile);
    expect(find.text(Copy.feedbackAttachScreenshot), findsOneWidget);
    expect(preview, findsOneWidget);
    expect(
      tester.getRect(attach).bottom,
      lessThanOrEqualTo(tester.getRect(preview).top),
    );
    expect(tester.getSize(attach).height, lessThan(60));
    // The screen it shows is announced, not printed.
    expect(find.text(Copy.feedbackScreenshotOf('Projects')), findsNothing);

    await tester.tap(attach);
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
  });

  testWidgets('no screenshot is stated when none was captured', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.text(Copy.feedbackNoScreenshot), findsOneWidget);
    expect(find.byType(AppEmptyState), findsNothing);
  });

  testWidgets('the form opens, closes and reopens without failing', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, launcher: true);
    for (int round = 0; round < 3; round++) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(GiveFeedbackScreen), findsOneWidget);
      expect(harness.container.exists(giveFeedbackControllerProvider), isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GiveFeedbackScreen), findsNothing);
      expect(tester.takeException(), isNull);
      // Closing released the form's state, so the next opening is fresh.
      expect(harness.container.exists(giveFeedbackControllerProvider), isFalse);
    }
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fourth time works');
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(
      (await harness.repo.watch().first).single.message,
      'Fourth time works',
    );
    expect(find.byType(GiveFeedbackScreen), findsNothing);
  });

  test('rebuilding the form state while it is open is safe', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ProviderSubscription<Object?> keepAlive = container.listen(
      giveFeedbackControllerProvider,
      (Object? _, Object? _) {},
    );
    addTearDown(keepAlive.close);
    container
        .read(giveFeedbackControllerProvider.notifier)
        .chooseCategory(FeedbackCategory.error);
    container.invalidate(giveFeedbackControllerProvider);
    expect(
      container.read(giveFeedbackControllerProvider).category,
      FeedbackCategory.general,
    );
  });
}

final class _Harness {
  const _Harness(this.repo, this.container);

  final FeedbackRepositoryImpl repo;
  final ProviderContainer container;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Uint8List? screenshot,
  Size size = const Size(400, 1200),
  bool launcher = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
    clock: FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
  );
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      feedbackClockProvider.overrideWith(
        (Ref _) => FixedClock(DateTime.utc(2026, 9, 18, 7, 2)),
      ),
      feedbackRepositoryProvider.overrideWith((Ref _) => repo),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(feedbackDraftProvider.notifier)
      .capture(
        FeedbackDraft(
          context: aFeedbackEntry().context,
          screenshot: screenshot,
        ),
      );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: launcher ? const _Launcher() : const GiveFeedbackScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(repo, container);
}

/// Opens the form the way the Feedback menu does.
class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          unawaited(
            openFeedbackFlow<bool>(context, page: const GiveFeedbackScreen()),
          );
        },
        child: const Text('Open'),
      ),
    );
  }
}
