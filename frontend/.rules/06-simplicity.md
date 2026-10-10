# 06 — Simplicity

The product's central claim is that a field worker can use it. These rules are how that claim survives contact with
281 tasks.

*Built into tasks 031, 033, 072-076; audited by 236 and 239.*

## FE-SIMP-01 — One primary action per screen
No other control is larger, it sits in the lower third, and it is reachable with one thumb. If a screen has two
equally important actions, the screen has not been designed yet.

## FE-SIMP-02 — Project-scoped, capacity-aware navigation
Projects, Templates and Settings appear directly when their localized labels and touch targets fit. Only overflow
adds a three-dot More control, listing the hidden destinations without duplicating visible tabs (task 167).
Opening or dismissing More preserves the current route. Rails expose the same destinations directly. Recycle bin
belongs to Settings at every width, never to a home tab or overflow menu. Capture and record CRUD remain children
of the opened project (task 166). Presentation tabs share the existing Projects and More route branches.

## FE-SIMP-03 — Three taps to a record
Within the opened project: Capture, shutter, save. Opening a project establishes the owner before capture;
restart resumes the previous valid screen (task 166). Anything else that adds a tap needs a written justification.

## FE-SIMP-04 — One sign-in, and nothing else, at the start
Signing in once is the only thing a new install asks for (§71.1). No onboarding tour, no setup wizard, no second
login ever: the session and role grant are cached for a configurable period (default 30 days) and refreshed
silently (§70.4). Past that first screen, a new install captures within thirty seconds using a shipped
template.

## FE-SIMP-05 — Default, do not ask
Today's date, the current context, the last template, the last camera setting. A question the app can answer itself is
a question it must not ask.

## FE-SIMP-06 — Advanced is collapsed
Adding a field asks three questions: label, type, required. Every other attribute lives behind **Advanced**, closed by
default.

## FE-SIMP-07 — One decision at a time
No dialog chains. Every dialog has a safe default and a way out. Destructive dialogs name the consequence and the
count.

## FE-SIMP-08 — Warnings never block
Quality warnings, duplicate warnings and validation warnings all offer *keep anyway*. Only genuine data corruption
blocks a save.

## FE-SIMP-09 — Errors never discard input
No failure path may lose a photo, a caption or a typed value. Recovery is always offered, and it always works.

## FE-SIMP-10 — Plain language
"Not detected", not `null`. "Analyse", not "invoke extraction pipeline". Sentence case, no exclamation marks, verbs
for actions.

## FE-SIMP-11 — Empty means "do this next"
Every empty state names the next action and offers it. Blank space is a missing feature.

## FE-SIMP-12 — A new setting is a failure of defaults
Adding one requires stating why the default cannot be right for most people. Settings are where indecision goes to
hide.
