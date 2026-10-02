import 'package:tapture/core/copy/domain_copy.g.dart';

import 'field_rule.dart';
import 'field_validators.dart';
import 'severity.dart';
import 'validation_issue.dart';

/// Whole-record and export-set rules (task 015).
///
/// Identity fields must be present, evidence must be present where a field
/// demands it, and an export set is the union of its records' issues.
abstract final class RecordValidators {
  /// Every issue on a record whose values are [values].
  ///
  /// [hasEvidence] is whether the record holds a photo or other evidence.
  /// [conflicts] are field keys that still disagree; each blocks approval
  /// and names the field.
  static List<ValidationIssue> check({
    required Iterable<FieldRule> fields,
    required Map<String, Object?> values,
    required bool hasEvidence,
    Iterable<String> conflicts = const <String>[],
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    var evidenceDemanded = false;
    for (final FieldRule field in fields) {
      issues.addAll(
        FieldValidators.check(field, values[field.fieldKey], values),
      );
      if (field.requiresEvidence) {
        evidenceDemanded = true;
      }
    }
    if (evidenceDemanded && !hasEvidence) {
      issues.add(
        ValidationIssue(
          null,
          Severity.error,
          DomainCopy.validationEvidence,
          localizedMessage: DomainCopy.messages.validationEvidence,
        ),
      );
    }
    for (final String fieldKey in conflicts) {
      String label = fieldKey;
      for (final FieldRule field in fields) {
        if (field.fieldKey == fieldKey) {
          label = field.label;
          break;
        }
      }
      issues.add(
        ValidationIssue(
          fieldKey,
          Severity.error,
          DomainCopy.conflictBlocksApproval(label),
          localizedMessage: DomainCopy.messages.conflictBlocksApproval(label),
        ),
      );
    }
    return issues;
  }

  /// Issues across an export set. Each record is checked on its own.
  static List<ValidationIssue> exportSet({
    required Iterable<FieldRule> fields,
    required Iterable<Map<String, Object?>> records,
    required bool Function(Map<String, Object?> record) hasEvidence,
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    for (final Map<String, Object?> record in records) {
      issues.addAll(
        check(fields: fields, values: record, hasEvidence: hasEvidence(record)),
      );
    }
    return issues;
  }
}
