import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/processing.dart' as jobs;

import '../domain/processing_job.dart';

/// Maps a `processing_jobs` row to a [ProcessingJob] and back, so Drift
/// types stop at the data layer.
abstract final class ProcessingJobMapper {
  /// The job a stored [row] describes. A failed row is permanent.
  static ProcessingJob toJob(sqlite.ProcessingJobRow row) {
    return ProcessingJob(
      id: row.id,
      recordId: row.recordId,
      stage: row.stage,
      attemptCount: row.attempts,
      status: jobStatus(row.status),
      lastError: row.lastError,
      leaseExpiresAt: row.leaseExpiresAt,
      permanent: row.status == jobs.ProcessingJobStatus.failed,
      skipReason: row.skipReason,
      rejections: _rejections(row.rejections),
      provider: row.provider,
      model: row.model,
      queuedAt: row.queuedAt,
      startedAt: row.startedAt,
      finishedAt: row.finishedAt,
    );
  }

  /// The columns that store [job]. [queuedAt] stands in when the job has
  /// none yet.
  static sqlite.ProcessingCompanion toCompanion(
    ProcessingJob job, {
    required DateTime queuedAt,
  }) {
    return sqlite.ProcessingCompanion(
      id: Value<String>(job.id),
      recordId: Value<String>(job.recordId),
      stage: Value<String>(job.stage),
      status: Value<jobs.ProcessingJobStatus>(rowStatus(job.status)),
      attempts: Value<int>(job.attemptCount),
      lastError: Value<String?>(job.lastError),
      queuedAt: Value<DateTime>(job.queuedAt ?? queuedAt),
      startedAt: Value<DateTime?>(job.startedAt),
      finishedAt: Value<DateTime?>(job.finishedAt),
      provider: Value<String?>(job.provider),
      model: Value<String?>(job.model),
      leaseExpiresAt: Value<DateTime?>(job.leaseExpiresAt),
      skipReason: Value<String?>(job.skipReason),
      rejections: Value<String?>(
        job.rejections.isEmpty ? null : jsonEncode(job.rejections),
      ),
    );
  }

  /// The stored status for [status].
  static jobs.ProcessingJobStatus rowStatus(JobStatus status) {
    return switch (status) {
      JobStatus.queued => jobs.ProcessingJobStatus.queued,
      JobStatus.running => jobs.ProcessingJobStatus.running,
      JobStatus.completed => jobs.ProcessingJobStatus.completed,
      JobStatus.failed => jobs.ProcessingJobStatus.failed,
    };
  }

  /// The domain status for a stored [status].
  static JobStatus jobStatus(jobs.ProcessingJobStatus status) {
    return switch (status) {
      jobs.ProcessingJobStatus.queued => JobStatus.queued,
      jobs.ProcessingJobStatus.running => JobStatus.running,
      jobs.ProcessingJobStatus.completed => JobStatus.completed,
      jobs.ProcessingJobStatus.failed => JobStatus.failed,
    };
  }
}

/// Stored rejections are a JSON list of strings. Anything else reads as
/// none rather than failing the whole row.
List<String> _rejections(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const <String>[];
  }
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is List) {
      return <String>[
        for (final Object? item in decoded)
          if (item is String) item,
      ];
    }
  } on FormatException {
    return const <String>[];
  }
  return const <String>[];
}
