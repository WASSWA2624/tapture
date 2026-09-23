import 'package:tapture/core/ai/ai_operation.dart';

/// One model exposed by a provider for selected operations.
final class ModelDescriptor {
  /// Creates immutable model metadata.
  factory ModelDescriptor({
    required String id,
    required String label,
    required Set<AiOperation> operations,
  }) {
    return ModelDescriptor._(
      id: id,
      label: label,
      operations: Set<AiOperation>.unmodifiable(operations),
    );
  }

  const ModelDescriptor._({
    required this.id,
    required this.label,
    required this.operations,
  });

  /// Stable wire id.
  final String id;

  /// Operator-facing name.
  final String label;

  /// Operations supported by this model.
  final Set<AiOperation> operations;
}
