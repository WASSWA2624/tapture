# 033 — Fix feedback search remount

**Phase** 23 · Hardening  |  **Depends on** [026](026-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Typing in Download feedback and Delete feedback Search keeps the query visible and filters the
list. Clearing filters still empties the field.

## Files

- `frontend/lib/core/widgets/app_search_field.dart`
- `frontend/lib/features/feedback/presentation/feedback_filter_panel.dart`
- `frontend/test/core/widgets/app_search_field_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`

## Constraints

- Do not remount Search when `FeedbackFilter.isEmpty` becomes false (FE-SIMP-09).
- Size-class rebuilds must not drop the query (FE-RESP-03).
- Debounce stays `AppConstants.interaction.debounce` (FE-CODE-09).
- Other screens' search fields stay unchanged.

## Definition of done

- [x] After one debounce, Search still shows the typed query and hides non-matching rows.
- [x] Clear filters empties Search and shows the full list.
- [x] Tests: download screen types "crash", pumps the debounce, then clears; `AppSearchField` clears only when parent `text` becomes empty.
