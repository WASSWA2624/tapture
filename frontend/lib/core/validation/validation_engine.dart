import 'field_rule.dart';
import 'field_validators.dart';
import 'record_validators.dart';
import 'validation_issue.dart';

/// The one validation pass capture, review, import and export call (task 015).
///
/// An error blocks a save, an approval and an export. A warning never does.
abstract interface class ValidationEngine {
  /// Issues for one [field] holding [value], beside [siblings].
  List<ValidationIssue> validateField(
    FieldRule field,
    Object? value,
    Map<String, Object?> siblings,
  );

  /// Issues for one record.
  List<ValidationIssue> validateRecord({
    required Iterable<FieldRule> fields,
    required Map<String, Object?> values,
    required bool hasEvidence,
    Iterable<String> conflicts,
  });

  /// Issues for a set of records about to be exported.
  List<ValidationIssue> validateExportSet({
    required Iterable<FieldRule> fields,
    required Iterable<Map<String, Object?>> records,
    required bool Function(Map<String, Object?> record) hasEvidence,
  });
}

/// The engine every feature shares. It holds no second copy of a check:
/// field rules and record rules live in one place.
final class _SharedValidationEngine implements ValidationEngine {
  const _SharedValidationEngine();

  @override
  List<ValidationIssue> validateField(
    FieldRule field,
    Object? value,
    Map<String, Object?> siblings,
  ) {
    return FieldValidators.check(field, value, siblings);
  }

  @override
  List<ValidationIssue> validateRecord({
    required Iterable<FieldRule> fields,
    required Map<String, Object?> values,
    required bool hasEvidence,
    Iterable<String> conflicts = const <String>[],
  }) {
    return RecordValidators.check(
      fields: fields,
      values: values,
      hasEvidence: hasEvidence,
      conflicts: conflicts,
    );
  }

  @override
  List<ValidationIssue> validateExportSet({
    required Iterable<FieldRule> fields,
    required Iterable<Map<String, Object?>> records,
    required bool Function(Map<String, Object?> record) hasEvidence,
  }) {
    return RecordValidators.exportSet(
      fields: fields,
      records: records,
      hasEvidence: hasEvidence,
    );
  }
}

/// The engine features call.
const ValidationEngine validationEngine = _SharedValidationEngine();
