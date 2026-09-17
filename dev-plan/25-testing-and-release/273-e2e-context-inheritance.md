# 273 — End-to-end: context inheritance and caption scope

**Phase** 25 · Testing and release  |  **Depends on** [117](../11-context/117-context-apply-to-record.md), [130](../12-capture/130-caption-scope-selector.md), [272](272-e2e-capture-to-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two integration runs over the machinery that decides how far one edit reaches: inherited context across records, and
caption application across a record's photos. Each run proves a different scope rule and fails on its own.

## Files

- `frontend/integration_test/context_test.dart` (new)
- `frontend/integration_test/caption_scope_test.dart` (new)

## Steps

1. `context_test.dart` — capture five records under one project context and assert all five inherit it; override the
   context on one record and assert only that record changes; change the district on the project and assert the change
   cascades to the four still inheriting and leaves the overridden record alone.
2. `caption_scope_test.dart` — apply a caption to one photo, to a selection of three, and to all photos of a record,
   asserting after each that exactly the intended set carries it; then edit one photo's caption and assert the others
   keep the previous text.

## Constraints

- Both runs assert the audit trail for every value they change: who, when, from what, to what (FE-SEC-09).

## Definition of done

- [ ] An override never leaks beyond its own record, and a cascade never overwrites an override.
- [ ] Each of the three caption scopes lands on exactly its target set, and a later single edit is independent.
- [ ] Tests: `context_test.dart` and `caption_scope_test.dart` run green offline against fakes, end to end.
