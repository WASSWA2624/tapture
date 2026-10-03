# Implement one dev-plan task

Implement the single task file named with this prompt. Any `dev-plan/<folder>/<NNN-slug>.md` task uses this same procedure.

```text
Follow @prompts/dev-prompt-implementer.md on @dev-plan/<folder>/<NNN-slug>.md
```

Read the current code first. Map **Files**, **Contract**, and each **Definition of done** box to what is already on disk. If every box is checked and the code still meets them, stop with no edit, commit, or push. Change only what an open box, or a box the evidence shows is false, requires. Leave existing modules, public APIs, unrelated files, and this prompt as they are. A `new` file that already matches the contract stays. A `changed` file gets only the delta the task describes. Stop before any refactor that moves or rewrites existing modules.

Read, in order: this prompt; the named task in full; `AGENTS.md`; `dev-plan/STANDARD.md`; the rule files named in Constraints (`frontend/.rules/` or `backend/.rules/` in full — Constraints never drop a rule); dependency tasks only far enough to avoid breaking them; the task’s current **Files** and callers of any contract that must change. Stop if a required dependency is unmet. Leave that dependency unimplemented.

Build exactly what the task describes, then stop. Follow **Steps** and **Out of scope**. Set `**Implementation started:** Yes` before any box can be checked. Tick a box only after it is verified here; reopen a box the evidence contradicts. Ship the named tests. Reuse `core/` and `Radii`. Extra discoveries go to `dart run tool/new_task.dart` from `frontend/`.

After every checklist change, and again before reporting, run from `frontend/`: `dart run tool/sync_dev_tracker.dart`, then `--check`. That refresh is what updates `dev-tracker.md`; confirm its row for this task matches the checklist, then include `dev-tracker.md` and the other generated progress files in the same change. Leave the task Partially complete while any box is still open. Leave `dev-tracker.md`, the index, folder summaries, and `Implementation step` lines to the synchronizer.

Gate: Flutter — format, `flutter analyze`, `dart run tool/verify.dart --fast` from `frontend/`. Backend — `npm run verify` from `backend/`. A new checker passes on this tree, fails on a fixture violation, and reports file and line. When the task changes a screen or interaction, run the named tests and exercise that flow; state any check left unrun.

When the gate is green and the checklist matches it, commit and push this task only. Branch `task/<number>-<slug>` (create it from `HEAD` on `main` or `master`). Subject: `NNN Why this change`, using this task’s number. Stage the task’s files, its checklist, `dev-tracker.md`, and the other generated progress files. `git push -u origin HEAD` to `origin`. Keep the hook. If it fails, fix and make a new commit. No empty commit, secrets, `--no-verify`, `--amend`, force-push, git-config change, or push of `main`/`master`.

Report the task id, Complete or Partially complete, boxes closed, the matching `dev-tracker.md` row, gate result, and commit. If already satisfied, say so and list no files.
