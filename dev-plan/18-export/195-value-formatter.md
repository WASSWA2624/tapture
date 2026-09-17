# 195 — Export value formatter

**Phase** 18 · Export  |  **Depends on** [089](../09-templates/089-field-type-registry.md), [153](../13-processing/153-normalise-units.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One formatter every writer calls, so a value reads identically in XLSX, CSV, JSON and PDF. It renders each field type
of the registry for a named target format and never loses information a downstream reader needs.

## Files

- `frontend/lib/core/export/value_formatter.dart` (new)

## Contract

```dart
class ExportValueFormatter {
  const ExportValueFormatter(this.registry);
  /// Rendered form of [value] for [target]; `null` becomes the empty string.
  String format(Object? value, FieldType type, ExportFormat target);
  /// Typed form for writers that carry native cell types, e.g. XLSX dates and numbers.
  Object? typed(Object? value, FieldType type);
}
```

## Steps

1. Handle dates, numbers with units, choices with their codes, booleans, multi-values and nulls; give multi-values one
   separator across all formats.
2. Render identifiers as text always, preserving leading zeros and never coercing them to numbers.
3. Take normalised dates from 284; do not parse date strings here.

## Constraints

- This is the single formatter for exported values (FE-CONS-09); a writer that formats a value itself is a defect.
- Pure Dart, no Flutter import, so PDF and CSV writers can share it from an isolate (FE-STR-05).

## Definition of done

- [ ] XLSX, CSV, JSON and PDF show the same value in the same way for every registry type.
- [ ] An asset number such as `00734` exports as `00734` in all four formats.
- [ ] Tests: table-driven unit tests of `value_formatter.dart` over every field type crossed with every target format, including null and multi-value cases.
