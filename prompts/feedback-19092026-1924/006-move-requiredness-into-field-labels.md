# 006 — Move requiredness into field labels

**Feedback:** FBK0000013 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **Depends on:** —

## Goal
A marked text field says whether it is required or optional in its label, for example "Name (required)"
and "Description (optional)", both while empty (as the placeholder) and once floated. There is no
separate caption. This holds for every marked field in the app, in light, dark and outdoor, at compact,
medium and expanded widths, and at 200 percent text.

## Evidence
- FBK0000013 (in part): the reporter asks for the required and optional marks to sit in the label or
  placeholder in brackets, as in "Name (required)", for every input. `screenshots/FBK0000013.png` shows
  New project with Name, Description and Organisation, each with "Required" or "Optional" on a separate
  line under the box. Android, mobile, compact, portrait, system dark, route `/projects/new`.
- Root cause: `AppTextField` sets `labelText: field.label` (`frontend/lib/core/widgets/fields/app_text_field.dart:233`)
  and renders requiredness as a caption through `_supportingCopy` (`:347-378`), using `Copy.fieldRequired`
  and `Copy.fieldOptional` (`frontend/lib/core/copy/copy.dart:125-128`). That caption design came from
  task 291.
- `AppEmailField` and `AppPhoneField` pass `requiredness` through to `AppTextField`, so one change covers
  every marked field: Operator, project create, edit and settings, and the typed-name confirmation.

## Scope
- Change:
  - `copy.dart`: add `fieldLabelRequired(String label)` and `fieldLabelOptional(String label)` as `Intl`
    messages with a `label` placeholder ("{label} (required)", "{label} (optional)"). Remove
    `fieldRequired` and `fieldOptional` if nothing else uses them.
  - `app_text_field.dart`: build `labelText` from those messages when `requiredness` is not `unmarked`.
    `_supportingCopy` then carries the helper only, and the `unmarked` path is unchanged.
  - Tests: `frontend/test/core/widgets/fields/app_text_field_test.dart`, `app_email_field_test.dart`,
    `app_phone_field_test.dart`, `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`
    and `frontend/test/core/copy/copy_test.dart`.
  - Goldens, as listed in Verification.
- Do not change: the `FieldRequiredness` enum or its default (`unmarked`), validation, error text,
  counters, dictation (008), or fields other than `AppTextField` and its wrappers.

## Rules
- FE-CONS-01: one change in `AppTextField`; screens keep passing `requiredness`.
- FE-L10N-03: never concatenate. Use a placeholder message, so the word order can change per language.
- FE-L10N-01, FE-L10N-02 and FE-L10N-06: `Copy` keys that name meaning, and labels that survive a 35
  percent expansion.
- FE-A11Y-02 and FE-A11Y-05: the semantic label includes the mark, so requiredness is not colour-only.
- FE-A11Y-03 and FE-RESP-06: long labels wrap or ellipsise without clipping the field at 200 percent.
- FE-CONS-03: update the gallery's required and optional samples (`widget_gallery_screen.dart:467-473`).

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 03-design-system move-requiredness-into-field-labels "Move requiredness into field labels"`
   (FE-FLOW-08).
2. Add the two messages, and change the label and supporting-copy logic.
3. Tests:
   - a required field's label reads "Name (required)" both empty and focused, with no "Required" caption;
   - an optional field with a helper shows "(optional)" in the label and the helper below it;
   - an unmarked field is unchanged;
   - the semantics include the mark;
   - no overflow at 360 dp and 200 percent text.
4. Regenerate the affected goldens.

## Human review
⛔ Stop before step 2 and ask:
- Task 291 put the marks in a caption. The reporter wants them in the label. Use "(required)" and
  "(optional)" in brackets, or an asterisk for required with nothing for optional? Recommend brackets
  for both, as the reporter asked; an asterisk needs a legend (FE-SIMP-10).
Proceed only with an explicit answer. If the answer is "proceed", use brackets for both.

## Acceptance criteria
- [ ] New project shows "Name (required)", "Description (optional)" and "Organisation (optional)", with
      no caption under the boxes.
- [ ] Operator, project details and project settings show the same pattern.
- [ ] A screen reader announces the mark with the label.
- [ ] Fields fit at 360 dp, in landscape and at 200 percent text, in light, dark and outdoor.
- [ ] FBK0000013's marks part is resolved. Dictation is 008.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate with `--update-goldens` only `app_text_field_*`, `app_email_field_*`, `app_phone_field_*`
  and `app_form_*` under `frontend/test/design_system/`, plus any gallery golden the run reports. List
  every file regenerated.
