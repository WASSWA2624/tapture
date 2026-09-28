# 078 — Keep the device id in the storage root

**Phase** 23 · Hardening  |  **Depends on** [076](076-resolve-project-capture-package-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Found while writing task 076's project packages. The device id (specification §10.2: created at first launch,
never reused) is kept in the OS temp folder on native platforms
(`frontend/lib/core/device/device_io.dart`, `${Directory.systemTemp.path}/tapture-device/device.id`), which the OS
or a cleaner may empty, and only in memory on web, so every page load gets a new id. A project package names the
device it came from and a merge records it, so an id that changes makes one device look like several.

Keep the id where it survives: in the database's `device_profile.deviceId` (already a column), read once at start,
with the temp file read only to migrate an existing id into it. On web the database lives in IndexedDB, so the id
survives a reload there too.

## Files

- `frontend/lib/core/device/device_identity.dart`
- `frontend/lib/core/device/device_io.dart`
- `frontend/lib/core/db/tables/device_profile.dart`
- `frontend/lib/main.dart`

## Definition of done

- [x] The device id survives clearing the OS temp folder and, on web, a page reload.
- [x] An id already in the temp file is kept, not replaced, on the first launch after the change.
- [x] Tests: identity resolution from the profile, from the legacy file, and a fresh install.
