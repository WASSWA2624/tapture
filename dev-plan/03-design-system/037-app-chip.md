# 037 — Chip and chip row

**Phase** 03 · Design system  |  **Depends on** [031](031-theme-assembly.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The compact value display the context bar, filter bar and multi-choice fields are all built from: a chip in plain,
selectable and dismissible forms, and a row that lays chips out with overflow handling.

## Files

- `frontend/lib/core/widgets/app_chip.dart` (new)

## Contract

```dart
class AppChip extends StatelessWidget {
  final String label; final IconData? icon; final bool selected; final VoidCallback? onTap, onDismiss;
}
class AppChipRow extends StatelessWidget { final List<AppChip> chips; final bool scrollable; }
```

## Steps

1. Implement the plain, selectable and dismissible variants from one widget; a chip with neither callback is not
   interactive and takes no tap target.
2. `AppChipRow` wraps when `scrollable` is false and scrolls horizontally when it is true, in both cases without
   clipping a label.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- Gallery entry covering plain, selected, dismissible and overflowing rows, plus goldens in light, dark and outdoor
  (FE-CONS-03).
- Selection carries a tick or shape as well as a tint (FE-A11Y-05).

## Definition of done

- [ ] The context bar and filter bar are assembled from this and define no chip of their own.
- [ ] A long chip label at 200 percent text scale truncates or wraps rather than clipping.
- [ ] Tests: goldens of every variant and an overflowing row in light, dark and outdoor; widget tests that tap selects
      and dismiss removes.
