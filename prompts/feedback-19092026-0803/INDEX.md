# Feedback prompts — TAPTURE-19092026-0803.xlsx

9 entries → 10 prompts. Generated 19 Sep 2026. Repository commit: c4eb48c.

All nine entries came from one profile: Android, mobile, compact (393x886 dp), portrait, system dark,
text scale 1, offline by choice, production build 1.0.0. The export's filter was "All", with 9 records;
FBK0000001 is not in this archive. Five entries carry one image each. Every image is the screen Feedback
was tapped on. Only `FBK0000002.png` shows the fault itself, and `FBK0000006.png` shows its current,
masked form.

## Run order
| Prompt | Title | Feedback | Type | Priority | Depends on |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-fix-storage-root-on-android.md) | Fix the storage root on Android | FBK0000002 | Defect | P2 | — |
| [002](002-save-downloads-to-public-tapture-folder.md) | Save downloads to a public Tapture folder | FBK0000009, FBK0000010 | Defect | P3 | — |
| [003](003-keep-feedback-bar-above-keyboard.md) | Keep the feedback bar above the keyboard | FBK0000005 | Defect | P3 | — |
| [004](004-move-storage-root-to-public-documents.md) | Move the storage root to public Documents | FBK0000009 | Defect | P3 | 001, 002 |
| [005](005-unify-confirmation-dialog-design.md) | Unify the confirmation dialog design | FBK0000007 | Improvement | P4 | — |
| [006](006-add-screenshot-help-for-other-screens.md) | Add screenshot help for other screens | FBK0000004 | Improvement | P5 | — |
| [007](007-persist-theme-mode-in-settings-store.md) | Persist the theme mode in the settings store | FBK0000003 | Gap | P5 | — |
| [008](008-add-appearance-settings-screen.md) | Add the Appearance settings screen | FBK0000003 | Gap | P5 | 007 |
| [009](009-show-feedback-download-location.md) | Show the feedback download location | FBK0000006 | Improvement | P5 | 002 |
| [010](010-add-save-to-folder-option.md) | Add a Save to a folder option | FBK0000008 | Suggestion | P6 | 002, 009 |

Priorities: P1 crash, data loss, security or privacy; P2 blocks capture or a core flow; P3 correctness or
accessibility defect; P4 shared design-system or `core/` change; P5 gap or improvement; P6 suggestion.
Every prompt except 003 has a ⛔ *Human review* stop, and each one states a default.

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000002 | General feedback | Storage | 001. Not already resolved: `9715bcd` replaced the error screen with placeholder totals, but `StorageRoot` still fails on Android because it requests an undeclared media permission. |
| FBK0000003 | Suggestion | Settings | 007 then 008 |
| FBK0000004 | General feedback | Settings | 006 |
| FBK0000005 | General feedback | Settings | 003 |
| FBK0000006 | General feedback | Storage | 009 |
| FBK0000007 | Suggestion | Settings | 005 |
| FBK0000008 | Suggestion | Projects | 010 |
| FBK0000009 | General feedback | Projects | Split: downloads → 002; stored files → 004 |
| FBK0000010 | General feedback | Projects | 002 |

## Open questions
- **Where the evidence folder lives on Android (blocks 004).** The options are shared `Documents/Tapture`
  on Android 11+, the hidden app folder, a folder picked through the Storage Access Framework, or
  all-files access. Recommend shared Documents, with the app folder as a fallback. Decide before capture
  (phase 12) writes any photo there.
- **Capturing other apps on Android (shapes 006).** In-app capture needs MediaProjection: a plugin
  (FE-FLOW-06), a permission and a foreground service. Recommend no, because a system screenshot plus
  Choose photos covers it.
- **Save to a folder beyond Android (shapes 010).** Desktop needs `file_selector`, which is a new
  dependency with its own task. The web could use `showSaveFilePicker` where browsers support it.
  Recommend Android only for now.
- **Appearance in the specification (shapes 008).** `app-write-up.md` §57 lists no Appearance section,
  while §58 asks for a sunlight theme. Should the specification owner add it to §57? 008 records the
  FE-SIMP-12 reason in its task and leaves the specification alone.
