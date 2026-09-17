# 241 — Failure injection suite

**Phase** 23 · Hardening  |  **Depends on** [014](../01-orchestration/014-riverpod-test.md), [138](../12-capture/138-capture-recovery.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The harness that forces any injectable dependency to fail on demand, and the suite that drives each one into failure
and proves the app stays usable with its evidence intact.

## Files

- `frontend/test/support/fault_injection.dart` (new)
- `frontend/integration_test/failure_paths_test.dart` (new)

## Contract

```dart
class FaultInjector {
  void fail(Dependency d, Failure f);
  void clear();
}
```

## Steps

1. Make every injectable service consult the injector, so a test can fail it per case and restore it with `clear`.
2. Cover camera denied, microphone denied, storage full, provider unreachable, key invalid, response malformed, bundle
   corrupt, database locked and the process killed mid-capture.
3. Assert for each case: nothing captured is lost, the message names what happened and the next step, and the retry
   path (256) actually completes.

## Constraints

- Every injectable dependency has a case; adding one without a case fails the suite (FE-TEST-10).
- The suite runs offline with no real provider reachable (FE-TEST-05).
- Degradation is partial and named, never a freeze or a blank screen (FE-PERF-10).

## Definition of done

- [ ] Every injected failure leaves the app usable, the raw evidence intact and a retry that works.
- [ ] Tests: the failure-path suite, one case per dependency, plus a fixture proving the injector itself fails a call
      and restores it on `clear`.
