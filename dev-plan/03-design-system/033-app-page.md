# 033 — Page scaffold

**Phase** 03 · Design system  |  **Depends on** [031](031-theme-assembly.md), [032](032-breakpoints.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The single page frame every later screen composes: app bar with title and optional subtitle, action slot, body, footer
action slot, safe-area and keyboard insets, scroll behaviour and optional pull-to-refresh.

## Files

- `frontend/lib/core/widgets/app_page.dart` (new)

## Contract

```dart
class AppPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Widget? footer;
  final Future<void> Function()? onRefresh;
}
```

## Steps

1. Compose app bar, subtitle line, body slot and footer action slot; attach pull-to-refresh only when `onRefresh` is
   given.
2. Apply `ContentConstraint` and the per-size-class padding automatically so no screen repeats either.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- Gallery entry plus goldens in light, dark and outdoor (FE-CONS-03).
- Notches, gesture bars and the keyboard are handled here, never by a screen (FE-RESP-08); the body always scrolls
  (FE-RESP-06).
- Landscape is supported, and rotation loses nothing in the body (FE-RESP-07).

## Definition of done

- [ ] Every screen in later phases composes `AppPage`; none builds its own `Scaffold`.
- [ ] Pull-to-refresh appears only where refreshing means something.
- [ ] Tests: goldens in light, dark and outdoor at compact, medium and expanded widths; widget test that the body
      scrolls without overflow at 200 percent text scale in both orientations.
