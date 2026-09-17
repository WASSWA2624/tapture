# 227 — Google Drive, OneDrive and Dropbox destinations

**Phase** 21 · Cloud upload  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [224](224-destination-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three consumer providers, each signed in with the user's own account and uploading into a folder that user picks,
over one shared OAuth flow rather than three.

## Files

- `frontend/lib/core/cloud/oauth_destination_client.dart` (new)
- `frontend/lib/core/cloud/google_drive_destination.dart` (new)
- `frontend/lib/core/cloud/onedrive_destination.dart` (new)
- `frontend/lib/core/cloud/dropbox_destination.dart` (new)

## Steps

1. Write the authorisation-code-with-PKCE flow, token exchange and refresh once in `oauth_destination_client.dart`;
   the three backends supply only endpoints, scope names, the folder picker call and the upload call.
2. Request the narrowest scope that permits creating files in the chosen folder — never a read-all scope, never
   account-wide metadata.
3. Store access and refresh tokens in secure storage under the destination's entry. On a 401, refresh once and retry;
   if refresh fails, surface a re-authorisation prompt and leave the destination configured.
4. Upload through each provider's resumable endpoint, reporting progress and accepting a starting offset so 426 can
   continue an interrupted transfer.

## Constraints

- OAuth and provider packages go through the dependency allowlist (task 005); the redirect scheme is registered per
  platform, not hardcoded in Dart (FE-CODE-09).
- Tokens never leave secure storage, never enter a log line and never appear in a failure message (FE-SEC-01).
- No client code outside `core/cloud/` (FE-SEC-03).

## Definition of done

- [ ] The app never reads the user's other Drive, OneDrive or Dropbox content; only the folder it was given and the
      files it created there.
- [ ] An expired token refreshes silently without the user re-picking the folder; a revoked token asks for
      re-authorisation without losing the destination.
- [ ] Tests: unit tests of `google_drive_destination.dart`, `onedrive_destination.dart` and `dropbox_destination.dart`
      against fakes; a test asserting the requested scope string for each provider; a refresh-then-retry and a
      refresh-failure test on `oauth_destination_client.dart`.
