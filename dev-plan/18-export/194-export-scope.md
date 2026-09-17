# 194 — Scope and options sections

**Phase** 18 · Export  |  **Depends on** [163](../14-records/163-records-list.md), [193](193-export-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two sections that between them build every field of an `ExportRequest`: the scope section chooses which records are
included and shows a live count of them, the options section chooses columns and extras. Both are plain sections with
no screen of their own.

## Files

- `frontend/lib/features/exports/presentation/export_scope_section.dart` (new)
- `frontend/lib/features/exports/presentation/export_options_section.dart` (new)

## Steps

1. Offer five scopes: approved only, all records, current context subtree, date range, current filter from 304.
2. Recompute the record count whenever the scope changes, off the build method.
3. Offer raw columns, refined columns, confidence, evidence and the extra sheets; default refined columns on for
   every field that has a refined value.
4. Persist the options per project so the next export opens with the last choice.

## Constraints

- Both sections render the four states of FE-CONS-04; the count never blocks on a query in `build` (FE-PERF-02).
- Extras and column detail sit in a collapsed advanced group (FE-SIMP-06); no new control is invented for either
  section (FE-CONS-01).

## Definition of done

- [ ] The chosen scope shows a live record count before the export starts, and the count follows filter changes.
- [ ] Refined columns arrive on by default for refined fields; the choice is remembered per project.
- [ ] Tests: widget tests of `export_scope_section.dart` and `export_options_section.dart` covering each scope, the empty and failure states, and that saved options are restored.
