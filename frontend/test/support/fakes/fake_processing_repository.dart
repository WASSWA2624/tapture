import 'dart:async';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/job_retry.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';

/// In-memory [ProcessingRepository] for feature tests that must not open a
/// database.
final class FakeProcessingRepository implements ProcessingRepository {
  /// Creates an empty queue. [concurrency] stands in for the settings cap.
  FakeProcessingRepository({int? concurrency})
    : concurrency = concurrency ?? AppConstants.processing.concurrency;

  /// How many jobs may be running at once.
  final int concurrency;

  final Map<String, ProcessingJob> _rows = <String, ProcessingJob>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;
  final List<({DateTime at, int images})> _usage =
      <({DateTime at, int images})>[];

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    if (!_changes.isClosed) {
      _changes.close();
    }
  }

  /// Records one online request so the queue can show today's total.
  void recordUsage(DateTime at, {required int images}) {
    _usage.add((at: at, images: images));
  }

  @override
  Stream<List<ProcessingJob>> watchAll() {
    return _watch(() => _rows.values.toList());
  }

  @override
  Stream<QueueSnapshot> watchQueue({String? projectId}) {
    return Stream<QueueSnapshot>.multi((
      MultiStreamController<QueueSnapshot> listener,
    ) {
      listener.add(_snapshot());
      final StreamSubscription<void> sub = _changes.stream.listen((_) {
        if (!listener.isClosed) {
          listener.add(_snapshot());
        }
      });
      listener.onCancel = sub.cancel;
    });
  }

  @override
  Future<Result<int>> enqueuePending({
    String? projectId,
    String? groupLabel,
  }) async {
    return const Success<int>(0);
  }

  @override
  Future<Result<ProcessingJob?>> byId(String id) async {
    return Success<ProcessingJob?>(_rows[id]);
  }

  @override
  Future<Result<ProcessingJob>> save(ProcessingJob job) async {
    if (job.recordId.isEmpty) {
      return const FailureResult<ProcessingJob>(
        ValidationFailure(
          message: 'A job needs a record.',
          recoveryAction: 'Open a record and queue it again.',
        ),
      );
    }
    final String id = job.id.isEmpty ? 'job-${_next++}' : job.id;
    final ProcessingJob stored = job.copyWith(id: id);
    _rows[id] = stored;
    _emit();
    return Success<ProcessingJob>(stored);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty || !_rows.containsKey(id)) {
      return const FailureResult<void>(_missing);
    }
    if (reason.isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    _rows.remove(id);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<String>> enqueue(String recordId) async {
    for (final ProcessingJob job in _rows.values) {
      if (job.recordId == recordId) {
        return Success<String>(job.id);
      }
    }
    final Result<ProcessingJob> saved = await save(
      ProcessingJob(id: '', recordId: recordId),
    );
    return saved.map((ProcessingJob job) => job.id);
  }

  @override
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    String? groupLabel,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    for (final ProcessingJob job in _rows.values.toList()) {
      final DateTime? expiry = job.leaseExpiresAt;
      if (job.status == JobStatus.running &&
          (expiry == null || !expiry.isAfter(now))) {
        _rows[job.id] = job.copyWith(
          status: JobStatus.queued,
          clearLease: true,
          clearStarted: true,
        );
      }
    }
    final int running = _rows.values
        .where((ProcessingJob job) => job.status == JobStatus.running)
        .length;
    if (running >= concurrency) {
      return const Success<ProcessingJob?>(null);
    }
    final List<ProcessingJob> ready =
        _rows.values.where((ProcessingJob job) {
          if (job.status != JobStatus.queued) {
            return false;
          }
          final DateTime? notBefore = job.startedAt;
          return notBefore == null || !notBefore.isAfter(now);
        }).toList()..sort(
          (ProcessingJob a, ProcessingJob b) =>
              (a.queuedAt ?? now).compareTo(b.queuedAt ?? now),
        );
    if (ready.isEmpty) {
      return const Success<ProcessingJob?>(null);
    }
    final ProcessingJob next = ready.first;
    final ProcessingJob claimed = next.copyWith(
      status: JobStatus.running,
      startedAt: now,
      leaseExpiresAt: now.add(lease),
    );
    _rows[next.id] = claimed;
    _emit();
    return Success<ProcessingJob?>(claimed);
  }

  @override
  Future<Result<void>> complete(String jobId) async {
    final ProcessingJob? job = _rows[jobId];
    if (job == null) {
      return const FailureResult<void>(_missingJob);
    }
    _rows[jobId] = job.copyWith(
      status: JobStatus.completed,
      finishedAt: DateTime.now().toUtc(),
      clearLease: true,
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) async {
    final ProcessingJob? job = _rows[jobId];
    if (job == null) {
      return const FailureResult<void>(_missingJob);
    }
    final int attempts = job.attemptCount + 1;
    final bool stop =
        permanent || attempts >= AppConstants.processing.maxAttempts;
    final DateTime now = DateTime.now().toUtc();
    _rows[jobId] = job.copyWith(
      status: stop ? JobStatus.failed : JobStatus.queued,
      attemptCount: attempts,
      lastError: reason,
      permanent: stop,
      clearLease: true,
      startedAt: stop ? null : now.add(JobRetry.backoffFor(attempts)),
      clearStarted: stop,
      finishedAt: stop ? now : null,
      clearFinished: !stop,
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage) async {
    final ProcessingJob? job = _rows[id];
    if (job == null) {
      return const FailureResult<ProcessingJob>(_missingJob);
    }
    final ProcessingJob next = job.copyWith(stage: stage.name);
    _rows[id] = next;
    _emit();
    return Success<ProcessingJob>(next);
  }

  @override
  Future<Result<void>> release(String id) async {
    final ProcessingJob? job = _rows[id];
    if (job == null) {
      return const FailureResult<void>(_missing);
    }
    _rows[id] = job.copyWith(status: JobStatus.queued, clearLease: true);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> retry(String id) async {
    final ProcessingJob? job = _rows[id];
    if (job == null) {
      return const FailureResult<void>(_missing);
    }
    _rows[id] = job.copyWith(
      status: JobStatus.queued,
      attemptCount: 0,
      permanent: false,
      clearError: true,
      clearLease: true,
      clearStarted: true,
      clearFinished: true,
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<({int requests, int images})>> usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    final DateTime start = DateTime.utc(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    var requests = 0;
    var images = 0;
    for (final ({DateTime at, int images}) row in _usage) {
      if (!row.at.isBefore(start) && row.at.isBefore(end)) {
        requests++;
        images += row.images;
      }
    }
    return Success<({int requests, int images})>((
      requests: requests,
      images: images,
    ));
  }

  QueueSnapshot _snapshot() {
    final Map<String, int> groups = <String, int>{};
    var queued = 0;
    var failed = 0;
    final List<ProcessingJob> failures = <ProcessingJob>[];
    for (final ProcessingJob job in _rows.values) {
      if (job.status == JobStatus.failed) {
        failed++;
        failures.add(job);
      } else if (job.status == JobStatus.queued ||
          job.status == JobStatus.running) {
        queued++;
        groups.update(
          job.recordId,
          (int count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return (
      unprocessed: queued,
      queued: queued,
      failed: failed,
      requestsToday: _usage.length,
      imagesToday: _usage.fold<int>(
        0,
        (int total, ({DateTime at, int images}) row) => total + row.images,
      ),
      requestCap: AppConstants.processing.dailyRequestCap,
      groups: <QueueGroup>[
        for (final MapEntry<String, int> entry in groups.entries)
          (label: entry.key, records: entry.value),
      ],
      failures: failures,
    );
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Stream<List<T>> _watch<T>(List<T> Function() snapshot) {
    return Stream<List<T>>.multi((MultiStreamController<List<T>> listener) {
      listener.add(snapshot());
      final StreamSubscription<void> sub = _changes.stream.listen((_) {
        if (!listener.isClosed) {
          listener.add(snapshot());
        }
      });
      listener.onCancel = sub.cancel;
    });
  }
}

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _missingJob = StorageFailure(
  message: 'That job is no longer on this device.',
  recoveryAction: 'Refresh the queue and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);
