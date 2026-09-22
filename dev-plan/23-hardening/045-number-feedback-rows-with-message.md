# 045 — Number feedback rows with their message

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Number Download feedback and Delete feedback rows in list order, and put
the Feedback ID and the start of the message on the same title line.

## Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_browser.dart`
- `frontend/lib/features/feedback/presentation/feedback_entry_tile.dart`
- `frontend/lib/features/feedback/presentation/download_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/delete_feedback_screen.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`
- `frontend/test/features/feedback/presentation/delete_feedback_screen_test.dart`

## Constraints

- Rows stay `AppListTile` (FE-CONS-06). No new row widget (FE-CONS-01).
- The title is built by `Copy` with placeholders (FE-L10N-01, FE-L10N-03).
- The list position is formatted with `intl` (FE-L10N-04, FE-CONS-09).
- The message is user data; collapse whitespace only (FE-L10N-07).
- One line with an ellipsis; no clipping at 200 percent (FE-RESP-06,
  FE-RESP-10, FE-A11Y-03). The title is the semantic label (FE-A11Y-02).
- Do not change the facts subtitle, selection, filters, paging, actions,
  or the workbook.

## Definition of done

- [x] Both screens show "1. FBK… · <message>", then "2. …", in list order.
- [x] A long message ellipsises on the ID line at 360, 768 and 1280 dp.
- [x] At 200 percent text the title stays one line and nothing overflows.
- [x] Numbers continue across Show more and restart at 1 after a filter.
- [x] Tests: numbered titles; ellipsis; collapsed line breaks; tick keeps
      the number; filter restarts at 1; the new Copy key.
