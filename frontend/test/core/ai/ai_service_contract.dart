import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/job_retry.dart';

/// How the provider behind an [AiService] under contract answers.
enum ContractOutcome {
  /// It answers with [contractText].
  success,

  /// It never answers in time.
  timeout,

  /// It is down or not configured (503).
  unavailable,

  /// The organisation's quota is spent (429 `quota_exceeded`).
  quota,

  /// The server's circuit breaker has paused the provider (429
  /// `rate_limited`).
  breakerOpen,

  /// It answers with something that is not the agreed shape.
  malformed,
}

/// The text a successful provider under contract returns.
const String contractText = 'Contract text';

/// The shared suite every [AiService] implementation passes (task 024): a
/// failure the device can wait out queues the job rather than failing the
/// capture, and one that retrying cannot mend is reported once. [subject]
/// builds the implementation whose provider answers with the outcome.
void runAiServiceContract(
  String name,
  AiService Function(ContractOutcome outcome) subject,
) {
  group('$name honours the AiService contract', () {
    Future<Result<ReadTextResult>> read(ContractOutcome outcome) {
      return subject(
        outcome,
      ).readText(const ReadTextRequest(imagePaths: <String>[]));
    }

    Future<ProviderFailure> failed(ContractOutcome outcome) async {
      final Result<ReadTextResult> result = await read(outcome);
      expect(result, isA<FailureResult<ReadTextResult>>(), reason: '$outcome');
      final Failure failure = (result as FailureResult<ReadTextResult>).failure;
      expect(failure, isA<ProviderFailure>(), reason: '$outcome');
      return failure as ProviderFailure;
    }

    test('a success returns the provider’s text', () async {
      final Result<ReadTextResult> result = await read(ContractOutcome.success);
      expect((result as Success<ReadTextResult>).value.text, contractText);
    });

    for (final ContractOutcome outcome in <ContractOutcome>[
      ContractOutcome.timeout,
      ContractOutcome.unavailable,
      ContractOutcome.quota,
      ContractOutcome.breakerOpen,
    ]) {
      test('${outcome.name} queues the job rather than failing it', () async {
        final ProviderFailure failure = await failed(outcome);
        expect(JobRetry.classify(failure, attempt: 1).permanent, isFalse);
        expect(failure.recoveryAction, isNotEmpty);
      });
    }

    test('a paused provider is told apart from a spent quota', () async {
      final ProviderFailure quota = await failed(ContractOutcome.quota);
      final ProviderFailure paused = await failed(ContractOutcome.breakerOpen);
      expect(quota.kind, ProviderFailureKind.rateLimited);
      expect(paused.kind, ProviderFailureKind.rateLimited);
      expect(paused.message, isNot(quota.message));
    });

    test('a malformed answer is reported once, never retried', () async {
      final ProviderFailure failure = await failed(ContractOutcome.malformed);
      expect(failure.kind, ProviderFailureKind.malformed);
      expect(JobRetry.classify(failure, attempt: 1).permanent, isTrue);
    });
  });
}
