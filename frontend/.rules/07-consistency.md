# 07 — Consistency and uniformity

*Enforced by dev-plan tasks 013 (tokens) and 047 (widget gallery); every design-system task adds to the catalogue.*

## FE-CONS-01 — Catalogue first
Before writing a widget, look in `core/widgets/`. If something close exists, extend it rather than fork it. Building a
parallel button, field, dialog or empty state is a review rejection.

## FE-CONS-02 — Second use means promotion
Needed twice, it moves to `core/widgets/` in the same pull request — with a gallery entry and a golden test. No
exceptions, no "later".

## FE-CONS-03 — The gallery is the contract
Every catalogue widget appears in the widget gallery screen in every state. A component that is not in the gallery
does not exist as far as other features are concerned.

## FE-CONS-04 — Four states, always
Every data view renders loading, empty, error and offline — through `AsyncValueView`, never hand-rolled. A screen that
shows a spinner and nothing else is incomplete.

## FE-CONS-05 — One way to ask, one way to tell
One dialog API, one bottom sheet API, one snackbar API. Confirmations look the same in every feature; destructive
actions always pair a confirm with an undo.

## FE-CONS-06 — One row, one pill, one thumbnail
Projects, records, templates and datasets use `AppListTile`. Every status renders through `AppStatusPill`. Every photo
renders through `AppPhotoThumb`.

## FE-CONS-07 — One vocabulary
The same word for the same concept everywhere, in code and on screen: record, capture, context, template, bundle,
merge, refine. `lib/core/naming/domain_names.dart` is the reference; synonyms fail the naming test.

## FE-CONS-08 — One icon per concept
Camera, microphone, scan, refine, export, merge, duplicate, conflict, verified. Fixed once in the design system;
never chosen ad hoc per screen.

## FE-CONS-09 — One formatter
Dates, times, numbers, units, currency and file sizes are formatted by shared helpers, so the same value never appears
two ways in two screens.

## FE-CONS-10 — Same gesture, same result
Long-press selects. Swipe never deletes without confirmation. Pull-to-refresh only where refreshing means something.
Tap on a value edits it, everywhere.

## FE-CONS-11 — Errors read the same
Every failure is rendered by `AppErrorState` from a typed `Failure`. No screen writes its own error copy.
