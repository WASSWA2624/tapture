import 'package:tapture/core/errors/result.dart';

import 'purge_candidate.dart';

/// The rows and files the retention purge reads and removes (D13).
///
/// A port, so `PurgeJob`'s policy stays pure Dart; the data layer implements
/// it in a file whose name contains `purge`, the only place a hard delete
/// may live (FE-SEC-08).
abstract interface class PurgeStore {
  /// Every record in the recycle bin: status deleted with a `records`
  /// tombstone, excluding records a project delete tombstoned. Recent ones
  /// are included; the job decides which are past the window.
  Future<Result<List<PurgeCandidate>>> candidates();

  /// Removes [candidate]'s record for good: its files and cached thumbnails
  /// first, then every row it owns, in one transaction. Returns how many
  /// files went; a file already missing counts as removed.
  Future<Result<int>> purge(PurgeCandidate candidate);
}
