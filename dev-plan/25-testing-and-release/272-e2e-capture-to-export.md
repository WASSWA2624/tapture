# 272 — End-to-end: capture to export, immediate and deferred

**Phase** 25 · Testing and release  |  **Depends on** [136](../12-capture/136-save-immediate.md), [206](../18-export/206-export-screen.md), [271](271-test-harness-unit.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two integration runs over the capture spine: the core path processed as it goes, and forty records captured with the
network off and processed later. Together they are the vertical slice no change may break silently.

## Files

- `frontend/integration_test/capture_to_export_test.dart` (new)
- `frontend/integration_test/offline_deferred_test.dart` (new)

## Steps

1. `capture_to_export_test.dart` — create a project, pick a template, set context, capture, process, review, approve,
   export. Assert the exported file carries the approved values for every captured record, and that the run touches no
   screen state the app cannot rebuild from the database.
2. `offline_deferred_test.dart` — with the backend and provider unreachable, capture forty records saved raw (254),
   then process them in a later pass, then export. Assert `outboundCallCount` stays zero for the whole capture stretch,
   that each save is durable before the interface confirms it, and that raw values survive beside the refined ones.
3. Export the same input through both runs and compare: deferred processing must produce an identical export to
   immediate processing.

## Constraints

- Capture is never blocked by a missing network, an unreachable server or a slow provider; the offline run asserts this
  rather than assuming it (FE-SEC-04).
- Raw values are append-only — the deferred run reads the raw column after refinement and finds it unchanged
  (FE-SEC-08).

## Definition of done

- [ ] A break anywhere between capture and export fails one of the two runs loudly, naming the step.
- [ ] The offline run records zero outbound calls during capture and forty durable records before any processing.
- [ ] Deferred and immediate processing of the same input yield the same export.
- [ ] Tests: both files run green offline against the fakes from 504, in the pipeline's integration job.
