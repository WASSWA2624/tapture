import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_category.dart';

void main() {
  test('fromWire keeps known names and falls back to general', () {
    expect(FeedbackCategory.fromWire('error'), FeedbackCategory.error);
    expect(FeedbackCategory.fromWire('nope'), FeedbackCategory.general);
    expect(FeedbackCategory.other.exportLabel, 'Other');
  });

  test('the form offers four types and no longer offers Improvement', () {
    expect(FeedbackCategory.offered, <FeedbackCategory>[
      FeedbackCategory.general,
      FeedbackCategory.error,
      FeedbackCategory.suggestion,
      FeedbackCategory.other,
    ]);
    expect(
      FeedbackCategory.fromWire('improvement'),
      FeedbackCategory.improvement,
    );
  });

  test('filters offer Improvement only while an entry still holds it', () {
    expect(
      FeedbackCategory.filterable(<FeedbackCategory>[FeedbackCategory.error]),
      FeedbackCategory.offered,
    );
    expect(
      FeedbackCategory.filterable(<FeedbackCategory>[
        FeedbackCategory.improvement,
      ]),
      <FeedbackCategory>[
        FeedbackCategory.general,
        FeedbackCategory.improvement,
        FeedbackCategory.error,
        FeedbackCategory.suggestion,
        FeedbackCategory.other,
      ],
    );
  });
}
