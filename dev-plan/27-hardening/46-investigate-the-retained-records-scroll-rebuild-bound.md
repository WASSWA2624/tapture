# 173 — Investigate the retained Records scroll rebuild bound

**Depends on** [014](../14-records.md#014--records-find-read-and-change-what-was-captured), [157](../24-product-refinements.md#157--reduce-shared-component-internal-padding)

## Implement

Diagnose the retained 10,000-record scroll test's rebuilt-row bound against current compact geometry. Measure its viewport, row/prototype height, cache extent and frame/read behavior; identify the cause before correcting the production implementation or the evidenced assertion. Preserve the paging, smooth-scroll and lazy-materialization budgets.

## Files

- `frontend/test/features/records/presentation/records_list_screen_test.dart`
- `frontend/test/features/records/presentation/records_list_harness.dart`
- Confirmed record-list cause files identified by the investigation
- Relevant portable acceptance-source patch and hash manifest
- This task and generated `dev-tracker.md`

## Constraints

Never raise a budget merely to make a test pass. Keep the 10,000-record fixture, timing and page-read checks, and use measured current geometry for a test-bound correction. No broad performance refactor. Follow FE-PERF-01/03/06, FE-TEST-01/02/06/09 and FE-FLOW-02/03/08.

## Definition of done

- [ ] An isolated measurement explains the observed rebuilt-row count, including current row height, viewport and cache/frame contribution.
- [ ] The confirmed cause is corrected and the full 10,000-record scroll assertion passes with the original timing/page-read budgets intact.
- [ ] Repeated focused measurements substantiate the corrected bound; portable source/hash delivery, formatting, analysis, tracker synchronization, `--check` and plan integrity pass.

## Evidence

2026-10-13, task 170: full and isolated runs observe 28 rebuilt rows against a bound of 27. The isolated timing assertions and four-page read limit pass (`frontend/build/task170-w2-retained-scroll.log`); the source of the row-count mismatch has not been established. Task 170 changes only icon outlines and preserves row/prototype geometry. No repair or budget relaxation has begun.
