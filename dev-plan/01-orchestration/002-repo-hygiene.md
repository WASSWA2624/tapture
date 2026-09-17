# 002 — Repository hygiene files

**Phase** 01 · Project setup and guardrails  |  **Depends on** [001](001-flutter-project-init.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the ignore and editor configuration that keeps generated output and secrets out of git from the first commit.

## Files

- `.gitignore` (edit)
- `.editorconfig` (new)

## Steps

1. Ignore build/, .dart_tool/, generated .g.dart and .freezed.dart output, *.keystore, key.properties, local .env files and sample bundles.
2. Write `.editorconfig` fixing UTF-8, LF endings, two-space indentation for Dart and a final newline.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] A clean checkout followed by a build produces no untracked files.
- [x] Tests written and passing: `frontend/tool/check_repo_hygiene.dart` fails if a build artefact path is missing from `.gitignore`.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
