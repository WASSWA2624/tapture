# 028 — Serialisation conventions

**Phase** 02 · Foundation services  |  **Depends on** [003](../01-orchestration/003-strict-lints.md), [004](../01-orchestration/004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Code generation is configured in `frontend/build.yaml`, and `core/serialisation/converters.dart` holds the converters
every model reuses, so a wire format never changes because a Dart identifier was renamed.

## Files

- `frontend/build.yaml` (new)
- `frontend/lib/core/serialisation/converters.dart` (new)

## Contract

```dart
class UtcDateTimeConverter implements JsonConverter<DateTime, String>;  class JsonMapConverter ...
```

## Steps

1. Configure the generator, then write converters for UTC date-times, enums with stable wire names and JSON-held maps.
2. Fix the rule that every wire name is stated explicitly and never derived from a Dart identifier that may be renamed.

## Constraints

- Generated output is committed, so a clean checkout builds without a generator run (FE-CODE-13).
- Models stay immutable: `final` fields, `const` where possible, change through `copyWith` (FE-CODE-04).
- `dynamic` appears only inside a decoder and is narrowed on the next line (FE-CODE-05).

## Definition of done

- [ ] Renaming a Dart field does not change the serialised key.
- [ ] Date-times round-trip as UTC regardless of the device offset, and an unknown enum wire name fails loudly rather than defaulting silently.
- [ ] Tests: `frontend/test/core/serialisation/converters_test.dart` round-trips each converter, including the unknown-enum and null cases.
