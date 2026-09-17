# 171 — Validation display

**Phase** 15 · Data quality  |  **Depends on** [044](../03-design-system/044-app-form-scaffold.md), [170](170-validation-engine.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One widget that renders the `ValidationIssue`s of 315 two ways: inline beneath the field it names, and as a summary
at the head of a long form. Every screen that edits a record reports problems through it.

## Files

- `frontend/lib/core/widgets/forms/validation_display.dart` (new)

## Constraints

- Errors and warnings differ by icon and wording, not by colour alone (FE-A11Y-05, FE-THEME-05).
- A warning renders and the form stays submittable; only an error blocks (FE-SIMP-08).
- Tokens only — no literal colour, spacing or text style in this file (FE-THEME-01).

## Definition of done

- [ ] Every screen reports problems the same way; no feature builds its own error text style (FE-CONS-11).
- [ ] The summary names how many issues there are and links to the first field with an error.
- [ ] A change in the issue list is announced to a screen reader (FE-A11Y-07).
- [ ] Tests: golden tests of `validation_display.dart` in light, dark and outdoor themes, plus a widget test of each
      state it renders — none, warnings only, errors only, and mixed.
