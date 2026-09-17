# 044 — Form scaffold, validation display and focus behaviour

**Phase** 03 · Design system  |  **Depends on** [034](034-app-button.md), [035](035-app-text-field.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The form frame plus the keyboard behaviour that makes it usable in one hand: consistent field spacing, an error summary,
a submit bar, unsaved-changes guarding, next-field traversal, dismissal on scroll, and keeping the focused field clear
of the keyboard.

## Files

- `frontend/lib/core/widgets/forms/app_form.dart` (new)
- `frontend/lib/core/widgets/forms/focus_actions.dart` (new)
- `frontend/lib/core/widgets/forms/keep_focused_visible.dart` (new)

## Contract

```dart
class AppForm extends StatefulWidget {
  final List<Widget> fields; final String submitLabel;
  final Future<void> Function() onSubmit; final bool guardUnsaved;
}
extension FocusActions on BuildContext { void dismissKeyboard(); void focusNext(); }
class KeepFocusedVisible extends StatelessWidget { final Widget child; }
```

## Steps

1. `AppForm`: token field spacing, an error summary at the top listing every invalid field, a submit bar that shows the
   button's busy state during `onSubmit`, and an unsaved-changes prompt when `guardUnsaved` is set.
2. `FocusActions`: dismiss the keyboard on scroll, and advance focus field to field in visual order.
3. `KeepFocusedVisible`: scroll the focused field above the keyboard inset as focus moves.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- `AppForm` and the error summary get a gallery entry and goldens in light, dark and outdoor (FE-CONS-03).
- Traversal order matches visual order, and switch access reaches every action including submit (FE-A11Y-06).
- No layout inside the form assumes the keyboard is closed (FE-RESP-06).

## Definition of done

- [ ] Leaving a dirty form always prompts, on every screen that uses `AppForm`.
- [ ] A long form stays usable on a compact phone with the keyboard open; the focused field is never hidden behind it.
- [ ] Submitting twice runs `onSubmit` once.
- [ ] Tests: widget test of the unsaved-changes guard; widget test that focus advances in visual order and the focused
      field stays visible under a simulated keyboard inset; goldens of the form with and without the error summary in
      light, dark and outdoor.
