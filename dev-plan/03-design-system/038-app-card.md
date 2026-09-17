# 038 — Card, list tile and section header

**Phase** 03 · Design system  |  **Depends on** [030](030-color-tokens.md), [031](031-theme-assembly.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three containers every list and detail screen is built from: the grouped-content card, the single row that projects,
records, templates and datasets all render through, and the group heading used inside lists and forms.

## Files

- `frontend/lib/core/widgets/app_card.dart` (new)
- `frontend/lib/core/widgets/app_list_tile.dart` (new)
- `frontend/lib/core/widgets/app_section_header.dart` (new)

## Contract

```dart
class AppCard extends StatelessWidget {
  final Widget child; final EdgeInsets? padding; final VoidCallback? onTap; final int elevationLevel;
}
class AppListTile extends StatelessWidget {
  final Widget? leading, trailing; final String title; final String? subtitle;
  final AppStatusPill? status; final bool dense, selected; final VoidCallback? onTap, onLongPress;
}
class AppSectionHeader extends StatelessWidget { final String title; final Widget? action; }
```

## Steps

1. `AppCard` takes its padding, radius and surface treatment from `Elevation.surface`, and becomes tappable only when
   `onTap` is given.
2. `AppListTile` supports dense and comfortable densities, a status pill slot, selection state for multi-select lists,
   and long-press.
3. `AppSectionHeader` renders the heading from the `section` type role with an optional trailing action.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- All three get a gallery entry covering each density and state, plus goldens in light, dark and outdoor (FE-CONS-03).
- Projects, records, templates and datasets must all be expressible with `AppListTile`; a feature-local row is a review
  rejection (FE-CONS-06).
- Long-press selects and tap opens; no other gesture is bound here (FE-CONS-10).

## Definition of done

- [ ] Lists and detail sections share one container, and all four entity lists share one row.
- [ ] Selection and status are readable without relying on colour.
- [ ] Tests: goldens of the card, of the row in dense, comfortable, selected, with-status and with-trailing forms, and
      of the section header, each in light, dark and outdoor; widget test that long-press selects and tap opens.
