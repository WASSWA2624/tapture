# 11 — Workflow

## Acceptance evidence

Record the agreed scope, acceptance criteria, actual verification results and remaining work with each change.
Report Partially complete when implementation or a required gate remains unfinished. Preserve historical evidence
without treating an old successful run as current verification. Never stage unrelated user edits automatically.
Backend verification success alone does not establish an unverified product or release requirement.

## BE-FLOW-01 — One change, one branch, one pull request

Use a descriptive branch name and commit subjects that identify the change, matching the frontend convention.
Separate unrelated work into its own pull request.

## BE-FLOW-02 — The gate is a command

One script runs format, lint, type check, unit, integration and contract tests, plus the dependency and secret scans.
It runs identically locally and in continuous integration.

## BE-FLOW-03 — API changes travel together

Route, OpenAPI document, contract test and client expectation change in the same pull request, or the change is not
finished.

## BE-FLOW-04 — Security changes need a second reader

Authentication, authorisation, relay access, retention and key custody. Named in the pull request template.

## BE-FLOW-05 — Dependencies need approval and provenance

Documented approval, pinned version, licence note, and a sentence on what it replaces.

## BE-FLOW-06 — Rules change deliberately

Editing this folder means updating the enforcing test in the same change.

## BE-FLOW-07 — The boundary is not negotiable in a pull request

A change that would make the server a durable store, a backup or a reader of project content is rejected on sight and
becomes a specification discussion instead.
