import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';
import 'package:tapture/features/feedback/presentation/feedback_shot.dart';

import '../../../support/factories.dart';

void main() {
  test('a first capture is held closed until Give us feedback starts', () {
    final _Harness harness = _harness();
    harness.draft.capture(
      FeedbackDraft(context: aFeedbackEntry().context, screenshot: _bytes(1)),
    );
    final FeedbackDraft held = harness.read();
    expect(held.open, isFalse);
    expect(held.expanded, isFalse);
    expect(held.shots, hasLength(1));
    expect(held.shots.single.id, 'capture');
    expect(held.shots.single.bytes, _bytes(1));
  });

  test('a later capture replaces the held one until the form is open', () {
    final _Harness harness = _harness();
    harness.draft.capture(
      FeedbackDraft(context: aFeedbackEntry().context, screenshot: _bytes(1)),
    );
    harness.draft.capture(
      FeedbackDraft(
        context: aFeedbackEntry(screen: 'Capture').context,
        screenshot: _bytes(2),
      ),
    );
    final FeedbackDraft held = harness.read();
    expect(held.shots, hasLength(1));
    expect(held.shots.single.bytes, _bytes(2));
    expect(held.context.screen, 'Capture');
    expect(held.open, isFalse);
  });

  test('an open draft keeps its text and gains an added screen', () {
    final _Harness harness = _harness();
    harness.draft.capture(
      FeedbackDraft(context: aFeedbackEntry().context, screenshot: _bytes(1)),
    );
    harness.draft.openGive();
    harness.draft.setText(message: 'Still writing');
    harness.draft.setCategory(FeedbackCategory.error);
    harness.draft.capture(
      FeedbackDraft(
        context: aFeedbackEntry(screen: 'Capture').context,
        screenshot: _bytes(2),
      ),
    );
    final FeedbackDraft open = harness.read();
    expect(open.open, isTrue);
    expect(open.expanded, isTrue);
    expect(open.message, 'Still writing');
    expect(open.category, FeedbackCategory.error);
    expect(open.context.screen, 'Projects');
    expect(open.shots, hasLength(2));
    expect(open.shots.first.id, 'capture');
    expect(open.shots.last.id, 'shot-1');
    expect(open.shots.last.bytes, _bytes(2));
  });

  test('an empty recapture does not add a shot to an open draft', () {
    final _Harness harness = _harness();
    harness.draft.capture(
      FeedbackDraft(context: aFeedbackEntry().context, screenshot: _bytes(1)),
    );
    harness.draft.openGive();
    harness.draft.capture(FeedbackDraft(context: aFeedbackEntry().context));
    expect(harness.read().shots, hasLength(1));
  });

  test('collapse keeps the draft so the operator can keep writing', () {
    final _Harness harness = _harness();
    harness.draft.capture(
      FeedbackDraft(context: aFeedbackEntry().context, screenshot: _bytes(1)),
    );
    harness.draft.openGive();
    harness.draft.setText(message: 'Halfway');
    harness.draft.collapse();
    expect(harness.read().open, isTrue);
    expect(harness.read().expanded, isFalse);
    expect(harness.read().message, 'Halfway');
    harness.draft.expand();
    expect(harness.read().expanded, isTrue);
  });

  test('addShot turns attach on and refuses a ninth image', () {
    final _Harness harness = _harness();
    harness.draft.capture(FeedbackDraft(context: aFeedbackEntry().context));
    expect(harness.read().attachShots, isFalse);
    expect(
      harness.draft.addShot(
        FeedbackShot(id: 'photo', bytes: _bytes(3), label: 'Photo'),
      ),
      isNull,
    );
    expect(harness.read().attachShots, isTrue);
    for (
      int index = 0;
      index < AppConstants.userFeedback.maxShots - 1;
      index++
    ) {
      expect(
        harness.draft.addShot(
          FeedbackShot(
            id: 'extra-$index',
            bytes: _bytes(index + 4),
            label: 'Extra',
          ),
        ),
        isNull,
      );
    }
    expect(
      harness.draft.addShot(
        FeedbackShot(id: 'full', bytes: _bytes(99), label: 'Full'),
      ),
      Copy.feedbackShotsFull,
    );
    expect(harness.read().shots, hasLength(AppConstants.userFeedback.maxShots));
  });
}

final class _Harness {
  const _Harness(this.container, this.draft);

  final ProviderContainer container;
  final FeedbackDraftController draft;

  FeedbackDraft read() => container.read(feedbackDraftProvider)!;
}

_Harness _harness() {
  final ProviderContainer container = ProviderContainer();
  addTearDown(container.dispose);
  return _Harness(container, container.read(feedbackDraftProvider.notifier));
}

Uint8List _bytes(int seed) => Uint8List.fromList(<int>[seed]);
