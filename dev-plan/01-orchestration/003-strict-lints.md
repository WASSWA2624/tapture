# 003 — Strict analyzer configuration

**Phase** 01 · Project setup and guardrails  |  **Depends on** [001](001-flutter-project-init.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Configure the analyzer as the first reviewer, with warnings treated as failures.

## Files

- `frontend/analysis_options.yaml` (edit)

## Steps

1. Include flutter_lints, then enable strict-casts, strict-inference and strict-raw-types under the analyzer language section.
2. Turn on the rules for const usage, sorted directives, unnecessary awaits, unused elements and public API documentation on core/.
3. Set errors so that every warning and hint is promoted to an error.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] Running the analyzer on the fresh project reports zero issues.
- [x] Introducing an implicit dynamic cast fails the analyzer.
- [x] Tests written and passing: `frontend/tool/verify.dart` runs the analyzer and fails on any issue.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
