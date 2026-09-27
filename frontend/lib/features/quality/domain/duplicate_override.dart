import 'duplicate_ledger.dart';

/// Writes a new capture onto an existing record (task 015).
///
/// Reachable only after the comparison. Replaced values stay in history.
/// Photos from the new record are attached. One audit row names the override.
abstract final class DuplicateOverride {
  /// Applies the override of [rightId] onto [leftId].
  static void apply({
    required DuplicateLedger ledger,
    required String leftId,
    required String rightId,
    required String person,
    required Map<String, String> previous,
    required Map<String, String> next,
    required List<String> photoHashes,
  }) {
    for (final MapEntry<String, String> entry in next.entries) {
      final String? before = previous[entry.key];
      if (before == entry.value) {
        continue;
      }
      ledger.replaceValue(
        fieldKey: entry.key,
        previous: before,
        next: entry.value,
      );
    }
    for (final String hash in photoHashes) {
      ledger.attachPhoto(hash);
    }
    ledger.addAudit(
      action: 'override',
      leftId: leftId,
      rightId: rightId,
      person: person,
      detail: 'override',
    );
  }
}
