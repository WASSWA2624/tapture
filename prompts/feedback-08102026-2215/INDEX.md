# Feedback prompts — TAPTURE-08102026-2215.xlsx

7 entries → 1 prompt, 8 work items. Generated 2026-10-09. Repository commit: `695ae551`.

Four entries require work; three are already resolved in the current code. All rows were General feedback on Capture `/capture`, Android/mobile, app 1.0.0 production, English, compact portrait, light theme, 393×886 at text scale 1, online. All seven images were inspected. Matching screenshots do not make distinct requests duplicates. Classifications below describe current behavior, not freshly executed test results.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-resolve-capture-field-feedback.md) | W1 | Enforce field processing eligibility | FBK0000203 | Gap | P1 | — |
| 001 | W2 | Fill inherited capture metadata at first save | FBK0000203 | Gap | P2 | W1 |
| 001 | W3 | Permit audited automatic-field corrections | FBK0000203 | Gap | P2 | W1, W2 |
| 001 | W4 | Render readable context hierarchy | FBK0000202, FBK0000205 | Improvement | P2 | — |
| 001 | W5 | Search Manual form fields | FBK0000200 | Gap | P3 | — |
| 001 | W6 | Compact Capture controls around caption entry | FBK0000205 | Improvement | P3 | W4 |
| 001 | W7 | Explain automatic and processing field sources | FBK0000203 | Gap | P3 | W1, W2, W3, W5 |
| 001 | W8 | Fill opted-in local network address fields | FBK0000203 | Suggestion | P4 | W1, W7 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000200 | General feedback | Capture / Manual form | **Gap — 001 W5.** Add field search. Image shows the long field list without search; pending failed-write input must survive filtering. |
| FBK0000201 | General feedback | Capture / Manual form | **Already resolved.** Manual input supersedes processed values. `frontend/lib/core/db/tables/record_fields.dart:182` preserves raw, writes manual refinement, clears superseded final approval and audits; `frontend/lib/features/records/domain/record_value.dart:71` displays final → refined → raw; `frontend/lib/features/processing/domain/proposal_application.dart:61` protects verified/manual values. Image shows Manual form, without demonstrating an overwrite. No new edit affordance is inferred. |
| FBK0000202 | General feedback | Capture | **Improvement — 001 W4.** Present context values readably with real hierarchy order/separators. Image shows a thin scrolling strip containing pinned fields; current compact code suppresses separators and mixes pins with levels. |
| FBK0000203 | General feedback | Capture / Manual form | **Gap — 001 W1, W2, W3, W7, W8.** Existing explicit-source automation/template controls are retained; fill inherited source-less capture date/time/device values, enforce processing exclusion, allow permitted audited automatic-field corrections, explain sources and implement the approved device-source boundary. Image shows blank metadata fields without source/status. W8 is the suggestion subpart of this entry's overall source-workflow gap. |
| FBK0000204 | General feedback | Capture | **Already resolved.** Context prefills matching fields automatically: `frontend/lib/features/capture/presentation/capture_screen.dart:316` snapshots levels/pins and `frontend/lib/features/capture/data/capture_record_writer.dart:344` merges automatic/context/typed values before the atomic insert with `CONTEXT` provenance. Image shows existing context chips; later changes do not rewrite earlier records. |
| FBK0000205 | General feedback | Capture | **Improvement — 001 W4, W6.** Separate readable context from a compact target/guide/photo composition and give caption entry more room. Image shows stacked selectors and the oversized empty-photo state. Populated photos are already horizontal/cached in `frontend/lib/features/capture/presentation/photo_tray.dart:81`; preserve that resolved subpart. |
| FBK0000206 | General feedback | Capture | **Already resolved.** Template context fields/levels and Capture values are selectable: `frontend/lib/features/templates/presentation/field_advanced_section.dart:170`, `frontend/lib/features/context/presentation/context_hierarchy_screen.dart:376` (template levels), `:449` (exact field picker), `:539` (persist), and `frontend/lib/features/context/presentation/context_bar.dart:125` (Setup/Manage and value pickers). Image includes Presets/Manage. No separate context-configuration feature is needed. |

## Open questions

Answer these in [001's Decisions](001-resolve-capture-field-feedback.md#decisions) before implementation. “Proceed” accepts all defaults; a declined authorization leaves dependent work open.

| Prompt / Decision | Question | Default |
| :--- | :--- | :--- |
| 001 D1 | Exclude automatic/protected values from structured AI context as well as extraction targets? | **(a)** Filter protected context keys; retain approved raw photo/caption evidence unchanged. |
| 001 D2 | Permit audited per-record corrections to automatic business/date/time values? | **(a)** Permit explicit corrections; preserve raw evidence and immutable metadata/GPS restrictions. |
| 001 D3 | Retain non-hierarchical pins in the visible context bar? | **(a)** Hierarchy/commands first trail, pins second trail; preserve one-tap behavior and stored values. |
| 001 D4 | Approve the exact additive shared chip/choice/empty-state contracts and replacement of task 011's context-height cap? | **(a)** Approve opt-in variants with unchanged defaults and gallery coverage; require natural scaled height and complete-label/control reachability. |
| 001 D5 | Enable a native local address source and keep unsupported temperature/manual fallback explicit? | **(a)** Native template opt-in; unavailable address on web; manual temperature. No new egress, dependency, permission or global policy. |
| 001 D6 | Approve the additive `LOCAL_ADDRESS` template/source format for D5(a)? | **(a)** Approve compatible additive persistence/transfer, retain originals and document minimum reader compatibility. |
| 001 D7 | Temporarily restore verified image inputs for actual visual comparison while retaining zero delivered test PNGs? | **(a)** Restore verified inputs temporarily, review intended updates, preserve images/manifests externally, then remove only temporary test images. |
| 001 D8 | Approve the three sanctioned save-time fallbacks for source-less inherited date/time/device fields? | **(a)** Bind only automatic `record_admin` capture date/time/device keys, preserve explicit configuration and existing records. |
| 001 D9 | Include enumerated non-image acceptance tests plus relative helper closure in the delivered implementation? | **(a)** Include only the exact approved sources with unchanged ignore rules/index; force-add exact source paths only for a requested commit. |

No entry needs a separate reporter clarification under these bounded Decisions. Device availability and platform exclusions are explicit in W8; every shared presentation item covers all six platforms and the full width/orientation/theme/text-scale matrix. This is a prompts-only deliverable: no application code, tests, plan, tracker, dependencies or source archive were modified. The runner records implementation progress and verification when executing 001.
