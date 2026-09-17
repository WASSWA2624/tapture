# 228 — Upload confirmation

**Phase** 21 · Cloud upload  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [225](225-destination-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The sheet that stands between a file and the network: it names the file, its size, the destination and the remote
folder, and only an explicit tap starts the transfer. Every upload asks, every time.

## Files

- `frontend/lib/features/cloud/presentation/upload_confirm_sheet.dart` (new)

## Steps

1. Show file name, byte size formatted by the shared formatter, destination label and the full remote folder path.
2. Offer confirm and cancel only — no "remember this", no "always allow", no per-destination blanket consent.
3. Cancel returns before any request is constructed and before any credential is read.
4. Route the sheet through the dialog service (072) so it cannot be bypassed by a caller building its own dialog.

## Constraints

- Every send path calls this sheet; a caller reaching `CloudDestination.send` without a confirmation result is a
  defect (FE-SEC-03).
- One decision on the sheet, with the destination already chosen (FE-SIMP-07).

## Definition of done

- [ ] No bytes leave the device without this sheet being confirmed, including retries of a failed upload.
- [ ] No setting anywhere suppresses it, and a second upload of the same file asks again.
- [ ] Tests: widget test asserting cancel performs no request and reads no credential; test asserting a repeat upload
      of the same file to the same destination prompts a second time.

## Out of scope

- Any form of automatic, scheduled or background upload; this phase has no sync channel.
