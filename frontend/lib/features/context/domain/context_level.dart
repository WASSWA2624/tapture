part of 'context_state.dart';

/// One level in a project's context hierarchy.
final class ContextLevel {
  /// Creates a level. [order] is 0-based from the root (highest).
  const ContextLevel({
    required this.fieldKey,
    required this.order,
    this.datasetId,
    this.label = '',
  });

  /// Template field key this level binds to.
  final String fieldKey;

  /// Hierarchy order. Smaller is higher.
  final int order;

  /// Optional reference dataset for picker search.
  final String? datasetId;

  /// Operator-facing name (template label), stored as user data.
  final String label;

  /// Returns a copy with the provided fields replaced.
  ContextLevel copyWith({
    String? fieldKey,
    int? order,
    String? datasetId,
    String? label,
    bool clearDatasetId = false,
  }) {
    return ContextLevel(
      fieldKey: fieldKey ?? this.fieldKey,
      order: order ?? this.order,
      datasetId: clearDatasetId ? null : (datasetId ?? this.datasetId),
      label: label ?? this.label,
    );
  }

  @override
  int get hashCode => Object.hash(fieldKey, order, datasetId, label);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ContextLevel &&
            other.fieldKey == fieldKey &&
            other.order == order &&
            other.datasetId == datasetId &&
            other.label == label);
  }
}
