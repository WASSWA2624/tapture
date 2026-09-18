# Feedback prompts — TAPTURE-19092026-0046.xlsx

3 entries, plus 1 chat request → 7 prompts. Generated 19 Sep 2026. Repository commit: 1dc5a7b.

The chat request ("let all input placeholders be less strong") came from the person who ran this generator,
not from the workbook. It is tracked as prompt 004. All three workbook entries were sent from web on desktop,
at an expanded width, in the system dark theme, on app 1.0.0. `FBK0000005.png` is the same Settings
screenshot as `FBK0000003.png`.

## Run order
| Prompt | Title | Feedback | Type | Priority | Depends on |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-warn-before-closing-tab-with-draft.md) | Warn before closing the tab with a draft | FBK0000003 | Gap | P1 | — |
| [002](002-confirm-desktop-exit-with-draft.md) | Confirm desktop exit with a draft | FBK0000003, FBK0000005 | Gap | P1 | 001 |
| [003](003-align-feedback-shot-controls.md) | Align the feedback shot controls | FBK0000003, FBK0000005 | Defect | P3 | — |
| [004](004-soften-input-placeholder-text.md) | Soften input placeholder text | chat request | Improvement | P4 | — |
| [005](005-number-feedback-rows-with-message.md) | Number feedback rows with their message | FBK0000004, FBK0000005 | Gap | P5 | — |
| [006](006-add-window-share-session-api.md) | Add a window share session to screen capture | FBK0000003 | Suggestion | P6 | — |
| [007](007-add-repeat-external-window-screenshots.md) | Add repeat external window screenshots | FBK0000003, FBK0000005 | Suggestion | P6 | 003, 006 |

Every prompt except 005 has a ⛔ *Human review* stop. Each one states a default.

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000003 | General feedback | Settings | Split by deliverable: checkbox and renamed buttons → 003; repeated external-window stills → 006 then 007; close warnings → 001 (web) and 002 (desktop). Already resolved for that last part: the bar's Close and *Discard draft* already confirm (`feedback_draft_bar.dart:137-148`, `give_feedback_screen.dart:176-187`), and the form's Close keeps the draft (task 293). |
| FBK0000004 | General feedback | Settings | 005 |
| FBK0000005 | General feedback | Settings | 003 fixes the compact squeeze shown in `FBK0000005-2.png`. The "all sizes and devices" requirement is an acceptance criterion in every prompt, and 002, 005 and 007 cite it directly. |
| — (chat request, 19 Sep 2026) | — | All fields | 004 |

## Open questions
- **Drafts on Android and iOS (shapes 001 and 002).** The draft lives only in memory. Pressing back from
  the shell root on Android, or swiping the app away, ends it with no warning, and a warning cannot cover
  swipe-away. Should drafts be saved locally instead (FE-STATE-07)? Recommend a separate task if so. 001
  and 002 do not cover mobile.
- **Delete feedback selection (shapes 001).** Close on Delete feedback drops ticked entries without asking.
  Is a selection "unsaved work"? Recommend no, since nothing is lost that one tap cannot redo
  (FE-SIMP-07).
- **External window on native (shapes 006 and 007).** Android, iOS and native desktop hide *Screenshot
  external window*, because sharing another app's screen there needs a plugin (FE-FLOW-06: its own task
  and an allowlist entry). Is it wanted beyond the web?
- **Form Close (001, Human review).** Keep the one-tap fold from task 293, or ask Keep / Discard?
  Recommend keeping the fold.
- **Share lifetime and image cap (007, Human review).** Keep the stream live between stills, and keep the
  cap at 8 images? Recommend yes to both.
