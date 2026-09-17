# 072 — Router, route table and guards

**Phase** 06 · Application shell  |  **Depends on** [004](../01-orchestration/004-folder-scaffold.md), [019](../02-foundation/019-app-bootstrap.md), [040](../03-design-system/040-app-empty-state.md), [046](../03-design-system/046-copy-helper.md), [047](../03-design-system/047-widget-gallery.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

GoRouter is installed with one declared route table, typed navigation helpers and a single `redirect` chain. Deep
links resolve to the screen they name; a project-scoped link with no project open diverts to the picker and resumes
at the original destination afterwards; an unknown path renders `AppErrorState`.

Shell feature routes compose `AppPage` with `showAppBar: false` so the status line (075) is the only title bar.
Placeholder bodies use catalogue widgets (`AppEmptyState`, `AppSearchField`, `AppListTile`) and `Copy` — no feature
literals.

## Files

- `frontend/lib/app/router.dart` (new)
- `frontend/lib/app/route_guards.dart` (new, `part of 'router.dart'`)
- `frontend/lib/app/app.dart` (edit — `routerConfig: ref.watch(routerProvider)`)

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
```

`appGuards` takes `Ref`, not `WidgetRef` — `WidgetRef` is sealed and needs a widget.

## Steps

1. Declare every path once in `router.dart`. Screens navigate through `AppRoutes` helpers; no call site concatenates
   a path string. Include `/templates` and `/queue` so the status overflow (075) has destinations before those
   screens exist.
2. Four `StatefulShellRoute.indexedStack` branches — Projects, Capture, Records, More — so 073 can wrap them.
   Project-scoped routes carry metadata; the guard tests the flag, not a path pattern.
3. Compose `redirect` from `appGuards()` in order. `_firstRun` is first so 267 can prepend sign-in. Debug-only
   `/_gallery` (`WidgetGalleryScreen.route`) bypasses first-run when `kDebugMode`.
4. Carry the intended location as `AppRoutes.fromQuery` on the diversion and return to it once `OpenProjectId` is set.
5. Unknown paths render `AppErrorState` with a typed `ValidationFailure` and `onRetry` → `AppRoutes.projects`.
6. Placeholder `_RoutePage` sets `showAppBar: false`. List-like routes show `AppSearchField` only when the size
   class is not expanded (the expanded list pane already has search). More shows catalogue tiles for Templates and
   Queue.

## Constraints

- Routing lives in `lib/app/`; no feature declares a route or a path literal (FE-STR-02, FE-CODE-09).
- Guards are pure functions over `GoRouterState` and provider reads (FE-STATE-04).
- `typedef Router = GoRouter` so `router.dart` is named after its first public type (FE-STR-06).

## Definition of done

- [x] Deep linking to a record opens it directly, and no screen builds a path string by hand.
- [x] Opening a capture link with no project selected asks which project, then continues to that capture screen.
- [x] An unknown path renders the shared error state with a way back, never a blank page.
- [x] Tests: `frontend/test/app/router_test.dart` resolves every declared route plus the not-found path;
  `frontend/test/app/route_guards_test.dart` asserts diversion and resumption for a project-scoped location.
