import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_bar.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';
import 'package:tapture/features/feedback/presentation/feedback_overlay.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_screen.dart';

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
    expect(await harness.repo.watch().first, isEmpty);
  });

  testWidgets('saving writes the entry, clears the draft and says so', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, screenshot: aFeedbackPng);
    await tester.enterText(_message, 'The list is slow');
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    final FeedbackEntry saved = (await harness.repo.watch().first).single;
    expect(saved.message, 'The list is slow');
    expect(saved.category, FeedbackCategory.general);
    expect(saved.screenshotCount, 1);
    expect(harness.draft, isNull);
    expect(find.byType(GiveFeedbackScreen), findsNothing);
    expect(find.text(Copy.feedbackSaved), findsOneWidget);
  });

  testWidgets('other needs a name before it can save', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text(Copy.feedbackCategoryOther));
    await tester.pump();
    // The named type's field now leads; the message is the last one.
    await tester.enterText(_message.last, 'Still slow');
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackOtherRequired), findsWidgets);
  });

  testWidgets('the four short types sit side by side, without Improvement', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(1000, 900));
    final double top = tester.getTopLeft(find.text(_types.first)).dy;
    for (final String label in _types) {
      expect(tester.getTopLeft(find.text(label)).dy, top);
    }
    expect(find.text(Copy.feedbackCategoryImprovement), findsNothing);
    expect(find.text(Copy.feedbackType), findsNothing);
    expect(
      find.byType(AppRadioGroup<FeedbackCategory>),
      hasSemanticLabel(Copy.feedbackType),
    );
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
    expect(top(_types[0]), top(_types[1]));
    expect(top(_types[2]), top(_types[3]));
    expect(top(_types[2]), greaterThan(top(_types[0])));
    expect(left(_types[0]), left(_types[2]));
  });

  testWidgets('a compact Save stays in reach while the form scrolls', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(360, 480), screenshot: aFeedbackPng);
    final Finder save = find.widgetWithText(FilledButton, Copy.feedbackSave);
    final Rect before = tester.getRect(save);
    expect(before.bottom, lessThanOrEqualTo(480));
    expect(before.height, lessThanOrEqualTo(48));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(save), before);
  });

  testWidgets('the attach checkbox leads its label, above the images', (
    WidgetTester tester,
  ) async {
    await _pump(tester, screenshot: aFeedbackPng);
    final Finder attach = find.byType(AppSwitchTile);
    final Finder label = find.text(Copy.feedbackAttachImages(1));
    final Finder preview = find.bySemanticsLabel(
      Copy.feedbackScreenshotPreview,
    );
    expect(
      tester.getRect(find.byType(Checkbox)).right,
      lessThan(tester.getRect(label).left),
    );
    expect(tester.getSize(attach).height, lessThanOrEqualTo(48));
    expect(
      tester.getRect(attach).bottom,
      lessThanOrEqualTo(tester.getRect(preview).top),
    );

    await tester.tap(attach);
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
  });

  testWidgets('photos are added, previewed large, and removed', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      photos: PhotoPicker.fake(
        photos: <Uint8List>[aFeedbackPng, aFeedbackPng, aFeedbackPng],
      ),
    );
    expect(find.text(Copy.feedbackNoScreenshot), findsOneWidget);
    await tester.tap(find.byTooltip(Copy.feedbackChoosePhoto));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackAttachImages(3)), findsOneWidget);
    final Finder tiles = find.bySemanticsLabel(Copy.feedbackScreenshotPreview);
    expect(tiles, findsNWidgets(3));
    // Three at up to four across balance as two rows of two and one.
    expect(tester.getSize(tiles.first).width, tester.getSize(tiles.last).width);

    await tester.tap(tiles.first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(Copy.feedbackShotPreview), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AppPanelDialog),
        matching: find.byTooltip(Copy.close),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(Copy.feedbackRemoveShot(Copy.photo)).first);
    await tester.pumpAndSettle();
    expect(harness.draft!.shots, hasLength(2));
  });

  testWidgets('the camera control shows only where there is a camera', (
    WidgetTester tester,
  ) async {
    await _pump(tester, photos: const PhotoPicker.fake(canTakePhoto: false));
    expect(find.byTooltip(Copy.feedbackTakePhoto), findsNothing);
    expect(find.byTooltip(Copy.feedbackChoosePhoto), findsOneWidget);
  });

  testWidgets('a refused picker explains itself and adds nothing', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      photos: const PhotoPicker.fake(
        failure: PermissionFailure(message: Copy.photoNoAccess),
      ),
    );
    await tester.tap(find.byTooltip(Copy.feedbackTakePhoto));
    await tester.pumpAndSettle();
    expect(find.text(Copy.photoNoAccess), findsWidgets);
    expect(harness.draft!.shots, isEmpty);
  });

  testWidgets('close folds the form into the bar and keeps everything', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, screenshot: aFeedbackPng);
    await tester.tap(find.text(Copy.feedbackCategoryError));
    await tester.enterText(_message, 'Still writing');
    await tester.tap(find.byTooltip(Copy.close));
    await tester.pumpAndSettle();
    expect(find.byType(GiveFeedbackScreen), findsNothing);
    expect(find.text(Copy.feedbackDiscardDraftMessage), findsNothing);
    expect(find.byType(FeedbackDraftBar), findsOneWidget);
    expect(find.text('Still writing'), findsOneWidget);
    // The app under the bar stays usable.
    await tester.tap(find.text('App screen'));

    await tester.enterText(
      find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.byType(TextField),
      ),
      'Still writing, from the bar',
    );
    await tester.tap(find.byTooltip(Copy.feedbackContinue));
    await tester.pumpAndSettle();
    expect(find.text('Still writing, from the bar'), findsOneWidget);
    expect(harness.draft!.category, FeedbackCategory.error);
    expect(harness.draft!.shots, hasLength(1));
  });

  testWidgets('the form folds and reopens any number of times', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    for (int round = 0; round < 3; round++) {
      await tester.tap(find.byTooltip(Copy.close));
      await tester.pumpAndSettle();
      expect(harness.container.exists(giveFeedbackControllerProvider), isFalse);
      harness.container.read(feedbackDraftProvider.notifier).expand();
      await tester.pumpAndSettle();
      expect(find.byType(GiveFeedbackScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(_message, 'Fourth time works');
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(
      (await harness.repo.watch().first).single.message,
      'Fourth time works',
    );
  });

  testWidgets('on a wide window the form docks beside a usable app', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(1400, 900));
    final Rect form = tester.getRect(find.byType(GiveFeedbackScreen));
    expect(form.width, AppConstants.userFeedback.panelWidth);
    expect(form.right, 1400);
    final Rect app = tester.getRect(find.text('App screen'));
    expect(app.right, lessThanOrEqualTo(form.left));
    expect(app.left, greaterThan(700));
    await tester.tap(find.text('App screen'));
  });

  testWidgets('discard asks first, then drops the draft', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.feedbackDiscardDraft));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDiscardDraftMessage), findsOneWidget);
    await tester.tap(find.text(Copy.discard));
    await tester.pumpAndSettle();
    expect(harness.draft, isNull);
    expect(find.byType(GiveFeedbackScreen), findsNothing);
  });

  testWidgets('the bar close asks first, then drops the draft', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(_message, 'Still writing');
    await tester.tap(find.byTooltip(Copy.close));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.byTooltip(Copy.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDiscardDraftMessage), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDraftBar), findsOneWidget);
    expect(find.text('Still writing'), findsOneWidget);
    expect(harness.draft, isNotNull);

    await tester.tap(
      find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.byTooltip(Copy.close),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.discard));
    await tester.pumpAndSettle();
    expect(harness.draft, isNull);
    expect(find.byType(FeedbackDraftBar), findsNothing);
  });

  test('rebuilding the form state while it is open is safe', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ProviderSubscription<Object?> keepAlive = container.listen(
      giveFeedbackControllerProvider,
      (Object? _, Object? _) {},
    );
    addTearDown(keepAlive.close);
    container.invalidate(giveFeedbackControllerProvider);
    expect(container.read(giveFeedbackControllerProvider).saveError, isNull);
  });
}

const List<String> _types = <String>[
  Copy.feedbackCategoryGeneral,
  Copy.feedbackCategoryError,
  Copy.feedbackCategorySuggestion,
  Copy.feedbackCategoryOther,
];

final Finder _message = find.descendant(
  of: find.byType(GiveFeedbackScreen),
  matching: find.byType(TextField),
);

final class _Harness {
  const _Harness(this.repo, this.container);

  final FeedbackRepositoryImpl repo;
  final ProviderContainer container;

  FeedbackDraft? get draft => container.read(feedbackDraftProvider);
}

/// The real overlay over a stand-in app, with a draft already open, as the
/// Feedback menu leaves it.
Future<_Harness> _pump(
  WidgetTester tester, {
  Uint8List? screenshot,
  Size size = const Size(400, 1200),
  PhotoPicker photos = const PhotoPicker.fake(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 18, 7, 2));
  final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
    clock: clock,
  );
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      feedbackClockProvider.overrideWith((Ref _) => clock),
      feedbackRepositoryProvider.overrideWith((Ref _) => repo),
      feedbackPhotosProvider.overrideWith((Ref _) => photos),
    ],
  );
  addTearDown(container.dispose);
  container.read(feedbackDraftProvider.notifier)
    ..capture(context: aFeedbackEntry().context, screenshot: screenshot)
    ..expand();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const FeedbackOverlay(
          origin: FeedbackOrigin.unknown,
          child: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text('App screen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(repo, container);
}
