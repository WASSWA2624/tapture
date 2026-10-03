import 'package:tapture/core/errors/result.dart';

import 'duplicate_pair_view.dart';
import 'duplicate_resolution.dart';
import 'quality_counts.dart';
import 'record_variance.dart';
import 'uncaptured_rows.dart';

/// The quality store: duplicate pairs, their resolution, variances and the
/// counts that block a clean export (task 015).
///
/// Detection, variance computation and counting only propose. The one call
/// that settles anything, [resolve], runs because a person chose.
abstract interface class QualityRepository {
  /// [projectId]'s unresolved pairs whose records are both live, oldest
  /// first, and again after every change.
  Stream<List<DuplicatePairView>> watchUnresolvedPairs(String projectId);

  /// The pair [pairId] read whole, or null when it is gone or resolved.
  Future<Result<DuplicatePairView?>> pair(String pairId);

  /// Every record paired with [recordId], unresolved or kept both, and again
  /// after every change. Each record's badge links to these.
  Stream<List<DuplicateCounterpart>> watchCounterparts(String recordId);

  /// Runs detection for [recordIds] against the rest of their project and
  /// queues each candidate as an unresolved pair. Returns how many pairs are
  /// newly queued. Writes no record: callers run it after the save, the
  /// import or the merge has already been confirmed.
  Future<Result<int>> scanRecords(List<String> recordIds);

  /// [scanRecords] over every live record of [projectId].
  Future<Result<int>> scanProject(String projectId);

  /// Applies a person's [resolution] to pair [pairId] in one transaction:
  /// the records it changes, their history, the audit rows and the pair.
  Future<Result<void>> resolve(String pairId, DuplicateResolution resolution);

  /// [projectId]'s stored variances, grouped by record, and again after
  /// every change.
  Stream<List<RecordVariance>> watchVariances(String projectId);

  /// Register rows that produced no record and checklist rows never
  /// captured in [projectId].
  Future<Result<UncapturedRows>> missingItems(String projectId);

  /// The counts that still block a clean export of [projectId], and again
  /// after every change to its records.
  Stream<QualityCounts> watchCounts(String projectId);
}
