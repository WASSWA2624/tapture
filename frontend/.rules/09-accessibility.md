# 09 — Accessibility

*Enforced by dev-plan task 017 (accessibility matchers); audited by task 236.*

## FE-A11Y-01 — 48dp minimum target
Every interactive element, including icon buttons, chips and list actions. Enforced by matcher, not by eye.

## FE-A11Y-02 — Every control has a label
`AppIconButton` requires a semantic label and a tooltip in its constructor, so an unlabelled icon button cannot
compile.

## FE-A11Y-03 — 200 percent text without clipping
Every screen, both orientations. Text scale is part of the golden matrix.

## FE-A11Y-04 — Contrast is measured
4.5:1 body, 3:1 large text and interactive outlines, in light, dark and outdoor themes.

## FE-A11Y-05 — Never colour alone
Status, confidence, validity and selection all carry a second signal — icon, text or shape.

## FE-A11Y-06 — Focus follows the eye
Traversal order matches visual order. Forms move field to field with the keyboard. Switch access reaches every action.

## FE-A11Y-07 — State changes are announced
Saving, saved, processing, failed and merged are announced to screen readers as they happen, not left silent.

## FE-A11Y-08 — Motion and boldness settings are honoured
Reduced motion removes non-essential animation. Bold text is respected rather than overridden.

## FE-A11Y-09 — Field-usable, not just screen-reader-usable
Camera controls are large and glove-friendly; capture and save give haptic confirmation; primary actions sit within
thumb reach on a large phone.

## FE-A11Y-10 — Every widget test asserts it
Design-system tests use the accessibility matchers by default. Accessibility is not a phase; it is a precondition.
