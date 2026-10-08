# 150 — Restore current-tree frontend guardrail compliance

**Depends on** [001](../01-orchestration.md)

## Implement

Repair only the existing naming and test-coverage gaps verified by task 147's current-tree guardrail run. Keep the
checker rules and automatic route discovery intact; this is acceptance repair, not new application behavior.

- Give the already-public `MeetingReviewEdits` typedef its own correctly named file and update its existing callers.
  Keep the controller and edit/save behavior unchanged.
- Correct the naming checker's multiline variable-header parsing. The valid
  `processingCancellableTemplateAssistProvider` declaration currently produces an uppercase `Provider` finding
  because the checker treats the first line, `final Provider<`, as the variable name. Preserve true provider-name,
  public-type/file-name, file-layout and all-findings enforcement, including original declaration line numbers.
- Supply meaningful mirrored tests for the nine capture/processing domain and data files listed below, reusing
  existing real database fixtures and grounded processing tests. File existence and duplicated generic assertions
  alone do not satisfy their contracts.
- Reconcile automatic discovery of `ProjectHomeScreen` and `ReviewScreen` with actual production-route fixtures.
  Cover empty records/templates on a retained project, empty review findings on a retained record and missing-owner
  recovery. Reuse the existing screen harness and test the enabled, reachable next action where the empty-state
  contract requires it; do not manufacture data or a fake screen to silence inventory findings.

Task 111 already owns the separately verified Whisper source/build provenance drift; tasks 148 and 149 own the
iOS notification setup and nested compression-metadata gaps. Dependency API/analyzer repairs belong to task 147.
None is added to this task, and task 146's delivered PNG cleanup remains in force.

## Files

- `frontend/tool/check_naming.dart`
- `frontend/test/tool/check_naming_test.dart` and exact positive/negative multiline declaration fixtures under `frontend/test/tool/fixtures/naming/`
- `frontend/lib/features/meetings/presentation/meeting_review_controller.dart`
- `frontend/lib/features/meetings/presentation/meeting_review_edits.dart` (new; existing typedef only)
- Existing callers of `MeetingReviewEdits`, including `frontend/test/features/meetings/presentation/meeting_review_controller_test.dart`
- `frontend/lib/features/capture/data/deleted_capture_files.dart`
- `frontend/lib/features/capture/domain/attachment_repository.dart`
- `frontend/test/features/capture/data/deleted_capture_files_test.dart` (new)
- `frontend/test/features/capture/domain/attachment_repository_test.dart` (new)
- `frontend/lib/features/processing/data/extraction_responses.dart`
- `frontend/lib/features/processing/data/online_extraction.dart`
- `frontend/lib/features/processing/data/processing_evidence.dart`
- `frontend/lib/features/processing/data/processing_findings.dart`
- `frontend/lib/features/processing/data/processing_usage.dart`
- `frontend/lib/features/processing/domain/processing_findings_repository.dart`
- `frontend/lib/features/processing/domain/processing_usage_repository.dart`
- `frontend/test/features/processing/data/extraction_responses_test.dart` (new)
- `frontend/test/features/processing/data/online_extraction_test.dart` (new)
- `frontend/test/features/processing/data/processing_evidence_test.dart` (new)
- `frontend/test/features/processing/data/processing_findings_test.dart` (new)
- `frontend/test/features/processing/data/processing_usage_test.dart` (new)
- `frontend/test/features/processing/domain/processing_findings_repository_test.dart` (new)
- `frontend/test/features/processing/domain/processing_usage_repository_test.dart` (new)
- `frontend/test/support/screen_fixtures.dart`, `frontend/test/support/screen_harness.dart`
- `frontend/test/support/screen_inventory.dart` (only if a fixture-proven discovery correction is necessary)
- `frontend/test/states/screen_inventory_test.dart`, `frontend/test/states/empty_state_coverage_test.dart`
- `frontend/.gitignore` (exact test/helper/static-fixture exceptions only)

## Definition of done

- [ ] Public meeting types satisfy their file names, and existing review controller/save/reopen tests retain the same behavior.
- [ ] The naming checker accepts the valid multiline generic/function-type provider and rejects actual uppercase or incorrectly suffixed names; every finding retains its real file and declaration line.
- [ ] Tests: positive and deliberate negative naming fixtures pass without exclusions, assertion weakening or a rewritten valid feature declaration hiding the parser defect; the current-tree naming checker is clean.
- [ ] Tests: each of the nine mirrored domain/data suites exercises its real contract, including applicable restore ownership/durable-byte failure, stale extraction/cancellation, evidence identity, findings/retry approval and attributable usage boundaries; existing neighboring regressions remain green.
- [ ] Tests: strict test presence passes, all nine suites and their transitive helpers/static fixtures ship, and no image removed by task 146 is restored as a delivered file.
- [ ] Tests: automatic screen inventory and actual-route empty-state coverage pass for ProjectHomeScreen and ReviewScreen, with retained-owner/empty-child and missing-owner cases; no waiver list or lowered semantics, layout or tap-target threshold is introduced.
- [ ] Changed-source formatting, frontend analysis and relevant architecture/security guardrails pass on the current tree; deliberate-violation fixtures still fail.
- [ ] Owning tasks 023, 132 and 143 record fresh verified evidence before their reopened criteria close; tracker generation and `--check` pass.

## Evidence

2026-10-08: `frontend/build/task147-tool-guardrail-tests.log` ended with 562 passes and eight failures. This task
owns the two repeated shipped-tree naming assertions, the strict test-presence assertion's nine missing mirrored
tests, and screen inventory's missing `ProjectHomeScreen`/`ReviewScreen` fixtures. All architecture suites and the
two in-memory AST discovery regressions passed. The naming and test-presence checkers use unchanged text/path logic;
their findings predate the package upgrade. The collection routes are discovered through existing async-list
components, independently of the migrated named-argument AST visitor. Three speech-provenance assertions remain
with task 111, and the analyzer assertion's dependency-migration diagnostics remain with task 147. Implementation
has not begun; every acceptance item remains open.
