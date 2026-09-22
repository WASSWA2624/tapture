import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// In-memory stand-in for [ResponseStore].
final class FakeResponseStore {
  /// Stored rows, oldest first.
  final List<({String jobId, String summary, String raw, bool parsedOk})> rows =
      <({String jobId, String summary, String raw, bool parsedOk})>[];

  /// Appends one response. Refuses a summary that names a secret.
  Result<void> save({
    required String jobId,
    required String requestSummary,
    required String rawResponse,
    required bool parsedOk,
  }) {
    final String folded = requestSummary.toLowerCase();
    if (folded.contains('bearer ') ||
        folded.contains('"apikey"') ||
        folded.contains('"secret"')) {
      return const FailureResult<void>(
        StorageFailure(
          message: 'A request summary cannot include a secret.',
          recoveryAction: 'Store shape and size only, then save again.',
        ),
      );
    }
    rows.add((
      jobId: jobId,
      summary: requestSummary,
      raw: rawResponse,
      parsedOk: parsedOk,
    ));
    return const Success<void>(null);
  }
}
