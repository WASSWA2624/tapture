# 02 — Foundation services

The empty app that boots, logs, fails safely, and the small services every later feature injects.

Task 002 (1). One prompt for the completed phase; the atomics it absorbed are listed in [RETIRED.md](../RETIRED.md).

- [x] [002 — Foundation services](002-foundation-services.md)

## As built

The numbers below are the original atomics; they now live in task 002. Implement 019–029 in order. After 019 the app is a guarded `ProviderScope` + `MaterialApp.router`. Later phases fill the router and theme; do not invent a second root widget.

| Task | Public surface to reproduce |
| :--- | :--- |
| 019 | `main()` inside `runZonedGuarded`; `TaptureApp` in `lib/app/app.dart` (`typedef App = TaptureApp`); `Env` / `Flavor.dev\|prod`; Android flavours on `android/app/build.gradle.kts` (not `.gradle`); `LifecycleObserver`. As wired today: `TaptureApp` also installs `themeModeProvider`, `buildTheme` / outdoor, `routerProvider`, and `ErrorBoundary` → `GlobalErrorPage` (031, 072, 076). Flavour-dependent chrome stays on a provider (`_appTitleProvider`), never `if (Env.isDev)` in a feature. |
| 020 | `AppConstants` with const area records (`lists`, `images`, `secrets`, `interaction`, `storage`, …). Nested classes are illegal (FE-STR-06). |
| 021 | Sealed `Failure` + `Result<T>` in `lib/core/errors/`. Variants are `part` files. `ErrorBoundary` replaces a throwing child. |
| 022 | `Logger` (levels, tags, redacting buffer, `persist: true`); `exportLog`; `AppProviderObserver` (`typedef ProviderObserver = AppProviderObserver`) in the dev flavour only. |
| 023 | `Clock` / `SystemClock` / `FixedClock`; `IdService` / `UuidV7Service`; `deviceId` / `deviceDescriptor`. `DateTime.now` is legal only in `SystemClock`. |
| 024 | `sha256OfFile` via `runIsolate` (64KiB chunks); `sha256OfString` sync; `CancellationToken` → `CancelledFailure`. `crypto` on the allowlist. |
| 025 | `ConnectivityService.watch()` folds radio + manual override (override ⇒ `offline`). `metered` ≠ `online`. Plugin only here; tests use `ConnectivityService.fake`. Status line (075) reads this stream. |
| 026 | `request` / `status` for camera, microphone, location, storage. Permanent denial opens settings. Location is not requested while GPS is off (`gpsEnabled` callback, default off). |
| 027 | `putSecret` / `readSecret` / `deleteAll` over `SecretKey` mapped to `AppConstants.secrets`. Includes `SecretKey.databaseEncryption` (064). |
| 028 | `build.yaml` `field_rename: none`; `UtcDateTimeConverter`, `JsonMapConverter`, `EnumWireConverter`. |
| 029 | `AiService` with typed `readText` / `extractFields` / `refineText` / `transcribe` returning `Result`. `AiService.unavailable()` is the disabled stand-in. |

Tests live under `frontend/test/app/` and `frontend/test/core/` matching each service file. Do not add a second connectivity plugin, a second `ErrorBoundary`, or a feature-level `WidgetsBindingObserver`.
