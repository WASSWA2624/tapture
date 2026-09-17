# 04 — Theming

*Enforced by dev-plan task 013 (design-token test); built by tasks 030-031.*

## FE-THEME-01 — Tokens are the only source of style
Colour, spacing, radius, elevation, duration and text style come from the token files. A literal `Color(...)`,
`EdgeInsets.all(12)`, `BorderRadius.circular(8)`, `Duration(...)` or `TextStyle(...)` in `lib/features/` fails the
build.

## FE-THEME-02 — Three themes, one token set
Light, dark and outdoor. Every token is defined in all three. A token defined in only one mode is a bug that ships as
an invisible control.

## FE-THEME-03 — Outdoor mode changes contrast, never layout
Raised contrast, thicker outlines, no low-contrast tints — identical geometry, so nothing moves when a user switches
in the field.

## FE-THEME-04 — Semantic names, not descriptive ones
`danger`, `warning`, `success`, `outline`, `surface`. Never `red`, `lightGrey2`, `blue700`. The name says the role.

## FE-THEME-05 — Colour is never the only signal
Every status carries colour **and** an icon **and** text. A colour-blind user in bright sunlight must still read the
state.

## FE-THEME-06 — Depth through tone, not shadow
Surfaces separate by tone and outline. Heavy shadows disappear outdoors and cost fill rate.

## FE-THEME-07 — Style Material centrally
Buttons, fields, chips, dialogs, sheets and app bars are themed once in `app_theme.dart`, so a stock widget already
looks like Tapture without local decoration.

## FE-THEME-08 — One icon set, sized by token
Icons come from a single family, at token sizes. One concept, one icon, everywhere (see `07-consistency.md`).

## FE-THEME-09 — Motion is small and skippable
Durations from tokens, under 250ms for anything on the capture path, and reduced-motion settings are honoured.

## FE-THEME-10 — Contrast minimums
4.5:1 for body text, 3:1 for large text and interactive outlines, in all three themes. Verified by the accessibility
matchers, not by eye.

## FE-THEME-11 — Need a new token? Add a token.
Never a one-off override in a screen. Adding to the token file is cheap; a private exception is not.
