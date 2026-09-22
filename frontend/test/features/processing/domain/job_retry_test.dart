import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/domain/job_retry.dart';

void main() {
  test('a network failure waits, and the wait grows then stops', () {
    final JobRetry first = JobRetry.classify(
      const NetworkFailure(message: 'The network is not available.'),
      attempt: 1,
    );
    final JobRetry second = JobRetry.classify(
      const NetworkFailure(message: 'The network is not available.'),
      attempt: 2,
    );
    expect(first.permanent, isFalse);
    expect(second.backoff, greaterThan(first.backoff));
    expect(second.backoff.inMilliseconds, lessThanOrEqualTo(30000));
    final JobRetry capped = JobRetry.classify(
      const ProviderFailure(message: '429 rate limit'),
      attempt: 5,
    );
    expect(capped.permanent, isTrue);
    expect(capped.backoff, Duration.zero);
  });

  test('authentication and an unreadable response stop immediately', () {
    final JobRetry auth = JobRetry.classify(
      const ProviderFailure(message: '401 authentication failed'),
      attempt: 1,
    );
    final JobRetry parsed = JobRetry.classify(
      const ValidationFailure(
        message: 'The provider response could not be read.',
      ),
      attempt: 1,
    );
    expect(auth.permanent, isTrue);
    expect(parsed.permanent, isTrue);
    expect(auth.reason, contains('authentication'));
  });
}
