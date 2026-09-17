# 072 — Router, route table and guards

**Phase** 06 · Application shell  |  **Depends on** [004](../01-orchestration/004-folder-scaffold.md), [019](../02-foundation/019-app-bootstrap.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

GoRouter is installed with one declared route table, typed navigation helpers and a single `redirect` chain. Deep
links resolve to the screen they name; a project-scoped link with no project open diverts to the picker and resumes
at the original destination afterwards; an unknown path renders `AppErrorState`.

## Files

- `frontend/lib/app/router.dart` (new)
- `frontend/lib/app/route_guards.dart` (new)

## Contract

```dart
final routerProvider = Provider<GoRouter>(...);

abstract final class AppRoutes {
  static const projects = '/projects';
  static String project(String id);
  static String capture(String projectId);
  static String record(String id);
}

/// Ordered redirect chain; each guard returns a location or null.
typedef RouteGuard = String? Function(GoRouterState state, WidgetRef ref);
List<RouteGuard> appGuards();
```

## Steps

1. Declare every path once in `router.dart`. Screens navigate through `AppRoutes` helpers; no call site concatenates
   a path string.
2. Mark project-scoped routes in the table itself, so the guard tests a route flag rather than pattern-matching
   paths.
3. Compose `redirect` from `appGuards()` in order, so later tasks add a gate — first run, app lock — as one entry
   rather than a second redirect.
4. Carry the intended location as a query parameter on the diversion and return to it once a project is opened.
5. Add the not-found route rendering the shared error state with a route back to `AppRoutes.projects`.

## Constraints

- Routing lives in `lib/app/`; no feature declares a route or a path literal (FE-STR-02, FE-CODE-09).
- Guards are pure functions over `GoRouterState` and provider reads, so they are unit-testable without a widget
  (FE-STATE-04).

## Definition of done

- [ ] Deep linking to a record opens it directly, and no screen builds a path string by hand.
- [ ] Opening a capture link with no project selected asks which project, then continues to that capture screen.
- [ ] An unknown path renders the shared error state with a way back, never a blank page.
- [ ] Tests: `frontend/test/app/router_test.dart` resolves every declared route plus the not-found path;
  `frontend/test/app/route_guards_test.dart` asserts diversion and resumption for a project-scoped location.
