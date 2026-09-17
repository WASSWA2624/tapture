# 279 — Release gate program

**Phase** 25 · Testing and release  |  **Depends on** [234](../22-privacy-and-security/234-secret-scan-test.md), [275](275-e2e-merge.md), [277](277-ci-pipeline.md), [278](278-release-build.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The program that verifies every release condition and refuses to produce a build when one fails. A release is two
artefacts, the app and the backend it requires (A70), and the gate covers both.

## Files

- `frontend/tool/release_gate.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // --tag <version>; exits 0 only when every gate passes
```

## Steps

1. Run and record, for the app: the full verify command, a secret scan over the built artefacts, a migration test from
   the previously released schema, an offline end-to-end run, an export opened by a spreadsheet reader, and the
   permission list diffed against the previous release.
2. Run and record, for the backend: `npm run verify`, its own migration test from the last released schema, the contract
   tests against the published specification, and a scan proving no provider key can leave the server.
3. Run and record, for the pair: the sign-in, proxy and offline end-to-end run (521), which is the gate that proves a
   required backend is never a required connection (A70.4).
4. Print a gate table of pass, fail and waived, and write it beside the artefact as the release record.
5. Exit non-zero on any failure; a skipped gate counts as a failure unless waived explicitly on the command line.

## Constraints

- The backend migration and contract gates run from the last released schema, not from empty (BE-TEST-09).
- A waiver is recorded with its reason in the release record and surfaces in the backlog report (520).

## Definition of done

- [ ] A build cannot be produced while any gate fails, in either the app or the backend.
- [ ] A backend whose contract tests fail blocks the app release, and the record says why.
- [ ] The 521 gate failing blocks the release even when every other gate passes.
- [ ] Tests: `frontend/test/tool/release_gate_test.dart` covers the pass, fail and waiver paths, including a failing
      backend gate and a skipped gate treated as a failure.
