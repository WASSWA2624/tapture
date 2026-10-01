# 098 — Connect configured desktop cloud accounts through external-browser PKCE

**Implementation step:** 21.03

**Phase** 21 · Cloud upload  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](../02-foundation/002-foundation-services.md), [004](../04-data-layer/004-local-database.md), [005](../05-file-storage/005-file-storage.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

**Implementation started:** Yes

Connect configured Windows, macOS and Linux consumer accounts through the existing shared PKCE/token client
of [021](021-cloud-upload.md), retaining the mobile Google SDK of [094](094-connect-native-google-drive.md).
Use the Flutter-maintained [`url_launcher` 6.3.2](https://pub.dev/packages/url_launcher/versions/6.3.2),
BSD-3-Clause, pinned directly and allowlisted. It replaces the missing desktop browser hand-off; no shell,
embedded credential browser, provider client secret or custom OAuth protocol package is introduced.

Follow [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252.html): launch the external browser and bind a bounded
HTTP listener only to an explicitly configured loopback IP. Configure each provider's client ID and
`GOOGLE_DRIVE_REDIRECT_URI`, `ONEDRIVE_REDIRECT_URI` or `DROPBOX_REDIRECT_URI` at build time. Google Desktop
clients may explicitly request port 0, resolved to an ephemeral port before opening the browser; other providers
require a nonzero registered port. Dropbox requires its exact redirect registered in its
[app console](https://docs.dropboxapi.com/dropbox-api/docs/oauth); Microsoft public-client redirects follow its
[registration rules](https://learn.microsoft.com/en-us/entra/identity-platform/reply-url).
Absent or unsupported configuration hides that consumer destination. No registered IDs are invented.

Require canonical explicit redirect configuration; reject a path silently normalized by URI parsing.
Validate Host, path, method, state and single bounded code/error parameters before accepting a callback. Reuse
the exact runtime redirect in code exchange. Cancellation, a stalled launcher, timeout or occupied port closes
the listener and detaches callbacks; no response or failure echoes an authorization code. macOS sandbox builds
declare the network client/server entitlements needed for explicit HTTPS and local loopback operations.
Browser consumer upload remains a distinct unsupported software contract: the browser registry/transport is not
implemented by this desktop receiver. Real provider registration, consent and platform builds remain unverified.

## Files

- `frontend/lib/core/cloud/cloud_oauth_redirect.dart`
- `frontend/lib/core/cloud/desktop_cloud_sign_in.dart`
- `frontend/lib/core/cloud/cloud_sign_in_io.dart`
- `frontend/lib/core/cloud/cloud_settings.dart`
- `frontend/lib/core/cloud/oauth_destination_client.dart`
- `frontend/lib/features/cloud/data/cloud_backends.dart`, `cloud_backends_io.dart`
- `frontend/lib/features/cloud/presentation/destination_editor_controller.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/macos/Runner/*.entitlements`
- `frontend/pubspec.yaml`, `frontend/pubspec.lock`, `frontend/tool/allowlist.yaml`
- `frontend/test/core/cloud/desktop_cloud_sign_in_test.dart`
- Existing OAuth factory/controller regressions.

## Definition of done

- [x] The maintained launcher is pinned directly and allowlisted with its license, purpose and replacement.
- [x] Configured desktop providers use external-browser PKCE with loopback-only binding, exact callback checks,
      runtime redirect exchange and secure token persistence; unconfigured providers remain unavailable.
- [x] Cancellation, timeout, rejected callbacks, launcher failure and occupied ports release the actual server,
      request subscription and token callback without publishing credentials.
- [x] Tests cover real local HTTP callbacks/exchange, ephemeral and fixed redirects, spoofed Host/path/state,
      duplicate/oversized fields, refused configuration, cancellation, timeout and late launch results.
- [ ] Final desktop builds compile; registered Google, Microsoft and Dropbox accounts complete consent,
      upload, token renewal and revoked-scope recovery on their configured platforms.

2026-10-01 software verification: the desktop callback/OAuth factory/native Google cancellation suite passed
22 tests, including actual local HTTP callback/token exchange, real listener close checks and secure token
persistence. A separate disposed-editor regression passed and verifies that a late successful probe cannot save
a dismissed form or retain its new credential. Provider endpoints in these tests are local test servers; they do
not establish external consent, registered provider configuration or a final desktop release build.
