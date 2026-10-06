import 'package:tapture/core/errors/result.dart';

/// Local review findings and potentially charged attempts for one record/job.
abstract interface class ProcessingFindingsRepository {
  /// Stand-in before bootstrap and in isolated feature tests.
  const factory ProcessingFindingsRepository.empty() = _EmptyFindings;

  /// Latest durable review findings, without loading the complete queue.
  Stream<List<String>> watchRecord(String recordId);

  /// Whether another attempt needs approval because its prior charge is unknown.
  Future<Result<bool>> requiresRetryApproval(String jobId);
}

final class _EmptyFindings implements ProcessingFindingsRepository {
  const _EmptyFindings();
  @override
  Stream<List<String>> watchRecord(String recordId) =>
      Stream<List<String>>.value(const <String>[]);
  @override
  Future<Result<bool>> requiresRetryApproval(String jobId) async =>
      const Success<bool>(false);
}
