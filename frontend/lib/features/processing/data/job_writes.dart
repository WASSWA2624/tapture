import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart'
    show ProcessingJobStatus;

import 'stage_support.dart';

/// Small writes a stage makes onto its job row.
final class JobWrites {
  /// Creates the writer over [db].
  const JobWrites({required this._db});

  final AppDatabase _db;

  /// Records why the online stage was skipped.
  Future<void> setSkip(String jobId, String reason) async {
    await (_db.update(_db.processing)
          ..where(($ProcessingTable table) => table.id.equals(jobId)))
        .write(ProcessingCompanion(skipReason: Value<String>(reason)));
  }

  /// Records which provider and model answered.
  Future<void> setProvider(
    String jobId, {
    String? provider,
    String? model,
  }) async {
    await (_db.update(
      _db.processing,
    )..where(($ProcessingTable table) => table.id.equals(jobId))).write(
      ProcessingCompanion(
        provider: Value<String?>(provider),
        model: Value<String?>(model),
      ),
    );
  }

  /// Puts the job back on the queue with [message] shown beside it.
  Future<void> setQueueMessage(String jobId, String message) async {
    await (_db.update(
      _db.processing,
    )..where(($ProcessingTable table) => table.id.equals(jobId))).write(
      ProcessingCompanion(
        status: const Value<ProcessingJobStatus>(ProcessingJobStatus.queued),
        lastError: Value<String>(message),
        leaseExpiresAt: const Value<DateTime?>(null),
      ),
    );
  }

  /// Adds [rejected] to the job's rejection reasons, without duplicates.
  Future<void> appendRejections(String jobId, List<String> rejected) async {
    final ProcessingJobRow? row =
        await (_db.select(_db.processing)
              ..where(($ProcessingTable table) => table.id.equals(jobId)))
            .getSingleOrNull();
    if (row == null) {
      return;
    }
    final List<String> combined = <String>{
      ...StageSupport.strings(row.rejections ?? '[]'),
      ...rejected,
    }.toList();
    await (_db.update(_db.processing)
          ..where(($ProcessingTable table) => table.id.equals(jobId)))
        .write(ProcessingCompanion(rejections: Value(jsonEncode(combined))));
  }

  /// The rejection reasons already stored on the job.
  Future<List<String>> rejections(String jobId) async {
    final ProcessingJobRow? row =
        await (_db.select(_db.processing)
              ..where(($ProcessingTable table) => table.id.equals(jobId)))
            .getSingleOrNull();
    return StageSupport.strings(row?.rejections ?? '[]');
  }
}
