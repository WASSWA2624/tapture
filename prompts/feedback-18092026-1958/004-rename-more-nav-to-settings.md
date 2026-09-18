# 004 — Rename More nav to Settings

**Feedback:** FBK0000003 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **Depends on:** —

## Goal
The fourth shell destination, already a settings cog, reads Settings in the rail and the bottom bar,
on compact, medium and expanded, in light, dark and outdoor. It still opens the settings root.

## Evidence
- FBK0000003: the More item with a cog is Settings and should open a settings screen; rename it.
  Screenshot 1: rail label More, cog icon, settings list titled Settings.
- Root cause: `Copy.navMore` is `'More'` (`copy.dart`) while the icon is `Icons.settings` /
  `settings_outlined` (`nav_shell.dart`) and the page title is already `Copy.settingsTitle`
  (`'Settings'`). Routes are `/more`, `/more/operator`, … (`AppRoutes.more`).
- FE-SIMP-02 names the fourth destination "More" in prose; the limit is four destinations, not the
  word More.

## Scope
- Change: `Copy.navMore` to `'Settings'`. Update FE-SIMP-02 to say Settings. Comments that call the
  tab "More" (`settings_screen.dart`, `router.dart`, `feedback_host.dart`). Tests already assert
  `Copy.navMore`.
- Do not change: `AppRoutes.more` path strings (`/more/…`), destination count, icons, settings
  tiles, `Copy.settingsTitle` (duplicate visible string is fine).

## Rules
- FE-L10N-01: visible strings stay on `Copy`.
- FE-SIMP-02: still four destinations; update the label in the rule.
- FE-CONS-07, FE-CONS-08: one word and one icon for settings.
- FE-FLOW-07: if `frontend/.rules/06-simplicity.md` changes, the nav test is the enforcing check.
- FE-TEST-01.

## Steps
1. Record the work: `cd frontend && dart run tool/new_task.dart 23-hardening rename-more-nav-to-settings "Rename More nav to Settings"`.
2. Set `Copy.navMore` to `'Settings'`. Keep the key `navMore` unless you also rename every
   reference (unnecessary).
3. Edit FE-SIMP-02: "Projects, Capture, Records, Settings."
4. Update operator-facing comments that say the fourth tab is More.
5. `nav_shell_test` already expects `Copy.navMore`; confirm the rail and bar show Settings.

## Human review
⛔ Stop before step 2 and ask:
- Rename the visible label only, keep `/more` routes (recommended), or also rename paths and
  `AppRoutes.more` to `/settings` (breaks bookmarks and stored feedback routes)?
Proceed only with an explicit answer. If the answer is "proceed", do the label only.

## Acceptance criteria
- [ ] Compact bar, medium rail and expanded rail all say Settings for destination 3.
- [ ] That destination still opens the settings root (`Copy.settingsTitle`).
- [ ] `/more/operator`, `/more/capture` and `/more/storage` still resolve.
- [ ] Four destinations, Capture still dominant.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens.
