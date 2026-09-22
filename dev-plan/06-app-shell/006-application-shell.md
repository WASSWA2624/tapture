# 006 — Application shell: navigation, the status line and the frame every feature plugs into

**Phase** 06 · Application shell  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The frame every later screen mounts inside. `routerProvider` installs GoRouter — pinned at `^17.5.0`, which still
carries route `metadata` — with one declared route table, typed `AppRoutes` helpers that are the only way a screen
names a path, and a single `redirect` composed from `appGuards()`: first run, project scope, then resume-intended. A
deep link resolves to the screen it names; a project-scoped link with no project open diverts to the picker carrying
the intended location as `from=` and resumes there once `OpenProjectId` is set; an unknown path renders
`AppErrorState` with a way back rather than a blank page; and a debug-only `/_gallery` bypasses the first-run gate.
Four `StatefulShellRoute.indexedStack` branches — Projects, Capture, Records, More — each own a navigator, and
`NavShell` selects their chrome through `ResponsiveBuilder`: a bottom bar under 600dp, a navigation rail from 600dp,
and that rail plus a persistent list pane from 1024dp where the destination has a list, every branch keeping its
stack and its half-typed input across a destination switch and a size-class change. Above the body sits `StatusLine`,
the app's only title bar — wordmark, `Spacer`, and a trailing vertical three-dots `AppOverflowMenu` whose rows,
project and context, pinned template, network state and unprocessed count, are the only labelled commands in the
chrome and each navigate through `AppRoutes` — with `OfflineBanner` beneath it explaining a transition into offline
once. That menu is also `AppPage.overflow`: a catalogue widget in `core/widgets/` with `AppOverflowAction` as its row
type, a gallery entry, `Copy.overflowMenu` and light, dark and outdoor goldens, so visible page `actions` everywhere
stay icon-only. One skippable first-run screen asks for an operator name and nothing else before capture, behind one
persisted `TextStore` flag the first guard reads. `GlobalErrorPage` is the `ErrorBoundary` fallback wrapped around
`MaterialApp.router`, offering restart, a redacted log export and the recycle bin, and no way to destroy work.
Later field-feedback work is included: Capture-tab icon state, count-card navigation, the expanded Projects list
pane, the Projects destination count, the shell back button and title, and the remaining projects-shell feedback.

## Files

Routing and guards:

- `frontend/lib/app/router.dart` (new; changed by the shell step to wrap the four branches in `NavShell`)
- `frontend/lib/app/route_guards.dart` (new, `part of 'router.dart'`; changed by the first-run step)
- `frontend/lib/app/app.dart` (changed — `routerConfig: ref.watch(routerProvider)`, then `ErrorBoundary` in `builder`)

The navigation shell:

- `frontend/lib/app/nav_shell.dart` (new; changed to host `StatusLine` + `OfflineBanner` above the body)

First run:

- `frontend/lib/features/onboarding/presentation/first_run_screen.dart` (new)

The status line, the banner and the overflow menu:

- `frontend/lib/app/widgets/status_line.dart` (new)
- `frontend/lib/app/widgets/offline_banner.dart` (new)
- `frontend/lib/core/widgets/app_overflow_menu.dart` (new)
- `frontend/lib/core/widgets/app_overflow_action.dart` (new, `part of` the menu — do **not** name this `*item*`;
  FE-CODE-03 bans `item`)
- `frontend/lib/core/widgets/app_page.dart` (changed — `overflow`, icon-only `actions` docs, append the menu)
- `frontend/lib/core/widgets/widgets.dart` (changed — export the menu)
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart` (changed — overflow on the gallery `AppPage` plus a
  buttons-section sample)
- `frontend/lib/core/copy/copy.dart` (changed — `Copy.overflowMenu = 'More options'`)

The last-resort screen:

- `frontend/lib/app/widgets/global_error_page.dart` (new)

Follow-up files:

- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/widgets/status_line_test.dart`
- `dev-plan/06-app-shell/073-nav-shell.md`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/project_delete_action.dart`
- `frontend/lib/features/templates/presentation/` local `_templatesRoot` constants
- `frontend/test/app/router_test.dart`
- `frontend/test/core/widgets/app_page_test.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart` (new)
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_filter.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/test/app/nav_pane_golden_test.dart` (new)
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_filter_test.dart` (new)
- `frontend/lib/features/projects/presentation/current_project.dart`
- `frontend/test/app/nav_destination_golden_test.dart`
- `frontend/test/features/projects/presentation/current_project_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/lib/app/shell_title.dart`
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/core/widgets/shell_header_scope.dart`
- `frontend/lib/core/widgets/app_list_tile.dart`
- `frontend/lib/features/projects/presentation/project_list_actions.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/settings/domain/setting_keys.dart`


## Contract

```dart
typedef Router = GoRouter;
final Provider<GoRouter> routerProvider;

abstract final class AppRoutes {
  static const projects = '/projects';
  static const fromQuery = 'from';
  static const firstRun = '/first-run';
  static const records = '/records';
  static const more = '/more';
  static const templates = '/templates';
  static const queue = '/queue';
  static String project(String id);
  static String capture(String projectId);
  static String record(String id);
}

typedef RouteGuard = String? Function(GoRouterState state, Ref ref);
typedef RouteGuards = List<RouteGuard>;
List<RouteGuard> appGuards(); // [_firstRun, _projectScope, _resumeIntended]

final NotifierProvider<OpenProjectId, String?> openProjectIdProvider;

class NavShell extends StatelessWidget {
  const NavShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
}

class FirstRunScreen extends ConsumerStatefulWidget { const FirstRunScreen({super.key}); }

class FirstRunSnapshot { final bool completed; final bool busy; /* operator name */ }
final firstRunProvider; // TextStore flag `firstRun`; test helper firstRunCompletedOverride()

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

// Stub providers on status_line.dart until 007 · Account and settings, 008 · Projects,
// 011 · Context, 012 · Capture and 013 · Processing replace them:
connectivityServiceProvider, networkStateProvider, offlineByChoiceProvider,
statusProjectLabelProvider, statusContextProvider, statusTemplateLabelProvider,
unprocessedCountProvider, networkOnlineOverride();
```

`appGuards` takes `Ref`, not `WidgetRef` — `WidgetRef` is sealed and needs a widget.

`_firstRun`: if the flag is down and the path is not `/first-run` (and not debug `/_gallery`), redirect to
`AppRoutes.firstRun`. If the flag is up and the path is `/first-run`, redirect to capture.

Destinations, in order, with `Copy` labels:

| Index | Label | Outline / filled icon | Dominant | List pane |
| ---: | :--- | :--- | :---: | :---: |
| 0 | `Copy.navProjects` | `folder_outlined` / `folder` | | yes |
| 1 | `Copy.navCapture` | `photo_camera_outlined` / `photo_camera` | yes (48+ dp, size only) | |
| 2 | `Copy.navRecords` | `list_alt_outlined` / `list_alt` | | yes |
| 3 | `Copy.navMore` | `settings_outlined` / `settings` | | |

Keys: `nav-bar`, `nav-rail`, `nav-pane`, `nav-body-slot`, `nav-icon-$index`; `status-overflow` on the title-bar menu;
`app-page-overflow` on `AppPage`; `app-overflow` on catalogue and gallery samples. Menu rows: `status-project`,
`status-template`, `status-network`, `status-unprocessed`. Semantic name of the control: `Copy.overflowMenu`.

## Steps

1. Land the router, the route table and the guards. Declare every path once in `router.dart`, reached only through
   `AppRoutes` helpers, and include `/templates` and `/queue` with placeholder pages in the More branch so the status
   overflow has destinations before those screens exist. Declare the four `StatefulShellRoute.indexedStack` branches
   for the shell step to wrap, and mark project-scoped routes with route `metadata` so the guard tests a flag rather
   than a path pattern; that is why `go_router` is pinned at `^17.5.0`, which still carries `metadata` and runs on
   Dart 3.12.2, instead of 18, which pulls `material_ui` and its `@awaitNotRequired`. Compose `redirect` from
   `appGuards()` in order, `_firstRun` first so sign-in can be prepended as a route change rather than a redesign.
   `RouteGuard` takes `Ref` so a `ProviderContainer` can exercise a guard without a widget, and `route_guards.dart`
   is `part of 'router.dart'` so a guard reaches `AppRoutes` without a cycle. Carry the intended location as
   `AppRoutes.fromQuery` on a diversion and return to it once `OpenProjectId` is set; `openProjectIdProvider` is now
   an alias over the `CurrentProject` notifier that 008 · Projects owns, so its readers keep one name. An unknown
   path renders `AppErrorState` from a typed `ValidationFailure` with `onRetry` to `AppRoutes.projects`, and the
   debug-only `/_gallery` (`WidgetGalleryScreen.route`) bypasses first run when `kDebugMode`. Placeholder `_RoutePage`
   composes `AppPage` with `showAppBar: false` so the status line is the only title bar, uses catalogue widgets —
   `AppEmptyState`, `AppSearchField`, `AppListTile` — and `Copy` rather than feature literals, and shows
   `AppSearchField` only when the size class is not expanded, because the expanded list pane already carries search;
   More shows catalogue tiles for Templates and Queue.
2. Land `NavShell`. Wrap the four branches so each owns a navigator whose stack survives a switch; the shell is the
   container and declares no routes. Select the layout with `ResponsiveBuilder`, never a `MediaQuery` width the shell
   compares itself. Compact is `StatusLine` + `OfflineBanner` in a top `SafeArea`, the body, then `NavigationBar`;
   medium keeps that header with a `NavigationRail` at `NavigationRailLabelType.all` and no pane; expanded adds a
   `Sizes.listPane` column of title, `AppSearchField` and `AppEmptyState`, but only where `hasList` is true, so
   Capture and More drop it. Chrome follows the messaging-client shell already on the tokens: the bar sits on
   `surface` with an outline hairline, and the desktop rail is inverted to the dark panel
   (`AppColors.dark.surfaceVariant`) with `AppColors.dark.primary` for selected glyphs only when brightness is light
   **and** the palette is not outdoor, so outdoor keeps its high-contrast rail. Capture stays larger (`Space.x8`) and
   primary-toned in every layout but uses unselected ink unless it is the selected destination. `/capture` is the
   unscoped branch root so the tab works, while `/projects/:id/capture` stays project-scoped in the same branch.
3. Land the first-run flow: one screen between install and first capture, composing `AppPage` + `AppBrandLockup` +
   `AppTextField` + `AppPrimaryAction` + a text `AppButton`, with `Copy.firstRun*` strings, the branded header fill on
   compact and the same widgets in a readable column when wider. It asks for an operator name and nothing else, then
   offers `Copy.firstRunStartProject`, which starts a project from a shipped template, with caption
   `Copy.firstRunStartCaption`, beside `Copy.firstRunSkip`; both stay disabled until the field is non-empty, and
   skipping reaches `/capture` with the name alone. Completion is one persisted
   `TextStore.firstRun` flag the guard reads, the notifier stays private in the screen file, and a test `Override` is
   exported for completed-flag suites. No tour, no wizard, no second step. Title-bar actions on this `AppPage` stay
   icon-only; labelled commands belong in `overflow`. 007 · Account and settings later adopts the stored name onto
   `device_profile.operatorName` when the profile row is empty, and a product decision in the field-feedback pass
   withdrew the screen, `/first-run`, the `_firstRun` guard entry, the flag and its copy, so the app opens on Projects
   and the operator name is now set under More → Operator.
4. Land the status line, the overflow menu and the offline banner. `AppOverflowMenu` is a 48dp `PopupMenuButton` with
   `Icons.more_vert` that shows no row labels closed and always shows `AppOverflowAction.label` and its optional icon
   open; `inverted: true` paints the icon `onPrimary` for the compact light header and a light `AppPage` app bar,
   dark uses `onSurface`, and the sheet is tokens only — outline plus `Radii.md`, elevation 0, transparent shadow.
   `AppPage.actions` stay icon-only `AppIconButton`s with `semanticLabel` and `tooltip`, and a non-empty `overflow`
   appends the menu as the last action, inverted whenever the brightness is not dark because the app bar fill is
   `primary` in light and outdoor. `StatusLine` is `AppBrandLockup` · `Spacer` · `AppOverflowMenu(inverted: compact &&
   !dark)` with no labelled chips on the bar; its rows go to `AppRoutes.project(id)` or `AppRoutes.projects` for
   project and context, `AppRoutes.templates` for the template label, `AppRoutes.more` for network — online, metered,
   offline and offline-by-choice, labelled apart — and `AppRoutes.queue` for `Copy.unprocessedCount(n)`. Compact and
   light fills the bar with `colors.primary` and inverts the lockup; medium and expanded use `surface` or
   `surfaceVariant` with an outline hairline and no inversion. Network comes from `ConnectivityService`, which already
   folds the manual override, and `offlineByChoiceProvider` re-reads `SettingKeys.offlineByChoice` once
   007 · Account and settings owns it; the project label reads the current-project provider from 008 · Projects while
   context, template and unprocessed stay stubs for 011 · Context, 012 · Capture and 013 · Processing. Counts come
   from watch queries, never a cache and never a timer. `OfflineBanner` uses `AppBanner`, appears only on a transition
   into offline, is dismissible, and reappears only on the next transition — not on rebuild and not on navigation.
   The catalogue and gallery name `AppOverflowMenu`, add `_sample('app_overflow_menu')` and light, dark and outdoor
   goldens, and `Copy.overflowMenu` joins `copy_test.dart`'s `_values`.
5. Land `GlobalErrorPage`. Wrap `MaterialApp.router`'s `builder` in `ErrorBoundary` with this page as its fallback, an
   extra optional slot added to the boundary that 002 · Foundation services published, so a build failure anywhere
   lands here; `TaptureApp` already owns theme and `routerProvider`, and no second `MaterialApp` appears. A static
   stack restores the original `ErrorWidget.builder`, so a replacement root may mount the next boundary before the
   previous one disposes. Compose `AppPage` + `AppErrorState` over a typed `Failure` and offer exactly three ways
   forward: restart, which remounts the failed subtree under the existing `ProviderScope` without killing the process
   or discarding unsaved work; export, which writes the dated, device-named log through `exportLog` with redaction
   left in `Logger` and hands it to an injectable `shareFile`, the production default leaving the file on disk until a
   later task approves a share plugin; and the recycle bin, which navigates through `AppRoutes.more` until
   014 · Records owns a route. State in plain language that the work is still on the device
   (`Copy.workStillOnDevice`), and offer no clear-data, no reset and no reinstall.

## Constraints

- Routing lives in `lib/app/`; no feature declares a route, writes a path literal or concatenates a path string
  (FE-STR-02, FE-CODE-09).
- Guards are pure functions over `GoRouterState` and provider reads, and take `Ref` so one runs without a widget
  (FE-STATE-04).
- `typedef Router = GoRouter`, so `router.dart` is named after its first public type, and the first-run notifier stays
  private so that file still holds one public class (FE-STR-06).
- Four destinations, no fifth (FE-SIMP-02).
- Size classes come from `ResponsiveBuilder`; no width comparison outside `core/widgets/responsive/` (FE-RESP-02).
- Navigation adapts, state does not: a size-class change loses no stack and no in-progress input (FE-RESP-03).
- Tokens only. Neither the bar, the rail, the status line nor the menu sheet is restyled with a feature `Color` or
  `TextStyle` literal (FE-THEME-01).
- `AppOverflowMenu` lives in `core/widgets/` because `AppPage` cannot import `app/` (FE-STR-04), which makes it a
  catalogue widget owing a gallery entry, `Copy.overflowMenu` and light, dark and outdoor goldens.
- Visible title-bar buttons have **no** text label; every overflow row **has** one (FE-A11Y-02, FE-A11Y-05).
- The row type is `AppOverflowAction`, never `AppOverflowItem` — `item` is a banned word (FE-CODE-03).
- Strings come from `Copy`, not literals in a widget (FE-L10N-01).
- One source of truth: the status line derives its counts and caches nothing (FE-STATE-06, FE-STATE-08).
- New `core/widgets/` files owe `test/core/widgets/…_test.dart`, the `part` file included (FE-TEST-02).
- First run asks one thing and offers one primary action, and its gate is one entry in the guard chain rather than a
  wizard (FE-SIMP-01, FE-SIMP-04, FE-SIMP-07, §56 rule 4, §71.1).
- The device identifier comes from `device_identity.dart`; no shell screen creates an identity of its own
  (FE-STR-11).
- No control on the error page deletes, purges or resets anything (FE-SIMP-09, FE-SEC-08).
- Every failure the shell shows is rendered from a typed `Failure` through `AppErrorState`; the shell writes no
  bespoke error copy (FE-CONS-11).
- The log export writes the file and takes its share sheet by injection; no share plugin is added to the allowlist
  here (FE-FLOW-06).
- Nothing blocks capture: going offline is explained once in a dismissible banner and never a dialog, first run is
  cleared with one field or skipped, and a failing subtree lands on a page that leaves the app running (rule 3 of the
  standard).

## Definition of done

- [x] Deep linking to a record opens it directly, and no screen builds a path string by hand.
- [x] Opening a capture link with no project selected asks which project, then continues to that capture screen.
- [x] An unknown path renders the shared error state with a way back, never a blank page.
- [x] The debug-only `/_gallery` route reaches the gallery past the first-run gate, and only in a debug build.
- [x] Every shell route composes `AppPage` with `showAppBar: false`, so the status line is the only title bar, and its
      placeholder body uses catalogue widgets and `Copy` rather than feature literals.
- [x] A guard runs against a `ProviderContainer` with no widget in the tree.
- [x] Rotating a tablet moves the navigation between bar and rail without losing the stack or a half-typed field.
- [x] Leaving a destination and returning shows the previous stack, not its root.
- [x] Capture is the dominant destination at all three widths.
- [x] Expanded Capture and More hide the list pane; Projects and Records keep it.
- [x] A new install captures within thirty seconds of clearing the first-run screen, having answered only the
      operator name.
- [x] The first-run gate is one entry in the router guard chain, so sign-in can precede it without editing a later
      screen.
- [x] Skipping the project step still leaves a usable app.
- [x] The title bar shows the wordmark and a trailing ⋮ only; status commands appear after the menu opens.
- [x] A user can answer "where am I and what is queued" from the overflow without leaving the current screen, and
      every row is a link through `AppRoutes`.
- [x] `AppPage.actions` stay icon-only; labelled page commands go through `overflow`.
- [x] Offline by choice reads differently from offline by radio.
- [x] Going offline shows the explanation once and never interrupts capture with a dialog.
- [x] Dismissing the banner keeps it dismissed until the next offline transition.
- [x] A fatal build error renders the error page instead of a red screen, with the app still running.
- [x] No path from that screen can destroy the user's work.
- [x] The exported log reaches a shareable file and contains no record values or credentials.
- [x] Tests: `frontend/test/app/router_test.dart` resolves every declared route plus the not-found path.
- [x] Tests: `frontend/test/app/route_guards_test.dart` asserts diversion and resumption for a project-scoped
      location.
- [x] Tests: `frontend/test/app/nav_shell_test.dart` widget-tests 400, 800 and 1200dp for bar, rail and
      rail-plus-pane, and asserts stack preservation across both a destination switch and a width change.
- [x] Tests: `frontend/test/features/onboarding/presentation/first_run_screen_test.dart` covers the skip path, the
      template path and the completed-flag short-circuit on second launch.
- [x] Tests: `frontend/test/app/widgets/status_line_test.dart` opens `status-overflow` before asserting labels and
      navigation.
- [x] Tests: `frontend/test/core/widgets/app_overflow_menu_test.dart` asserts 48dp, `Copy.overflowMenu`, no visible
      label until open, and `onTap`.
- [x] Tests: `frontend/test/core/widgets/app_overflow_action_test.dart` covers the `part` file's row type, so no new
      `core/widgets/` file ships without a suite.
- [x] Tests: `frontend/test/core/widgets/app_page_test.dart` asserts icon-only actions plus a labelled overflow row.
- [x] Tests: `frontend/test/app/widgets/offline_banner_test.dart` drives online → offline → online.
- [x] Tests: `frontend/test/app/widgets/global_error_page_test.dart` pumps a deliberately throwing subtree, asserts
      the three actions, asserts restart preserves unsaved state, and asserts no destructive action is present.
- [x] Tests: light, dark and outdoor goldens cover the overflow menu, the gallery carries
      `_sample('app_overflow_menu')`, and `copy_test.dart`'s `_values` holds `Copy.overflowMenu`.

### Follow-up work

#### Fix navigation icons and the Capture tab state

- [x] Projects shows a folder in the bar and the rail, and the status line's project item shows the same
      folder.
- [x] With any tab other than Capture selected, the camera is larger but not accent-coloured.
- [x] With Capture selected, it is accent-coloured and filled.
- [x] Tests at 400, 800 and 1200 dp: Capture size dominance; accent only when Capture is selected;
      Projects `folder_outlined` / `folder`; the status line project item is the folder.

#### Fix the project home count navigation

- [x] Each of the four count cards opens a location that names the open project and the filter.
- [x] From each of those lists, the title-bar back control and a pop return to the project home with
      its counts unchanged.
- [x] After opening any of them, the rail and the bottom bar still select Projects.
- [x] Opening Templates or Unprocessed from Settings leaves Settings selected, and tapping Settings
      returns to the settings list rather than a placeholder.
- [x] Old `/queue`, `/exports` and `/templates` links still resolve.
- [x] Tests: `router_test` nested paths, settings-beneath, unknown path, project-scoped divert;
      `project_home_screen_test` card locations, pop, widths and back a11y; `nav_shell_test`
      destination selection.

#### Show the project list in the expanded list pane

- [x] At 1200 dp the pane lists every non-deleted, non-archived project under its search bar, with
      no heading above the search bar.
- [x] Typing in the pane search narrows the list; no match shows an empty state offering
      "Create a project".
- [x] At 1200 dp with at least one project, the body shows the open project and no second copy of
      the list.
- [x] At 1200 dp with no projects, the body shows "Create a project".
- [x] At 400 and 800 dp the list and "Create a project" stay in the body.
- [x] Changing width between 400 and 1200 dp loses neither the typed search nor the open project.
- [x] Tests: pane list, search, clear, no-match, heading gone, Records empty; body create-button
      widths; search and open project across 400↔1200; pane goldens in light, dark and outdoor,
      empty and with three projects.

#### Show the project count on the Projects destination

- [x] With no projects the destination shows no badge; with projects it shows the count.
- [x] Creating, archiving, deleting and restoring updates the badge live.
- [x] The badge appears on the bar at 400 dp and on the rail at 800 and 1200 dp, both orientations.
- [x] Screen readers hear a plural-correct, locale-formatted count.
- [x] The badge meets 4.5:1 in light, dark and outdoor, including on the inverted rail.
- [x] At 200 percent text nothing clips and no label is pushed out.
- [x] In RTL the badge uses the icon's end, not hard right.
- [x] Capture, Records and Settings stay visually unchanged.

#### Shell back and screen title

- [x] `/projects`, `/capture`, `/records` and `/more` show the wordmark and the
      status menu, and no back control.
- [x] Storage, a filtered Records list, project home and project capture show
      one row: back, one title, and that page's actions. No second title row.
- [x] Back from storage lands on Settings, from a project home on the project
      list, and from project capture on that project.
- [x] The row does not overflow at 200 percent text at 400 dp and 1200 dp.
- [x] Tests cover those routes.

#### Resolve projects shell feedback

- [x] Expanded project rows, dividers and more controls stay inside the pane.
- [x] Compact and medium lists still open a project on tap and are not forced
      to 280 dp.
- [x] `Space.x2` sits between a page action and its overflow menu.
- [x] Each width shows `Copy.projectsCreate` once, and that control opens
      `/projects/new`.
- [x] Projects shows no numeric badge; its spoken name is Projects.
- [x] A stored internal route is the first location; `https://` and `/lock`
      open `/projects`.
- [x] Tests cover those cases.




## Follow-up absorbed from 317, 324, 325, 328, 333, 334

### Fix navigation icons and the Capture tab state

Navigation uses widely recognised icons: a folder for Projects everywhere a project is meant. Only the
destination that is actually selected looks selected. Capture stays larger than its neighbours but no
longer wears the selected colour when another tab is active.

Files:

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/app/router.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/widgets/status_line_test.dart`
- `dev-plan/06-app-shell/073-nav-shell.md`

Constraints:

- One icon per concept, from one family, at token sizes (FE-CONS-08, FE-THEME-08).
- Selection is shown by colour, the filled icon and the bar's indicator (FE-A11Y-05, FE-THEME-05).
- Still exactly four destinations (FE-SIMP-02).
- Tokens only; outdoor changes contrast, not shape (FE-THEME-01, FE-THEME-03).
- Do not change the four destinations, their order or labels, the rail inversion rules, the list pane,
  or Capture's size.

### Fix the project home count navigation

Tapping Review, Process, Export or Share on the project home opens a list that belongs to the open
project and can be left again by the platform's own way back. Templates, Unprocessed and Export
history live under Settings so that branch still has the settings list beneath them. Old `/queue`,
`/exports` and `/templates` links redirect to the nested paths.

Files:

- `frontend/lib/app/router.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/project_delete_action.dart`
- `frontend/lib/features/templates/presentation/` local `_templatesRoot` constants
- `frontend/test/app/router_test.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/core/widgets/app_page_test.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`

Constraints:

- Paths are declared once in `router.dart`; feature files keep matching local constants (FE-STR-02,
  FE-CODE-09).
- A push survives a rail-to-bar change (FE-RESP-03).
- Still four destinations — nesting changes paths, not the menu (FE-SIMP-02).
- Leaving a list discards nothing; the back control is keyboard-reachable (FE-SIMP-09, FE-A11Y-06).
- Reuse `AppPage` and `AppIconButton` — 48 dp, semantic label, tooltip (FE-CONS-01, FE-A11Y-01,
  FE-A11Y-02).
- Placeholder bodies stay placeholders.

### Show the project list in the expanded list pane

On expanded widths the list pane lists projects under its search bar, the search bar filters them
by name, and the pane no longer repeats the destination name as a heading. The body stops repeating
that list and shows the open project's home; "Create a project" stays in the body only while there
are no projects. Compact and medium keep the list and the footer in the body.

Files:

- `frontend/lib/features/projects/presentation/project_list_view.dart` (new)
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_filter.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/nav_pane_golden_test.dart` (new)
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_filter_test.dart` (new)

Constraints:

- One `ProjectListView` in the pane and on the screen (FE-CONS-02). Rows stay `AppListTile`
  (FE-CONS-06).
- The pane renders loading, empty, error and offline through `AsyncValueView` (FE-CONS-04).
- `core/` never imports `features/`; the pane is wired in `lib/app/` through the feature barrel
  (FE-STR-04, FE-STR-08).
- Size class comes from `context.sizeClass` (FE-RESP-02). A width change keeps the search text and
  the open project (FE-RESP-03).
- Search matches the project name only, case-insensitive and accent-folded, with no new packages.

### Show the project count on the Projects destination

The Projects destination shows how many active projects sit behind it — on the compact bar and on
the medium and expanded rail — so the menu says how much is there without being opened. The count
is derived from the existing list watch, announced to screen readers, and capped at `99+` on the
badge so 200 percent text cannot push the label out.

Files:

- `frontend/lib/features/projects/presentation/current_project.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/nav_destination_golden_test.dart`
- `frontend/test/features/projects/presentation/current_project_test.dart`
- `frontend/test/core/copy/copy_test.dart`

Constraints:

- Four destinations. A count is not a fifth (FE-SIMP-02). Capture, Records and Settings get no badge.
- No `MediaQuery` width comparison; the same destination badge feeds `_Bar` and `_Rail` (FE-RESP-02).
- Count active projects only, so the number matches what the destination opens onto.
- The count is derived from `projectListProvider`, never stored and never a second query
  (FE-STATE-06).
- ICU plural plus `intl` for the number (FE-L10N-03, FE-L10N-04). The badge caps at `99+`; the
  semantic label keeps the exact count.
- Token colours in all three themes, including the inverted light-desktop rail (FE-THEME-01, FE-THEME-10).
- The badge is a number, never colour alone (FE-THEME-05, FE-A11Y-05). It announces when it changes
  (FE-A11Y-07). In RTL it sits at the icon's end (AlignmentDirectional).

### Shell back and screen title

On every route that is not a branch root, the status line is the only header:
a back control, the screen title, and that page's actions. The four roots keep
the wordmark and the status menu.

Files:

- `frontend/lib/app/shell_title.dart`
- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/core/widgets/shell_header_scope.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/test/app/widgets/status_line_test.dart`

Constraints:

- One header. Roots stay `/projects`, `/capture`, `/records` and `/more`,
  unless a filter query has drilled in (FE-CONS-01, FE-CONS-10).
- Page title and actions publish through `ShellHeaderScope` in `core/`.
  `core/` does not import a feature (FE-STR-04).
- Titles come from `Copy` or the open project's name (FE-L10N-01).
- Back is a 48 dp `AppIconButton`. The title ellipsises at 200 percent
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- System back is unchanged. The status menu's destinations are unchanged.
- Do not outline the back control. Do not remove the root wordmark.

### Resolve projects shell feedback

Clip the expanded project list pane, space title-row actions from overflow,
keep one Create a project control, remove the Projects destination count,
and restore the last internal route on launch.

Files:

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/router.dart`
- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/core/widgets/app_list_tile.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/features/projects/presentation/project_list_actions.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/router_test.dart`
- `frontend/test/core/widgets/app_page_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`

Constraints:

- One `AppListTile`. The pane stays 280 dp (FE-CONS-06, FE-RESP-04).
- One primary create control (FE-SIMP-01). Compact and medium use the footer;
  expanded uses the pane button when rows exist and the empty-state action
  when they do not.
- Restore only a relative internal path, never `/lock` (FE-SEC-06).
- `Copy` for new strings. Tests travel with the change (FE-L10N-01, FE-TEST-01).

## Out of scope

- Sign-in, enrolment and role grants. The app-side steps of 024 · The minimal backend put them in front of the
  first-run gate rather than this phase widening to hold them.
- The screens behind the placeholder routes: templates belong to 009 · Templates, the processing queue to
  013 · Processing and the recycle bin to 014 · Records.
- The real project, context, pinned-template and unprocessed watches behind the status line's stub providers, which
  008 · Projects, 011 · Context, 012 · Capture and 013 · Processing supply.
