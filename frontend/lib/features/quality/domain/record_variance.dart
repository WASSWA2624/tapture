import 'field_variance.dart';

/// One stored variance row, ready to read without opening its record
/// (task 015).
final class RecordVariance {
  /// Creates a row.
  const RecordVariance({
    required this.id,
    required this.recordId,
    required this.recordName,
    required this.fieldKey,
    required this.label,
    required this.status,
    this.recordNumber,
    this.context = '',
    this.recorded = '',
    this.found = '',
  });

  /// The stored variance.
  final String id;

  /// The record it was computed for.
  final String recordId;

  /// That record's name, or empty.
  final String recordName;

  /// That record's per-project number, when allocated.
  final int? recordNumber;

  /// The field.
  final String fieldKey;

  /// The field's label from the template, or its key.
  final String label;

  /// The deepest context value of the record, or empty.
  final String context;

  /// The register value.
  final String recorded;

  /// What the field worker found.
  final String found;

  /// How the two compare.
  final VarianceStatus status;
}
