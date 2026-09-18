import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';

import '../../../support/factories.dart';

void main() {
  test('reference pads the number', () {
    expect(aFeedbackEntry().reference, 'FBK0000001');
    expect(aFeedbackEntry(number: 12).reference, 'FBK0000012');
  });

  test('categoryLabel uses the export name, and names an other type', () {
    expect(aFeedbackEntry().categoryLabel, 'General feedback');
    expect(
      aFeedbackEntry(
        category: FeedbackCategory.other,
        otherCategory: 'Speed',
      ).categoryLabel,
      'Other: Speed',
    );
  });

  test('json round-trips and skips a damaged row', () {
    final FeedbackEntry entry = aFeedbackEntry(message: 'Slow <list>');
    final FeedbackEntry? restored = FeedbackEntry.fromJson(entry.toJson());
    expect(restored?.message, 'Slow <list>');
    expect(restored?.reference, entry.reference);
    expect(restored?.context.screen, 'Projects');
    expect(FeedbackEntry.fromJson(<String, Object?>{'id': ''}), isNull);
    expect(FeedbackEntry.fromJson('nope'), isNull);
  });
}
