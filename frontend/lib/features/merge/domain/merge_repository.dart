import 'dart:async';

import 'package:tapture/core/errors/result.dart';
import 'merge_history_entry.dart';

/// Persistence port for merge sessions. Drift types stop at the data layer.
abstract interface class MergeRepository {
  /// Persisted history with source, timestamp, category counts and resolutions.
  Stream<List<MergeHistoryEntry>> watchHistory(String projectId);

  /// Restores the latest unchanged merge while preserving audit and evidence.
  Future<Result<void>> undo(String id);

  /// Live list of merge sessions on this device.
  Stream<List<MergeSession>> watchAll();

  /// The session with [id], or null when it is not on this device.
  Future<Result<MergeSession?>> byId(String id);

  /// Inserts or updates [session] and returns the stored row.
  Future<Result<MergeSession>> save(MergeSession session);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});
}

/// The work of joining a bundle back into a project.
typedef MergeSession = ({String id, String bundleName, String status});
