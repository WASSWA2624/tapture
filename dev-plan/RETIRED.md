# Retired task numbers

On 2026-09-22 the 177 unstarted tasks numbered 105–281 were merged into sixteen, one for each remaining phase. The
work is unchanged: every deliverable, file, contract, constraint and test obligation those files carried is now
carried by the phase task that absorbed it. Only the packaging changed.

Each merged task takes the lowest number of the range it absorbs, so 105–120 are live. The numbers above that are
retired: they are not reused, and they are not left as an unexplained hole in a plan whose numbering is otherwise
contiguous. `check_plan.dart` reads the table below, so a gap is something the plan states rather than something it
lost.

Tasks 001–104 and 282–335 were already finished or in progress when the merge happened. None of them moved, and the
tracker entries and commit messages that name them still point at the same work.

## What absorbed what

| Was | Is now |
| :--- | :--- |
| 105–112 | [105 — Reference data](10-reference-data/105-reference-data.md) |
| 113–119 | [106 — Context](11-context/106-context.md) |
| 120–141 | [107 — Capture](12-capture/107-capture.md) |
| 142–161 | [108 — Processing](13-processing/108-processing.md) |
| 162–169 | [109 — Records](14-records/109-records.md) |
| 170–179 | [110 — Data quality](15-data-quality/110-data-quality.md) |
| 180–185 | [111 — Review](16-review/111-review.md) |
| 186–192 | [112 — Meetings](17-meetings/112-meetings.md) |
| 193–207 | [113 — Export](18-export/113-export.md) |
| 208–219 | [114 — Bundles and merge](19-bundles-and-merge/114-bundles-and-merge.md) |
| 220–223 | [115 — Data import](20-data-import/115-data-import.md) |
| 224–229 | [116 — Cloud upload](21-cloud-upload/116-cloud-upload.md) |
| 230–235 | [117 — Privacy and security](22-privacy-and-security/117-privacy-and-security.md) |
| 236–244 | [118 — Hardening](23-hardening/118-hardening.md) |
| 245–270 | [119 — The minimal backend](24-backend/119-minimal-backend.md) |
| 271–281 | [120 — Testing and release](25-testing-and-release/120-testing-and-release.md) |

## Retired numbers

This is the table the checker reads. A number listed here may hold a hole in the numbering, and no task file may
carry it.

| Numbers | Retired because |
| :--- | :--- |
| 121–281 | The sixteen phase tasks above absorbed the 177 tasks that held these numbers. |
