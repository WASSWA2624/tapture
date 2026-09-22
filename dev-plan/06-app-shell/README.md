# 06 — Application shell

Navigation, routing and the always-visible status line.

Task 006 (1). One prompt for the completed phase; the atomics it absorbed are listed in [RETIRED.md](../RETIRED.md).

- [x] [006 — Application shell: navigation, the status line and the frame every feature plugs into](006-application-shell.md)

## As built

The numbers below are the original atomics; they now live in task 006. Reproduce 072–076 in order against the design-system catalogue (phase 03) and foundation services (phase 02). Chrome is a messaging-client shell: compact header uses the light primary fill (`#075E54`) with `onPrimary` ink; dark uses `surfaceVariant`; medium/expanded keep a surface rail (dark-rail treatment on light desktop). Destination icons are folder / camera / list / settings. Capture stays visually dominant by size.

The **app title bar is `StatusLine`**, not a page `AppBar`. Shell routes set `AppPage.showAppBar: false`. Visible title-bar controls are icon-only (wordmark, optional `AppIconButton`s). Labelled commands sit in `AppOverflowMenu` (vertical three-dots, extreme right). `AppPage.overflow` appends the same control on screens that still show an app bar (gallery, first-run, error page).

| Task | What to leave behind |
| :--- | :--- |
| 072 | `routerProvider` + `AppRoutes` + `appGuards()` in `router.dart` / `route_guards.dart` |
| 073 | `NavShell` — bar < 600, rail ≥ 600, rail + list pane ≥ 1024 when the destination `hasList` |
| 074 | `FirstRunScreen` + `_firstRun` as the first guard |
| 075 | `StatusLine` (brand + ⋮), `AppOverflowMenu` / `AppOverflowAction`, `OfflineBanner`, `AppPage.actions` icon-only + `AppPage.overflow` |
| 076 | `GlobalErrorPage` as the `ErrorBoundary` fallback around `MaterialApp.router` |
