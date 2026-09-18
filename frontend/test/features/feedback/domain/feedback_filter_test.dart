import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_screenshot_filter.dart';

import '../../../support/factories.dart';

void main() {
  final FeedbackEntry general = aFeedbackEntry();
  final FeedbackEntry error = aFeedbackEntry(
    id: 'fb-2',
    number: 2,
    submittedAtUtc: DateTime.utc(2026, 9, 19, 8),
    category: FeedbackCategory.error,
    message: 'Crash on save',
    hasScreenshot: true,
    screen: 'Capture',
    platform: 'android',
  );

  test('the default filter lets every entry through', () {
    const FeedbackFilter filter = FeedbackFilter();
    expect(filter.isEmpty, isTrue);
    expect(filter.matches(general), isTrue);
    expect(filter.matches(error), isTrue);
  });

  test('each facet can drop an entry', () {
    expect(
      const FeedbackFilter(
        categories: <FeedbackCategory>{FeedbackCategory.error},
      ).matches(general),
      isFalse,
    );
    expect(
      FeedbackFilter(fromUtc: DateTime.utc(2026, 9, 19)).matches(general),
      isFalse,
    );
    expect(
      FeedbackFilter(toUtc: DateTime.utc(2026, 9, 18, 6)).matches(general),
      isFalse,
    );
    expect(
      const FeedbackFilter(screens: <String>{'Capture'}).matches(general),
      isFalse,
    );
    expect(
      const FeedbackFilter(platforms: <String>{'android'}).matches(general),
      isFalse,
    );
    expect(
      const FeedbackFilter(
        screenshot: FeedbackScreenshotFilter.attached,
      ).matches(general),
      isFalse,
    );
    expect(const FeedbackFilter(search: 'crash').matches(general), isFalse);
    expect(const FeedbackFilter(search: 'FBK0000001').matches(general), isTrue);
  });

  test('apply returns newest first and reports a backwards range', () {
    const FeedbackFilter filter = FeedbackFilter();
    expect(filter.apply(<FeedbackEntry>[general, error]).first.id, 'fb-2');
    expect(
      FeedbackFilter(
        fromUtc: DateTime.utc(2026, 9, 20),
        toUtc: DateTime.utc(2026, 9, 18),
      ).isRangeBackwards,
      isTrue,
    );
  });

  test('copyWith can clear a bound', () {
    final FeedbackFilter bound = FeedbackFilter(
      fromUtc: DateTime.utc(2026, 9, 18),
    );
    expect(bound.copyWith(clearFrom: true).fromUtc, isNull);
    expect(FeedbackFilter.screensIn(<FeedbackEntry>[error]), <String>[
      'Capture',
    ]);
    expect(FeedbackFilter.platformsIn(<FeedbackEntry>[error]), <String>[
      'android',
    ]);
  });
}
