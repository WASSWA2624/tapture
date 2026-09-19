import 'dart:typed_data';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/screen_capture.dart';
import 'package:tapture/core/lifecycle/lifecycle.dart';
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
import 'package:tapture/features/feedback/presentation/feedback_shots.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_screen.dart';
import 'package:tapture/features/settings/domain/operator_profile.dart';
import 'package:tapture/features/settings/presentation/operator_profile_screen.dart';

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
    final Finder attach = find.widgetWithText(
      AppSwitchTile,
      Copy.feedbackAttachImages(1),
    );
    final Finder label = find.text(Copy.feedbackAttachImages(1));
    final Finder preview = find.bySemanticsLabel(
      Copy.feedbackScreenshotPreview,
    );
    expect(
      tester
          .getRect(find.descendant(of: attach, matching: find.byType(Checkbox)))
          .right,
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

  testWidgets('one image is a square thumbnail at 393 dp', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(393, 886), screenshot: aFeedbackPng);
    _expectSquareThumbnail(tester);
  });

  testWidgets('one image is a square thumbnail in the 420 dp docked panel', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(1400, 900), screenshot: aFeedbackPng);
    expect(
      tester.getSize(find.byType(GiveFeedbackScreen)).width,
      AppConstants.userFeedback.panelWidth,
    );
    _expectSquareThumbnail(tester);
  });

  testWidgets('tapping the thumbnail opens the preview at full width', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(393, 886), screenshot: aFeedbackPng);
    final Finder tile = find.bySemanticsLabel(Copy.feedbackScreenshotPreview);
    final double thumb = tester.getSize(tile).width;
    await tester.tap(tile);
    await tester.pumpAndSettle();
    final Finder preview = find.bySemanticsLabel(Copy.feedbackShotPreview);
    expect(preview, findsOneWidget);
    expect(tester.getSize(preview).width, greaterThan(thumb));
    // AppPanelDialog's box is the Dialog (window-wide); the image fills the
    // inset panel. Allow 1 dp for rounding.
    final Finder panel = find
        .descendant(
          of: find.byType(AppPanelDialog),
          matching: find.byType(ConstrainedBox),
        )
        .first;
    expect(
      tester.getSize(preview).width,
      closeTo(tester.getSize(panel).width, 1),
    );
  });

  testWidgets('three images keep balanced square tiles', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      photos: PhotoPicker.fake(
        photos: <Uint8List>[aFeedbackPng, aFeedbackPng, aFeedbackPng],
      ),
    );
    await tester.tap(find.byTooltip(Copy.feedbackChoosePhoto));
    await tester.pumpAndSettle();
    final Finder tiles = find.bySemanticsLabel(Copy.feedbackScreenshotPreview);
    expect(tiles, findsNWidgets(3));
    final Size first = tester.getSize(tiles.at(0));
    final Size last = tester.getSize(tiles.at(2));
    expect(first.width, first.height);
    expect(first.width, last.width);
    expect(
      tester.getTopLeft(tiles.at(0)).dy,
      tester.getTopLeft(tiles.at(1)).dy,
    );
    expect(
      tester.getTopLeft(tiles.at(2)).dy,
      greaterThan(tester.getTopLeft(tiles.at(0)).dy),
    );
  });

  testWidgets('one image does not overflow at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, size: const Size(393, 886), screenshot: aFeedbackPng);
    expect(tester.takeException(), isNull);
    _expectSquareThumbnail(tester);
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

  testWidgets('another window is offered only where capture is available', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.byTooltip(Copy.feedbackAddWindow), findsNothing);
    expect(find.byTooltip(Copy.feedbackAddScreen), findsOneWidget);
    expect(find.byTooltip(Copy.feedbackTakePhoto), findsOneWidget);
    expect(find.byTooltip(Copy.feedbackChoosePhoto), findsOneWidget);
  });

  testWidgets('another window attaches a still and turns attach on', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      screenCapture: ScreenCapture.fake(canCapture: true, frame: aFeedbackPng),
    );
    expect(find.text(Copy.feedbackNoScreenshot), findsOneWidget);
    await tester.tap(find.byTooltip(Copy.feedbackAddWindow));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackAttachImages(1)), findsOneWidget);
    expect(harness.draft!.shots, hasLength(1));
    expect(harness.draft!.shots.single.label, Copy.feedbackOtherWindow);
    expect(harness.draft!.attachShots, isTrue);
    expect(find.byTooltip(Copy.feedbackStopSharing), findsOneWidget);
    expect(find.text(Copy.feedbackSharingWindow), findsOneWidget);
    expect(
      find.text(Copy.feedbackShotAdded(Copy.feedbackOtherWindow)),
      findsWidgets,
    );
    expect(find.byTooltip(Copy.feedbackAddScreen), findsOneWidget);
    expect(find.byTooltip(Copy.feedbackChoosePhoto), findsOneWidget);
  });

  testWidgets('a refused display picker explains itself and adds nothing', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      screenCapture: const ScreenCapture.fake(
        canCapture: true,
        failure: PermissionFailure(message: Copy.displayNoAccess),
      ),
    );
    await tester.tap(find.byTooltip(Copy.feedbackAddWindow));
    await tester.pumpAndSettle();
    expect(find.text(Copy.displayNoAccess), findsWidgets);
    expect(harness.draft!.shots, isEmpty);
    expect(find.byTooltip(Copy.feedbackStopSharing), findsNothing);
    expect(find.text(Copy.feedbackSharingWindow), findsNothing);
  });

  testWidgets(
    'while sharing, the bar offers another still and typing still works',
    (WidgetTester tester) async {
      final _Harness harness = await _pump(
        tester,
        screenCapture: ScreenCapture.fake(
          canCapture: true,
          frames: <Uint8List>[aFeedbackPng, aFeedbackPng],
        ),
      );
      await tester.tap(find.byTooltip(Copy.feedbackAddWindow));
      await tester.pumpAndSettle();
      expect(harness.draft!.shots, hasLength(1));
      await tester.enterText(_message, 'Typed while sharing');
      await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackDraftBar), findsOneWidget);
      final Finder barWindow = find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.byTooltip(Copy.feedbackAddWindow),
      );
      expect(barWindow, findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(FeedbackDraftBar),
          matching: find.byType(TextField),
        ),
        'Typed while sharing, from the bar',
      );
      await tester.tap(barWindow);
      await tester.pumpAndSettle();
      expect(harness.draft!.shots, hasLength(2));
      expect(find.text('Typed while sharing, from the bar'), findsOneWidget);
    },
  );

  testWidgets('Stop sharing hides the stop control', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      screenCapture: ScreenCapture.fake(canCapture: true, frame: aFeedbackPng),
    );
    await tester.tap(find.byTooltip(Copy.feedbackAddWindow));
    await tester.pumpAndSettle();
    expect(find.byTooltip(Copy.feedbackStopSharing), findsOneWidget);
    await tester.tap(find.byTooltip(Copy.feedbackStopSharing));
    await tester.pumpAndSettle();
    expect(find.byTooltip(Copy.feedbackStopSharing), findsNothing);
    expect(find.text(Copy.feedbackSharingWindow), findsNothing);
    expect(find.byTooltip(Copy.feedbackAddWindow), findsOneWidget);
  });

  testWidgets(
    'at 360 dp and 200 percent text the bar and shots row do not overflow',
    (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        size: const Size(360, 800),
        screenCapture: ScreenCapture.fake(
          canCapture: true,
          frame: aFeedbackPng,
        ),
      );
      await tester.ensureVisible(find.byTooltip(Copy.feedbackAddWindow));
      await tester.tap(find.byTooltip(Copy.feedbackAddWindow));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FeedbackShots), findsOneWidget);
      await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackDraftBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the folded bar screenshot control adds one image and is labelled',
    (WidgetTester tester) async {
      final _Harness harness = await _pump(tester);
      expect(harness.draft!.shots, isEmpty);
      await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
      await tester.pumpAndSettle();
      final Finder add = find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.byTooltip(Copy.feedbackAddScreen),
      );
      expect(add, findsOneWidget);
      expect(add, meetsTapTarget());
      expect(add, hasSemanticLabel(Copy.feedbackAddScreen));
      await _addThisScreen(tester, harness);
      expect(
        find.text(Copy.feedbackShotAdded(FeedbackOrigin.unknown.screen)),
        findsWidgets,
      );
    },
  );

  testWidgets('both screenshot tips show when capture is unavailable', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      size: const Size(360, 800),
      screenCapture: const ScreenCapture.fake(canCapture: false),
    );
    expect(find.text(Copy.feedbackShotTipScreens), findsOneWidget);
    expect(find.text(Copy.feedbackShotTipApps), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('neither screenshot tip shows when capture is available', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      screenCapture: const ScreenCapture.fake(canCapture: true),
    );
    expect(find.text(Copy.feedbackShotTipScreens), findsNothing);
    expect(find.text(Copy.feedbackShotTipApps), findsNothing);
  });

  testWidgets('the folded bar has no overflow at 360 dp with an image count', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(360, 800), screenshot: aFeedbackPng);
    await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.bySemanticsLabel(Copy.feedbackImageCount(1)),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(FeedbackDraftBar)).right,
      lessThanOrEqualTo(360),
    );

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDraftBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(FeedbackDraftBar)).right,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('close folds the form into the bar and keeps everything', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, screenshot: aFeedbackPng);
    await tester.tap(find.text(Copy.feedbackCategoryError));
    await tester.enterText(_message, 'Still writing');
    final Finder collapse = find.byTooltip(Copy.feedbackContinueLater);
    expect(collapse, findsOneWidget);
    expect(collapse, hasSemanticLabel(Copy.feedbackContinueLater));
    expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);
    await tester.tap(collapse);
    await tester.pumpAndSettle();
    expect(find.byType(GiveFeedbackScreen), findsNothing);
    expect(find.text(Copy.feedbackDiscardDraftTitle), findsNothing);
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

  testWidgets('the folded bar sits above an open keyboard on a phone', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(393, 886));
    await _foldBar(tester);
    _openKeyboard(tester, bottom: 300);
    await tester.pump();
    _expectBarAboveKeyboard(tester, inset: 300);
  });

  testWidgets(
    'the folded bar sits above an open keyboard at medium and expanded widths',
    (WidgetTester tester) async {
      await _pump(tester, size: const Size(700, 886));
      await _foldBar(tester);
      _openKeyboard(tester, bottom: 300);
      await tester.pump();
      _expectBarAboveKeyboard(tester, inset: 300);

      tester.view.physicalSize = const Size(1280, 886);
      await tester.pump();
      expect(find.byType(FeedbackDraftBar), findsOneWidget);
      _expectBarAboveKeyboard(tester, inset: 300);
    },
  );

  testWidgets('the folded bar stays visible above the keyboard in landscape', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(886, 393));
    await _foldBar(tester);
    _openKeyboard(tester, bottom: 200);
    await tester.pump();
    _expectBarAboveKeyboard(tester, inset: 200);
  });

  testWidgets('a taller bar at 200 percent text stays above the keyboard', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, size: const Size(393, 886));
    await _foldBar(tester);
    _openKeyboard(tester, bottom: 300);
    await tester.pump();
    _expectBarAboveKeyboard(tester, inset: 300);
  });

  testWidgets('closing the keyboard returns the bar above the navigation bar', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(393, 886));
    await _foldBar(tester);
    final Rect resting = tester.getRect(find.byType(FeedbackDraftBar));
    _openKeyboard(tester, bottom: 300);
    await tester.pump();
    expect(
      tester.getRect(find.byType(FeedbackDraftBar)).bottom,
      lessThan(resting.bottom),
    );
    _closeKeyboard(tester);
    await tester.pump();
    expect(tester.getRect(find.byType(FeedbackDraftBar)), resting);
  });

  testWidgets('typed text survives opening and closing the keyboard', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(393, 886));
    await _foldBar(tester);
    await tester.enterText(_barMessage, 'Kept through the keyboard');
    await tester.pump();
    _openKeyboard(tester, bottom: 300);
    await tester.pump();
    expect(find.text('Kept through the keyboard'), findsOneWidget);
    _closeKeyboard(tester);
    await tester.pump();
    expect(find.text('Kept through the keyboard'), findsOneWidget);
    expect(_barMessage.hitTestable(), findsOneWidget);
  });

  testWidgets('the form folds and reopens any number of times', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    for (int round = 0; round < 3; round++) {
      await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
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

  testWidgets('typing arms the leave guard', (WidgetTester tester) async {
    final _Harness harness = await _pump(tester);
    expect(harness.guard.isHeld, isFalse);
    await tester.enterText(_message, 'Still writing');
    await tester.pump();
    expect(harness.guard.isHeld, isTrue);
  });

  testWidgets('a successful Save releases the leave guard', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(_message, 'The list is slow');
    await tester.pump();
    expect(harness.guard.isHeld, isTrue);
    await tester.tap(find.text(Copy.feedbackSave));
    await tester.pumpAndSettle();
    expect(harness.guard.isHeld, isFalse);
  });

  testWidgets('a confirmed discard releases the leave guard', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(_message, 'Still writing');
    await tester.pump();
    expect(harness.guard.isHeld, isTrue);
    await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.feedbackDiscardDraft));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.discard));
    await tester.pumpAndSettle();
    expect(harness.guard.isHeld, isFalse);
  });

  testWidgets('an exit request with a draft asks before discarding', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(_message, 'Still writing');
    await tester.pump();

    final Future<AppExitResponse> cancelled = harness.observer
        .didRequestAppExit();
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDiscardDraftTitle), findsOneWidget);
    expect(find.text(Copy.feedbackDiscardDraftMessage(0)), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(await cancelled, AppExitResponse.cancel);
    expect(find.text('Still writing'), findsOneWidget);
    expect(harness.draft, isNotNull);

    final Future<AppExitResponse> confirmed = harness.observer
        .didRequestAppExit();
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.discard));
    await tester.pumpAndSettle();
    expect(await confirmed, AppExitResponse.exit);
    expect(harness.draft, isNull);
  });

  testWidgets('an exit request asks while the draft is folded into the bar', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    await tester.enterText(_message, 'Still writing');
    await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDraftBar), findsOneWidget);

    final Future<AppExitResponse> pending = harness.observer
        .didRequestAppExit();
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDiscardDraftTitle), findsOneWidget);
    expect(find.text(Copy.feedbackDiscardDraftMessage(0)), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(await pending, AppExitResponse.cancel);
    expect(find.text('Still writing'), findsOneWidget);
  });

  testWidgets('an exit request with no draft exits without a dialog', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester);
    expect(await harness.observer.didRequestAppExit(), AppExitResponse.exit);
    expect(find.text(Copy.feedbackDiscardDraftTitle), findsNothing);
  });

  testWidgets('discard asks first, then drops the draft', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, screenshot: aFeedbackPng);
    await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.feedbackDiscardDraft));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDiscardDraftTitle), findsOneWidget);
    expect(find.text(Copy.feedbackDiscardDraftMessage(1)), findsOneWidget);
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
    await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
    await tester.pumpAndSettle();
    final Finder discard = find.descendant(
      of: find.byType(FeedbackDraftBar),
      matching: find.byTooltip(Copy.feedbackDiscardDraft),
    );
    expect(discard, findsOneWidget);
    expect(discard, hasSemanticLabel(Copy.feedbackDiscardDraft));
    await tester.tap(discard);
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackDiscardDraftTitle), findsOneWidget);
    expect(find.text(Copy.feedbackDiscardDraftMessage(0)), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDraftBar), findsOneWidget);
    expect(find.text('Still writing'), findsOneWidget);
    expect(harness.draft, isNotNull);

    await tester.tap(
      find.descendant(
        of: find.byType(FeedbackDraftBar),
        matching: find.byTooltip(Copy.feedbackDiscardDraft),
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

  testWidgets(
    'Screenshot current screen captures the app, not the form, until opted in',
    (WidgetTester tester) async {
      final _Harness harness = await _pump(tester, size: const Size(400, 1200));
      expect(harness.draft!.includeUi, isFalse);
      expect(_includeTile(tester).value, isFalse);
      final Uint8List appOnly = await _addThisScreen(tester, harness);
      expect(_pngSize(appOnly).width, 400);

      await tester.tap(find.text(Copy.feedbackIncludeUi));
      await tester.pumpAndSettle();
      expect(harness.draft!.includeUi, isTrue);
      expect(_includeTile(tester).value, isTrue);
      final Uint8List withUi = await _addThisScreen(tester, harness);
      expect(withUi, isNot(appOnly));
      expect(harness.draft!.shots, hasLength(2));
    },
  );

  testWidgets('opting in on a wide window captures the docked app and panel', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, size: const Size(1400, 900));
    final Uint8List appOnly = await _addThisScreen(tester, harness);
    expect(
      _pngSize(appOnly).width,
      1400 - AppConstants.userFeedback.panelWidth,
    );

    await tester.tap(find.text(Copy.feedbackIncludeUi));
    await tester.pumpAndSettle();
    final Uint8List withUi = await _addThisScreen(tester, harness);
    expect(_pngSize(withUi).width, 1400);
    expect(_pngSize(withUi).width, greaterThan(_pngSize(appOnly).width));
  });

  for (final ({String name, ThemeData theme}) mode in _feedbackThemes) {
    testWidgets('include-UI is labelled and 48dp in ${mode.name}', (
      WidgetTester tester,
    ) async {
      await _pump(tester, theme: mode.theme);
      final Finder include = find.widgetWithText(
        AppSwitchTile,
        Copy.feedbackIncludeUi,
      );
      expect(include, findsOneWidget);
      expect(include, meetsTapTarget());
      expect(include, hasSemanticLabel(Copy.feedbackIncludeUi));
      expect(find.byTooltip(Copy.feedbackAddScreen), findsOneWidget);
      expect(find.byTooltip(Copy.feedbackAddScreen), meetsTapTarget());
      await expectNoA11yIssues(tester);
    });
  }

  testWidgets('another window stays labelled and unclipped at 360 dp', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      size: const Size(360, 800),
      screenCapture: ScreenCapture.fake(canCapture: true, frame: aFeedbackPng),
    );
    final Finder add = find.byTooltip(Copy.feedbackAddWindow);
    expect(add, findsOneWidget);
    expect(add, meetsTapTarget());
    expect(add, hasSemanticLabel(Copy.feedbackAddWindow));
    expect(tester.getRect(add).right, lessThanOrEqualTo(360));
    expect(find.byTooltip(Copy.feedbackAddScreen), findsOneWidget);
    expect(find.byTooltip(Copy.feedbackChoosePhoto), findsOneWidget);
    await expectNoA11yIssues(tester);
  });

  for (final ({String name, ThemeData theme}) mode in _feedbackThemes) {
    testWidgets('another window is labelled and 48dp in ${mode.name}', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        theme: mode.theme,
        screenCapture: const ScreenCapture.fake(canCapture: true),
      );
      final Finder add = find.byTooltip(Copy.feedbackAddWindow);
      expect(add, findsOneWidget);
      expect(add, meetsTapTarget());
      expect(add, hasSemanticLabel(Copy.feedbackAddWindow));
      await expectNoA11yIssues(tester);
    });
  }

  testWidgets('at 360 dp each checkbox label sits on one line', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(360, 800), screenshot: aFeedbackPng);
    final double line = (TextPainter(
      text: const TextSpan(text: 'Ag', style: AppText.label),
      textDirection: TextDirection.ltr,
    )..layout()).height;
    expect(
      tester.getSize(find.text(Copy.feedbackAttachImages(1))).height,
      line,
    );
    expect(
      tester.getRect(find.text(Copy.feedbackAttachImages(1))).right,
      lessThanOrEqualTo(360),
    );
    expect(
      tester.getRect(find.text(Copy.feedbackIncludeUi)).right,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets(
    'at 360 dp and 200 percent text the shots section does not overflow',
    (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        size: const Size(360, 800),
        screenshot: aFeedbackPng,
        screenCapture: ScreenCapture.fake(
          canCapture: true,
          frame: aFeedbackPng,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(FeedbackShots), findsOneWidget);
    },
  );

  testWidgets(
    'on a wide window the docked panel shows both checkboxes and the capture row',
    (WidgetTester tester) async {
      await _pump(
        tester,
        size: const Size(1400, 900),
        screenshot: aFeedbackPng,
        screenCapture: const ScreenCapture.fake(canCapture: true),
      );
      final Finder attach = find.text(Copy.feedbackAttachImages(1));
      final Finder include = find.text(Copy.feedbackIncludeUi);
      final Finder capture = find.byTooltip(Copy.feedbackAddScreen);
      expect(attach, findsOneWidget);
      expect(include, findsOneWidget);
      expect(capture, findsOneWidget);
      expect(find.byTooltip(Copy.feedbackAddWindow), findsOneWidget);
      expect(
        tester.getRect(attach).bottom,
        lessThanOrEqualTo(tester.getRect(include).top),
      );
      expect(
        tester.getRect(include).bottom,
        lessThanOrEqualTo(tester.getRect(capture).top),
      );
    },
  );
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

final Finder _barMessage = find.descendant(
  of: find.byType(FeedbackDraftBar),
  matching: find.byType(TextField),
);

Future<void> _foldBar(WidgetTester tester) async {
  await tester.tap(find.byTooltip(Copy.feedbackContinueLater));
  await tester.pumpAndSettle();
  expect(find.byType(FeedbackDraftBar), findsOneWidget);
}

void _openKeyboard(WidgetTester tester, {required double bottom}) {
  tester.view.viewInsets = FakeViewPadding(bottom: bottom);
}

void _closeKeyboard(WidgetTester tester) {
  tester.view.resetViewInsets();
}

void _expectBarAboveKeyboard(WidgetTester tester, {required double inset}) {
  final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect bar = tester.getRect(find.byType(FeedbackDraftBar));
  expect(bar.bottom, lessThanOrEqualTo(size.height - inset));
  expect(bar.top, greaterThanOrEqualTo(0));
  expect(_barMessage.hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

final class _Harness {
  const _Harness(this.repo, this.container);

  final FeedbackRepositoryImpl repo;
  final ProviderContainer container;

  FeedbackDraft? get draft => container.read(feedbackDraftProvider);

  LeaveGuard get guard => container.read(leaveGuardProvider);

  LifecycleObserver get observer => container.read(lifecycleObserverProvider);
}

Future<Uint8List> _addThisScreen(WidgetTester tester, _Harness harness) async {
  final int before = harness.draft!.shots.length;
  final Finder add = find.byTooltip(Copy.feedbackAddScreen);
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  for (int i = 0; i < 50 && harness.draft!.shots.length == before; i++) {
    await tester.runAsync(() {
      return Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
  }
  expect(harness.draft!.shots, hasLength(before + 1));
  final Uint8List bytes = harness.draft!.shots.last.bytes;
  expect(bytes, isNotEmpty);
  return bytes;
}

void _expectSquareThumbnail(WidgetTester tester) {
  final Finder tile = find.bySemanticsLabel(Copy.feedbackScreenshotPreview);
  expect(tile, findsOneWidget);
  final Size size = tester.getSize(tile);
  expect(size.width, size.height);
  expect(size.width, lessThanOrEqualTo(AppConstants.userFeedback.galleryTile));
  expect(
    size.width,
    lessThan(tester.getSize(find.byType(FeedbackShots)).width),
  );
  expect(tile, meetsTapTarget());
}

AppSwitchTile _includeTile(WidgetTester tester) {
  return tester.widget<AppSwitchTile>(
    find.widgetWithText(AppSwitchTile, Copy.feedbackIncludeUi),
  );
}

Size _pngSize(Uint8List png) {
  final ByteData header = ByteData.sublistView(png, 16, 24);
  return Size(header.getUint32(0).toDouble(), header.getUint32(4).toDouble());
}

List<({String name, ThemeData theme})> get _feedbackThemes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

/// The real overlay over a stand-in app, with a draft already open, as the
/// Feedback menu leaves it.
Future<_Harness> _pump(
  WidgetTester tester, {
  Uint8List? screenshot,
  Size size = const Size(400, 1200),
  PhotoPicker photos = const PhotoPicker.fake(),
  ScreenCapture screenCapture = const ScreenCapture.fake(),
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewInsets();
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
      feedbackScreenCaptureProvider.overrideWith((Ref _) => screenCapture),
      operatorProfileOverride(
        load: () async => const OperatorProfile(name: 'Ada', initials: 'A'),
        save: (OperatorProfile profile) async =>
            Success<OperatorProfile>(profile),
      ),
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
        theme: theme ?? buildTheme(brightness: Brightness.light),
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
