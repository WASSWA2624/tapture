import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_submitter.dart';

void main() {
  test('resolve prefers a signed-in account, then a local name', () {
    expect(
      FeedbackSubmitter.resolve(name: 'Ada', accountId: 'acc-1'),
      FeedbackSubmitter.signedInUser,
    );
    expect(
      FeedbackSubmitter.resolve(name: 'Ada'),
      FeedbackSubmitter.localOperator,
    );
    expect(FeedbackSubmitter.resolve(), FeedbackSubmitter.anonymous);
  });

  test('fromWire keeps known names and falls back to anonymous', () {
    expect(
      FeedbackSubmitter.fromWire('localOperator'),
      FeedbackSubmitter.localOperator,
    );
    expect(FeedbackSubmitter.fromWire('nope'), FeedbackSubmitter.anonymous);
  });
}
