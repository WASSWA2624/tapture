# 036 — Choice, multi-choice and boolean fields

**Phase** 03 · Design system  |  **Depends on** [031](031-theme-assembly.md), [035](035-app-text-field.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The selection family: the shared `Choice<T>` option type, single selection that changes presentation with option count,
multiple selection that shows its values on the closed field, and boolean input as a full-width tile. Settings screens
and boolean template fields end up using the same control.

## Files

- `frontend/lib/core/widgets/fields/choice.dart` (new)
- `frontend/lib/core/widgets/fields/app_choice_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_multi_choice_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_switch_tile.dart` (new)

## Contract

```dart
class Choice<T> { const Choice(this.value, this.label, {this.icon}); final T value; final String label; final IconData? icon; }
class AppChoiceField<T> extends StatelessWidget {
  final String label; final List<Choice<T>> options; final T? value; final ValueChanged<T?> onChanged;
}
class AppMultiChoiceField<T> extends StatelessWidget {
  final String label; final List<Choice<T>> options; final Set<T> value; final ValueChanged<Set<T>> onChanged;
}
class AppSwitchTile extends StatelessWidget {
  final String title; final String? description; final bool value; final ValueChanged<bool> onChanged;
}
```

## Steps

1. `AppChoiceField`: under four options render a segmented control; at four or more open a searchable sheet.
2. `AppMultiChoiceField`: selection sheet with search, select-all and clear, with the current values shown as chips on
   the closed field.
3. `AppSwitchTile`: title, optional description, the whole tile tappable, and a checkbox variant sharing the layout.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- All three get a gallery entry covering the segmented and sheet presentations, empty, partial and full selection, and
  goldens in light, dark and outdoor (FE-CONS-03).
- Selection carries a second signal beyond colour — a tick or shape, not only a tinted background (FE-A11Y-05).
- Option labels come from the user's template and are never translated, matched or normalised (FE-L10N-07).

## Definition of done

- [x] A 200-option list stays usable on a compact screen, and selected values are readable without opening the sheet.
- [x] Settings and boolean template fields share one control.
- [x] Tests: widget tests of the presentation switch either side of the four-option boundary, of select-all and clear,
      and that tapping anywhere on a switch tile toggles it; goldens of all three in light, dark and outdoor.
