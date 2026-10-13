# 172 — Dispose Records pane test semantics before framework verification

**Depends on** [014](../14-records.md#014--records-find-read-and-change-what-was-captured)

## Implement

Investigate and correct the retained Records pane test's semantics-handle lifetime. Preserve its full-text, focus, tap-target and accessibility assertions; release the test-owned handle before Flutter's end-of-test framework verification rather than relying on later teardown.

## Files

- `frontend/test/features/records/presentation/records_list_screen_test.dart`
- Relevant portable acceptance-source patch and hash manifest
- This task and generated `dev-tracker.md`

## Constraints

No application or shared accessibility-checker changes. Do not skip the test, suppress the framework assertion or remove its semantics checks. Follow FE-A11Y-10, FE-TEST-01/02/06 and FE-FLOW-02/03/08.

## Definition of done

- [ ] The pane test verifies the same full text and accessible controls, disposing every test-owned semantics handle on success and failure before framework verification.
- [ ] Isolated and retained pane/selection tests pass without changing application behavior or weakening assertions.
- [ ] Portable helper closure and hashes are verified; formatting, analysis, tracker synchronization, `--check` and plan integrity pass.

## Evidence

2026-10-13, task 170: the retained pane full-text test reaches end-of-test verification with its `addTearDown`-owned `SemanticsHandle` still active. Isolated reproduction after preserving the original harness defaults fails for the same handle lifetime (`frontend/build/task170-w2-retained-pane.log`). New task-170 row-control cases explicitly release their handles and pass. No implementation of this repair has begun.
