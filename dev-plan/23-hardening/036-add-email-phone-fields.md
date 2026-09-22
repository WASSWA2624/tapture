# 036 — Add email phone fields

**Phase** 23 · Hardening  |  **Depends on** [003](../03-design-system/003-design-system.md), [035](035-mark-required-optional-fields.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The catalogue has reusable email and phone fields that compose
`AppTextField`: correct keyboard, no dictation, optional by default. They
appear in the widget gallery. Operator still uses a single Contact field.

## Files

- `frontend/lib/core/widgets/fields/app_email_field.dart`
- `frontend/lib/core/widgets/fields/app_phone_field.dart`
- `frontend/lib/core/widgets/fields/app_text_field.dart`
- `frontend/lib/core/widgets/widgets.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/fields/app_email_field_test.dart`
- `frontend/test/core/widgets/fields/app_phone_field_test.dart`
- `frontend/test/design_system/app_email_field/gallery_golden_test.dart`
- `frontend/test/design_system/app_phone_field/gallery_golden_test.dart`
- `frontend/test/design_system/catalogue_golden_test.dart`

## Constraints

- Compose `AppTextField`; do not fork a field (FE-CONS-01).
- One public type per file, documented (FE-STR-06, FE-CODE-12).
- Caller passes the label; widgets do not decide validation (FE-L10N-01).
- Contact, not secrets: no obscure, no secure storage (FE-SEC-01).
- Tokens, 48dp, labelled, 200 percent text (FE-THEME-01, FE-A11Y-01–03).
- Do not change Operator storage or the Contact field.

## Definition of done

- [x] Gallery shows email and phone in empty, filled, error and disabled, light, dark and outdoor, at 100 and 200 percent text without clipping.
- [x] Neither field offers a microphone.
- [x] Operator Contact is unchanged.
- [x] Tests: keyboard type, no microphone under `DictationScope`, 48dp, semantic label; goldens in light, dark and outdoor.
