# 016 — Test presence checker

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/tool/check_tests.dart` reports every source file that owes a test and has none, by layer, and turns the
report into a failure under `--strict`.

## Files

- `frontend/tool/check_tests.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // --strict turns the report into a failure
```

## Steps

1. Require a test file for every file under `domain/` and `data/`, and for every widget under `core/widgets/`.
2. Exempt barrels, generated files and presentation screens covered by an integration test.
3. Print a coverage-of-files table by layer, and fail in strict mode when a required test is missing.

## Constraints

- The layer decides what is owed: unit tests for domain and pure logic, in-memory database tests for repositories and DAOs, behaviour tests for widgets, goldens for design-system widgets (FE-TEST-02).
- Tests ship with the change, so the strict run is what `verify.dart` calls, not an advisory report (FE-TEST-01).

## Definition of done

- [ ] Adding a domain service without a test fails the strict run and names the missing test path.
- [ ] A barrel, a generated file and an integration-covered screen produce no finding.
- [ ] Tests: `frontend/test/tool/check_tests_test.dart` over a fixture tree holding one exempt file, one covered file and one uncovered file per layer.
