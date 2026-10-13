# 174 — Reconcile retained Capture setup tests with project-scoped navigation

**Depends on** [166](../24-product-refinements.md#166--simplify-project-navigation-and-recycle-bin-management)

## Implement

Reconcile retained Capture setup and no-project acceptance with task 166's project-scoped navigation. The production workflow helper still expects a retired Change project overflow command before testing template/context/Manual and durable capture. Update the tests to exercise project choice through the current Projects flow, preserving every remaining setup, ownership, draft, keyboard and save assertion.

## Files

- `frontend/test/features/capture/presentation/capture_workflow_fixture.dart`
- `frontend/test/features/capture/presentation/capture_screen_test.dart`
- Native/browser workflow entry points and the recursive acceptance-source helper closure
- Relevant portable acceptance-source patch and hash manifest
- This task and generated `dev-tracker.md`

## Constraints

No production route, command, setting, default or persistence changes. Do not remove the setup helper or skip failing matrix cases. Preserve original field labels, per-project durable drafts and locked saved edits. Follow FE-SIMP-02/03, FE-RESP-03/07/10, FE-STATE-07, FE-TEST-01/02/05/06 and FE-FLOW-02/03/08.

## Definition of done

- [ ] Capture setup tests verify the current project-choice route plus surviving template/context/Manual commands and their exact ownership/order contracts.
- [ ] No-project recovery verifies the current Projects/create path and preserves durable capture data rather than restoring a retired in-Capture switcher.
- [ ] Required native, browser, keyboard and capture/save matrix tests execute and pass; independent browser-bootstrap limitations remain attributed to task 162.
- [ ] Portable helper closure/hash delivery, formatting, analysis, tracker synchronization, `--check` and plan integrity pass.

## Evidence

2026-10-13, task 170: two retained CaptureScreen no-project cases seek `capture-change-project`; the native production fixture's unchanged `_verifySetupCommands` expects that retired command first and fails before the new guide-absence assertions. Current Capture begins its setup overflow with template/context/Manual commands under task 166. Dedicated new removal/recovery cases pass; the obsolete setup expectations remain unchanged and recorded. No implementation of this repair has begun.
