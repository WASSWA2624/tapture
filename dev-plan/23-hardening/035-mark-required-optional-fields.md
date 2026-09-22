# 035 — Mark required optional fields

**Phase** 23 · Hardening  |  **Depends on** [003](../03-design-system/003-design-system.md), [007](../07-account-and-settings/007-account-and-settings.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Operator (and any field that opts in) shows which inputs are required and
which are optional before Save. Unmarked fields look as they do today.

## Files

- `frontend/lib/core/widgets/fields/app_text_field.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/fields/app_text_field_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`
- `frontend/test/design_system/app_text_field/gallery_golden_test.dart`

## Constraints

- Extend `AppTextField`; do not fork a label widget (FE-CONS-01).
- `Copy.fieldRequired` / `Copy.fieldOptional` are their own strings; never
  concatenate them into the label (FE-L10N-01, FE-L10N-03).
- Semantics announce required/optional; not colour alone (FE-A11Y-02,
  FE-A11Y-05, FE-A11Y-07).
- Tokens only (FE-THEME-01). Gallery shows both marks (FE-CONS-03).
- Do not change validation rules or other screens' labels.

## Definition of done

- [x] On Operator, Name and Initials read as required and Contact as optional before Save, in light, dark and outdoor, at 100 and 200 percent text, without clipping.
- [x] Unmarked fields elsewhere look as they do today.
- [x] Tests: gallery + goldens include both marks; Operator shows the marks before Save; a11y matcher on the field; `copy_test.dart` lists the new keys.
