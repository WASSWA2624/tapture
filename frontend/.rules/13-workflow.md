# 13 — Workflow

*Enforced by dev-plan tasks 001, 087 and 099 (plan checker, scaffolder, verification, Git hooks and progress tracking).*

## FE-FLOW-01 — One task, one branch, one pull request
`task/<number>-<slug>`. Commit subjects start with the task number. A pull request that touches two tasks is split.

## FE-FLOW-02 — The gate is a command
`dart run tool/verify.dart --changed` is the only gate. It runs format, the analyzer and tests for the files that
changed, and a repository checker only when one of that checker's inputs changed. The same command runs locally
before review and in continuous integration.

## FE-FLOW-03 — Done means the checklist is ticked
Every box in the task's Definition of done, including the tests. A partially finished task stays open rather than
merging with a promise.

The task checklist is the progress source, not the tracker or a percentage. Record `**Implementation started:** Yes`
when code work has begun but no acceptance item is verified. After every implementation/status change, run
`dart run tool/sync_dev_tracker.dart`; the regenerated `dev-tracker.md` must accompany the work.
Task creation, verification and the installed pre-commit hook refresh it automatically; CI uses `--check` to
reject drift. Never auto-tick acceptance or auto-stage a user's unrelated/partially staged changes (task 087).

## FE-FLOW-04 — Never widen a task
Anything discovered mid-task becomes a new task via `dart run tool/new_task.dart <step> "<title>"`. Scope creep is how a plan
stops being a plan.

## FE-FLOW-05 — Review cites rules
Feedback references a rule identifier or a specification section. Preference without a rule behind it is a suggestion,
not a blocker — and if it should be a rule, propose it as one.

## FE-FLOW-06 — Dependencies need a task
Adding a package requires its own task, an allowlist entry with a pinned version, a licence check and a note on what
it replaces.

## FE-FLOW-07 — Rules change deliberately
Editing this folder means editing the enforcing test in the same pull request, and saying in the commit body what
changed and why.

## FE-FLOW-08 — The plan is the backlog
New work becomes a numbered task in its step. Nothing lives only in a chat, an issue tracker or someone's memory.
Task IDs are append-only identities. Execution follows numbered steps and the task order within each, with prerequisites
earlier in that flow; moving a task does not change its ID.
