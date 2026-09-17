# 021 — Result type, failure taxonomy and error boundary

**Phase** 02 · Foundation services  |  **Depends on** [014](../01-orchestration/014-riverpod-test.md), [019](019-app-bootstrap.md), [020](020-app-constants.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The sealed `Failure` hierarchy and the `Result<T>` every fallible call returns, plus the `ErrorBoundary` widget that
catches a build error below it and renders that `Failure` as a recoverable panel instead of a red screen.

## Files

- `frontend/lib/core/errors/failure.dart` (new)
- `frontend/lib/core/errors/result.dart` (new)
- `frontend/lib/core/widgets/error_boundary.dart` (new)

## Contract

```dart
sealed class Failure { String get message; String? get recoveryAction; }
sealed class Result<T> { R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess); }
class ErrorBoundary extends StatefulWidget { final Widget child; final VoidCallback? onRetry; }
```

## Steps

1. Define StorageFailure, PermissionFailure, NetworkFailure, ProviderFailure, ValidationFailure, CorruptionFailure and CancelledFailure, each with a plain-language message and a recovery action.
2. Implement Success and FailureResult with `map`, `flatMap`, `fold` and `getOrElse`.
3. Add a helper that wraps a throwing call and converts known exceptions into the right `Failure`.
4. In `ErrorBoundary`, override the error builder for the subtree, log the error, and render the failure's message, its recovery action and the retry affordance.

## Constraints

- `core/errors/` imports no Flutter, so a `domain/` file can return `Result` (FE-STR-05).
- Every variant carries a user-facing message and a recovery action; nothing relies on `toString` for user copy (FE-CODE-06, FE-SIMP-10).
- Recovery is always offered and always works; the boundary never discards input already captured below it (FE-SIMP-09).

## Definition of done

- [x] Domain methods return `Result` without importing Flutter.
- [x] All seven `Failure` variants expose a message and a recovery action in plain language.
- [x] A throwing child under `ErrorBoundary` produces a recoverable panel with a retry, not a red screen.
- [x] Tests: `frontend/test/core/errors/result_test.dart` covers mapping, folding, `getOrElse` and exception conversion; `frontend/test/core/widgets/error_boundary_test.dart` pumps a deliberately throwing child and asserts the retry path.
