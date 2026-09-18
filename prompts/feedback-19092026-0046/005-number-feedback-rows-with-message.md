# 005 — Number feedback rows with their message

**Feedback:** FBK0000004, FBK0000005 · **Type:** Gap · **Priority:** P5 · **Effort:** S · **Depends on:** none

## Goal
On Download feedback and Delete feedback, each row is numbered 1, 2, 3 and so on in list order. The first
line shows the number, the Feedback ID and the start of the message, cut with an ellipsis when it is too
long. This works at compact, medium and expanded widths, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000004: on Download feedback and Delete feedback, number the rows and show the feedback text on the
  same line as the Feedback ID, with an ellipsis if long. Web, expanded, dark. No image.
- FBK0000005: apply every change to all screen sizes and devices.
- Root cause: `frontend/lib/features/feedback/presentation/feedback_entry_tile.dart:38-47` passes only
  `entry.reference` as the title and `Copy.feedbackEntryFacts(type, when, screen)` as the subtitle. The
  message is never shown and nothing is numbered. Both screens build rows through `FeedbackBrowser.tile`
  (`feedback_browser.dart:64,117`), whose builder receives no position. `AppListTile` already draws the title
  on one line with an ellipsis (`app_list_tile.dart:85-91`).

## Scope
- Change:
  - `feedback_browser.dart`: `tile` becomes `Widget Function(FeedbackEntry entry, int number)`. `number`
    is the 1-based position in `matching` (newest first), so it continues across *Show more* pages.
  - `feedback_entry_tile.dart`: add a required `int number`. The title becomes
    `Copy.feedbackEntryTitle(formattedNumber, entry.reference, oneLineMessage)`, where:
    - `formattedNumber` uses `NumberFormat.decimalPattern` for the active locale, as
      `app_text_field.dart:339` does;
    - `oneLineMessage` collapses every run of whitespace, including line breaks, to one space and trims it.

    Keep the subtitle as it is.
  - `download_feedback_screen.dart:67` and `delete_feedback_screen.dart:82-87`: pass `number`.
  - `frontend/lib/core/copy/copy.dart`: add `feedbackEntryTitle(String number, String reference,
    String message)`, which returns `'$number. $reference · $message'`, with a one-line doc.
- Do not change: `AppListTile`, the facts subtitle, selection, select-all, filters, paging, the download or
  delete actions, or the workbook.

## Rules
- FE-CONS-06: rows stay `AppListTile`. FE-CONS-01: no new row widget.
- FE-L10N-01 and FE-L10N-03: the title is built by `Copy` with placeholders. FE-L10N-04 and FE-CONS-09: the
  number is formatted with `intl`.
- FE-L10N-07: the message is user data and is shown as written, apart from collapsing whitespace.
- FE-A11Y-02: the title is the row's semantic label, so a screen reader hears the number, the ID and the
  message.
- FE-RESP-06, FE-RESP-10 and FE-A11Y-03: one line with an ellipsis, and no clipping at 200 percent text.
- FE-PERF-05: nothing new is computed per build beyond a string. The list stays paged.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening number-feedback-rows-with-message "Number feedback rows with their message"`
   (FE-FLOW-08).
2. Add `Copy.feedbackEntryTitle`.
3. Change the `FeedbackBrowser.tile` signature and pass `index + 1` while iterating
   `matching.take(visible)`.
4. Add `number` to `FeedbackEntryTile` and build the title. Update both screens.
5. Add tests:
   - `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`:
     - "rows are numbered in list order and show the message beside the ID";
     - "a long message is cut to one line with an ellipsis at 360 dp";
     - "a message with line breaks reads as one line".
   - `frontend/test/features/feedback/presentation/delete_feedback_screen_test.dart`:
     - "rows are numbered and ticking one keeps its number";
     - "numbers restart at 1 after a filter".
   - `frontend/test/core/copy/copy_test.dart`: the new key.

## Acceptance criteria
- [ ] On both screens, the first row reads "1. FBK… · <message start>", the next "2. …", in the order shown.
- [ ] A message longer than the line ends with an ellipsis on the same line as the ID, at 360dp, 768dp and
      1280dp.
- [ ] At 200 percent text, each title is still one line with an ellipsis, and nothing overflows.
- [ ] After *Show more*, numbering continues (for example, 21 follows 20). After a filter change, it
      restarts at 1.
- [ ] The facts subtitle, the selection tick and select-all work as before, in light, dark and outdoor.
- [ ] FBK0000004 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No design-system goldens change, because `AppListTile` is untouched.
