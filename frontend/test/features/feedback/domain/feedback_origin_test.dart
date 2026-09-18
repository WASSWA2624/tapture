import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_origin.dart';

void main() {
  test('unknown is a stand-in the shell can pass', () {
    expect(FeedbackOrigin.unknown.screen, 'unknown');
    expect(FeedbackOrigin.unknown.route, isEmpty);
  });
}
