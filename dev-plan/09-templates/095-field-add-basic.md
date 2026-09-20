# 095 — Add and edit a field, with Advanced, validation and options

**Phase** 09 · Templates  |  **Depends on** [036](../03-design-system/036-app-choice-field.md), [089](089-field-type-registry.md), [094](094-field-list-editor.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three-question add flow of §12.3 — **Label**, **Type**, **Required?** — with every other attribute defaulted and
tucked behind a collapsed Advanced section that carries §12.2 in full, plus the two editors Advanced opens: validation
rules and choice options.

## Files

- `frontend/lib/features/templates/presentation/field_add_sheet.dart` (new)
- `frontend/lib/features/templates/presentation/field_advanced_section.dart` (new)
- `frontend/lib/features/templates/presentation/field_validation_editor.dart` (new)
- `frontend/lib/features/templates/presentation/field_options_editor.dart` (new)

## Steps

1. Generate the field key from the label, guaranteeing uniqueness and stability, and hold it to the atomicity
   conventions of §13.1: `snake_case`, one fact, unit in the key where the value is measured.
2. Offer REQUIRED, RECOMMENDED and OPTIONAL as three equal choices, defaulting to OPTIONAL. Requiredness is the
   user's decision at every point, never the app's (§13.2).
3. Warn, without blocking, when a label packs two facts (`Make / Model`, `Address`) and offer to split it.
4. Advanced stays collapsed and carries every attribute of §12.2 the add flow defaults — default value, unit, help
   text, input mode, stickable, context level, auto fill, refine, identity — plus the two that decide whether a field
   applies at all: `required_when` and `hidden`.
5. `required_when` takes a simple expression over other fields of the same template — `fault_present == true` —
   validated against the field list as it is typed, with a plain-language preview of what it means.
6. `hidden` keeps the field out of the capture screen and out of every export while preserving values already
   captured under it (§18); it is never a delete.
7. Validation rules cover pattern, length, range and required-with, with ready-made patterns (serial, asset tag,
   registration) and a custom option carrying a live test box.
8. Choice options can be added, reordered, renamed and retired; renaming updates the label only, never the stored
   code.
9. Any change made here creates a new template version (§18).

## Constraints

- Advanced is closed by default and a simple template never meets it (FE-SIMP-06).
- The two-fact warning offers *keep anyway*; it never blocks the save (FE-SIMP-08).
- Labels, help text and option names are template content, stored as user data, not localisation keys (FE-L10N-07).

## Definition of done

- [x] A field is added in under ten seconds and lands OPTIONAL unless the user says otherwise; a two-fact label is questioned once and the user can still insist.
- [x] `required_when` naming an unknown field is refused at edit time, not at capture time.
- [x] Hiding a field removes it from capture and export, and a later unhide brings its old values back intact.
- [x] A validation rule can be tested against a sample value before saving, and renaming an option does not rewrite historical records.
- [x] Tests: unit tests over key generation and collision handling, `required_when` expression validation, the hide/unhide value round trip, and option rename leaving stored codes untouched; widget tests of `field_add_sheet.dart`, `field_validation_editor.dart` and `field_options_editor.dart` covering empty and failure states.

## Out of scope

- Setting requiredness for a whole template in one pass; that is 165.
