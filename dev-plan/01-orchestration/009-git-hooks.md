# 009 — Git hook installer

**Phase** 01 · Project setup and guardrails  |  **Depends on** [008](008-verify-command.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Write the installer that puts the pre-commit and commit-message hooks in place, so the gates are hard to skip.

## Files

- `frontend/tool/install_hooks.dart` (new)
- `frontend/tool/hooks/pre-commit` (new)
- `frontend/tool/hooks/commit-msg` (new)

## Steps

1. The pre-commit hook runs the verify command in fast mode on staged Dart files.
2. The commit-msg hook requires the subject to start with a three-digit task number followed by a space.
3. The installer copies both hooks, makes them executable and is safe to run repeatedly.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] A commit message without a task number is rejected.
- [x] Running the installer twice leaves exactly one copy of each hook.
- [x] Tests written and passing: `frontend/test/tool/commit_msg_test.dart` covers valid and invalid subjects.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
