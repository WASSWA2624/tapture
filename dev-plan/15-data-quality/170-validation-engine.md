# 170 — Validation engine and validators

**Phase** 15 · Data quality  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [089](../09-templates/089-field-type-registry.md), [098](../09-templates/098-identity-fields.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One engine that capture, review, import and export all call to validate a value, a record and an export set. It
holds the field rules, the whole-record rules, and the expression evaluator that `required_when` and the Computed
field type both depend on (§12.1, §12.2). Task 164 lets a user type `fault_present == true`; nothing evaluates it
until this exists, so conditional requiredness and computed values do not work.

## Files

- `frontend/lib/core/validation/validation_engine.dart` (new)
- `frontend/lib/core/validation/field_validators.dart` (new)
- `frontend/lib/core/validation/field_expression.dart` (new)
- `frontend/lib/core/validation/record_validators.dart` (new)

## Contract

```dart
enum Severity { error, warning }

class ValidationIssue {
  const ValidationIssue(this.fieldKey, this.severity, this.message);
  final String? fieldKey;
  final Severity severity;
  final String message;
}

abstract interface class ValidationEngine {
  List<ValidationIssue> validateField(FieldDef field, Object? value, Map<String, Object?> siblings);
  List<ValidationIssue> validateRecord(RecordEntry record, TemplateDef template);
  List<ValidationIssue> validateExportSet(Iterable<RecordEntry> records, TemplateDef template);
}

sealed class FieldExpression {
  static Result<FieldExpression> parse(String source, List<FieldDef> fields);
}

Object? evaluate(FieldExpression expression, Map<String, Object?> values);
```

## Steps

1. Every issue carries a field key, a severity and a plain-language message. Errors block a save, an approval and an
   export; warnings never do.
2. Field rules: required, type, pattern, length, range, option membership and unit sanity, driven by the field type
   registry of 154 rather than a switch at each call site.
3. The expression grammar covers comparison, equality, `and`/`or`/`not` and arithmetic over other fields of the same
   record — `qty * unit_cost`, `fault_present == true`. No function calls, no access outside the record.
4. Parse against the template's field list, so an expression naming a field that does not exist fails in the template
   editor (164) rather than at capture time.
5. An expression that cannot be evaluated — a missing operand, a type mismatch — yields `null`, never a guess and
   never an exception: a Computed field with incomplete inputs is simply not yet computed (§34).
6. Requiredness is resolved per record, never read straight off the template: a field is required when its
   `Requiredness` is `required`, or when its `required_when` expression evaluates true for this record's values.
7. Record rules also cover identity fields present (171) and evidence present where the template demands it.

## Constraints

- Everything under `core/validation/` is pure Dart: no Flutter, Drift or HTTP import (FE-STR-05).
- The evaluator takes no template repository, database or Flutter dependency, so 164, 252 and 363 call it directly
  (FE-CONS-01).
- Parse and evaluation failures come back as `Result` failures, never thrown (FE-CODE-06).

## Definition of done

- [ ] Capture, review, import and export all validate through this engine; no feature holds a second copy of a check.
- [ ] `required_when` and Computed fields are evaluated through this one evaluator, and a malformed or unsatisfiable
      expression yields `null` plus a typed failure rather than an exception.
- [ ] A record cannot be approved with an empty identity field, or an empty `required_when`-triggered field, when the
      template demands one.
- [ ] Tests: `frontend/test/core/validation/` — table-driven unit tests per rule type over valid and invalid values,
      expression tests covering parsing, evaluation, missing operands and type mismatches, and record-validator tests
      against the template fake, with no Flutter binding.

## Out of scope

- Rendering issues in the interface; that is task 171.
