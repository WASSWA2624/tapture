import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_context.dart';
import 'package:tapture/features/feedback/domain/feedback_device_type.dart';
import 'package:tapture/features/feedback/domain/feedback_submitter.dart';

import '../../../support/factories.dart';

void main() {
  test('json round-trips the captured moment', () {
    final FeedbackContext context = aFeedbackEntry().context;
    final FeedbackContext restored = FeedbackContext.fromJson(context.toJson());
    expect(restored.screen, 'Projects');
    expect(restored.submitter, FeedbackSubmitter.localOperator);
    expect(restored.deviceType, FeedbackDeviceType.desktop);
    expect(restored.addresses, <String>['192.0.2.10']);
    expect(restored.utcOffsetMinutes, 180);
  });

  test('missing keys fall back rather than failing', () {
    final FeedbackContext restored = FeedbackContext.fromJson(
      <String, Object?>{},
    );
    expect(restored.screen, isEmpty);
    expect(restored.submitter, FeedbackSubmitter.anonymous);
    expect(restored.deviceType, FeedbackDeviceType.mobile);
    expect(restored.devicePixelRatio, 1);
    expect(restored.textScale, 1);
    expect(restored.capturedAtUtc, DateTime.utc(1970));
  });
}
