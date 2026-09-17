# 011 — Naming and file-layout checker

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the checker that enforces file naming, one public type per file, and the banned-word list for type names.

## Files

- `frontend/tool/check_naming.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)
```

## Steps

1. Assert file names are snake_case and that the primary public type name matches the file name.
2. Assert providers are camelCase ending in Provider, and that a file declares at most one public class.
3. Reject the words manager, helper, util, data, info and item in class names, naming the file and the offending identifier. Match whole camel-case segments, not substrings, so `ReferenceDataset` passes and `RecordData` does not; check only types this repository declares, so Flutter's `ThemeData` and `IconData` are never flagged.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] Renaming a class without renaming its file fails the check.
- [x] Tests written and passing: `frontend/test/tool/check_naming_test.dart` covers each rule with a passing and a failing fixture.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
