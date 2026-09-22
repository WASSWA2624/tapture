# 038 — Split operator contact fields

**Phase** 23 · Hardening  |  **Depends on** [007](../07-account-and-settings/007-account-and-settings.md), [035](035-mark-required-optional-fields.md), [036](036-add-email-phone-fields.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Operator collects optional Email and optional Phone. A stored
`operatorContact` with `@` becomes email, otherwise phone, and saves
stop writing the old key. Feedback still gets one derived contact string.

## Files

- `frontend/lib/core/constants/app_constants.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/widgets/forms/app_form.dart`
- `frontend/lib/features/settings/domain/operator_profile.dart`
- `frontend/lib/features/settings/data/settings_store.dart`
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart`
- `frontend/lib/features/feedback/presentation/feedback_context_capture.dart`
- `frontend/test/core/app_constants_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/db/tables/device_profile_test.dart`
- `frontend/test/core/widgets/forms/app_form_test.dart`
- `frontend/test/features/settings/domain/operator_profile_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`

## Constraints

- Use `AppEmailField` and `AppPhoneField`; do not invent Operator inputs
  (FE-CONS-01).
- Migrate beside the old value on read; a save writes the new keys and
  removes `operatorContact`; never drop unknown preference keys
  (FE-STATE-07, FE-SEC-08).
- Email and phone are not secrets; they stay on the device-profile row
  (FE-SEC-01, FE-SEC-07).
- Empty email and empty phone are valid; format-check a non-empty email
  for `@` only (FE-SIMP-08).
- Do not add email or phone columns to the feedback workbook.

## Definition of done

- [x] Operator shows optional Email and optional Phone, no Contact field.
- [x] Save with only a name and initials still succeeds.
- [x] A stored `ada@x` contact becomes email after one load/save; a
      phone-like contact becomes phone.
- [x] New feedback entries still populate `operatorContact` (email if
      set, else phone).
- [x] Tests: migrate/save at the domain layer; widget tests for the two
      fields, optional marks, name-and-initials-only save, and invalid
      email copy.
