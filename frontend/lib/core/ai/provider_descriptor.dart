import 'package:tapture/core/ai/ai_operation.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/model_descriptor.dart';
import 'package:tapture/core/ai/provider_key_custody.dart';

/// Registry-owned provider presentation and resolution metadata.
final class ProviderDescriptor {
  /// Creates immutable provider metadata.
  factory ProviderDescriptor({
    required String id,
    required String label,
    required Set<AiOperation> operations,
    required ProviderKeyCustody keyCustody,
    required bool deviceKeyAllowed,
    required bool available,
    required AiService service,
    required List<ModelDescriptor> models,
  }) {
    return ProviderDescriptor._(
      id: id,
      label: label,
      operations: Set<AiOperation>.unmodifiable(operations),
      keyCustody: keyCustody,
      deviceKeyAllowed: deviceKeyAllowed,
      available: available,
      service: service,
      models: List<ModelDescriptor>.unmodifiable(models),
    );
  }

  const ProviderDescriptor._({
    required this.id,
    required this.label,
    required this.operations,
    required this.keyCustody,
    required this.deviceKeyAllowed,
    required this.available,
    required this.service,
    required this.models,
  });

  /// Stable wire id.
  final String id;

  /// Operator-facing name.
  final String label;

  /// Supported operations.
  final Set<AiOperation> operations;

  /// Credential custody boundary.
  final ProviderKeyCustody keyCustody;

  /// Whether administrators explicitly permit a device-held key.
  final bool deviceKeyAllowed;

  /// Whether this descriptor can currently resolve work.
  final bool available;

  /// Service implementation. Credentials are not stored here.
  final AiService service;

  /// Ordered model catalogue.
  final List<ModelDescriptor> models;
}
