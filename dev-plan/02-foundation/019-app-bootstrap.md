# 019 — Application bootstrap, flavours and lifecycle

**Phase** 02 · Foundation services  |  **Depends on** [003](../01-orchestration/003-strict-lints.md), [004](../01-orchestration/004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One guarded entry point installs error handling, `ProviderScope`, a router placeholder and the lifecycle observer
before the first frame, and the build knows which flavour it is: a development install sits alongside a production one.

## Files

- `frontend/lib/main.dart` (edit)
- `frontend/lib/app/app.dart` (new)
- `frontend/lib/app/env.dart` (new)
- `frontend/android/app/build.gradle` (edit)
- `frontend/lib/core/lifecycle/lifecycle_observer.dart` (new)

## Contract

```dart
Future<void> main();
class TaptureApp extends ConsumerWidget;
enum Flavor { dev, prod }
abstract final class Env { static Flavor get flavor; static bool get isDev; }
class LifecycleObserver with WidgetsBindingObserver { Stream<AppLifecycleState> get states; }
```

## Steps

1. Ensure widget bindings are initialised, then run the app inside `runZonedGuarded`.
2. Route `FlutterError.onError` and the zone error handler to the logger service once it exists, and to a temporary handler until then.
3. Install `ProviderScope` and a single `MaterialApp.router` placeholder.
4. Define the flavours in Gradle with distinct application id suffixes and display names, then read the flavour from a compile-time constant and expose it through `Env`.
5. Register `LifecycleObserver`, emit lifecycle events, flush pending writes on pause and notify listeners on resume.

## Constraints

- No feature branches on `Env.flavor`; flavour-dependent values are provided at the scope instead (FE-STATE-03, FE-STR-04).
- `LifecycleObserver` is the app's only `WidgetsBindingObserver` and ships with a fake, so no later feature registers its own (FE-STR-11, FE-TEST-03).
- The pause flush is awaited rather than left floating, so a background transition cannot lose a write (FE-STATE-07, FE-CODE-07).

## Definition of done

- [ ] An uncaught error is captured rather than lost, and the app still renders.
- [ ] A development build installs alongside a production build, and `Env.flavor` reports the flavour it was compiled with.
- [ ] Backgrounding during capture never loses an unsaved photo reference.
- [ ] Tests: `frontend/test/app/bootstrap_test.dart` pumps the app and asserts a thrown error reaches the handler; `frontend/test/app/env_test.dart` asserts the default and an override; `frontend/test/core/lifecycle/lifecycle_observer_test.dart` drives pause and resume and asserts the flush.
