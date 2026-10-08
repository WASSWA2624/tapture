# Feedback prompts — TAPTURE-08102026-1045.xlsx

12 entries → 1 prompt, 11 work items. Generated 2026-10-08 (Africa/Kampala). Repository commit: `1efe1204`.

Read all 12 Feedback rows, all 19 screenshot files and Export Details (12 records, 19 images, all categories/platforms/screens, no search/date filter). The archive was generated at 10:45 EAT. The repository was accessible; every actionable entry was checked against current code. The output directory was absent, so numbering starts at 001. No application, test, plan and tracker changes were made during generation.

All observations: General feedback, Android, Mobile, app 1.0.0, production, English, compact portrait, viewport 393×886 at 2.75x, display 393×886, text scale 1, online. FBK0000188–FBK0000196 use light theme; FBK0000197–FBK0000199 use system (dark). Device model is reported only as Android; the OS field contains a vendor build string, which is unnecessary to the shared causes. Submission times span 05:49–06:14 EAT on 2026-10-08. Routes below replace personal/project identifiers with parameters. Reporter identity, device identifiers, addresses and user agents are intentionally omitted.

Use [001 — Streamline field workflow feedback](001-streamline-field-workflow-feedback.md). Its Decisions must be answered before implementation; this generation task does not execute the implementation prompt.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Publish one project archive through a shorter export flow | FBK0000188, FBK0000189 | Defect | P3 | — |
| 001 | W2 | Label every recycle-bin Restore action | FBK0000197 | Defect | P3 | — |
| 001 | W3 | Retire the Check files page | FBK0000198 | Improvement | P5 | — |
| 001 | W4 | Retire the standalone Rapid mode | FBK0000190 | Improvement | P5 | — |
| 001 | W5 | Move manual capture fields into the menu | FBK0000190, FBK0000191 | Improvement | P5 | W4 |
| 001 | W6 | Access processing from each project | FBK0000199 | Improvement | P5 | — |
| 001 | W7 | Compact the expanded speech-model list | FBK0000195 | Improvement | P5 | — |
| 001 | W8 | Relocate standalone account setup into AI settings | FBK0000194 | Improvement | P5 | — |
| 001 | W9 | Consolidate AI explanations and status | FBK0000193 | Improvement | P5 | W8 |
| 001 | W10 | Add reusable provider branding to the choice field | FBK0000192 | Suggestion | P6 | W9 |
| 001 | W11 | Expose configured xAI accounts through Responses | FBK0000192 | Suggestion | P6 | W10 |

## Coverage

Each entry has exactly one classification below. W1 combines export interaction/publication in the same flow; W4/W5 split independent Rapid removal and Capture composition; W10/W11 split branding and provider capability. Sharing a settings screen alone does not merge independent requests. There are no duplicates, already-resolved entries, or out-of-scope entries.

| Feedback ID | Category | Screen / route | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000188 | General feedback | Projects › project › Export project; `/projects/:projectId/exports` | Improvement → **001 W1**. Requests fewer export steps. Images `FBK0000188.png`, `-2.png`, `-3.png` show the project Export menu, a mandatory preflight summary/Export tap, then scrolled details and Reports/data action. Current `project_export_screen.dart:145/178` still requires that sequence. |
| FBK0000189 | General feedback | Projects › project › Export project; `/projects/:projectId/exports` | Defect → **001 W1**. Requests one project ZIP. Image shows completed summary/Share, not the alleged file count. Current `export_repository_impl.dart:311/319` already creates a ZIP with its workbook nested; `project_export_screen.dart:215` then publishes a second native copy through `saveStored`, confirming duplication at the publication layer. |
| FBK0000190 | General feedback | Capture; `/capture` | Improvement → **001 W4, W5**. Requests less congestion and removal of Rapid. First two images show context/target/guide/evidence/import/caption controls; `-3.png` shows the Rapid entry; `-4.png` shows its separate run list/footer. Current `capture_screen.dart:409/518/632` still exposes mode, inline fields and separate import. |
| FBK0000191 | General feedback | Projects › project › Capture; recorded `/projects/:projectId/capture/rapid` | Improvement → **001 W5**. Requests manual form access through the menu. The image shows regular Capture's long metadata form despite the route value; scope is the shared Capture form, not only Rapid. Current `InlineFieldsSection` remains in normal Capture at `capture_screen.dart:518`. |
| FBK0000192 | General feedback | AI; `/more/ai`, route name `settingsAi` | Suggestion → **001 W10, W11**, subject to D8/D9. Requests additional providers and logos. Image shows three text-only account choices. Current shared choice field lacks an asset-leading slot and `server_provider_registry.dart:68` retains only Gemini/OpenAI before catalogue refresh. Compatible administrator-defined providers already work; the bounded recommended addition is xAI. |
| FBK0000193 | General feedback | AI; `/more/ai`, route name `settingsAi` | Improvement → **001 W9**. Requests less crowded text. Three images show custody, fallback, credential-status failure and unavailable/test messages around settings, with spending controls expanded/collapsed. Current `ai_provider_settings_screen.dart:122/135/211/231` still stacks these states. |
| FBK0000194 | General feedback | Organisation; `/more/account` | Improvement → **001 W8**, subject to D7. Requests removal of the pictured page. Image identifies the standalone empty server-address/optional-organisation form. Current `account_route.dart:30` still returns it. Default relocates its existing capability into AI; initial self-hosted sign-in setup is retained because the same form is required there. |
| FBK0000195 | General feedback | Language; `/more/language`, route name `settingsLanguage` | Improvement → **001 W7**. Requests an organized, less congested UI. Image shows expanded model rows with decorative wells, repeated metadata and separate Verify buttons. Current `speech_settings_section.dart:307/347` retains that presentation. The existing collapsed default is acknowledged, not claimed as a new fix. |
| FBK0000196 | General feedback | Language; `/more/language`, route name `settingsLanguage` | **Question → Needs clarification:** Which named settings/content should be removed? The message only says some things can go; its unmarked image shows app/voice language, offline engine, transcription quality and model management without identifying a target. Do not remove language choices, speech quality, offline recovery and model capabilities on this evidence. W7 addresses the separate visual report but does not close this question. |
| FBK0000197 | General feedback | Recycle bin; `/more/recycle-bin`, route name `recycleBin` | Defect → **001 W2**. Requests a recognizable Restore button with icon/label. Image shows icon-only deleted-project actions. Current record and other-entity rows use `AppIconButton` at `recycle_bin_screen.dart:260/325`; shared Restore glyph remains trash-shaped. |
| FBK0000198 | General feedback | Check files; `/more/storage/check` | Improvement → **001 W3**, subject to D3. Requests removal of the pictured diagnostics page. Image lists missing references/unowned files. Current Storage entry and `router.dart:910` still expose it. Remove presentation under the default; diagnostics/import guards and all raw files remain intact. |
| FBK0000199 | General feedback | Unprocessed; `/more/queue`, route name `queue` | Improvement → **001 W6**, subject to D6. Requests project-only Process access. Image displays a global queue and unassigned group. Current `status_line.dart:248` and `router.dart:1005` expose global processing; project-scoped route already exists. Keep unassigned evidence and the existing pipeline. |

Code references in this table resolve beneath `frontend/lib/`: presentation filenames are in their named features, `router.dart` is `app/router.dart`, `status_line.dart` is `app/widgets/status_line.dart`, and `server_provider_registry.dart` is `core/ai/server_provider_registry.dart`. Every executable item gives full paths. Image names resolve under `prompts/TAPTURE-08102026-1045/screenshots/`; their contents are paraphrased in the prompt so implementation does not require this archive open.

## Open questions

- **001 D1 / W1:** immediate local export versus summary-first. Default **a**, immediate local generation; **b** leaves the shortening request open.
- **001 D2 / W1:** approve existing canonical native location, explicit platform handoff and one web download. Default **a**; **b** pauses W1 for another destination policy.
- **001 D3 / W3:** retire Check files page/entry versus entry-only removal. Default **a**, legacy route redirects to Storage and services/evidence remain.
- **001 D4 / W4:** retire Rapid surface versus retain. Default **a**, legacy project route redirects to ordinary Capture with its shared draft preserved.
- **001 D5 / W5:** menu access to template fields/document import versus fields-only relocation. Default **a**, caption/dictation/audio stay visible.
- **001 D6 / W6:** retire global Process versus badge-only removal. Default **a**, project menu access and legacy global redirects to Projects; keep unassigned evidence.
- **001 D7 / W8:** inline account relocation versus shortcut-only removal. Default **a**, collapsed AI account section plus compatibility redirect; initial sign-in setup remains.
- **001 D8 / W10:** approve additive shared leading-slot API and official bundled logos versus defer. Default **a**, existing caller defaults unchanged, no dependency.
- **001 D9 / W11:** add configured xAI through the existing Responses protocol versus await named providers. Default **a**, explicit admin models/budget and no deployment/live traffic.
- **001 D10 / all items:** authorize a bounded exception to plan execution order versus wait for earlier open steps. Default **a**, feedback-only exception using completed shared dependencies; historical task 143 approval is not reused.
- **Reporter — FBK0000196:** Which specific controls/content on Language should be removed? Name them, such as app-language summary, offline-engine explanation, quality control, model details, Verify and import. There is **no inferred default** for deleting supported settings; the report stays open until its target is named.

There is no split: all specified changes can run against this repository in one ordered prompt. Human decisions, multiple platforms and mixed priorities do not justify a second prompt. Rejected/deferred defaults and unavailable required verification must be reported as Partially complete by the implementation runner.
