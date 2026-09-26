import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'processing_repository.dart';

/// Leases a job to exactly one runner and takes it back after a crash.
///
/// Enqueue, claim, complete and fail each commit in one transaction. An
/// implementation is built for one scope (a project, some context groups),
/// so [claim] keeps the Contract's shape. A storage error is thrown as a
/// typed `Failure`.
abstract interface class JobQueue {
  /// The queue over [repository] for one scope: [projectId] and
  /// [groupLabels], every project and group when omitted. Each call is one
  /// repository transaction.
  factory JobQueue.over(
    ProcessingRepository repository, {
    String? projectId,
    List<String> groupLabels,
  }) = _RepositoryJobQueue;

  /// Queues [recordId] and returns the job id. A second call returns the
  /// job already waiting for that record.
  Future<String> enqueue(String recordId);

  /// Claims the oldest ready job for [lease], or null when none is free.
  ///
  /// An expired lease is released inside the same transaction, so a job
  /// killed mid-run becomes claimable again. The concurrency cap is read
  /// from the settings store by the implementation.
  Future<ProcessingJob?> claim(Duration lease);

  /// Marks [jobId] finished.
  Future<void> complete(String jobId);

  /// Records [reason] on [jobId]. A permanent failure stops. A transient
  /// one returns to the queue after bounded backoff.
  Future<void> fail(String jobId, String reason, {required bool permanent});
}

final class _RepositoryJobQueue implements JobQueue {
  _RepositoryJobQueue(
    this._repository, {
    this.projectId,
    this.groupLabels = const <String>[],
  });

  final ProcessingRepository _repository;
  final String? projectId;
  final List<String> groupLabels;

  @override
  Future<String> enqueue(String recordId) async {
    return _value(await _repository.enqueue(recordId));
  }

  @override
  Future<ProcessingJob?> claim(Duration lease) async {
    return _value(
      await _repository.claim(
        lease,
        projectId: projectId,
        groupLabels: groupLabels,
      ),
    );
  }

  @override
  Future<void> complete(String jobId) async {
    _value(await _repository.complete(jobId));
  }

  @override
  Future<void> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) async {
    _value(await _repository.fail(jobId, reason, permanent: permanent));
  }
}

T _value<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw Failure.from(failure),
  };
}
