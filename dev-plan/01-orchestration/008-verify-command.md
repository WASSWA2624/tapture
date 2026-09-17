# 008 — The verify command

**Phase** 01 · Project setup and guardrails  |  **Depends on** [005](005-dependency-allowlist.md), [006](006-plan-integrity-checker.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the single command that runs every gate, so a developer and continuous integration run exactly the same checks.

## Files

- `frontend/tool/verify.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // --fast skips golden and integration suites
```

## Steps

1. Run in this order (as built in `frontend/tool/verify.dart`): format (`dart format --output=none --set-exit-if-changed .`), analyzer (`flutter analyze`), dependency allowlist, structure, plan, **test presence `--strict`**, guardrail tests, unit and widget tests, then golden tests and integration tests.
2. Print a single summary table of gate names and outcomes, and exit non-zero if any gate fails.
3. Support `--fast` for the pre-commit path: goldens and integration are set aside. Naming and repo-hygiene checkers are reached through their own guardrail suites, not as extra rows.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] One command reproduces the entire review gate locally.
- [x] Tests written and passing: `frontend/test/tool/verify_test.dart` asserts the exit code aggregates gate failures correctly.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
