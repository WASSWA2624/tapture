# 075 — Global status line and offline banner

**Phase** 06 · Application shell  |  **Depends on** [025](../02-foundation/025-connectivity-service.md), [037](../03-design-system/037-app-chip.md), [041](../03-design-system/041-app-dialog-service.md), [073](073-nav-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A permanent one-line strip in the shell showing where the user is and what is pending, each segment a link, plus the
banner that explains offline working on the transition into `NetworkState.offline`. Neither ever blocks, dialogs or
steals focus.

## Files

- `frontend/lib/app/widgets/status_line.dart` (new)
- `frontend/lib/app/widgets/offline_banner.dart` (new)
- `frontend/lib/app/nav_shell.dart` (edit)

## Contract

```dart
class StatusLine extends ConsumerWidget { const StatusLine({super.key}); }
class OfflineBanner extends ConsumerWidget { const OfflineBanner({super.key}); }
```

## Steps

1. Segments, as `AppChip`s in one `AppChipRow`: current project and context, pinned template, network state,
   unprocessed count. Each tap navigates through `AppRoutes` to the thing the segment names.
2. Read the network state from `connectivity_service.dart`, which already folds the manual override in, and label
   offline-by-choice differently from offline-by-radio.
3. Counts come from watch queries, so the line updates itself with no refresh call and no timer.
4. The banner uses `AppBanner`, appears only on a transition into offline, is dismissible, and reappears only on the
   next transition — not on rebuild and not on navigation.
5. Both sit above the page body in the shell; the offline message is the specification's explanation, not an error.

## Constraints

- Every segment carries an icon and text; state is never conveyed by colour alone (FE-A11Y-05, FE-THEME-05).
- Strings come from the localisation layer, not literals in the widget (FE-L10N-01).
- One source of truth: the line derives its counts, it caches nothing (FE-STATE-06, FE-STATE-08).

## Definition of done

- [x] A user can answer "where am I and what is queued" without leaving the current screen, and every segment is a link.
- [x] Going offline shows the explanation once and never interrupts capture with a dialog.
- [x] Dismissing the banner keeps it dismissed until the next offline transition.
- [x] Tests: `frontend/test/app/widgets/status_line_test.dart` uses a fake connectivity source and stub counts to assert
  every segment and its navigation; `frontend/test/app/widgets/offline_banner_test.dart` drives
  online → offline → online and asserts exactly one appearance per transition and that dismissal persists within it.
