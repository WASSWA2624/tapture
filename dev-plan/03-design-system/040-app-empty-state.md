# 040 — Empty, error and loading states, and the async value view

**Phase** 03 · Design system  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [030](030-color-tokens.md), [034](034-app-button.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The four non-data states and the one widget that chooses between them. After this task a feature screen renders any
async provider by handing it to `AsyncValueView` and writes no state switch, no spinner and no error copy of its own.

## Files

- `frontend/lib/core/widgets/states/app_empty_state.dart` (new)
- `frontend/lib/core/widgets/states/app_error_state.dart` (new)
- `frontend/lib/core/widgets/states/app_loading_state.dart` (new)
- `frontend/lib/core/widgets/async_value_view.dart` (new)

## Contract

```dart
class AppEmptyState extends StatelessWidget {
  final IconData icon; final String headline, message; final String? actionLabel; final VoidCallback? onAction;
}
class AppErrorState extends StatelessWidget { final Failure failure; final VoidCallback? onRetry; }
enum SkeletonShape { list, card, detail }
class AppSkeleton extends StatelessWidget { final SkeletonShape shape; final int count; }
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value; final Widget Function(T) data; final Widget Function()? empty;
  final bool Function(T)? isEmpty; final VoidCallback? onRetry;
}
```

## Steps

1. `AppEmptyState`: icon, headline, one-line explanation and an optional primary action.
2. `AppErrorState`: map every `Failure` subtype to a plain-language message and a suggested action, with retry when
   `onRetry` is given.
3. `AppSkeleton`: list, card and detail placeholder shapes sized to the real content, plus a small inline spinner for
   actions rather than a full-screen one.
4. `AsyncValueView`: default loading and error to the shared states, take builders for data and empty, and treat
   `isEmpty` as the emptiness test on loaded data.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- All four get a gallery entry, plus goldens in light, dark and outdoor (FE-CONS-03).
- Every failure renders from a typed `Failure` through `AppErrorState`; no screen writes its own error copy
  (FE-CONS-11).
- Data views render loading, empty, error and offline through `AsyncValueView`, never a hand-rolled switch (FE-CONS-04).

## Definition of done

- [x] Every list screen shows a helpful empty state rather than blank space, and no screen shows a raw exception string.
- [x] Screens do not jump when data arrives, because the skeleton occupies the same space as the content.
- [x] Feature screens contain no manual async state switching.
- [x] Tests: widget test per `Failure` subtype asserting its message and that retry fires; widget test of
      `AsyncValueView` across loading, error, empty and data; goldens of all four in light, dark and outdoor.

## Out of scope

- The offline banner itself; that is part of task 041.
