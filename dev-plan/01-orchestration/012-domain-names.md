# 012 — Canonical domain names

**Phase** 01 · Project setup and guardrails  |  **Depends on** [011](011-naming-checker.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/lib/core/naming/domain_names.dart` holds one canonical type name per specification concept, and
`frontend/test/architecture/naming_test.dart` fails any near-synonym found in `frontend/lib/`, naming the term that
should have been used.

## Files

- `frontend/lib/core/naming/domain_names.dart` (new)
- `frontend/test/architecture/naming_test.dart` (new)

## Contract

```dart
abstract final class DomainNames { static const project = 'Project'; ... }
```

## Steps

1. Declare the canonical names: Project, TemplateDef, FieldDef, RecordEntry, FieldValue, CaptureSession, PhotoAsset, ContextState, ReferenceDataset, ProcessingJob, Bundle, MergeSession.
2. Map each canonical name to the synonyms it displaces — RecordModel, PhotoItem, TemplateData and the like — so the failure message can name the replacement.
3. Scan `frontend/lib/` for declarations matching a synonym and fail with file, line and the canonical term.

## Constraints

- One word per concept, in code and on screen; the registry is the reference and synonyms fail this test (FE-CONS-07).
- Match whole camel-case segments only, as `011` does, so `ReferenceDataset` and `FieldValue` pass while `RecordData` fails (FE-CODE-03).

## Definition of done

- [ ] Declaring `RecordModel` or `PhotoItem` fails the test with `RecordEntry` and `PhotoAsset` in the message.
- [ ] All twelve concepts resolve through `DomainNames`, with no second spelling anywhere in `lib/`.
- [ ] Tests: `frontend/test/architecture/naming_test.dart` over fixtures for three synonyms and one compliant tree.
