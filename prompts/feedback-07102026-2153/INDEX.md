# Feedback prompts — TAPTURE-07102026-2153.xlsx

23 entries → 1 prompt, 16 work items. Generated 2026-10-07 (Africa/Kampala). Repository commit: `18949f21`, inspected with pre-existing local changes preserved.

Read every Feedback row, the Screenshots and Export Details sheets, and all 25 image files. The export contains all categories/screens/platforms, with no search or date restriction. All 23 reports are General feedback from Android, Mobile, compact, portrait, light, text scale 1, app version 1.0.0, production, English, online; viewport/display 393×886 logical pixels, device-pixel ratio 2.75. That observed configuration is evidence, not the implementation reach.

Source: `prompts/TAPTURE-07102026-2153/TAPTURE-07102026-2153.xlsx`; image filenames below are relative to its `screenshots/` directory. Project and meeting route identifiers and project names are deliberately replaced with placeholders. No reporter identity or device identifier is copied here.

The output is prompts only. No application, test, plan or tracker change was made. Current-code findings are static inspection; application verification belongs to the implementation runner. None of the entries is already resolved. Four entries duplicate FBK0000167; the remaining 19 canonical entries are covered by 16 work items, combining the import, global-menu and AI-configuration pairs by shared flow.

## Run order
| Prompt | Item | Title | Feedback | Type | Priority | After |
| --- | --- | --- | --- | --- | --- | --- |
| [001](001-resolve-field-workflow-feedback.md) | W1 | Preserve and clarify meeting review edits | FBK0000187 | Defect | P0 | — |
| 001 | W2 | Offer template setup without blocking capture | FBK0000185 | Gap | P1 | — |
| 001 | W3 | Validate project names while editing | FBK0000184 | Defect | P2 | — |
| 001 | W4 | Return through home screens before exit | FBK0000169 | Gap | P2 | — |
| 001 | W5 | Group project commands in the shared menu | FBK0000186 | Improvement | P3 | — |
| 001 | W6 | Remove Projects filter controls | FBK0000165, FBK0000166, FBK0000167, FBK0000174, FBK0000175 | Improvement | P4 | — |
| 001 | W7 | Remove global queue and transcript shortcuts | FBK0000171, FBK0000172 | Improvement | P4 | W4 |
| 001 | W8 | Open project packages directly and compact import | FBK0000168, FBK0000173 | Improvement | P4 | W6 |
| 001 | W9 | Remove repository links from About | FBK0000183 | Improvement | P4 | — |
| 001 | W10 | Remove the Organisation settings shortcut | FBK0000179 | Improvement | P4 | W7 |
| 001 | W11 | Move relay access into project settings | FBK0000180 | Improvement | P4 | W10 |
| 001 | W12 | Collapse advanced capture defaults | FBK0000181 | Improvement | P4 | — |
| 001 | W13 | Compact language and speech controls | FBK0000182 | Improvement | P4 | W12 |
| 001 | W14 | Expose shipped and custom templates globally | FBK0000170 | Gap | P4 | W2 |
| 001 | W15 | Include deleted projects and files in recycling | FBK0000176 | Gap | P4 | — |
| 001 | W16 | Configure supported AI providers in a compact flow | FBK0000177, FBK0000178 | Suggestion | P5 | W10, W13 |

One prompt is sufficient: all changes belong to this repository and their contracts can be specified before implementation. Scope decisions and the independent security review are contained within it; no external shipment result requires a later prompt.

## Coverage
Each entry appears exactly once below. The Screen cell includes its normalized route and recorded route name; “not recorded” means the workbook field was empty. Outcomes include classification, work item and a sanitized paraphrase/image note. Precise code evidence and tests are in the linked prompt.

| Feedback ID | Category | Screen | Outcome |
| --- | --- | --- | --- |
| FBK0000165 | General feedback | Projects · `/projects` · `projects` | **Duplicate of FBK0000167** → 001 W6. Requests removal of the pictured control. `FBK0000165.png`: Status picker with Active/Archived and search/select/clear controls. |
| FBK0000166 | General feedback | Projects · `/projects` · `projects` | **Duplicate of FBK0000167** → 001 W6. Another removal request. `FBK0000166.png`: Project filters sheet with Status, Pinned state and Clear filters. |
| FBK0000167 | General feedback | Projects · `/projects` · `projects` | **Improvement** → 001 W6. Remove Projects filters. `FBK0000167.png`: filters sheet; `FBK0000167-2.png`: unmarked empty Projects screen with search/filter affordance. The image does not request removal of search or the empty state. |
| FBK0000168 | General feedback | Import · `/projects/import` · `project` | **Improvement** → 001 W8. Decongest import. `FBK0000168.png`: large introductory artwork and four always-visible format explanations with clipped descriptions. Retained generic import also needs the layout change. |
| FBK0000169 | General feedback | Projects · `/projects` · `projects` | **Gap** → 001 W4. Back should visit home screens before exit. `FBK0000169.png`: empty Projects root; no back sequence is shown. D3 fixes the exact hierarchy and platform conventions. |
| FBK0000170 | General feedback | Templates · `/more/templates` · `templates` | **Gap** → 001 W14. Browse shipped templates and create/edit custom copies while keeping shipped assets immutable. `FBK0000170.png`: empty global Templates with Add templates and Create a blank template. D12 sets global custom ownership. |
| FBK0000171 | General feedback | Transcripts · `/more/transcripts` · not recorded | **Improvement** → 001 W7. Remove Unprocessed from the pictured menu. `FBK0000171.png`: More popup with Templates, Unprocessed, Transcripts, Recycle bin and Settings. |
| FBK0000172 | General feedback | Transcripts · `/more/transcripts` · not recorded | **Improvement** → 001 W7. Remove Transcripts from that same menu. `FBK0000172.png`: same More popup; this is navigation scope, not deletion of stored transcripts. |
| FBK0000173 | General feedback | Projects · `/projects` · `projects` | **Improvement** → 001 W8. Label the action Import a Project and open supported selection directly. `FBK0000173.png`: empty Projects with Import a file. D7 chooses supported ZIP packages and explicitly handles folders/picker limitations. |
| FBK0000174 | General feedback | Projects · `/projects` · `projects` | **Duplicate of FBK0000167** → 001 W6. Remove filters here too. `FBK0000174.png`: Project filters sheet. |
| FBK0000175 | General feedback | Projects · `/projects` · `projects` | **Duplicate of FBK0000167** → 001 W6. Another pictured-control removal. `FBK0000175.png`: Status picker with Active/Archived. |
| FBK0000176 | General feedback | Recycle bin · `/more/recycle-bin` · `recycleBin` | **Gap** → 001 W15. Include deleted files, records and projects. `FBK0000176.png`: empty bin describes only records. D13 defines managed files, ownership-aware restoration and unchanged permanent-purge scope. |
| FBK0000177 | General feedback | AI · `/more/ai` · `settingsAi` | **Suggestion** → 001 W16. Search/select providers beyond the fixed two, enter credentials when required, then select models. `FBK0000177.png`: provider/model segments and credential-status failure. D14 defines supported protocols; D15 covers contracts, egress and migration. |
| FBK0000178 | General feedback | AI · `/more/ai` · `settingsAi` | **Improvement** → 001 W16. Simplify the same configuration flow. `FBK0000178.png`: same crowded provider/model/key form and large failure illustration. The item combines capability and layout in this one flow. |
| FBK0000179 | General feedback | Organisation · `/more/account` · not recorded | **Improvement** → 001 W10. Remove the pictured Organisation surface. `FBK0000179.png`: server/account setup form and Save. D9 defaults to removing the shortcut while preserving required explicit setup/recovery. |
| FBK0000180 | General feedback | Change relay · `/more/relay` · not recorded | **Improvement** → 001 W11. Remove the pictured global relay entry. `FBK0000180.png`: No project state with Open a project. D10 moves access into project settings while preserving relay state. |
| FBK0000181 | General feedback | Capture defaults · `/more/capture` · `settingsCapture` | **Improvement** → 001 W12. Decongest capture settings. `FBK0000181.png`: camera/date/location controls, quality, folders, naming and beginning of context controls. D11 defines collapsed groups without changing values. |
| FBK0000182 | General feedback | Language · `/more/language` · `settingsLanguage` | **Improvement** → 001 W13. Decongest language and speech settings. `FBK0000182.png`: six language radio rows and quality controls; `FBK0000182-2.png`: full model inventory with metadata and actions. D11 specifies disclosure and visible recovery. |
| FBK0000183 | General feedback | About · `/more/about` · `settingsAbout` | **Improvement** → 001 W9. Remove repository-related links. `FBK0000183.png`: Development plan and Specification below version/build/licences. D8 limits removal to those links. |
| FBK0000184 | General feedback | Create project · `/projects/new` · `project` | **Defect** → 001 W3. Validate fields during editing. `FBK0000184.png`: nonempty name still has required-name feedback. Current submit-only validation confirms the stale error. |
| FBK0000185 | General feedback | Project home · `/projects/:projectId` · `project` | **Gap** → 001 W2. Offer Add template when no templates exist. `FBK0000185.png`: empty project with disabled Start capturing and template-setup guidance. D2 reconciles the requested CTA with unconditional raw-capture access. |
| FBK0000186 | General feedback | Project home · `/projects/:projectId` · `project` | **Improvement** → 001 W5. Organize menu actions. `FBK0000186.png`: long flat list mixes setup, recording, exchange and destructive actions. D4 specifies groups in the existing shared menu. |
| FBK0000187 | General feedback | Review meeting · `/projects/:projectId/meetings/:meetingId/review` · `project` | **Defect** → 001 W1. Report asks for clearer UI; code inspection additionally confirms unconnected save callbacks and render-created controllers. `FBK0000187.png`: blank transcript area, bare counts and tightly stacked notes/minutes. D1 specifies readable, durable editing and preserves source evidence. |

## Open questions
The prompt contains these 15 Decisions. They are questions for implementation approval; generating the prompt does not approve them. “Proceed” on the prompt accepts its documented defaults.

| Prompt / Decision | Required answer | Default |
| --- | --- | --- |
| 001 D1 | Meeting editing, source-note JSON contract and layout | Durable notes/minutes editing, immutable originalNotes with legacy compatibility, labelled summary and compact idle transcript presentation. |
| 001 D2 | Empty-template action | Add template primary; Capture now secondary using raw capture. |
| 001 D3 | Back hierarchy and platform conventions | Child/branch/project hierarchy to Projects; native exit only at root; normal browser history and native iOS/desktop conventions. |
| 001 D4 | Project-menu visual grouping/shared API | Four labelled groups, backward-compatible shared action metadata; preserve every command. |
| 001 D5 | Filter removal and archive access | Remove filter controls/predicates; preserve search, pin sorting, active default and existing Show archived command. |
| 001 D6 | Global shortcuts’ reach | Remove Unprocessed/Transcripts global shortcuts at all widths; keep routes and project access. |
| 001 D7 | Project import types and generic import layout | Exact Import a Project label; existing ZIP picker; folders navigable only; retained generic format help collapsed. |
| 001 D8 | About removal | Remove Development plan/Specification links; retain version/build/licences. |
| 001 D9 | Organisation removal | Remove Settings shortcut; retain explicit account/server setup route and recovery. |
| 001 D10 | Relay removal | Move access from global Settings to Project settings; preserve existing links, queues and opt-in state. |
| 001 D11 | Capture and Language disclosure | Collapse specified advanced groups; preserve all settings and expose speech-health recovery. |
| 001 D12 | Global template ownership | Global custom library using existing nullable ownership; immutable shipped assets; independent project copies. |
| 001 D13 | Recycling types and restoration | Managed projects/records/photos and all owned attachments; ownership-aware restore; permanent purge remains record-only. |
| 001 D14 | Provider support boundary | Configured Gemini generateContent/OpenAI Responses protocol providers and configured models, including keyless configuration. |
| 001 D15 | Provider wire/persistence/egress change | Add catalogue metadata, forward provider-ID migration, configured HTTPS egress and preserved backend custody; no production deployment. |

No separate reporter-only question is left unassigned: ambiguous visual/removal intent is represented by Decisions with concrete defaults. A non-default answer must update the affected specification before execution. W16 additionally requires an explicit second-reader review of the completed security/contract/migration evidence. Relevant repository prerequisites and required real-platform/database checks must be verified before implementation acceptance; the current tracker is not a whole-repository green gate.
