import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_screen.dart';

import '../../../support/factories.dart';

void main() {
  testWidgets('an empty message stays on the form', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.ensureVisible(find.text(Copy.feedbackSave));
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackMessageRequired), findsWidgets);
    expect(find.text(Copy.feedbackStaysOnDevice), findsNothing);
    expect(find.byType(AppRadioGroup<FeedbackCategory>), findsOneWidget);
    expect(await harness.repo.watch().first, isEmpty);
  });

  testWidgets('saving writes the entry', (WidgetTester tester) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'The list is slow');
    await tester.ensureVisible(find.text(Copy.feedbackSave));
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
    await tester.ensureVisible(find.text(Copy.feedbackCategoryOther));
    await tester.tap(find.text(Copy.feedbackCategoryOther));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Still slow');
    await tester.ensureVisible(find.text(Copy.feedbackSave));
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackOtherRequired), findsWidgets);
  });

  testWidgets('a captured screenshot can be attached', (
    WidgetTester tester,
  ) async {
    await _pump(tester, screenshot: aFeedbackPng);
    expect(find.text(Copy.feedbackAttachScreenshot), findsOneWidget);
    expect(find.text(Copy.feedbackScreenshotOf('Projects')), findsOneWidget);
    expect(
      find.bySemanticsLabel(Copy.feedbackScreenshotPreview),
      findsOneWidget,
    );
  });

  testWidgets('no screenshot is stated when none was captured', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.text(Copy.feedbackNoScreenshot), findsOneWidget);
    expect(find.byType(AppEmptyState), findsNothing);
  });
}

final class _Harness {
  const _Harness(this.repo);

  final FeedbackRepositoryImpl repo;
}

Future<_Harness> _pump(WidgetTester tester, {Uint8List? screenshot}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1200);
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
        home: const GiveFeedbackScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(repo);
}
