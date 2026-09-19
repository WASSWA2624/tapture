# 319 — Move requiredness into field labels

**Phase** 03 · Design system  |  **Depends on** [035](035-app-text-field.md), [291](../23-hardening/291-mark-required-optional-fields.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A marked text field says whether it is required or optional in its label, for example
"Name (required)" and "Description (optional)", both while empty and once floated. There is
no separate caption. Unmarked fields stay as they are.

## Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/widgets/fields/app_text_field.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/widgets/fields/app_text_field_test.dart`
- `frontend/test/core/widgets/fields/app_email_field_test.dart`
- `frontend/test/core/widgets/fields/app_phone_field_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`
- `frontend/test/design_system/` goldens that draw a marked field

## Constraints

- One change in `AppTextField`; screens keep passing `requiredness` (FE-CONS-01).
- Never concatenate. Use a placeholder message so the word order can change per language
  (FE-L10N-03).
- `Copy` keys that name meaning, and labels that survive a 35 percent expansion (FE-L10N-01,
  FE-L10N-02, FE-L10N-06).
- The semantic label includes the mark, so requiredness is not colour-only (FE-A11Y-02,
  FE-A11Y-05).
- Long labels wrap or ellipsise without clipping the field at 200 percent (FE-A11Y-03,
  FE-RESP-06).
- Do not change the `FieldRequiredness` enum or its default, validation, error text, counters,
  dictation, or fields other than `AppTextField` and its wrappers.

## Definition of done

- [x] New project shows "Name (required)", "Description (optional)" and "Organisation
      (optional)", with no caption under the boxes.
- [x] Operator, project details and project settings show the same pattern.
- [x] A screen reader announces the mark with the label.
- [x] Fields fit at 360 dp, in landscape and at 200 percent text, in light, dark and outdoor.
- [x] Tests: a required field's label reads "Name (required)" empty and focused, with no
      "Required" caption; an optional field with a helper shows "(optional)" in the label and
      the helper below; an unmarked field is unchanged; semantics include the mark; no
      overflow at 360 dp and 200 percent text.
