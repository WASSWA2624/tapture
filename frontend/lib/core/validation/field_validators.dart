import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/units.dart';

import 'field_expression.dart';
import 'field_rule.dart';
import 'severity.dart';
import 'validation_issue.dart';

/// The field rules of task 015: required, type shape, pattern, length,
/// range, option membership and unit sanity.
///
/// Type shape is a blank-or-present check here. The field type registry
/// remains the place a feature asks whether a value is an integer, a date
/// or a choice; this class adds the rules that registry does not own and
/// the ones the engine tests directly.
abstract final class FieldValidators {
  /// Issues for [value] on [field], given the record's other [siblings].
  static List<ValidationIssue> check(
    FieldRule field,
    Object? value,
    Map<String, Object?> siblings,
  ) {
    if (field.hidden) {
      return const <ValidationIssue>[];
    }
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final bool empty = _empty(value);
    if (empty && _requiredNow(field, siblings)) {
      issues.add(
        ValidationIssue(
          field.fieldKey,
          Severity.error,
          field.identity
              ? DomainCopy.validationIdentity(field.label)
              : DomainCopy.validationRequired(field.label),
          localizedMessage: field.identity
              ? DomainCopy.messages.validationIdentity(field.label)
              : DomainCopy.messages.validationRequired(field.label),
        ),
      );
      return issues;
    }
    if (empty && field.recommended) {
      issues.add(
        ValidationIssue(
          field.fieldKey,
          Severity.warning,
          DomainCopy.validationRequired(field.label),
          localizedMessage: DomainCopy.messages.validationRequired(field.label),
        ),
      );
      return issues;
    }
    if (empty) {
      return issues;
    }
    final String text = '$value'.trim();
    final int? minLength = field.minLength;
    if (minLength != null && text.length < minLength) {
      issues.add(
        ValidationIssue(
          field.fieldKey,
          Severity.error,
          DomainCopy.validationTooShort(field.label),
          localizedMessage: DomainCopy.messages.validationTooShort(field.label),
        ),
      );
    }
    final int? maxLength = field.maxLength;
    if (maxLength != null && text.length > maxLength) {
      issues.add(
        ValidationIssue(
          field.fieldKey,
          Severity.error,
          DomainCopy.validationTooLong(field.label),
          localizedMessage: DomainCopy.messages.validationTooLong(field.label),
        ),
      );
    }
    final String? pattern = field.pattern;
    if (pattern != null && pattern.isNotEmpty) {
      final bool matches = _matches(pattern, text);
      if (!matches) {
        issues.add(
          ValidationIssue(
            field.fieldKey,
            Severity.error,
            DomainCopy.validationPattern(field.label),
            localizedMessage: DomainCopy.messages.validationPattern(
              field.label,
            ),
          ),
        );
      }
    }
    if (field.min != null || field.max != null) {
      final num? number = num.tryParse(text);
      if (number == null ||
          (field.min != null && number < field.min!) ||
          (field.max != null && number > field.max!)) {
        issues.add(
          ValidationIssue(
            field.fieldKey,
            Severity.error,
            DomainCopy.validationRange(field.label),
            localizedMessage: DomainCopy.messages.validationRange(field.label),
          ),
        );
      }
    }
    if (field.options.isNotEmpty && !_option(field.options, text)) {
      issues.add(
        ValidationIssue(
          field.fieldKey,
          Severity.error,
          DomainCopy.validationOption(field.label),
          localizedMessage: DomainCopy.messages.validationOption(field.label),
        ),
      );
    }
    final String? unit = field.unit;
    if (unit != null &&
        unit.isNotEmpty &&
        Units.convert(text, targetUnit: unit) == null) {
      issues.add(
        ValidationIssue(
          field.fieldKey,
          Severity.error,
          DomainCopy.validationUnit(field.label),
          localizedMessage: DomainCopy.messages.validationUnit(field.label),
        ),
      );
    }
    return issues;
  }

  /// The computed expression's value, or null when it is not yet computable.
  static Object? computed(FieldRule field, Map<String, Object?> siblings) {
    final String? source = field.computedExpression;
    if (source == null || source.trim().isEmpty) {
      return null;
    }
    final Result<FieldExpression> parsed = FieldExpression.parse(
      source,
      siblings.keys.toList(),
    );
    if (parsed is! Success<FieldExpression>) {
      return null;
    }
    return evaluate(parsed.value, siblings);
  }
}

bool _requiredNow(FieldRule field, Map<String, Object?> siblings) {
  if (field.required || field.identity) {
    return true;
  }
  final String? when = field.requiredWhen;
  if (when == null || when.trim().isEmpty) {
    return false;
  }
  final Result<FieldExpression> parsed = FieldExpression.parse(when, <String>[
    field.fieldKey,
    ...siblings.keys,
  ]);
  if (parsed is! Success<FieldExpression>) {
    return false;
  }
  return evaluate(parsed.value, siblings) == true;
}

bool _empty(Object? value) {
  if (value == null) {
    return true;
  }
  if (value is String) {
    return value.trim().isEmpty;
  }
  return false;
}

bool _matches(String pattern, String text) {
  try {
    return RegExp(pattern).hasMatch(text);
  } on FormatException {
    return false;
  }
}

bool _option(List<String> options, String text) {
  final String folded = text.toLowerCase();
  for (final String option in options) {
    if (option.toLowerCase() == folded) {
      return true;
    }
  }
  return false;
}
