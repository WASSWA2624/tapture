# 005 — Dependency allowlist checker

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the checker that fails the build when pubspec gains a package that was never approved.

## Files

- `frontend/tool/allowlist.yaml` (new)
- `frontend/tool/check_dependencies.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // exit 0 clean, 1 on violation
```

## Steps

1. Write allowlist.yaml listing every approved package with its pinned version, purpose and the task that introduced it.
2. Parse `frontend/pubspec.yaml`, compare direct dependencies against the allowlist, and report additions, removals and version drift.
3. Fail on any package not on the list; print the offending package and the rule that adding one requires its own task.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] Adding a package to pubspec without the allowlist entry fails the check.
- [x] Removing an allowlisted package reports a warning rather than an error.
- [x] Tests written and passing: `frontend/test/tool/check_dependencies_test.dart` covers approved, unapproved and version-drift fixtures.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
