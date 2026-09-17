# 001 — Create the Flutter project

**Phase** 01 · Project setup and guardrails

> **Implementation prompt.** Build exactly this task against the current repository state, then stop. The deliverable is working, analysed, tested Dart code — not a description of it.

## Implement

Initialise the Flutter application inside frontend/ with the Tapture identity, and delete the demo code.

## Files

- `frontend/pubspec.yaml` (new)
- `frontend/lib/main.dart` (new)

## Contract

```dart
void main()  // renders an empty MaterialApp scaffold; no counter demo
```

## Steps

1. Run the Flutter create command into frontend/ with organisation com.tapture and project name tapture, Android platform first.
2. Set the display name to Tapture and the application id to com.tapture.app in the Android manifest and Gradle config.
3. Delete the counter demo widget and its generated test; leave main.dart rendering an empty scaffold.

## Constraints

- Obey `frontend/.rules/`. The ones that bite here: `frontend/.rules/01-structure.md`, `frontend/.rules/02-coding-standards.md`, `frontend/.rules/13-workflow.md`.
- Checkers and guardrail tests must pass on the current tree and fail on a deliberate violation; ship a fixture proving both.
- A guardrail reports every violation it finds, with file and line, rather than stopping at the first.
- Build only what this file describes. Anything else you find becomes a new task file (`dart run tool/new_task.dart`), never extra scope here.
- `dart format` applied, `flutter analyze` clean, and `dart run tool/verify.dart --fast` green before this task closes.
- No `print`, no `TODO`, no hardcoded secret, no commented-out code left behind.

## Definition of done

- [x] The app builds and launches to a blank scaffold on a device or emulator.
- [x] No generated demo code remains anywhere in lib/ or `frontend/test/`.
- [x] Tests written and passing: `frontend/test/smoke_test.dart` pumps the app and asserts it builds without exception.
- [x] Contract above is implemented exactly, with nothing else made public.
- [x] Analyzer clean, formatter applied, guardrail suites green.

## Out of scope

- Anything not named above. Raise it as its own task rather than widening this one.
