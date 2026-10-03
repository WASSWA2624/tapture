Read in order: this prompt, the full task, AGENTS.md, all rule files named in Constraints, relevant dependencies, and affected code and callers.

Implement only the task’s Files, Contract, Steps, and Definition of done. Respect Out of scope. Make minimal changes; preserve matching files, existing modules, and public APIs. Do not refactor or edit this prompt. Reuse core/ and Radii. Record unrelated discoveries using `dart run tool/new_task.dart` from frontend/.

Set **Implementation started:** Yes before checking any box. Check only verified requirements; reopen contradicted boxes. Keep the task Partially complete while any box remains open.

After each checklist change and before reporting, run from frontend/:
  dart run tool/sync_dev_tracker.dart
  dart run tool/sync_dev_tracker.dart --check

Confirm the tracker row matches the checklist. Leave tracker updates to the synchronizer.

Run applicable gates:
- Flutter: `dart run tool/verify.dart --changed` from frontend/.
- Backend: `npm run verify` from backend/.

Add and run the named tests; exercise changed screens and interactions. New checkers must pass valid code, reject a violating fixture, and report file and line. Report blockers and unrun checks.

Commit and push only when gates pass and the checklist matches verification:
- Use task/<number>-<slug>; create from HEAD when on main/master.
- Stage only task files, its checklist, and generated progress files.
- Commit subject: `NNN Why this change`.
- Push: `git push -u origin HEAD`.

Keep hooks; fix failures with a new commit. No empty commits, secrets, --no-verify, --amend, force-push, git-config changes, or pushes to main/master.

Report task ID, Complete/Partially complete, boxes closed, matching tracker row, gate results, and commit/push status.