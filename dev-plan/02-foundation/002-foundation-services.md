# 002 — Foundation services

**Phase** 02 · Foundation services  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything the rest of the app injects, each piece with a hand-written fake beside it. One guarded entry point installs
error handling, `ProviderScope`, the router and the lifecycle observer before the first frame, and the build knows
which flavour it is, so a development install sits alongside a production one; `AppConstants` is the single home for
every duration, size, limit, threshold and secure-storage key name, so no later task writes a bare literal; the sealed
`Failure` taxonomy and the `Result<T>` every fallible call returns live in `core/errors/` without importing Flutter,
and `ErrorBoundary` turns a build error below it into a recoverable panel instead of a red screen; the logger carries
levels, tags, a bounded redacting buffer and rotating-file persistence, `exportLog` writes that buffer to a shareable
file so support needs no server, and `AppProviderObserver` feeds provider failures into it; an injectable UTC clock,
the time-ordered UUIDv7 generator built on it and the device identifier minted once and never regenerated give every
audit row and every merge their stamps; content hashing streams through the isolate runner that every heavy job uses
for progress and cancellation; the connectivity service reports online, metered or offline, and reports offline
whenever the manual override is on, whatever the radio says; one permissions service requests camera, microphone,
location and storage, each with a rationale and a recovery path; secure storage is the only sanctioned home for keys
and credentials, reached through typed accessors over a closed `SecretKey` enum; code generation is configured and the
shared converters hold the wire format steady against a Dart rename; and `AiService` is the single abstraction every
provider implements, with a null implementation for when AI is switched off.

## Files

Entry point, flavours and lifecycle:

- `frontend/lib/main.dart` (changed)
- `frontend/lib/app/app.dart` (new)
- `frontend/lib/app/env.dart` (new)
- `frontend/lib/app/provider_observer.dart` (new)
- `frontend/lib/core/lifecycle/lifecycle_observer.dart` (new)
- `frontend/android/app/build.gradle.kts` (changed — the project ships Kotlin Gradle, not `build.gradle`)

Constants, failures and logging:

- `frontend/lib/core/constants/app_constants.dart` (new)
- `frontend/lib/core/errors/failure.dart` (new)
- `frontend/lib/core/errors/result.dart` (new)
- `frontend/lib/core/widgets/error_boundary.dart` (new)
- `frontend/lib/core/logging/logger.dart` (new)
- `frontend/lib/core/logging/log_export.dart` (new)

Time, identity and heavy work:

- `frontend/lib/core/time/clock.dart` (new)
- `frontend/lib/core/ids/uuid_service.dart` (new)
- `frontend/lib/core/device/device_identity.dart` (new)
- `frontend/lib/core/hash/hashing_service.dart` (new)
- `frontend/lib/core/concurrency/isolate_runner.dart` (new)

Platform services:

- `frontend/lib/core/network/connectivity_service.dart` (new)
- `frontend/lib/core/permissions/permissions_service.dart` (new)
- `frontend/lib/core/security/secure_storage.dart` (new)

Serialisation and AI:

- `frontend/build.yaml` (new)
- `frontend/lib/core/serialisation/converters.dart` (new)
- `frontend/lib/core/ai/ai_service.dart` (new)

Dependency record:

- `frontend/pubspec.yaml` (changed)
- `frontend/tool/allowlist.yaml` (changed)

## Contract

```dart
// Bootstrap, flavours and lifecycle
Future<void> main();
class TaptureApp extends ConsumerWidget;   // typedef App = TaptureApp
enum Flavor { dev, prod }
abstract final class Env { static Flavor get flavor; static bool get isDev; }
class LifecycleObserver with WidgetsBindingObserver { Stream<AppLifecycleState> get states; }

// Constants
abstract final class AppConstants { static const listPageSize = 50; static const imageLongEdge = 1600; ... }

// Failures, results and the boundary
sealed class Failure { String get message; String? get recoveryAction; factory Failure.from(Object error); }
sealed class Result<T> {
  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess);
  Result<R> map<R>(R Function(T) convert);
  Result<R> flatMap<R>(Result<R> Function(T) convert);
  T getOrElse(T Function() orElse);
  static Result<T> capture<T>(T Function() body);
}
class ErrorBoundary extends StatefulWidget { final Widget child; final VoidCallback? onRetry; }

// Logging and diagnostics
abstract interface class Logger { void trace/info/warn/error(String tag, String message, {Object? error}); }
enum LogLevel { trace, info, warn, error }
Future<Result<File>> exportLog({required Directory into});
class AppProviderObserver extends ProviderObserver

// Clock, identifiers and device identity
abstract interface class Clock { DateTime nowUtc(); DateTime today(); Duration get offset; }
class SystemClock implements Clock;  class FixedClock implements Clock;
abstract interface class IdService { String newId(); }  class UuidV7Service implements IdService;
Future<String> deviceId();  Future<DeviceDescriptor> deviceDescriptor();

// Hashing and the isolate runner
Future<Result<String>> sha256OfFile(File f);  String sha256OfString(String s);
Future<Result<R>> runIsolate<M, R>(FutureOr<R> Function(M) task, M message, {void Function(double)? onProgress, CancellationToken? cancel});
class CancellationToken { bool get isCancelled; void cancel(); }

// Connectivity, permissions and secrets
enum NetworkState { online, metered, offline }  Stream<NetworkState> watch();  Future<void> dispose();
Future<Result<PermissionState>> request(AppPermission p);  Future<PermissionState> status(AppPermission p);
Future<Result<void>> putSecret(SecretKey k, String v);  Future<Result<String?>> readSecret(SecretKey k);
Future<Result<void>> deleteSecret(SecretKey k);  Future<void> deleteAll();

// Serialisation
class UtcDateTimeConverter implements JsonConverter<DateTime, String>;  class JsonMapConverter ...
class EnumWireConverter ...

// AI
abstract interface class AiService {
  const factory AiService.unavailable();
  Future<Result<ReadTextResult>> readText(ReadTextRequest request);
  Future<Result<ExtractFieldsResult>> extractFields(ExtractFieldsRequest request);
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request);
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request);
}
```

Each service publishes the fake beside it — `ConnectivityService.fake`, `PermissionsService.fake`,
`SecureStorage.fake`, `LifecycleObserver.fake`, `FixedClock`, the sequence id service and the in-memory logger — so a
later test never reaches the platform.

## Steps

1. Ensure widget bindings are initialised, then run the app inside `runZonedGuarded`, routing `FlutterError.onError`
   and the zone error handler to the logger of step 4 once it exists and to a temporary handler until then. Install
   `ProviderScope` and a single `MaterialApp.router` placeholder. Define the Android `dev` and `prod` flavours in
   Gradle with distinct application id suffixes and display names, then read the flavour from a compile-time constant
   — `FLAVOR`, falling back to `FLUTTER_APP_FLAVOR`, defaulting to `prod` — and expose it through `Env`, which carries
   a test override. Register `LifecycleObserver`, emit lifecycle events, await the pending-write flush on pause and
   notify listeners on resume. Pin `flutter_riverpod` ^3.4.3 on the allowlist so `ConsumerWidget` exists. The
   placeholder did not survive: the design system and application shell phases made `TaptureApp` the one root widget —
   `theme` and `darkTheme` from `buildTheme`, the outdoor theme when `themeModeProvider` reads `AppThemeMode.outdoor`,
   `routerConfig` from `routerProvider`, and a `builder` wrapping the route child in `ErrorBoundary` over
   `GlobalErrorPage` — with `typedef App = TaptureApp` so the file publishes the type it is named for.
   Flavour-dependent chrome stays on a provider (`_appTitleProvider`), never on `if (Env.isDev)` inside a feature.
2. Define every animation duration, the debounce interval, list page size, image long edge and quality, retention
   days, confidence thresholds and secure-storage key names in `AppConstants`, grouped into nested constant records by
   area — `lists`, `images`, `secrets`, `motion`, `interaction`, `retention`, `confidence` and the rest — rather than
   one flat list, so a caller reaches a value through one nested name. Page size is 50 and the image long edge 1600.
3. Define `StorageFailure`, `PermissionFailure`, `NetworkFailure`, `ProviderFailure`, `ValidationFailure`,
   `CorruptionFailure` and `CancelledFailure`, each with a plain-language message and a recovery action. Implement
   `Success` and `FailureResult` with `map`, `flatMap`, `fold` and `getOrElse`, plus `capture`, the helper that wraps a
   throwing call and converts a known exception into the right `Failure`. The variants sit in `part` files, so the
   hierarchy stays sealed and one class per file still holds. In `ErrorBoundary`, override the error builder for the
   subtree, log the error, and render the failure's message, its recovery action and the retry affordance.
4. Implement the logger as a ring buffer of the configured size, persisted to a rotating file when `persist` is on and
   held in memory otherwise, which is the fake tests use. Redact any value matching a pattern in
   `frontend/tool/secret_patterns.yaml` before it is written. Expose the buffer as a stream for the diagnostics
   screen. In `exportLog`, serialise the buffer with timestamps and tags into a file named with the date and the
   device id. In `AppProviderObserver`, log provider errors with the provider name and stack and record rebuild counts
   above the threshold; install it in the provider scope in the development flavour only and disable it entirely in
   production.
5. Expose `nowUtc`, `today` and the device offset on `Clock`, with `SystemClock` and `FixedClock` behind it, and
   record on `Clock` that `DateTime.now` is legal inside `SystemClock` and nowhere else. Implement UUIDv7 from the
   clock plus a random tail, with a deterministic sequence implementation for tests. Mint the device identifier once,
   persist it, read it back from memory or its file, and never regenerate it — not on restart, not on update. Expose
   model, operating system version and application version as `DeviceDescriptor` for audit rows.
6. Stream the file in 64KiB chunks, the chunk size coming from `AppConstants`, so a large photo is never loaded whole
   into memory; `sha256OfString` is the synchronous digest. Wrap the isolate spawn, forward progress messages, honour
   a `CancellationToken` that kills the worker and returns `CancelledFailure`, and map a thrown error to a `Failure`.
   Pin `crypto` ^3.0.7 on the allowlist.
7. Fold the platform connectivity stream and the manual override into one `watch()` where offline always wins, and
   keep `metered` distinct from `online` so a later task can defer an upload without inventing its own check. The
   override arrives as an injected stream, so the service does not wait on the settings feature that later drives it.
   Tests use `ConnectivityService.fake`. Pin `connectivity_plus` ^7.3.1 on the allowlist.
8. Wrap camera, microphone, location and storage with `request`, `status` and a rationale string. A denial returns
   `PermissionFailure` carrying its recovery action, a permanent denial offers the settings page instead of repeating
   the prompt, and location is not requested while GPS is off. Pin `permission_handler` ^12.0.3 on the allowlist.
9. Wrap the platform secure storage behind typed `putSecret`, `readSecret`, `deleteSecret` and `deleteAll` over a
   closed `SecretKey` enum whose names come from `AppConstants.secrets`, so no arbitrary key name can appear. Assert
   in debug that no secret value is ever passed to the preferences store or the database, and ship a fake backing
   store that survives a simulated restart. Pin `flutter_secure_storage` ^9.2.4 on the allowlist.
10. Configure the generator in `build.yaml` so json_serializable takes explicit `@JsonKey` wire names and derives
    nothing from a Dart identifier that may be renamed (`field_rename: none`). Write `UtcDateTimeConverter`,
    `JsonMapConverter` — a null map decodes to an empty one — and `EnumWireConverter`, which throws on an unknown wire
    name rather than defaulting silently. Pin `json_annotation` ^4.9.0, `json_serializable` ^6.9.0 and `build_runner`
    ^2.4.13 on the allowlist.
11. Declare `readText`, `extractFields`, `refineText` and `transcribe` on `AiService`, each taking a typed request and
    returning a typed result inside a `Result`, with OCR text, transcripts and template labels carried on the request
    as quoted data and no key anywhere on the interface. `AiService.unavailable()` is the stand-in used whenever AI is
    disabled: a `ProviderFailure` with a recovery action from all four methods.

## Constraints

- No feature branches on `Env.flavor`; flavour-dependent values are provided at the scope instead (FE-STATE-03,
  FE-STR-04). There is one `MaterialApp` and one `ProviderScope`, both in `app.dart`, which publishes the type it is
  named for (FE-STR-06).
- `LifecycleObserver` is the app's only `WidgetsBindingObserver` and ships with a fake, so no later feature registers
  its own (FE-STR-11, FE-TEST-03).
- The pause flush is awaited rather than left floating, so a background transition cannot lose a write (FE-STATE-07,
  FE-CODE-07).
- Numbers, durations, key names, buffer size, rotation count, retention and the rebuild threshold come from
  `AppConstants` or from the design tokens; a literal in feature code is a defect (FE-CODE-09). List page size is read
  from here by every paged query, so the value is stated once (FE-PERF-03).
- `core/errors/` imports no Flutter, so a `domain/` file can return `Result` (FE-STR-05).
- Every `Failure` variant carries a user-facing message and a recovery action; nothing relies on `toString` for user
  copy, and a permission denial crosses the boundary as one of those failures rather than as a raw exception
  (FE-CODE-06, FE-SIMP-10).
- Recovery is always offered and always works; the boundary never discards input already captured below it
  (FE-SIMP-09).
- Redaction happens before the write, so the rotating file and every export are clean at rest, not merely on display
  (FE-SEC-01).
- No record value, caption or transcript reaches a log line or the export; diagnostics stay local and are shared by
  the user by hand (FE-CODE-08, FE-SEC-10).
- `UuidV7Service` and `deviceId()` take their `Clock` and `IdService`; nothing here reads the system clock or
  generates an id inline (FE-STR-11).
- `DeviceDescriptor` carries model, OS version and app version only — no advertising identifier, no IMEI, no hardware
  serial (FE-SEC-07, FE-SEC-10).
- Hashing, copying and packaging read in chunks; nothing loads a 100MB file into memory (FE-PERF-07).
- No file input or output, hashing, decode or compression runs on the UI thread — it goes through `runIsolate` with
  progress and cancellation (FE-PERF-02).
- Cancellation and completion both release the isolate and its ports, leaving nothing behind, and the platform
  connectivity subscription is released on dispose (FE-STATE-09, FE-CODE-07).
- One switch stops every outbound call, and capture, editing, review and export continue unaffected (FE-SEC-04).
- Location is requested only where a project has enabled GPS, since GPS is off by default (FE-SEC-07).
- Secrets go to secure storage and nowhere else — never the database, logs, exports, bundles or preferences
  (FE-SEC-01).
- Nothing ships with a provider key; a key entered on the device is the administrator-permitted exception for a lone
  operator, not the default arrangement, and the AI interface takes no key at all, because custody belongs to the
  organisation's backend (FE-SEC-02).
- Every platform plugin — connectivity, permissions, secure storage — is reached only through its service here, and
  each service ships a hand-written fake, as do the clock, the id service, the device identity and the logger, so a
  later test never touches the platform (FE-STR-11, FE-STATE-10, FE-TEST-03).
- No feature imports a provider SDK; networking for AI lives only under `core/ai/` (FE-SEC-03).
- Request types carry OCR text, transcripts and template labels as quoted data, never interpolated into an
  instruction string (FE-SEC-05).
- Generated output is committed, so a clean checkout builds without a generator run (FE-CODE-13).
- Models stay immutable: `final` fields, `const` where possible, change through `copyWith` (FE-CODE-04).
- `dynamic` appears only inside a decoder and is narrowed on the next line (FE-CODE-05).

## Definition of done

- [x] An uncaught error is captured rather than lost, and the app still renders.
- [x] A development build installs alongside a production build, and `Env.flavor` reports the flavour it was compiled
      with.
- [x] Backgrounding during capture never loses an unsaved photo reference.
- [x] Tests: `frontend/test/app/bootstrap_test.dart` pumps the app and asserts a thrown error reaches the handler.
- [x] Tests: `frontend/test/app/env_test.dart` asserts the default flavour and an override.
- [x] Tests: `frontend/test/core/lifecycle/lifecycle_observer_test.dart` drives pause and resume and asserts the
      flush.
- [x] Every value later phases need — page size, image long edge and quality, retention days, confidence thresholds,
      secure-storage key names, animation durations, debounce interval — resolves in `AppConstants`.
- [x] Grouping is by area, so a caller reaches a value through one nested class rather than a flat namespace.
- [x] Tests: `frontend/test/core/app_constants_test.dart` asserts each value sits in a sane range and that no two
      storage key names collide.
- [x] Domain methods return `Result` without importing Flutter.
- [x] All seven `Failure` variants expose a message and a recovery action in plain language.
- [x] A throwing child under `ErrorBoundary` produces a recoverable panel with a retry, not a red screen.
- [x] Tests: `frontend/test/core/errors/result_test.dart` covers mapping, folding, `getOrElse` and exception
      conversion.
- [x] Tests: `frontend/test/core/widgets/error_boundary_test.dart` pumps a deliberately throwing child and asserts
      the retry path.
- [x] No log line and no exported file contains a redacted pattern, a record value or a credential, even when one is
      passed deliberately.
- [x] The buffer drops oldest entries at its bound, and level filtering discards anything below the configured level.
- [x] A provider that throws produces exactly one logged error, and the observer is absent from a production build.
- [x] Tests: `frontend/test/core/logging/logger_test.dart` proves redaction, level filtering and buffer bounds.
- [x] Tests: `frontend/test/core/logging/log_export_test.dart` scans the output against `secret_patterns.yaml`.
- [x] Tests: `frontend/test/app/provider_observer_test.dart` asserts one log per failure.
- [x] A test freezes time with `FixedClock` and asserts a stamped value exactly.
- [x] Identifiers generated in order sort in order as strings, and ten thousand contain no duplicate.
- [x] The device identifier is identical after a restart and after an app update.
- [x] Tests: `frontend/test/core/time/clock_test.dart` covers both clock implementations.
- [x] Tests: `frontend/test/core/ids/uuid_service_test.dart` asserts ordering, uniqueness and format.
- [x] Tests: `frontend/test/core/device/device_identity_test.dart` asserts persistence across two reads and the
      descriptor fields.
- [x] Hashing a hundred-megabyte file holds memory flat.
- [x] Cancelling mid-run completes with `CancelledFailure` and leaves no orphan isolate.
- [x] Tests: `frontend/test/core/hash/hashing_service_test.dart` uses known vectors and a large temporary file.
- [x] Tests: `frontend/test/core/concurrency/isolate_runner_test.dart` covers success, progress, failure and
      cancellation.
- [x] Enabling the manual override reports offline regardless of the radio state.
- [x] `metered` is distinguished from `online`, so later tasks can defer an upload without inventing their own check.
- [x] Tests: `frontend/test/core/network/connectivity_service_test.dart` uses a fake source and asserts the override
      wins from every radio state.
- [x] A denied permission returns `PermissionFailure` with a recovery action, never an exception.
- [x] A permanently denied permission offers the settings page rather than repeating the prompt.
- [x] Tests: `frontend/test/core/permissions/permissions_service_test.dart` covers granted, denied and permanently
      denied for camera, microphone, location and storage.
- [x] Secrets survive a restart and are absent from the database and every export.
- [x] `deleteAll` leaves no readable residue for any `SecretKey`.
- [x] Tests: `frontend/test/core/security/secure_storage_test.dart` uses a fake backing store and asserts isolation
      from the preferences store and the database.
- [x] Renaming a Dart field does not change the serialised key.
- [x] Date-times round-trip as UTC regardless of the device offset, and an unknown enum wire name fails loudly rather
      than defaulting silently.
- [x] Tests: `frontend/test/core/serialisation/converters_test.dart` round-trips each converter, including the
      unknown-enum and null cases.
- [x] Every AI call in the app goes through `AiService`; no feature references a provider SDK type.
- [x] The null implementation returns a `ProviderFailure` carrying a recovery action for all four methods.
- [x] Tests: `frontend/test/core/ai/ai_service_test.dart` holds the contract tests every implementation must pass,
      run against the null implementation.
- [x] Every package these services reach — `flutter_riverpod`, `crypto`, `connectivity_plus`, `permission_handler`,
      `flutter_secure_storage`, `json_annotation`, `json_serializable`, `build_runner` — is pinned on
      `frontend/tool/allowlist.yaml` with its version, purpose and introducing task.

## Out of scope

- Any real AI provider implementation, the networking behind it and the custody of its key: this phase publishes the
  interface and the unavailable stand-in, and 024 · The minimal backend supplies the provider registry and the proxy.
- The screens that surface what these services hold — the diagnostics log view, and the settings switch that drives
  the offline override — belong to later phases; this phase supplies the services and the streams behind them, and no
  widget beyond `ErrorBoundary`.
