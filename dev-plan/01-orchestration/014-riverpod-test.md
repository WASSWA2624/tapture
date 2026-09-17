# 014 — State and error-handling convention tests

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two architecture suites that hold the controller-to-repository boundary: `state_test.dart` keeps state management
uniform across features, and `errors_test.dart` keeps failures typed so no raw exception crosses a layer.

## Files

- `frontend/test/architecture/state_test.dart` (new)
- `frontend/test/architecture/errors_test.dart` (new)

## Steps

1. In `state_test.dart`, assert every provider declaration ends in `Provider` and lives in the feature that owns it.
2. Assert no `StatefulWidget` calls `setState` outside `frontend/lib/core/widgets/` and animation code.
3. Assert controllers expose intent methods, and that no widget calls a repository directly.
4. In `errors_test.dart`, assert no file under `domain/` or `data/` bare-throws a non-`Failure` type.
5. Assert every public repository method returns `Result` or `Future<Result>`.
6. Assert every `Failure` subclass declares a user-facing message field.

## Constraints

- Riverpod only — no service locator, no global singleton, `setState` confined to `core/widgets/` and animation code (FE-STATE-01).
- Providers are declared in the owning feature and exported through its barrel; `core/` declares none that depends on a feature (FE-STATE-03).
- Widgets read state and call intent methods; persistence and orchestration sit in the controller or domain, never in `build` (FE-STATE-04, FE-STATE-05).
- `Failure` is sealed and every variant carries a message and a recovery action (FE-CODE-06).

## Definition of done

- [x] A widget calling a repository method, and a provider declared outside its feature, each fail `state_test.dart`.
- [x] A repository method returning a bare `Future`, and a `Failure` subclass with no message field, each fail `errors_test.dart`.
- [x] Tests: both suites with a compliant and a non-compliant controller fixture, plus compliant and non-compliant repository and `Failure` fixtures under `frontend/test/architecture/fixtures/`.
