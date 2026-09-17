# 12 — Testing

*Enforced by dev-plan task 016 (test presence checker); harnesses in task 271.*

## FE-TEST-01 — Tests ship with the change
A task is not done until its tests exist and pass. Tests are never a follow-up task.

## FE-TEST-02 — What each layer owes
Domain and pure logic: unit tests, no Flutter binding. Repositories and DAOs: tests against an in-memory database.
Widgets: behaviour tests. Design-system widgets: goldens in light, dark and outdoor. Flows: integration tests.

## FE-TEST-03 — Fakes, not mocks
Every service has a hand-written fake. Mocking frameworks are for third-party surfaces we do not own, not for our own
interfaces.

## FE-TEST-04 — Factories for fixtures
A valid project, template, record or photo is one line of setup. Long arrange blocks mean a missing factory.

## FE-TEST-05 — Integration tests run offline
The network is disabled by default; a test that needs a provider uses a fake. No test calls a real AI service.

## FE-TEST-06 — Guardrail suites are load-bearing
The architecture tests in phase 01 are never skipped, weakened or excluded to make a change pass. Fix the code, or
change the rule and its test together, in one pull request.

## FE-TEST-07 — No arbitrary waits
Pump to an explicit condition. A fixed delay in a test is a defect that will flake in continuous integration.

## FE-TEST-08 — Names read as sentences
`approving a record with an unresolved conflict fails validation`. If a name is hard to write, the test is doing two
things.

## FE-TEST-09 — Every performance claim has a measurement
A budget stated in a task is asserted by a test, not assumed.

## FE-TEST-10 — Failure paths are tested as carefully as success
Denied permissions, full storage, dead provider, corrupt bundle, killed process. Each must leave the app usable and
the evidence intact.
