import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_screenshot_filter.dart';

void main() {
  test('admits the matching screenshot state', () {
    expect(FeedbackScreenshotFilter.any.admits(hasScreenshot: true), isTrue);
    expect(
      FeedbackScreenshotFilter.attached.admits(hasScreenshot: false),
      isFalse,
    );
    expect(
      FeedbackScreenshotFilter.missing.admits(hasScreenshot: false),
      isTrue,
    );
  });
}
