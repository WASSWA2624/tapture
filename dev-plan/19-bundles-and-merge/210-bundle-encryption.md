# 210 — Bundle encryption and secret exclusion

**Phase** 19 · Bundles and merge  |  **Depends on** [015](../01-orchestration/015-logging-checker.md), [027](../02-foundation/027-secure-storage-service.md), [208](208-bundle-format.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A bundle can be password-protected for travel on removable media, and no bundle — encrypted or not — ever contains a
key, credential, token or device secret.

## Files

- `frontend/lib/core/bundle/bundle_encryption.dart` (new)
- `frontend/lib/core/bundle/bundle_redaction.dart` (new)

## Contract

```dart
class BundleEncryption {
  /// Encrypts [plain] to [target] with a key derived from [password]; the password is never stored.
  Future<void> seal(File plain, File target, String password);
  /// Fails with `BundleAuthFailure` before writing anything when [password] is wrong.
  Future<void> open(File sealed, Directory target, String password);
}

class BundleRedaction {
  /// Columns and settings keys never serialised into a bundle.
  static const Set<String> excluded = {/* ... */};
  /// Throws when [entry] carries a secret-shaped value.
  void assertClean(BundleEntry entry);
}
```

## Steps

1. Derive the key from the password with a salt stored in the archive header; keep neither password nor derived key
   anywhere on the device.
2. Decrypt to a temporary directory and verify the whole archive before a single file is placed, so a wrong password
   leaves no partial extraction.
3. Filter secret-bearing columns and settings out of the write path in `bundle_redaction.dart`, and run the patterns of
   022 over every produced entry as the writer streams it.

## Constraints

- Encryption is real where it is claimed: no home-grown cipher, no key in shared preferences (FE-SEC-11, FE-SEC-01).
- No key is written to a bundle even when the device holds one (FE-SEC-02).

## Definition of done

- [ ] A wrong password fails cleanly, leaving no extracted file behind.
- [ ] The redaction check runs over every produced bundle and fails the write when a secret-shaped string appears.
- [ ] Tests: unit tests of `bundle_encryption.dart` over correct and wrong passwords asserting no partial extraction, and of `bundle_redaction.dart` with a fixture bundle seeded with a secret-shaped value.
