# 073 — Adaptive navigation shell

**Phase** 06 · Application shell  |  **Depends on** [032](../03-design-system/032-breakpoints.md), [033](../03-design-system/033-app-page.md), [072](072-router-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The four-destination shell wrapping every screen: bottom bar under 600dp, navigation rail from 600dp, rail plus a
persistent list pane from 1024dp when the destination has a list. Each destination keeps its own navigation stack
across switches and across a size class change.

Chrome follows the messaging-client shell already on the tokens: compact header is the status line (075); the bar
sits on `surface` with an outline hairline; the light-desktop rail uses the dark panel (`AppColors.dark.surfaceVariant`)
and accent (`AppColors.dark.primary`) so selected icons stay visible. Outdoor light keeps the high-contrast rail
(not the inverted desktop rail).

## Files

- `frontend/lib/app/nav_shell.dart` (new)
- `frontend/lib/app/router.dart` (edit — wrap the four branches in `NavShell`)

## Contract

```dart
class NavShell extends StatelessWidget {
  const NavShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
}
```

Destinations, in order, with `Copy` labels:

| Index | Label | Outline / filled icon | Dominant | List pane |
| ---: | :--- | :--- | :---: | :---: |
| 0 | `Copy.navProjects` | `folder_outlined` / `folder` | | yes |
| 1 | `Copy.navCapture` | `photo_camera_outlined` / `photo_camera` | yes (48+ dp, size only) | |
| 2 | `Copy.navRecords` | `list_alt_outlined` / `list_alt` | | yes |
| 3 | `Copy.navMore` | `settings_outlined` / `settings` | | |

Keys: `nav-bar`, `nav-rail`, `nav-pane`, `nav-body-slot`, `nav-icon-$index`.

## Steps

1. Wrap the four branches in `StatefulShellRoute.indexedStack` inside `router.dart`, so each branch owns a
   navigator and its stack survives a switch. `NavShell` is the container; it does not own routes.
2. Select the layout with `ResponsiveBuilder`; the shell never compares a `MediaQuery` width itself.
3. Compact: `StatusLine` + `OfflineBanner` in a top `SafeArea`, body, `NavigationBar`.
4. Medium: same header, `NavigationRail` with `NavigationRailLabelType.all`, no pane.
5. Expanded: rail plus a `Sizes.listPane` column (title, `AppSearchField`, `AppEmptyState`) only when
   `_destinations[index].hasList` is true. Capture and More drop the pane.
6. Invert the desktop rail only when brightness is light **and** the palette is not outdoor. Selected
   glyphs use `AppColors.dark.primary` on that rail, otherwise `context.colors.primary`. Capture stays
   larger (`Space.x8`) but uses unselected ink unless it is the selected destination.

## Constraints

- Four destinations, no fifth (FE-SIMP-02).
- Size classes come from `ResponsiveBuilder`; no width comparison outside `core/widgets/responsive/` (FE-RESP-02).
- Navigation adapts, state does not: a size class change loses no stack and no in-progress input (FE-RESP-03).
- Tokens only. Do not restyle the bar or rail with feature `Color` / `TextStyle` literals.

## Definition of done

- [x] Rotating a tablet moves the navigation between bar and rail without losing the stack or a half-typed field.
- [x] Leaving a destination and returning shows the previous stack, not its root.
- [x] Capture is the dominant destination at all three widths.
- [x] Expanded Capture and More hide the list pane; Projects and Records keep it.
- [x] Tests: `frontend/test/app/nav_shell_test.dart` widget-tests 400, 800 and 1200dp for bar, rail and rail-plus-pane,
  and asserts stack preservation across both a destination switch and a width change.
