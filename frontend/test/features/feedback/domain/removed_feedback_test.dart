import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/removed_feedback.dart';

import '../../../support/factories.dart';

void main() {
  test('holds the entry and its images, none by default', () {
    final RemovedFeedback removed = RemovedFeedback(entry: aFeedbackEntry());
    expect(removed.entry.reference, 'FBK0000001');
    expect(removed.shots, isEmpty);
  });
}
