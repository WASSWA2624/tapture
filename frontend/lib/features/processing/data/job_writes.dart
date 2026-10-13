import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/copy/localized_message.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart'
    show ProcessingJobStatus;
import 'package:tapture/core/errors/failure.dart';

import 'stage_support.dart';

/// Small writes a stage makes onto its job row.
final class JobWrites {
  /// Creates the writer over [db].
  const JobWrites({required this._db});

  final AppDatabase _db;

  /// Records why the online stage was skipped.
  Future<void> setSkip(
    String jobId,
    String reason, {
    int? expectedGeneration,
  }) async {
    await _write(
      jobId,
      ProcessingCompanion(skipReason: Value<String>(reason)),
      expectedGeneration: expectedGeneration,
    );
  }

  /// Records which provider and model answered.
  Future<void> setProvider(
    String jobId, {
    String? provider,
    String? model,
    int? expectedGeneration,
  }) async {
    await _write(
      jobId,
      ProcessingCompanion(
        provider: Value<String?>(provider),
        model: Value<String?>(model),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  /// Puts the job back on the queue with [message] shown beside it.
  Future<void> setQueueMessage(
    String jobId,
    String message, {
    LocalizedMessage? localizedMessage,
    int? expectedGeneration,
  }) async {
    await _write(
      jobId,
      ProcessingCompanion(
        status: const Value<ProcessingJobStatus>(ProcessingJobStatus.queued),
        lastError: Value<String>(message),
        lastErrorMessage: Value<String?>(
          localizedMessage == null
              ? null
              : jsonEncode(localizedMessage.toJson()),
        ),
        leaseExpiresAt: const Value<DateTime?>(null),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  /// Adds [rejected] to the job's rejection reasons, without duplicates.
  Future<void> appendRejections(
    String jobId,
    List<String> rejected, {
    int? expectedGeneration,
  }) => _db.transaction(() async {
    final ProcessingJobRow? row = await _read(jobId, expectedGeneration);
    if (row == null) return;
    final List<String> combined = <String>{
      ...StageSupport.strings(row.rejections ?? '[]'),
      ...rejected,
    }.toList();
    await _write(
      jobId,
      ProcessingCompanion(rejections: Value<String>(jsonEncode(combined))),
      expectedGeneration: expectedGeneration,
    );
  });

  /// The rejection reasons already stored on the job.
  Future<List<String>> rejections(
    String jobId, {
    int? expectedGeneration,
  }) async {
    final ProcessingJobRow? row = await _read(jobId, expectedGeneration);
    return StageSupport.strings(row?.rejections ?? '[]');
  }

  /// Stops an old attempt before it can reserve provider budget.
  Future<void> requireGeneration(String jobId, int expectedGeneration) async {
    await _read(jobId, expectedGeneration);
  }

  Future<ProcessingJobRow?> _read(String jobId, int? expectedGeneration) async {
    final ProcessingJobRow? row =
        await (_db.select(_db.processing)..where(
              ($ProcessingTable table) =>
                  _matches(table, jobId, expectedGeneration),
            ))
            .getSingleOrNull();
    if (expectedGeneration != null && row == null) {
      throw Failure.from(_superseded);
    }
    return row;
  }

  Future<void> _write(
    String jobId,
    ProcessingCompanion values, {
    int? expectedGeneration,
  }) async {
    final int changed =
        await (_db.update(_db.processing)..where(
              ($ProcessingTable table) =>
                  _matches(table, jobId, expectedGeneration),
            ))
            .write(values);
    if (expectedGeneration != null && changed == 0) {
      throw Failure.from(_superseded);
    }
  }

  Expression<bool> _matches(
    $ProcessingTable table,
    String jobId,
    int? expectedGeneration,
  ) =>
      table.id.equals(jobId) &
      (expectedGeneration == null
          ? const Constant<bool>(true)
          : table.requestGeneration.equals(expectedGeneration));
}

const CancelledFailure _superseded = CancelledFailure(
  message: 'This processing attempt was superseded.',
  recoveryAction: 'Review the latest processing attempt.',
);
