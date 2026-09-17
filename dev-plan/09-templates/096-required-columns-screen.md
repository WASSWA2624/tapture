# 096 — Required columns screen

**Phase** 09 · Templates  |  **Depends on** [094](094-field-list-editor.md), [095](095-field-add-basic.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one screen that lets a project decide, for a whole template at once, which columns it insists on. A shipped
template's requiredness is a suggestion; this screen is where the user overrules it (§13.2, §12.3).

## Files

- `frontend/lib/features/templates/presentation/required_columns_screen.dart` (new)
- `frontend/lib/features/templates/application/requiredness_controller.dart` (new)

## Contract

```dart
class RequirednessController {
  void set(String fieldKey, Requiredness value);
  void setHidden(String fieldKey, bool hidden);
  Future<TemplateVersion> commit();   // one version bump for the whole pass
}
```

## Steps

1. Render the template as one scrollable list: field label on the left, three radio columns — REQUIRED,
   RECOMMENDED, OPTIONAL — and a **Hide** toggle on the right.
2. Group rows by the template's field groups, with inherited groups (§13.3) collapsed by default.
3. Show the shipped default beside a changed value, so a user can see what they moved and put it back.
4. Commit the whole pass as **one** template version, not one per field (§18).
5. A hidden field leaves the capture screen and the export, and keeps every value already captured.

## Constraints

- Rows, radios and section headers come from the design system; this screen invents no control (FE-CONS-01).
- Version bumping calls the existing template versioning service rather than a second implementation (FE-STR-09).
- The radio grid stays usable at 200 percent text and names each cell for a screen reader (FE-A11Y-02, FE-A11Y-03).

## Definition of done

- [ ] A shipped template can be re-scoped from forty suggested columns to eight required ones in a single pass.
- [ ] Changing requiredness produces exactly one new template version, and records captured under an earlier version are not marked incomplete.
- [ ] A field made REQUIRED blocks approval, never capture: an incomplete record still saves and lands in NEEDS_REVIEW.
- [ ] Tests: widget test over the three-radio grid and the hide toggle; unit test that a multi-field pass commits one version.
- [ ] Contract above is implemented exactly, with nothing else made public.

## Out of scope

- Editing anything other than requiredness and visibility — labels, types and options stay in the field editor.
