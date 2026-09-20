# 330 — Add share_plus for opening files externally

**Phase** 05 · File storage  |  **Depends on** [065](065-storage-root.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`share_plus` is the one approved way to hand a file copy to the Android and iOS
system chooser. Features never import it; only `DownloadService` does.

## Files

- `frontend/pubspec.yaml`
- `frontend/tool/allowlist.yaml`

## Constraints

- One pinned version, a licence note, and a sentence on what it replaces
  (FE-FLOW-06).
- No feature calls the plugin (FE-STR-11).

## Definition of done

- [x] `share_plus` is in `pubspec.yaml` and `allowlist.yaml` at the same pin.
- [x] The dependency checker is green.
