# 022 — Logger, diagnostics export and provider observer

**Phase** 02 · Foundation services  |  **Depends on** [015](../01-orchestration/015-logging-checker.md), [019](019-app-bootstrap.md), [021](021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The logger with levels, tags, a bounded buffer and redaction; the export that writes that buffer to a shareable file
so support needs no server; and the Riverpod observer that feeds provider failures into it.

## Files

- `frontend/lib/core/logging/logger.dart` (new)
- `frontend/lib/core/logging/log_export.dart` (new)
- `frontend/lib/app/provider_observer.dart` (new)

## Contract

```dart
abstract interface class Logger { void trace/info/warn/error(String tag, String message, {Object? error}); }
Future<Result<File>> exportLog({required Directory into});
class AppProviderObserver extends ProviderObserver
```

## Steps

1. Implement a ring buffer of the configured size, persisted to a rotating file, with an in-memory fake for tests.
2. Redact any value matching a pattern in `frontend/tool/secret_patterns.yaml` before it is written.
3. Expose the buffer as a stream for the diagnostics screen.
4. In `exportLog`, serialise the buffer with timestamps and tags, naming the file with the date and the device id.
5. In `AppProviderObserver`, log provider errors with the provider name and stack, and record rebuild counts above a threshold in development builds; install it in the provider scope and disable it entirely in production.

## Constraints

- Buffer size, rotation count, retention and the rebuild threshold come from `AppConstants` (FE-CODE-09).
- Redaction happens before the write, so the rotating file and every export are clean at rest, not merely on display (FE-SEC-01).
- No record value, caption or transcript reaches a log line or the export; diagnostics stay local and are shared by the user by hand (FE-CODE-08, FE-SEC-10).
- `Logger` is an interface with a platform implementation and a hand-written in-memory fake (FE-TEST-03).

## Definition of done

- [ ] No log line and no exported file contains a redacted pattern, a record value or a credential, even when one is passed deliberately.
- [ ] The buffer drops oldest entries at its bound, and level filtering discards anything below the configured level.
- [ ] A provider that throws produces exactly one logged error, and the observer is absent from a production build.
- [ ] Tests: `frontend/test/core/logging/logger_test.dart` proves redaction, level filtering and buffer bounds; `frontend/test/core/logging/log_export_test.dart` scans the output against `secret_patterns.yaml`; `frontend/test/app/provider_observer_test.dart` asserts one log per failure.
