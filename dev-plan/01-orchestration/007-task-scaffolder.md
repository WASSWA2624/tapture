# 007 — Task scaffolding tool

**Phase** 01 · Project setup and guardrails  |  **Depends on** [006](006-plan-integrity-checker.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the generator that creates a new task file with the next free number and the standard section skeleton.

## Files

- `frontend/tool/new_task.dart` (new)
- `frontend/tool/task_template.md` (new)

## Contract

```dart
Future<int> main(List<String> args)  // new_task <phase-folder> <slug> "<title>"
```

## Steps

1. Scan dev-plan/ for the highest number, then write the next file into the given phase folder from the template.
2. Populate the heading, phase line and empty sections; refuse to overwrite an existing file.
3. Append the new task to the phase README checklist and to INDEX.md.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] Running the tool twice with the same slug fails rather than overwriting.
- [x] The generated file passes the plan integrity checker unchanged.
- [x] Tests written and passing: `frontend/test/tool/new_task_test.dart` generates into a temporary tree and asserts the result.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
