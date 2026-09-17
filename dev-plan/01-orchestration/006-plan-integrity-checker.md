# 006 — Plan integrity checker

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the tool that validates this plan itself: numbering, required sections, resolvable dependencies and unique slugs.

## Files

- `frontend/tool/check_plan.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // scans dev-plan/, exits non-zero on any structural error
```

## Steps

1. Parse every dev-plan task file; assert the filename number matches the heading number and that numbers are unique and contiguous.
2. Assert each file contains the required sections: Implement, Files, Definition of done.
3. Assert every dependency link resolves to an existing file and always points to a lower number.
4. Report tasks whose Definition of done has no ticked or unticked checkbox at all.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] Renumbering a file by hand and forgetting its heading fails the check.
- [x] A dependency pointing at a higher-numbered task fails the check.
- [x] Tests written and passing: `frontend/test/tool/check_plan_test.dart` runs the checker over valid and deliberately broken fixture trees.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
