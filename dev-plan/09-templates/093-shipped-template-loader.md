# 093 — Shipped template loader and library picker

**Phase** 09 · Templates  |  **Depends on** [090](090-shipped-templates-assets.md), [092](092-template-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Runtime loading of `assets/templates/`, a picker screen that previews a shipped template's fields, and the copy that
lands it in the project as an editable template. A new project becomes capture-ready in two taps without anyone
building a field.

## Files

- `frontend/lib/features/templates/data/shipped_template_loader.dart` (new)
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart` (new)

## Steps

1. Load each asset, validate it against `_schema.json`, and resolve its inherited groups (§13.3) before it is shown.
2. List the library with its §13.4 kinds; preview the resolved field list before adding, and allow renaming on add.
3. Copying writes a project-owned `TemplateDef` at version 1; the asset is never mutated.

## Constraints

- Assets are read through generated constants, never a literal path (FE-STR-12).
- Labels arriving from an asset are localisation keys resolved at render time, not display strings (FE-L10N-07).

## Definition of done

- [x] A new project is capture-ready without building anything: pick, preview, add.
- [x] Editing a copied template cannot affect the library, and a second copy of the same asset is unaffected by the first.
- [x] Tests: repository tests for `shipped_template_loader.dart` against an in-memory database, plus the fake later tests use; widget test of `shipped_picker_screen.dart` covering its empty and failure states.
