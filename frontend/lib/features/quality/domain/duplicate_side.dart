import 'package:tapture/features/records/domain/domain.dart' show RecordPhoto;

/// One record of a duplicate pair, as the review list and the comparison
/// show it (task 015).
final class DuplicateSide {
  /// Creates a side.
  const DuplicateSide({
    required this.recordId,
    required this.name,
    required this.capturedAt,
    required this.capturedBy,
    this.number,
    this.contextLabel = '',
    this.photos = const <RecordPhoto>[],
  });

  /// The record.
  final String recordId;

  /// The record's name, or empty.
  final String name;

  /// The per-project number, when one is allocated.
  final int? number;

  /// When it was captured.
  final DateTime capturedAt;

  /// Who captured it: the operator when known, else the device.
  final String capturedBy;

  /// The deepest context value it was captured in, or empty.
  final String contextLabel;

  /// Its live photos, in order.
  final List<RecordPhoto> photos;
}
