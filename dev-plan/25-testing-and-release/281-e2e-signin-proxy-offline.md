# 281 — End-to-end: sign in, proxy AI, then go offline

**Phase** 25 · Testing and release  |  **Depends on** [268](../24-backend/268-fe-role-affordances.md), [270](../24-backend/270-fe-ai-proxy-client.md), [271](271-test-harness-unit.md), [272](272-e2e-capture-to-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The end-to-end run that proves the sentence the MVP definition of done turns on (A67): an operator signs in once, runs
AI through the backend with no key on the device, and then does everything else with the server unreachable.

## Files

- `frontend/integration_test/signin_proxy_offline_test.dart` (new)

## Steps

1. Start against the fake backend. Sign in once, enrol the device, and assert the device holds no provider key at any
   point in the run.
2. Capture a record and process it through the AI proxy; assert the extraction succeeds and the usage counter moves.
3. Take the server away. Capture, review, approve, edit and export — all must succeed, with no login screen and no
   blocking dialog.
4. Advance the clock past both cache lifetimes with the server still away. Assert capture, review, edit and export still
   work, and that only relay, the proxy and a role change are refused, each with a plain-language reason.
5. Bring the server back. Assert the session and grant refresh silently, and queued proxy jobs drain on their own.

## Constraints

- The fake backend, the integration harness and the clock injection already exist in 504; this test adds no
  infrastructure of its own (FE-CONS-01).
- Nothing ships or stores a provider key on the device; the run asserts the absence, it does not merely avoid the path
  (FE-SEC-02).

## Definition of done

- [ ] The run passes with the backend reachable exactly once, at sign-in.
- [ ] No assertion in the run depends on a provider key existing on the device.
- [ ] After both cache lifetimes expire offline, capture, review, edit and export still work, and only relay, the proxy
      and a role change are refused.
- [ ] A failure anywhere in the offline stretch fails the release gate (519), not just this test.
- [ ] Tests: the integration test itself, running in the pipeline's integration job (516).

## Out of scope

- Relay, which is not in the MVP (A67, A72).
