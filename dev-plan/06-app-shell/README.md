# 06 — Application shell

Navigation, the always-visible status line, and the frame every feature plugs into.

Tasks 072–328 (9). Each file is a standalone implementation prompt.

- [x] [072 — Router, route table and guards](072-router-setup.md)
- [x] [073 — Adaptive navigation shell](073-nav-shell.md)
- [x] [074 — First-run flow](074-first-run.md)
- [x] [075 — Global status line and overflow menu](075-status-line.md)
- [x] [076 — Global error and crash recovery screen](076-global-error-page.md)
- [x] [317 — Fix navigation icons and the Capture tab state](317-fix-navigation-icons-and-capture-state.md)
- [x] [324 — Fix the project home count navigation](324-fix-count-card-navigation.md)
- [x] [325 — Show the project list in the expanded list pane](325-show-projects-in-list-pane.md)
- [x] [328 — Show the project count on the Projects destination](328-show-project-count-on-destination.md)

## As built

Reproduce 072–076 in order against the design-system catalogue (phase 03) and foundation services (phase 02). Chrome is a messaging-client shell: compact header uses the light primary fill (`#075E54`) with `onPrimary` ink; dark uses `surfaceVariant`; medium/expanded keep a surface rail (dark-rail treatment on light desktop). Destination icons are folder / camera / list / settings. Capture stays visually dominant by size.

The **app title bar is `StatusLine`**, not a page `AppBar`. Shell routes set `AppPage.showAppBar: false`. Visible title-bar controls are icon-only (wordmark, optional `AppIconButton`s). Labelled commands sit in `AppOverflowMenu` (vertical three-dots, extreme right). `AppPage.overflow` appends the same control on screens that still show an app bar (gallery, first-run, error page).

| Task | What to leave behind |
| :--- | :--- |
| 072 | `routerProvider` + `AppRoutes` + `appGuards()` in `router.dart` / `route_guards.dart` |
| 073 | `NavShell` — bar < 600, rail ≥ 600, rail + list pane ≥ 1024 when the destination `hasList` |
| 074 | `FirstRunScreen` + `_firstRun` as the first guard |
| 075 | `StatusLine` (brand + ⋮), `AppOverflowMenu` / `AppOverflowAction`, `OfflineBanner`, `AppPage.actions` icon-only + `AppPage.overflow` |
| 076 | `GlobalErrorPage` as the `ErrorBoundary` fallback around `MaterialApp.router` |
