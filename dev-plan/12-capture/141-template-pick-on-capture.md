# 141 — Choose or pin a template

**Phase** 12 · Capture  |  **Depends on** [092](../09-templates/092-template-list.md), [121](121-capture-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A sheet listing the project's templates, most recently used first, with the option to pin one for the session or for the
current context level.

## Files

- `frontend/lib/features/capture/presentation/template_picker_sheet.dart` (new)

## Steps

1. Hide the control entirely when the project has a single template.
2. Order by last used, then by name.
3. Offer pinning for the session or for the current context level, per the specification, and remember the pin.

## Constraints

- The last used template is the default; a question with one answer is not asked (FE-SIMP-05).

## Definition of done

- [ ] A single-template project never shows this control.
- [ ] A pinned template is still in force after a save and after a restart.
- [ ] Tests: widget test of `template_picker_sheet.dart` with one, several and no templates, asserting last-used ordering, that a session pin survives a reset, and that a context-level pin applies when that level is re-entered.
