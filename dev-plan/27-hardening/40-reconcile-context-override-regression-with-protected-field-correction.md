# 161 — Reconcile context override regression with protected field correction

**Depends on** [011](../11-context.md), [014](../14-records.md)

## Implement

Reproduce the context-on-records regression that attempts to refine a protected context field through ordinary `editValues` and receives “This field is read-only.” Reconcile the test with the current explicit automatic-field correction contract, or correct a demonstrated production defect through that contract. Preserve raw captured context, sibling records, project context and audit history; do not remove the protection to make a legacy test pass.

## Files

- `frontend/test/features/context/data/context_on_records_test.dart`
- `frontend/lib/features/records/data/record_repository_impl.dart`
- Existing explicit automatic-field correction tests and real database fixtures

## Definition of done

- [ ] Baseline reproduction and owning correction contract establish the cause of the failed ordinary edit.
- [ ] The intended correction path refines only the selected record, preserves its original context and all siblings/project context, and writes the required audit evidence.
- [ ] Meaningful database tests, analysis, tracker synchronization and plan checks pass without weakened protection.

## Evidence

2026-10-09: task 158's additional contract run passes 51 tests and fails this existing ignored-source test at line 126 with “This field is read-only.” Production record-editing and context persistence sources are unchanged by task 158. Baseline verification is recorded separately; no fix is included in the Capture setup task.

Baseline verification: the same unchanged acceptance source fails at line 126 with the same read-only result against the isolated `d921abb0` production sources (`frontend/build/task158-baseline-context-override.log`). No task-158 presentation source participates in that database test.
