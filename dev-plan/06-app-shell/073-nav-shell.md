# 073 — Adaptive navigation shell

**Phase** 06 · Application shell  |  **Depends on** [032](../03-design-system/032-breakpoints.md), [033](../03-design-system/033-app-page.md), [072](072-router-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The four-destination shell wrapping every screen: bottom bar under 600dp, navigation rail from 600dp, rail plus a
persistent list pane from 1024dp. Each destination keeps its own navigation stack across switches and across a size
class change.

## Files

- `frontend/lib/app/nav_shell.dart` (new)
- `frontend/lib/app/router.dart` (edit)

## Contract

```dart
class NavShell extends StatelessWidget {
  const NavShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
}
```

## Steps

1. Wrap the four branches in `StatefulShellRoute.indexedStack` inside `router.dart`, so each branch owns a
   navigator and its stack survives a switch.
2. Destinations, in order: Projects, Capture, Records, More. Capture is visually dominant — centre position, larger
   target, primary tone — in all three layouts.
3. Select the layout with `ResponsiveBuilder`; the shell never compares a `MediaQuery` width itself.
4. On expanded, the list pane shows the current branch's list and the detail sits beside it, using the same screens.

## Constraints

- Four destinations, no fifth (FE-SIMP-02).
- Size classes come from `ResponsiveBuilder`; no width comparison outside `core/widgets/responsive/` (FE-RESP-02).
- Navigation adapts, state does not: a size class change loses no stack and no in-progress input (FE-RESP-03).

## Definition of done

- [ ] Rotating a tablet moves the navigation between bar and rail without losing the stack or a half-typed field.
- [ ] Leaving a destination and returning shows the previous stack, not its root.
- [ ] Capture is the dominant destination at all three widths.
- [ ] Tests: `frontend/test/app/nav_shell_test.dart` widget-tests 400, 800 and 1200dp for bar, rail and rail-plus-pane,
  and asserts stack preservation across both a destination switch and a width change.
