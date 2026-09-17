# 035 — Text, number, date and search fields

**Phase** 03 · Design system  |  **Depends on** [023](../02-foundation/023-clock-service.md), [030](030-color-tokens.md), [031](031-theme-assembly.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The text-entry family: one base text input with every slot later fields need, and the three controls built on it —
numeric entry with units and range, one temporal control covering date, time and date-time, and the debounced search
input. No feature reaches for a raw `TextFormField` after this task.

## Files

- `frontend/lib/core/widgets/fields/app_text_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_number_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_date_field.dart` (new)
- `frontend/lib/core/widgets/app_search_field.dart` (new)

## Contract

```dart
class AppTextField extends StatelessWidget {
  final String label; final String? hint, helper, errorText; final TextEditingController controller;
  final int? maxLines; final Widget? trailing; final bool clearable;
}
class AppNumberField extends StatelessWidget {
  final String label; final String? unit; final num? min, max; final bool decimal; final ValueChanged<num?> onChanged;
}
enum DateFieldMode { date, time, dateTime }
class AppDateField extends StatelessWidget {
  final String label; final DateFieldMode mode; final DateTime? value; final bool autoFilled;
  final ValueChanged<DateTime?> onChanged;
}
class AppSearchField extends StatelessWidget {
  final String hint; final ValueChanged<String> onChanged; final VoidCallback? onSubmitted;
  final Duration debounce; final int? resultCount;
}
```

## Steps

1. `AppTextField`: label, hint, helper and error text, prefix and suffix slots, clear button, single and multi-line
   modes, character counter, and a trailing slot for the microphone or scanner. Errors arrive from the shared
   validation display rather than being formatted here.
2. `AppNumberField`: numeric keyboard, non-numeric characters rejected as they are typed, the template's unit shown
   as a suffix, and out-of-range values rendered in the shared error style.
3. `AppDateField`: formatted value with a picker, clearing, defaulting to now from the clock service, and the auto
   affordance on values that were filled in rather than typed.
4. `AppSearchField`: debounce at the interval in `AppConstants`, separate changed and submitted callbacks, and a result
   count slot.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- All four get a gallery entry covering empty, filled, error, disabled and multi-line states, and goldens in light,
  dark and outdoor (FE-CONS-03).
- Dates, times and numbers are formatted by the shared `intl` helpers against the active locale, never hand-built
  (FE-CONS-09, FE-L10N-04).
- Time comes from the clock service, never `DateTime.now()` at the call site (FE-STR-11).

## Definition of done

- [ ] Later fields and screens compose these instead of `TextFormField`; typing a letter into a number field is
      impossible and out-of-range values show the shared error style.
- [ ] Auto-filled dates are visibly distinct from typed ones in all three modes.
- [ ] Search fires once per debounce window, not once per keystroke; records, datasets and template pickers all use it.
- [ ] Tests: widget tests for error display, clearing, non-numeric rejection and range violation; widget test of the
      date field against a frozen clock covering all three `DateFieldMode` values; widget test of the debounce window
      under fake async; goldens of all four in light, dark and outdoor.

## Out of scope

- Validation rules themselves; the fields render errors handed to them, they do not decide them.
