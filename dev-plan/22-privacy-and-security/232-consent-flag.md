# 232 — Consent, face blurring and redaction

**Phase** 22 · Privacy and security  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [068](../05-file-storage/068-thumbnail-cache.md), [088](../09-templates/088-template-model.md), [089](../09-templates/089-field-type-registry.md), [127](../12-capture/127-photo-viewer.md), [205](../18-export/205-zip-package.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three protections a project that records people needs: a standard consent field type whose absence blocks export,
optional face blurring in exported photos, and hand-marked regions obscured in the copy sent for analysis. No original
file changes in any of them.

## Files

- `frontend/lib/features/quality/domain/consent_field.dart` (new)
- `frontend/lib/core/export/face_blur.dart` (new)
- `frontend/lib/features/capture/presentation/redaction_editor.dart` (new)

## Steps

1. Register consent as a field type (154) any template (153) can require; store the value with who confirmed it and
   when, per record.
2. When the project requires consent, export omits records lacking it and names them in the export summary rather than
   failing the whole run or omitting them silently.
3. Blur detected faces while packaging the zip (381), inside `runIsolate` (033), and report the face count found per
   photo so an operator can spot a miss.
4. Redaction editor marks rectangles over the photo viewer (228); marks are burned into the compressed copy (122) only,
   and the photo is flagged redacted-on-send so later sends reapply them.

## Constraints

- Originals stay byte-identical; blur and redaction write derived copies under `.cache` (FE-SEC-08).
- Both image passes run off the UI isolate (FE-PERF-02).
- Consent lives on the record as data with an audit entry, never in preferences (FE-SEC-07, FE-SEC-09).

## Definition of done

- [ ] Consent is recorded per record with who and when, and an export of a consent-requiring project omits records
      lacking it and lists them.
- [ ] A marked region and a detected face never reach a provider or an export in clear form, including on a re-send.
- [ ] Every original photo is byte-identical after export, blur and redaction.
- [ ] Tests: unit tests of `consent_field.dart` with no Flutter binding, covering the export block; hash comparison of
      originals before and after a blurred export; test asserting the sent copy differs from the original inside the
      marked region and matches outside it.
