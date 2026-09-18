import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';

import '../../../support/factories.dart';

void main() {
  test('a first capture is held closed until Give us feedback starts', () {
    final _Harness harness = _harness();
    harness.draft.capture(
      context: aFeedbackEntry().context,
      screenshot: _bytes(1),
    );
    final FeedbackDraft held = harness.read();
    expect(held.open, isFalse);
    expect(held.expanded, isFalse);
    expect(held.shots.single.bytes, _bytes(1));
    expect(held.shots.single.label, Copy.feedbackScreenshotOf('Projects'));
  });

  test('a later capture replaces the held one until the form is open', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context, screenshot: _bytes(1))
      ..capture(
        context: aFeedbackEntry(screen: 'Capture').context,
        screenshot: _bytes(2),
      );
    final FeedbackDraft held = harness.read();
    expect(held.shots.single.bytes, _bytes(2));
    expect(held.context.screen, 'Capture');
    expect(held.open, isFalse);
  });

  test('an open draft keeps its text and gains an added screen', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context, screenshot: _bytes(1))
      ..expand()
      ..setText(message: 'Still writing')
      ..setCategory(FeedbackCategory.error);
    final String? problem = harness.draft.capture(
      context: aFeedbackEntry(screen: 'Capture').context,
      screenshot: _bytes(2),
    );
    final FeedbackDraft open = harness.read();
    expect(problem, isNull);
    expect(open.open, isTrue);
    expect(open.expanded, isTrue);
    expect(open.message, 'Still writing');
    expect(open.category, FeedbackCategory.error);
    expect(open.context.screen, 'Projects');
    expect(open.shots.map((s) => s.bytes), <Uint8List>[_bytes(1), _bytes(2)]);
    expect(open.shots.last.label, Copy.feedbackScreenshotOf('Capture'));
    expect(open.shots.first.id, isNot(open.shots.last.id));
  });

  test('an empty recapture does not add a shot to an open draft', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context, screenshot: _bytes(1))
      ..expand()
      ..capture(context: aFeedbackEntry().context);
    expect(harness.read().shots, hasLength(1));
  });

  test('collapse keeps the draft so the operator can keep writing', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context)
      ..expand()
      ..setText(message: 'Halfway')
      ..collapse();
    expect(harness.read().open, isTrue);
    expect(harness.read().expanded, isFalse);
    expect(harness.read().message, 'Halfway');
    harness.draft.expand();
    expect(harness.read().expanded, isTrue);
  });

  test('addShot turns attach on and refuses one past the limit', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context)
      ..setAttachShots(false);
    for (int i = 0; i < AppConstants.userFeedback.maxShots; i++) {
      expect(harness.draft.addShot(_bytes(i), label: Copy.photo), isNull);
    }
    expect(harness.read().attachShots, isTrue);
    expect(
      harness.draft.addShot(_bytes(99), label: Copy.photo),
      Copy.feedbackShotsFull,
    );
    expect(
      harness.draft.capture(
        context: aFeedbackEntry().context,
        screenshot: _bytes(100),
      ),
      isNull,
      reason: 'a closed draft is replaced, not added to',
    );
  });

  test('a full open draft says why a screen was not added', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context)
      ..expand();
    for (int i = 0; i < AppConstants.userFeedback.maxShots; i++) {
      harness.draft.addShot(_bytes(i), label: Copy.photo);
    }
    expect(
      harness.draft.capture(
        context: aFeedbackEntry().context,
        screenshot: _bytes(99),
      ),
      Copy.feedbackShotsFull,
    );
  });

  test('removeShot drops only that image; clear drops the draft', () {
    final _Harness harness = _harness();
    harness.draft
      ..capture(context: aFeedbackEntry().context, screenshot: _bytes(1))
      ..addShot(_bytes(2), label: Copy.photo);
    harness.draft.removeShot(harness.read().shots.first.id);
    expect(harness.read().shots.single.bytes, _bytes(2));
    harness.draft.clear();
    expect(harness.container.read(feedbackDraftProvider), isNull);
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
