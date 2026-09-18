import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';

void main() {
  test('fromWire keeps known names and falls back to general', () {
    expect(FeedbackCategory.fromWire('error'), FeedbackCategory.error);
    expect(FeedbackCategory.fromWire('nope'), FeedbackCategory.general);
    expect(FeedbackCategory.other.exportLabel, 'Other');
  });
}
