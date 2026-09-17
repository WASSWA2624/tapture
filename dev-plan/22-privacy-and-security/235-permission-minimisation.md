# 235 — Permission minimisation review

**Phase** 22 · Privacy and security  |  **Depends on** [026](../02-foundation/026-permissions-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every platform permission the app declares is tied to one shipped feature and one rationale sentence shown at the point
of use. A fresh install asks for nothing until the user does something that needs it.

## Files

- `frontend/lib/core/permissions/permission_rationale.dart` (new)
- `frontend/android/app/src/main/AndroidManifest.xml` (edit)
- `frontend/ios/Runner/Info.plist` (edit)

## Contract

```dart
class PermissionRationale {
  const PermissionRationale({required this.permission, required this.feature, required this.message});
  final AppPermission permission; final String feature; final String message;
  static PermissionRationale of(AppPermission p);
}
```

## Steps

1. Write one entry per `AppPermission` (036), naming the feature that needs it and the sentence shown before the system
   prompt.
2. Delete every manifest and plist declaration not backed by an entry, including any pulled in transitively by a
   package.
3. Request at the point of use through the permissions service; nothing is requested during bootstrap.

## Constraints

- The rationale string comes from the copy helper, not a literal in the manifest merge (FE-L10N-01).
- A permission a package declares for us is still ours to justify or remove (FE-SEC-07).

## Definition of done

- [ ] A fresh install requests no permission until the user starts capture, recording, import or a folder upload.
- [ ] Every declared platform permission maps to exactly one rationale entry and one shipped feature.
- [ ] Tests: unit tests of `permission_rationale.dart` against the permissions fake; a test parsing the merged manifest
      and the plist that fails on any declaration without a rationale entry, and on any entry without a declaration.
