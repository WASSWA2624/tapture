# 209 — Bundle scope, sharing and receiving

**Phase** 19 · Bundles and merge  |  **Depends on** [207](../18-export/207-export-history.md), [208](208-bundle-format.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The interface around a bundle leaving and arriving: a scope section choosing how much of the project travels, the share
action that hands the file to the system, and the file association that makes an incoming bundle open the import flow
directly.

## Files

- `frontend/lib/features/merge/presentation/bundle_scope_section.dart` (new)
- `frontend/lib/features/merge/presentation/bundle_share_actions.dart` (new)

## Steps

1. Offer five scopes: full project, date range, context subtree, approved records only, and data without photos.
2. Show the estimated bundle size for the chosen scope before writing starts.
3. Register the bundle extension and MIME type so opening one from mail, a file manager or removable media lands in the
   import screen.

## Constraints

- Share and file-open both go through the platform wrapper, not `dart:io` or a plug-in call in the widget
  (FE-STR-11).
- An incoming file is untrusted until the reader validates it; this task hands it over and shows no content
  (FE-SEC-06).

## Definition of done

- [ ] A data-only bundle of a large project is small enough to send by email, and its size is stated before writing.
- [ ] Receiving a bundle by any transport lands in the same import screen.
- [ ] Tests: widget tests of `bundle_scope_section.dart` covering each scope and the four states, and of `bundle_share_actions.dart` asserting share and incoming-file handling both route through the wrapper.
