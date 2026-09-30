# Repository instructions

- Write efficient, professional, standard code and prefer reuse.
- Reuse uniform UI components and use the minimal corner radius (`Radii`, never zero).
- Follow `dev-plan/STANDARD.md` and the relevant frontend/backend rules.
- Keep `app-write-up.md` complete and concise: preserve distinct requirements, contracts and stable section
  references; consolidate repetition and use cross-references. Record implementation status in the tracker.
- Keep `dev-tracker.md` a brief visual dashboard. Put full task checklists/dependencies in the index and folder
  READMEs; progress bars count completed files without estimating partial effort.
- Use the chronological step/substep positions in `dev-plan/INDEX.md`. The three-digit task IDs are stable
  references, not execution positions; do not renumber them when a task moves.
- Keep whole-product hardening in the final numbered folder, after feature work and release infrastructure.
- Before implementing, read the task's dependencies and Definition of done. Set
  `**Implementation started:** Yes` if work has begun before any acceptance item can be checked.
- Update that task's acceptance checklist as verified work lands. Do not mark an item complete just because its
  file exists, a mock succeeds, or a later task is planned to finish it. Reopen criteria contradicted by evidence.
- **Every implementation update must refresh `dev-tracker.md` automatically before the work is reported done.**
  Run `dart run tool/sync_dev_tracker.dart` from `frontend/` after changing task progress, then
  `dart run tool/sync_dev_tracker.dart --check`. Task creation, frontend verification and the installed pre-commit
  hook also invoke the same synchronizer. This applies to frontend, backend and plan-only implementation work.
- Never hand-edit generated tracker/index/folder summaries or generated `Implementation step` metadata. Change
  the task checklist/source notes, then regenerate. Include the generated changes with the implementation;
  preserve unrelated user edits and do not automatically stage them.
- If implementation or required verification remains unfinished, report Partially complete and leave the relevant
  acceptance items open. The tracker records acceptance status; it does not certify the whole repository is green.
