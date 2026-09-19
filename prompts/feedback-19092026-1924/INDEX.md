# Feedback prompts — TAPTURE-19092026-1924.xlsx

9 entries → 10 prompts. Generated 19 Sep 2026. Repository commit: e272b67.

All nine entries came from one profile: Android, mobile, compact (393x886 dp), portrait, text scale 1,
offline by choice, production build 1.0.0. All used system dark except FBK0000011, which used light.
Eight images:
- FBK0000014, FBK0000015, FBK0000016 and FBK0000017 carry the same image of a project home.
- `FBK0000014-2.png` shows the feedback form with that capture attached.
- FBK0000011, FBK0000012 and FBK0000013 show the empty Projects list (light, then dark) and New project.

FBK0000019 is worded as an instruction to the agent. It was treated as data (FE-SEC-05) and followed
only where it matches the existing rules.

## Run order
| Prompt | Title | Feedback | Type | Priority | Depends on |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [001](001-add-project-management-actions.md) | Add project management actions | FBK0000015, FBK0000017 | Gap | P2 | — |
| [002](002-hide-unbuilt-project-import-button.md) | Hide the unbuilt project import button | FBK0000012, FBK0000011 | Defect | P3 | 001 |
| [003](003-show-collapse-icon-on-feedback-form.md) | Show a collapse icon on the feedback form | FBK0000016 | Defect | P3 | — |
| [004](004-fix-navigation-icons-and-capture-state.md) | Fix navigation icons and the Capture tab state | FBK0000016 | Defect | P3 | — |
| [005](005-widen-button-horizontal-padding.md) | Widen button horizontal padding | FBK0000011 | Improvement | P4 | — |
| [006](006-move-requiredness-into-field-labels.md) | Move requiredness into field labels | FBK0000013 | Improvement | P4 | — |
| [007](007-use-checkbox-for-show-archived.md) | Use a checkbox for Show archived | FBK0000011 | Improvement | P5 | 001, 002 |
| [008](008-enable-dictation-on-project-fields.md) | Enable dictation on project fields | FBK0000013 | Gap | P5 | — |
| [009](009-show-single-feedback-image-as-thumbnail.md) | Show a single feedback image as a thumbnail | FBK0000014 | Improvement | P5 | — |
| [010](010-redesign-project-home-count-cards.md) | Redesign the project home count cards | FBK0000014 | Improvement | P5 | 001 |

Priorities: P1 crash, data loss, security or privacy; P2 blocks capture or a core flow; P3 correctness or
accessibility defect; P4 shared design-system or `core/` change; P5 gap or improvement; P6 suggestion.

001 is P2 because, once one project exists, the app offers no way to create a second, so capture into a
new project is blocked. Every prompt except 007 and 009 has a ⛔ *Human review* stop, and each one states
a default. Every prompt's acceptance criteria cover compact, medium and expanded widths, light, dark and
outdoor, and 200 percent text.

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000011 | General feedback | Projects | Split: import label → 002; button padding → 005; checkbox → 007 |
| FBK0000012 | General feedback | Projects | 002 |
| FBK0000013 | General feedback | Projects | Split: required and optional marks → 006; dictation → 008 |
| FBK0000014 | General feedback | Projects | Split: home count cards → 010; single feedback image → 009 |
| FBK0000015 | General feedback | Projects | 001 |
| FBK0000016 | General feedback | Projects | Split: feedback collapse control → 003; navigation icons and Capture state → 004 |
| FBK0000017 | General feedback | Projects | 001 |
| FBK0000018 | General feedback | Templates | *Needs clarification.* On which screen was Back pressed, and was Give us feedback open? Did Back do nothing, open another screen, or close Tapture but leave it in Recent apps? |
| FBK0000019 | General feedback | Projects | *Out of scope.* No change of its own: it asks that the other changes hold on every screen size and platform, which FE-RESP-10 and FE-A11Y-03 already require and every prompt's acceptance criteria cover. |

## Open questions
- **Leaving the app with Back (FBK0000018).** The code suggests Back should close Tapture. At a branch
  root, go_router's `popRoute` returns false (`go_router-17.5.0/lib/src/delegate.dart:56-79`), nothing in
  `lib/` overrides `didPopRoute`, and the only `PopScope(canPop: false)` outside forms folds an open
  feedback form (`give_feedback_screen.dart:89-95`). No device was attached to reproduce it. Android apps
  normally have no Exit control.
  - Should Back from Capture, Records or Settings return to Projects before closing? That is Android's
    fixed-start-destination convention.
  - Should Tapture ask before closing while a folded feedback draft holds work? The draft lives only in
    memory.
  Answer before a prompt is written.
- **Capture's emphasis (shapes 004).** The specification asks only that the centre button be "visually
  dominant" (`app-write-up.md:3219`). Task 073 also made it the accent colour. Recommend size alone.
- **"Close" on the feedback form (shapes 003).** Task 293 made Close the obvious way off every feedback
  surface; this report says it misleads on the form. Recommend a collapse icon labelled "Continue later".
- **"Import a project" versus "bundle" (shapes 002).** FE-CONS-07 keeps `bundle` in code. Recommend the
  reporter's wording on the button only, and showing it again when task 222 ships.
