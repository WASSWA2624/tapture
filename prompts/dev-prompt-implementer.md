Read in order: this prompt, the full task, AGENTS.md, every rule file named in Constraints, the task's dependencies, and the code and callers the change touches.

Build only the task's Implement, Files, Contract, Steps, and Definition of done. Stop at Out of scope. Change as little as possible; keep matching files, modules, and public APIs. Do not edit this prompt. Reuse `core/` and `Radii`. Send anything else to `dart run tool/new_task.dart <step> "<title>"` from `frontend/`.

Set `**Implementation started:** Yes` before the first checkbox. Tick a box only after that requirement is verified. Reopen a box the evidence contradicts. Leave the task Partially complete while any box is open.

After every checklist change, and before reporting, run from `frontend/`:

    dart run tool/sync_dev_tracker.dart
    dart run tool/sync_dev_tracker.dart --check

The tracker row must match the checklist. Do not hand-edit `dev-tracker.md`.

Gates, from the package they belong to. Run a gate only when the task touches that package:

- Flutter, from `frontend/`: `dart run tool/verify.dart --changed <paths>`. This is the only Flutter gate. Pass the task's changed paths, package-relative (`lib/…`, `test/…`) or `../` for files outside `frontend/`. It formats, analyzes, and tests those files, and runs a repository checker only when one of that checker's inputs is included. Omit the paths only when the worktree contains this task's changes and nothing else.
- Backend, from `backend/`: `npm run verify`.

Run the tests the Definition of done names, and exercise changed screens. A new checker must pass valid code, fail a violating fixture, and report every violation with file and line. Report blockers and checks not run.

Commit and push only after the gates pass and the checklist matches:

- Branch `task/<number>-<slug>`, created from HEAD when the current branch is main or master.
- Stage the task's files, its checklist, and the generated tracker. Leave unrelated work unstaged.
- Subject: `NNN Why this change`.
- `git push -u origin HEAD`.

Keep the hooks. Fix a hook failure with a new commit. No empty commits, secrets, `--no-verify`, `--amend`, force-push, git-config changes, or pushes to main or master.

Report the task ID, Complete or Partially complete, boxes closed, the tracker row, gate results, and whether the commit and push happened.
