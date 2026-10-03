# 11 — Workflow

## Progress tracking — task 087

After every backend implementation/status change, update the corresponding dev-plan acceptance checklist and
automatically regenerate the shared tracker from `frontend/` with `dart run tool/sync_dev_tracker.dart`, followed
by `--check`. Complete, Partially complete and Pending follow `AGENTS.md`; record
`**Implementation started:** Yes` when work exists but no acceptance item is verified. Include generated progress
changes with the implementation. The shared pre-commit hook also refreshes the tracker for backend-only commits,
without staging unrelated files; CI rejects drift. Backend verification success alone never updates or approves
an unchecked acceptance item.

## BE-FLOW-01 — One task, one branch, one pull request

`task/<number>-<slug>`, commit subjects starting with the task number, matching the frontend convention.

## BE-FLOW-02 — The gate is a command

One script runs format, lint, type check, unit, integration and contract tests, plus the dependency and secret scans.
It runs identically locally and in continuous integration.

## BE-FLOW-03 — API changes travel together

Route, OpenAPI document, contract test and client expectation change in the same pull request, or the change is not
finished.

## BE-FLOW-04 — Security changes need a second reader

Authentication, authorisation, relay access, retention and key custody. Named in the pull request template.

## BE-FLOW-05 — Dependencies need a task

Pinned version, licence note, and a sentence on what it replaces.

## BE-FLOW-06 — Rules change deliberately

Editing this folder means updating the enforcing test in the same change.

## BE-FLOW-07 — The boundary is not negotiable in a pull request

A change that would make the server a durable store, a backup or a reader of project content is rejected on sight and
becomes a specification discussion instead.
