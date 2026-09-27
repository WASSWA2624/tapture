import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/features/templates/templates.dart';

/// Maps a template onto the shared engine (task 015).
///
/// Type checks go through [FieldTypeRegistry]. Requiredness, identity,
/// evidence and conflicts go through [validationEngine]. No other feature
/// keeps a copy of those checks.
abstract final class RecordRules {
  /// Issues for one field.
  static List<ValidationIssue> validateField(
    FieldDef field,
    Object? value,
    Map<String, Object?> siblings,
  ) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final Result<void> typed = FieldTypeRegistry.validate(
      type: field.type,
      value: value,
      field: field,
    );
    if (typed is FailureResult<void>) {
      issues.add(
        ValidationIssue(field.fieldKey, Severity.error, typed.failure.message),
      );
    }
    issues.addAll(
      validationEngine.validateField(ruleOf(field), value, siblings),
    );
    return issues;
  }

  /// Issues for a record. [conflicts] are field keys still unresolved.
  static List<ValidationIssue> validateRecord({
    required TemplateDef template,
    required Map<String, Object?> values,
    required bool hasEvidence,
    Iterable<String> conflicts = const <String>[],
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    for (final FieldDef field in template.fields) {
      if (field.hidden) {
        continue;
      }
      final Result<void> typed = FieldTypeRegistry.validate(
        type: field.type,
        value: values[field.fieldKey],
        field: field,
      );
      if (typed is FailureResult<void>) {
        issues.add(
          ValidationIssue(
            field.fieldKey,
            Severity.error,
            typed.failure.message,
          ),
        );
      }
    }
    issues.addAll(
      validationEngine.validateRecord(
        fields: <FieldRule>[
          for (final FieldDef field in template.fields)
            ruleOf(
              field,
              identity: template.identityFieldKeys.contains(field.fieldKey),
            ),
        ],
        values: values,
        hasEvidence: hasEvidence,
        conflicts: conflicts,
      ),
    );
    return issues;
  }

  /// Issues that block an export of [records].
  static List<ValidationIssue> validateExportSet(
    Iterable<Map<String, Object?>> records,
    TemplateDef template,
  ) {
    return validationEngine.validateExportSet(
      fields: <FieldRule>[
        for (final FieldDef field in template.fields)
          ruleOf(
            field,
            identity: template.identityFieldKeys.contains(field.fieldKey),
          ),
      ],
      records: records,
      hasEvidence: (Map<String, Object?> record) =>
          record['__evidence'] == true,
    );
  }

  /// Whether any issue blocks.
  static bool blocks(Iterable<ValidationIssue> issues) {
    return issues.any((ValidationIssue issue) => issue.blocks);
  }

  /// The engine's view of [field]. Pattern and range stay with the registry.
  static FieldRule ruleOf(FieldDef field, {bool identity = false}) {
    final Object? evidence = field.validation['evidence'];
    final Object? expression = field.validation['expression'];
    return FieldRule(
      fieldKey: field.fieldKey,
      label: field.label,
      required: field.requiredness == Requiredness.required,
      recommended: field.requiredness == Requiredness.recommended,
      identity: field.identity || identity,
      requiresEvidence: evidence == true,
      requiredWhen: field.requiredWhen,
      computedExpression:
          field.type == FieldType.computed && expression is String
          ? expression
          : null,
      hidden: field.hidden,
    );
  }
}
