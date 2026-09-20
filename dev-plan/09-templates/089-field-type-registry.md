# 089 — Field type registry

**Phase** 09 · Templates  |  **Depends on** [011](../01-orchestration/011-naming-checker.md), [088](088-template-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One registry describing each field type of §12.1 by its four behaviours: editor widget, validator, normaliser, and
storage-and-export form. Capture, review, validation and export read behaviour from here instead of switching on the
type themselves.

## Files

- `frontend/lib/features/templates/domain/field_type_registry.dart` (new)

## Steps

1. Register all nineteen types of §12.1 by name, so the registry test can assert the set is complete: text, long
   text, number, decimal, currency, percentage, date, time, date-time, boolean, choice, multi-choice, lookup,
   barcode, photo reference, document reference, GPS location, signature and computed.
2. Most types reuse an existing design-system field (053–062). Three do not and are declared as such: signature draws
   on screen and stores the result as an image beside the record's evidence, computed is read-only and evaluated by
   task 170, and GPS location is filled by task 135.
3. Keep the registry additive: adding a field type later is one entry here, not edits across ten files.

## Constraints

- The registry names editors through a builder supplied by presentation; `domain/` imports no widget (FE-STR-05).
- Type names match `lib/core/naming/domain_names.dart`; synonyms fail the naming checker (FE-CONS-07).
- Editors resolve to catalogue widgets; no type introduces a parallel field control (FE-CONS-01).

## Definition of done

- [x] Capture, review, validation and export all read behaviour from this registry rather than switching on type.
- [x] Every type of §12.1 is present, and a type missing any of its four behaviours fails the registry test.
- [x] Tests: unit test over the declared set asserting completeness and that each entry supplies all four behaviours.
