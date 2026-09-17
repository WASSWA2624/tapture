# 121 — Capture screen shell and inline template fields

**Phase** 12 · Capture  |  **Depends on** [033](../03-design-system/033-app-page.md), [034](../03-design-system/034-app-button.md), [089](../09-templates/089-field-type-registry.md), [115](../11-context/115-context-bar.md), [120](120-capture-session-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The capture screen assembled from the specification: context bar, photo tray, caption, identifier, the two save
actions, and a section where known template values can be typed during capture instead of waiting for review.

## Files

- `frontend/lib/features/capture/presentation/capture_screen.dart` (new)
- `frontend/lib/features/capture/presentation/inline_fields_section.dart` (new)

## Steps

1. Lay out compact first; medium and expanded put the tray and the form side by side.
2. Keep both save actions within one-thumb reach on a large phone, with the deferred save as the visually primary one.
3. Build the inline section from the field type registry (154), showing identity and required fields only, with the
   rest behind a closed "More fields".
4. Nothing on the screen is mandatory except one piece of evidence.

## Constraints

- The size class comes from `core/`; the screen never measures the viewport itself (FE-RESP-02).
- One primary action, largest and in the lower third (FE-SIMP-01); additional attributes stay collapsed (FE-SIMP-06).
- The section renders each field through the registry's widget; it never switches on field type itself (FE-CONS-01).

## Definition of done

- [ ] Nothing on the screen is mandatory except one piece of evidence.
- [ ] A fully manual project can be captured entirely on this screen without opening review.
- [ ] Tests: widget test of `capture_screen.dart` at compact, medium and expanded widths at 200 percent text scale; widget test of `inline_fields_section.dart` covering no fields, required-only, "More fields" expanded, and a field whose value fails validation.
