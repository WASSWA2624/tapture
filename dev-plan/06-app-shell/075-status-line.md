# 075 — Global status line and overflow menu

**Phase** 06 · Application shell  |  **Depends on** [025](../02-foundation/025-connectivity-service.md), [033](../03-design-system/033-app-page.md), [034](../03-design-system/034-app-button.md), [041](../03-design-system/041-app-dialog-service.md), [046](../03-design-system/046-copy-helper.md), [047](../03-design-system/047-widget-gallery.md), [048](../03-design-system/048-golden-baselines.md), [073](073-nav-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A permanent one-line **title bar** in the shell: wordmark on the left, a vertical three-dots control on the extreme
right, and nothing labelled in between. Opening the control shows the status commands — project + context, pinned
template, network state, unprocessed count — each a labelled row that navigates through `AppRoutes`.

The same overflow widget is the page-level "more" slot: `AppPage.actions` stay icon-only (no visible text);
`AppPage.overflow` appends `AppOverflowMenu` after those actions. The offline banner still explains
`NetworkState.offline` on the transition in, never as a dialog.

`AppOverflowMenu` lives in `core/widgets/` because `AppPage` cannot import `app/` (FE-STR-04). That makes it a
catalogue widget: gallery entry, `Copy.overflowMenu`, and light/dark/outdoor goldens.

## Files

- `frontend/lib/core/widgets/app_overflow_menu.dart` (new)
- `frontend/lib/core/widgets/app_overflow_action.dart` (new, `part of` the menu — do **not** name this `*item*`;
  FE-CODE-03 bans `item`)
- `frontend/lib/core/widgets/app_page.dart` (edit — `overflow`, icon-only `actions` docs, append the menu)
- `frontend/lib/core/widgets/widgets.dart` (edit — export the menu)
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart` (edit — overflow on the gallery `AppPage` plus a
  buttons-section sample)
- `frontend/lib/core/copy/copy.dart` (edit — `Copy.overflowMenu = 'More options'`)
- `frontend/lib/app/widgets/status_line.dart` (new)
- `frontend/lib/app/widgets/offline_banner.dart` (new)
- `frontend/lib/app/nav_shell.dart` (edit — `StatusLine` + `OfflineBanner` above the body)

## Contract

```dart
final class AppOverflowAction {
  const AppOverflowAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.key,
  });
}

class AppOverflowMenu extends StatelessWidget {
  const AppOverflowMenu({
    super.key,
    required this.items, // List<AppOverflowAction>
    this.inverted = false,
  });
}

class AppPage {
  final List<Widget> actions;          // icon-only; no visible text label
  final List<AppOverflowAction> overflow; // trailing ⋮, omitted when empty
}

class StatusLine extends ConsumerWidget { const StatusLine({super.key}); }
class OfflineBanner extends ConsumerWidget { const OfflineBanner({super.key}); }

// Stub providers on status_line.dart until 081 / 083 / 115 / 141 replace them:
connectivityServiceProvider, networkStateProvider, offlineByChoiceProvider,
statusProjectLabelProvider, statusContextProvider, statusTemplateLabelProvider,
unprocessedCountProvider, networkOnlineOverride();
```

Keys: `status-overflow` on the title-bar menu; `app-page-overflow` on `AppPage`; `app-overflow` on catalogue /
gallery samples. Menu rows: `status-project`, `status-template`, `status-network`, `status-unprocessed`.

Semantic name of the control: `Copy.overflowMenu`.

## Steps

1. Build `AppOverflowMenu` as a 48dp `PopupMenuButton` with `Icons.more_vert`. Closed state shows **no** row labels.
   Open rows always show `AppOverflowAction.label` (and optional icon). `inverted: true` paints the icon
   `onPrimary` for the compact light header and for a light `AppPage` app bar; dark uses `onSurface`. Tokens only;
   outline + `Radii.md` on the sheet; elevation 0 / transparent shadow.
2. `AppPage`: keep `actions` icon-only (`AppIconButton` with `semanticLabel` + `tooltip`, no visible text). When
   `overflow` is not empty, append `AppOverflowMenu` as the last action. Invert the icon when
   `Theme.brightness != Brightness.dark` (the app bar fill is `primary` in light/outdoor).
3. `StatusLine` row: `AppBrandLockup` · `Spacer` · `AppOverflowMenu(inverted: compact && !dark)`. Do **not** place
   labelled chips on the bar. Menu commands:
   - project / context → `AppRoutes.project(id)` or `AppRoutes.projects`
   - template label → `AppRoutes.templates`
   - network (online / metered / offline / offline-by-choice) → `AppRoutes.more`
   - `Copy.unprocessedCount(n)` → `AppRoutes.queue`
4. Compact + light: bar fill is `colors.primary`, lockup inverted. Medium/expanded: `surface` / `surfaceVariant`
   with an outline hairline; lockup not inverted.
5. Read network from `ConnectivityService` (already folds the manual override). Label offline-by-choice differently
   from offline-by-radio. Counts come from watch queries / stub providers — no cache, no timer (FE-STATE-06).
6. `OfflineBanner` uses `AppBanner`, appears only on a transition into offline, is dismissible, and reappears only
   on the next transition — not on rebuild and not on navigation. Both sit above the page body in `NavShell`.
7. Gallery + catalogue: mention `AppOverflowMenu` by name; add `_sample('app_overflow_menu')` and light/dark/outdoor
   goldens. Add `Copy.overflowMenu` to `copy_test.dart` `_values`.

## Constraints

- Visible title-bar buttons have **no** text label. Every overflow row **has** a text label (FE-A11Y-02, FE-A11Y-05).
- Do not name the row type `AppOverflowItem` — `item` is a banned word (FE-CODE-03). Use `AppOverflowAction`.
- Strings come from `Copy`, not literals in the widget (FE-L10N-01).
- One source of truth: the line derives its counts, it caches nothing (FE-STATE-06, FE-STATE-08).
- New `core/widgets/` files owe `test/core/widgets/…_test.dart` (FE-TEST-02), including the `part` file.

## Definition of done

- [x] The title bar shows the wordmark and a trailing ⋮ only; status commands appear after the menu opens.
- [x] A user can answer "where am I and what is queued" from the overflow without leaving the current screen, and
  every row is a link through `AppRoutes`.
- [x] `AppPage.actions` stay icon-only; labelled page commands go through `overflow`.
- [x] Going offline shows the explanation once and never interrupts capture with a dialog.
- [x] Dismissing the banner keeps it dismissed until the next offline transition.
- [x] Tests: `frontend/test/app/widgets/status_line_test.dart` opens `status-overflow` before asserting labels and
  navigation; `frontend/test/core/widgets/app_overflow_menu_test.dart` asserts 48dp, `Copy.overflowMenu`, no visible
  label until open, and `onTap`; `frontend/test/core/widgets/app_page_test.dart` asserts icon-only actions plus a
  labelled overflow row; `frontend/test/app/widgets/offline_banner_test.dart` drives online → offline → online.
