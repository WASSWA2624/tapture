# 171 — Align legacy Records list navigation acceptance with project-owned routes

**Depends on** [166](../24-product-refinements.md#166--simplify-project-navigation-and-recycle-bin-management)

## Implement

Reconcile the retained Records destination test with task 166's canonical project-owned record route. Confirm the current route contract and replace the obsolete legacy-address expectation without changing application navigation, redirects, selection or record operations. This is a test-contract repair discovered during task 170, not a production routing defect.

## Files

- `frontend/test/features/records/presentation/records_list_screen_test.dart`
- Relevant portable acceptance-source patch and hash manifest
- This task and generated `dev-tracker.md`

## Constraints

Preserve application code, legacy redirects, test coverage and ignore policy. Do not remove the navigation assertion or loosen it to a substring match. Follow FE-RESP-03, FE-SIMP-02, FE-TEST-01/02/06 and FE-FLOW-02/03/08.

## Definition of done

- [ ] The Records destination assertion verifies the exact canonical project-owned detail location and the expected record identity, with legacy redirect behavior retained.
- [ ] The repaired focused test and required routing regressions pass; unrelated Records suite failures remain attributed independently.
- [ ] Portable test/helper sources and reconstructed hashes are verified; formatting, analysis, tracker synchronization, `--check` and plan integrity pass.

## Evidence

2026-10-13, task 170: the unchanged retained test expects `/records/project-1-record-2` while the route is `/projects/project-1/records/project-1-record-2`, matching task 166. Both the full Records suite and isolated reproduction fail at this expectation (`frontend/build/task170-w2-retained-route.log`). Task 170's production row diff changes only the two outline arguments; its new edit/delete activation and project-owned navigation checks pass. No implementation of this repair has begun.
