import 'duplicate_side.dart';
import 'duplicate_signal.dart';

/// A duplicate pair read whole: both records and the fields that differ
/// (task 015). A proposal until a person resolves it.
final class DuplicatePairView {
  /// Creates a pair.
  const DuplicatePairView({
    required this.id,
    required this.projectId,
    required this.signal,
    required this.score,
    required this.templateId,
    required this.templateName,
    required this.existing,
    required this.incoming,
    required this.differences,
  });

  /// The stored pair.
  final String id;

  /// Project both records belong to.
  final String projectId;

  /// The strongest reason the two look alike.
  final DuplicateSignal signal;

  /// How strongly, 0 to 1.
  final double score;

  /// Template of the newer record.
  final String templateId;

  /// That template's name.
  final String templateName;

  /// The record that was there first. It survives an override or a merge.
  final DuplicateSide existing;

  /// The newer record. A discard or a merge moves it to the recycle bin.
  final DuplicateSide incoming;

  /// Fields whose values differ, in template order.
  final List<DuplicateDifference> differences;
}

/// One field the two records of a pair do not share (task 015).
///
/// [existing] is the value on the record that was there first, [incoming]
/// the value on the newer one. Both are display text; empty means no value.
typedef DuplicateDifference = ({
  String fieldKey,
  String label,
  String existing,
  String incoming,
});

/// A record paired with another, as that other record's badge links to it
/// (task 015). [resolved] is true once a person kept both.
typedef DuplicateCounterpart = ({
  String pairId,
  String recordId,
  String name,
  int? number,
  bool resolved,
});
