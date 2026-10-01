# 094 — Connect native Google Drive identity securely

**Implementation step:** 21.02

**Phase** 21 · Cloud upload  |  **Depends on** [002](../02-foundation/002-foundation-services.md), [004](../04-data-layer/004-local-database.md), [005](../05-file-storage/005-file-storage.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

**Implementation started:** Yes

Connect Android and iOS Google Drive identity through the maintained `google_sign_in` 7.2.0 package
(BSD-3-Clause; [package](https://pub.dev/packages/google_sign_in/versions/7.2.0)). Keep the adapter under
`core/cloud/`, following the destination credential and request permission contracts of
[021](021-cloud-upload.md) and the privacy boundaries of
[022](../22-privacy-and-security/022-privacy-and-security.md).

Explicit sign-in requests only `https://www.googleapis.com/auth/drive.file`. Configure the registered Android
web/server client ID using `GOOGLE_DRIVE_SERVER_CLIENT_ID`, or the registered iOS client ID using
`GOOGLE_DRIVE_CLIENT_ID` and its reversed URL scheme using the native `GOOGLE_DRIVE_REVERSED_CLIENT_ID` build
setting. Offer Google only when its mobile client is configured. Provider registration, Android signing
fingerprints, iOS URL routing and real consent require deployment-specific configuration.

The SDK owns token renewal. Store access tokens in secure storage and a bound account identifier in the secure
credential metadata; never invent a provider refresh token or request a server authorization code. Silent renewal
requests previously authorized scopes for that account. A different account or missing scope fails with a sign-in
action while preserving the destination. Initialize the SDK once on the main isolate. A transfer worker asks that
isolate to renew an expired token, waits for a generation-checked secure storage acknowledgement and retries once.
Cancellation ends a waiting worker; late SDK results cannot restore a removed credential.

## Files

- `frontend/lib/core/cloud/native_google_authorization.dart`
- `frontend/lib/core/cloud/native_google_client_io.dart`
- `frontend/lib/core/cloud/native_google_client_stub.dart`
- `frontend/lib/core/cloud/oauth_destination_client.dart`
- `frontend/lib/core/cloud/cloud_upload_context.dart`
- `frontend/lib/core/cloud/worker_cloud_destination_io.dart`
- `frontend/lib/features/cloud/presentation/destination_editor_controller.dart`
- `frontend/lib/features/cloud/data/cloud_backends_io.dart`
- `frontend/ios/Runner/Info.plist`
- `frontend/pubspec.yaml`, `frontend/pubspec.lock`, `frontend/tool/allowlist.yaml`

2026-10-01 source analysis found no cloud issues. `:app:compileProdDebugKotlin` compiled the Android app,
native hand-off/folder adapters and SDK dependencies successfully, excluding Flutter asset compilation.
This does not establish a registered provider build, iOS compilation or a real account consent journey.

## Definition of done

- [x] The pinned maintained SDK is allowlisted, with its version, license, purpose and task recorded.
- [ ] Google is offered only with explicit mobile client configuration, and explicit sign-in requests `drive.file`.
- [ ] Credentials remain in secure storage, account substitution is refused and destination removal rejects late writes.
- [ ] A worker renews through the main-isolate SDK and secure storage acknowledgement, retries an expired token once,
      and cancellation terminates a stalled renewal wait.
- [ ] Tests: `native_google_authorization_test.dart`, `oauth_destination_client_test.dart` and
      `worker_cloud_destination_test.dart` cover account binding, removal, SDK refresh, acknowledgement and cancellation.
- [ ] A configured Android build and iOS build compile with the registered provider client and callback settings.
- [ ] Real Android and iOS accounts complete consent, upload, silent renewal and revoked-scope recovery without
      reading unrelated Drive files or losing the configured destination.
