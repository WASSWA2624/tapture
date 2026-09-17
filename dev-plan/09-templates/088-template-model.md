# 088 — Template domain model and repository

**Phase** 09 · Templates  |  **Depends on** [053](../04-data-layer/053-templates-table.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Immutable `TemplateDef`, `FieldDef` and `TemplateRow`, their mappers to and from the Drift rows, and
`TemplateRepositoryImpl` behind the repository interface declared in 111. Every later task in this phase reads and
writes templates through these three types alone.

## Files

- `frontend/lib/features/templates/domain/template_def.dart` (new)
- `frontend/lib/features/templates/data/template_repository_impl.dart` (new)

## Contract

```dart
enum Requiredness { required, recommended, optional }

class TemplateDef {
  final String id, templateKey, name;
  final int version;
  final List<FieldDef> fields;
  final List<String> identityFieldKeys;
  final List<TemplateRow> rows;
}

class FieldDef {
  final String fieldKey, label;
  final FieldType type;
  final Requiredness requiredness;
  // §12.2 in full: defaultValue, unit, helpText, inputMode, stickable, contextLevel,
  // autoFill, refine, options, group, outputColumn, requiredWhen, hidden.
}
```

## Steps

1. Model every field attribute of §12.2, including `stickable`, `contextLevel`, `autoFill` and `refine`.
2. Requiredness is the three-value enum above, never a bool — a user may move a field between all three (§13.2).
3. Mappers are total: an attribute the table stores and the model drops is a defect the round-trip test catches.

## Constraints

- Nothing under `features/templates/domain/` imports Flutter or Drift; the mapper lives in `data/` (FE-STR-05).
- Models are `const`-constructible and copy-with, never mutated in place (FE-CODE-04).
- Presentation reaches templates only through the domain interface, never a DAO or Drift row (FE-STATE-05).

## Definition of done

- [ ] `TemplateDef`, `FieldDef` and `TemplateRow` carry every attribute of §12.2, with requiredness a three-value enum.
- [ ] Tests: `frontend/test/features/templates/template_mapper_test.dart` round-trips every attribute; repository tests run against an in-memory database, and ship the fake later tasks use (FE-STATE-10).
- [ ] Contract above is implemented exactly, with nothing else made public.
