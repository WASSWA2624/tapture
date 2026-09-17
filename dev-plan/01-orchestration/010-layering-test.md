# 010 — Layering enforcement test

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the test that fails when a file imports across a forbidden layer boundary.

## Files

- `frontend/test/architecture/layering_test.dart` (new)
- `frontend/test/architecture/import_graph.dart` (new)

## Contract

```dart
ImportGraph buildImportGraph(Directory libDir);  List<Violation> checkLayering(ImportGraph g)
```

## Steps

1. Build the import graph by parsing directives from every file under `frontend/lib/`.
2. Assert presentation never imports data; data never imports presentation; core never imports features.
3. Assert no feature imports another feature's internals, only its exported barrel.
4. Report every violation with file, import and the rule broken, rather than stopping at the first.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] The test passes on the empty scaffold and fails when a deliberate cross-layer import is added.
- [x] Tests written and passing: The test itself, plus a negative fixture under `frontend/test/architecture/fixtures/`.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
