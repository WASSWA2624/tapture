# 271 — Test harnesses: unit, widget and integration

**Phase** 25 · Testing and release  |  **Depends on** [016](../01-orchestration/016-test-presence-checker.md), [031](../03-design-system/031-theme-assembly.md), [049](../04-data-layer/049-drift-setup.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Three layers of shared test scaffolding: unit support (hand-written fakes, matchers and fixture factories for domain
tests), a widget pump helper that installs theme, providers, router and a fixed clock, and an integration harness that
boots the real app against an in-memory Drift database with every service faked and the network refused. Every suite in
this phase is written on top of them.

## Files

- `frontend/test/support/fakes.dart` (new)
- `frontend/test/support/matchers.dart` (new)
- `frontend/test/support/pump_app.dart` (new)
- `frontend/integration_test/support/harness.dart` (new)

## Contract

```dart
// frontend/test/support/pump_app.dart
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  DateTime? now,
});

// frontend/integration_test/support/harness.dart
Future<TestApp> bootTestApp({List<Override> overrides = const [], DateTime? now});

abstract class TestApp {
  AppDatabase get db;
  TestClock get clock;          // advance() drives every cache and retention window
  FakeAiService get ai;
  FakeBackend get backend;      // reachable() and unreachable() flip server availability
  int get outboundCallCount;    // any non-zero value in an offline stretch is a failure
  Future<void> dispose();
}
```

## Steps

1. Build `frontend/test/support/` first: fakes for every service interface, matchers for domain failures, and
   factories giving a valid project, template, record and photo in one line each.
2. Layer `pumpApp` on those fakes so a widget test names only its overrides.
3. Layer `bootTestApp` on `pumpApp`'s provider wiring plus `AppDatabase.memory()`; install a socket guard that fails
   the test on any real outbound call rather than letting it hang.
4. Expose pump-to-condition helpers so no suite reaches for a fixed delay.

## Constraints

- Fakes are hand-written; a mocking framework appears only for third-party surfaces we do not own (FE-TEST-03).
- The harness disables the network by default and no fake ever reaches a real AI service (FE-TEST-05).
- Helpers pump to an explicit condition; the harness offers no sleep or fixed-delay API (FE-TEST-07).

## Definition of done

- [ ] A unit test needs no boilerplate beyond its assertions, a widget test starts from one `pumpApp` call, and an
      integration test starts from one `bootTestApp` call.
- [ ] An integration test that opens a real socket or calls a real provider fails with a named harness error.
- [ ] The fixed clock makes goldens in light, dark and outdoor reproducible across runs (FE-TEST-02).
- [ ] Tests: `frontend/test/support/harness_smoke_test.dart` proves each layer boots and that the socket guard bites;
      one domain suite, one widget suite and one integration suite are moved onto the harnesses and stay green.
