import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/screen_capture.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';
import 'package:tapture/features/feedback/presentation/feedback_shot.dart';
import 'package:tapture/features/feedback/presentation/feedback_window_share_controller.dart';
import 'package:tapture/features/feedback/presentation/give_feedback_controller.dart';

import '../../../support/factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two taps add two stills from one start', () async {
    final _Harness harness = _harness();
    expect(await harness.share.addStill(), isNull);
    expect(await harness.share.addStill(), isNull);
    expect(harness.draft.shots, hasLength(2));
    expect(
      harness.draft.shots.every(
        (FeedbackShot shot) => shot.label == Copy.feedbackOtherWindow,
      ),
      isTrue,
    );
    expect(harness.sharing, isTrue);
    expect(harness.capture.isSharing, isTrue);
    expect(harness.capture.stops, 0);
  });

  test('cancel adds nothing and is not sharing', () async {
    final _Harness harness = _harness(
      capture: const ScreenCapture.fake(canCapture: true),
    );
    expect(await harness.share.addStill(), isNull);
    expect(harness.draft.shots, isEmpty);
    expect(harness.sharing, isFalse);
    expect(harness.capture.isSharing, isFalse);
  });

  test('ended clears sharing', () async {
    final _Harness harness = _harness();
    expect(await harness.share.addStill(), isNull);
    expect(harness.sharing, isTrue);
    harness.capture.end();
    await Future<void>.delayed(Duration.zero);
    expect(harness.sharing, isFalse);
    expect(harness.capture.isSharing, isFalse);
  });

  test('Save and discard call stop', () async {
    final _Harness harness = _harness();
    expect(await harness.share.addStill(), isNull);
    expect(harness.capture.isSharing, isTrue);
    harness.drafts.clear();
    await Future<void>.delayed(Duration.zero);
    expect(harness.capture.isSharing, isFalse);
    expect(harness.sharing, isFalse);
    expect(harness.capture.stops, 1);

    harness.drafts.capture(context: aFeedbackEntry().context);
    harness.drafts.setText(message: 'Saved while sharing');
    expect(await harness.share.addStill(), isNull);
    expect(harness.capture.isSharing, isTrue);
    final Result<FeedbackEntry> saved = await harness.form.save();
    expect(saved, isA<Success<FeedbackEntry>>());
    await Future<void>.delayed(Duration.zero);
    expect(harness.capture.isSharing, isFalse);
    expect(harness.sharing, isFalse);
    expect(harness.container.read(feedbackDraftProvider), isNull);
  });

  test('when full, it reports feedbackShotsFull', () async {
    final _Harness harness = _harness();
    expect(await harness.share.addStill(), isNull);
    for (
      int i = harness.draft.shots.length;
      i < AppConstants.userFeedback.maxShots;
      i++
    ) {
      expect(harness.drafts.addShot(aFeedbackPng, label: Copy.photo), isNull);
    }
    expect(harness.draft.shots, hasLength(AppConstants.userFeedback.maxShots));
    expect(await harness.share.addStill(), Copy.feedbackShotsFull);
    expect(harness.sharing, isTrue);
    expect(harness.capture.isSharing, isTrue);
    expect(harness.draft.shots, hasLength(AppConstants.userFeedback.maxShots));
  });
}

final class _Harness {
  const _Harness({
    required this.container,
    required this.share,
    required this.drafts,
    required this.form,
    required this.capture,
  });

  final ProviderContainer container;
  final FeedbackWindowShareController share;
  final FeedbackDraftController drafts;
  final GiveFeedbackController form;
  final ScreenCapture capture;

  bool get sharing => container.read(feedbackWindowShareProvider);

  FeedbackDraft get draft => container.read(feedbackDraftProvider)!;
}

_Harness _harness({ScreenCapture? capture}) {
  final ScreenCapture screen =
      capture ??
      ScreenCapture.fake(
        canCapture: true,
        frames: <Uint8List>[aFeedbackPng, aFeedbackPng, aFeedbackPng],
      );
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      feedbackScreenCaptureProvider.overrideWith((Ref _) => screen),
    ],
  );
  addTearDown(container.dispose);
  // The form is autoDispose; a yield would drop it before Save.
  final ProviderSubscription<Object?> formKeepAlive = container.listen(
    giveFeedbackControllerProvider,
    (Object? _, Object? _) {},
  );
  addTearDown(formKeepAlive.close);
  final FeedbackDraftController drafts = container.read(
    feedbackDraftProvider.notifier,
  );
  drafts.capture(context: aFeedbackEntry().context);
  return _Harness(
    container: container,
    share: container.read(feedbackWindowShareProvider.notifier),
    drafts: drafts,
    form: container.read(giveFeedbackControllerProvider.notifier),
    capture: screen,
  );
}
