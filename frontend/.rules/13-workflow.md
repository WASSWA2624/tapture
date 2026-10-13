# 13 — Workflow

*Applied through focused changes, verification and review.*

## FE-FLOW-01 — One change, one branch, one pull request
Use a descriptive branch name and commit subjects that identify the change. Separate unrelated changes into their
own pull requests.

## FE-FLOW-02 — No review command
There is no `frontend/tool/verify.dart` and no continuous-integration step that runs one. Do not add that command back.

## FE-FLOW-03 — Done means verified acceptance
Complete the change's declared acceptance criteria, including required tests. Report Partially complete when
implementation or required verification remains unfinished, naming the remaining work and evidence.
Do not claim success from a file's existence, a planned follow-up or an older green summary. Preserve unrelated
user edits and partially staged changes; never stage them automatically.

## FE-FLOW-04 — Never widen a change
Record unrelated findings for separate work. Complete the agreed scope without adding an unrequested feature,
redesign or refactor.

## FE-FLOW-05 — Review cites rules
Feedback references a rule identifier or a specification section. Preference without a rule behind it is a suggestion,
not a blocker — and if it should be a rule, propose it as one.

## FE-FLOW-06 — Dependencies need approval and provenance
Adding a package requires documented approval, an allowlist entry with a pinned version, a licence check and a note
on what it replaces.

## FE-FLOW-07 — Rules change deliberately
Editing this folder means editing the enforcing test in the same pull request, and saying in the commit body what
changed and why.

## FE-FLOW-08 — Decisions and verification are reviewable
Record the agreed scope, interface contracts, acceptance evidence and remaining work with the change. Complete
declared prerequisites before dependent implementation. Preserve historical references and raw verification
evidence without treating them as fresh acceptance.
