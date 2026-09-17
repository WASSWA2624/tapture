# 004 — Create the folder skeleton

**Phase** 01 · Project setup and guardrails  |  **Depends on** [003](003-strict-lints.md)

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Create every directory the architecture requires under frontend/, each with a barrel file, so no later task invents a location.

## Files

- `frontend/lib/app/` (new)
- `frontend/lib/core/` (new)
- `frontend/lib/features/` (new)
- `frontend/tool/paths.dart` (new)

## Steps

1. Create app/, and core/ with ai, background, bundle, cloud, concurrency, constants, copy, db, device, errors, export, feedback, files, hash, ids, import, lifecycle, logging, naming, network, normalise, permissions, security, serialisation, team, time, validation and widgets. This list is exhaustive: it is every core directory the plan goes on to use, and `frontend/tool/paths.dart` is what makes that checkable.
2. Create features/ with one folder per feature named in the plan, each containing empty data/, domain/ and presentation/ directories.
3. Write `frontend/tool/paths.dart` exporting the canonical directory list as constants, so guardrail checkers read the structure from one place rather than hardcoding paths.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] Every directory named in the plan exists and contains a barrel file.
- [x] Tests written and passing: `frontend/tool/check_structure.dart` fails when a required directory is missing or an unexpected top-level directory appears.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
