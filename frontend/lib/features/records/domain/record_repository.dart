import 'dart:async';

import 'package:tapture/core/errors/result.dart';

/// Persistence port for captured records. Drift types stop at the data layer.
abstract interface class RecordRepository {
  /// Live list of [projectId] records matching [filter].
  Stream<List<RecordSummary>> watchByProject(
    String projectId,
    RecordFilter filter,
  );

  /// The record with [id], or null when it is not on this device.
  Future<Result<RecordDetail?>> byId(String id);

  /// Inserts or updates [draft] and returns the stored row.
  Future<Result<RecordDetail>> save(RecordDraft draft);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});
}

/// Listing row for a captured record.
typedef RecordSummary = ({String id, String projectId, String status});

/// Full captured record as features read it.
typedef RecordDetail = ({
  String id,
  String projectId,
  String templateId,
  String status,
  Map<String, String> fields,
});

/// Values a save writes, with [id] null when the row is new.
typedef RecordDraft = ({
  String? id,
  String projectId,
  String templateId,
  Map<String, String> fields,
});

/// Restricts [RecordRepository.watchByProject] to a status, or all when null.
typedef RecordFilter = ({String? status});
