import 'field_conflict.dart';
import 'settlement_rule.dart';

/// Everything a merge would do, worked out before a byte is written
/// (task 076, W21). A value: the preview reads its counts, the conflict
/// screen its conflicts, and the apply step writes it (FE-STR-05).
final class MergePlan {
  /// Creates a plan.
  const MergePlan({
    required this.inserts,
    required this.files,
    required this.settled,
    required this.conflicts,
    required this.counts,
    required this.insertedRecords,
  });

  /// Rows to insert, by SQL table, already moved to the target project.
  final Map<String, List<Map<String, Object?>>> inserts;

  /// Files to copy: the package entry, and the path inside the project
  /// folder it lands at.
  final List<({String entry, String target})> files;

  /// Values the rules settled without a person, each with its rule.
  final List<
    ({
      String rowId,
      String fieldKey,
      String previous,
      String value,
      bool verified,
      SettlementRule rule,
    })
  >
  settled;

  /// What a person has to settle.
  final List<FieldConflict> conflicts;

  /// What the preview counts.
  final MergeCounts counts;

  /// Records the plan inserts, for the duplicate check.
  final List<String> insertedRecords;

  /// Whether merging would change nothing, as a second merge of the same
  /// package does.
  bool get isEmpty =>
      inserts.values.every((List<Map<String, Object?>> rows) => rows.isEmpty) &&
      settled.isEmpty &&
      conflicts.isEmpty;
}

/// The preview's counts (specification §48.1): new records, records the
/// merge changes, new photos, photos already here, deletions to apply,
/// values kept as on this device, and rows already in another project here.
typedef MergeCounts = ({
  int newRecords,
  int updatedRecords,
  int newPhotos,
  int photosHere,
  int deletions,
  int kept,
  int elsewhere,
});
