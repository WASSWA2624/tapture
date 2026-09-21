# 117 — Privacy and security: what leaves this device, and what never does

**Phase** 22 · Privacy and security  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [026](../02-foundation/026-permissions-service.md), [068](../05-file-storage/068-thumbnail-cache.md), [086](../08-projects/086-project-edit.md), [089](../09-templates/089-field-type-registry.md), [107](../12-capture/107-capture.md), [108](../13-processing/108-processing.md), [113](../18-export/113-export.md), [114](../19-bundles-and-merge/114-bundles-and-merge.md), [116](../21-cloud-upload/116-cloud-upload.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything that governs what leaves this device. One settings screen naming every outbound path — AI extraction, OCR,
speech, refinement and cloud upload — each row stating what it sends, where it goes and whether it is on, with the
switch in the row, and the list built from the provider registry and the destination repository rather than a
hardcoded array; beside it the location section that keeps GPS off by default, excludes coordinates from every export
and strips them from records already captured, audited and counted. Two project-level switches: one makes a project
fully manual, so no screen offers an online action and the queue accepts no online job for it; one holds images back
entirely, so extraction runs on on-device OCR text and says so on the result. The three protections a project that
records people needs: a standard consent field type whose absence blocks a record from export, optional face blurring
in exported photos, and hand-marked regions obscured in the copy sent for analysis — no original file changes in any
of them. A wrapper type that makes it impossible to interpolate OCR output, transcripts, imported cells, bundle
content or file names into an instruction, a query or a path, so such text travels as a delimited data block and is
escaped where it is rendered. A suite that produces a real export, a real bundle and a real exported log, then fails
if any byte of them matches a secret shape or a value held in secure storage during the run. And every platform
permission the app declares tied to one shipped feature and one rationale sentence shown at the point of use, so a
fresh install asks for nothing until the user does something that needs it.

## Files

Egress summary and location:

- `frontend/lib/features/settings/presentation/egress_summary_screen.dart` (new)
- `frontend/lib/features/settings/presentation/gps_privacy_section.dart` (new)

Per-project switches:

- `frontend/lib/features/projects/presentation/ai_disable_switch.dart` (new)
- `frontend/lib/features/projects/presentation/image_egress_switch.dart` (new)

Consent, blurring and redaction:

- `frontend/lib/features/quality/domain/consent_field.dart` (new)
- `frontend/lib/core/export/face_blur.dart` (new)
- `frontend/lib/features/capture/presentation/redaction_editor.dart` (new)

Untrusted text:

- `frontend/lib/core/security/untrusted_text.dart` (new)

Permissions:

- `frontend/lib/core/permissions/permission_rationale.dart` (new)
- `frontend/android/app/src/main/AndroidManifest.xml` (edit)
- `frontend/ios/Runner/Info.plist` (edit)

Guardrails:

- `frontend/test/support/secret_patterns.dart` (new)
- `frontend/test/security/secret_scan_test.dart` (new)

## Contract

```dart
class UntrustedText {
  const UntrustedText(this.raw);
  final String raw;
  String asDataBlock(String label);
  String forDisplay();
  String forFileName();
}

class PermissionRationale {
  const PermissionRationale({required this.permission, required this.feature, required this.message});
  final AppPermission permission; final String feature; final String message;
  static PermissionRationale of(AppPermission p);
}
```

## Steps

1. Build the egress summary screen first, so the rest of the phase has one place that states the truth. Build the
   outbound list from the provider registry (task 108) and the destination repository (task 116), never from a
   hardcoded array, so a new provider or destination cannot be missing from the screen. Each row states the operation
   — AI extraction, OCR, speech, refinement, cloud upload — what leaves it (text only, image, audio, file), where it
   goes, and its on or off state, with the switch in the row. The location section keeps GPS off by default, carries a
   switch excluding coordinates from every export, and an action removing coordinates from the current project's
   existing records; that removal writes an audit entry naming who removed them and when, and reports how many records
   changed.
2. Add the two per-project switches. Store both flags in project settings (task 086); the provider registry reads them
   before a request is composed, so the check cannot be skipped by a new caller. With AI off, processing entry points
   are absent from the record and photo screens rather than shown disabled, and the queue accepts no online job for
   that project. With image egress off, extraction uses on-device OCR text only and the request builder receives no
   image path, on first run, retry and refinement alike. State the basis on the extraction result — "text only,
   on-device OCR" — so the operator knows what a value came from.
3. Deliver consent, face blurring and redaction. Register consent as a field type through the field type registry
   (task 089) that any template can require, and store the value with who confirmed it and when, per record. When the
   project requires consent, export omits records lacking it and names them in the export summary rather than failing
   the whole run or omitting them silently. Blur detected faces while packaging the zip (task 113), inside
   `runIsolate` (task 024), and report the face count found per photo so an operator can spot a miss. The redaction
   editor marks rectangles over the photo viewer (task 107); marks are burned into the compressed copy of the
   thumbnail cache (task 068) only, and the photo is flagged redacted-on-send so later sends reapply them.
4. Wrap untrusted text at the boundary: the OCR reader, transcript writer, spreadsheet importer, bundle reader and
   file scanner all return `UntrustedText`, so a raw `String` from those sources cannot reach a request builder.
   Change the extraction request (task 108) to accept `UntrustedText` for these fields and emit them only inside a
   labelled, delimiter-escaped data block. `forDisplay` escapes for rendering; `forFileName` transliterates to ASCII
   and strips separators and traversal sequences. Neither rewrites `raw`, which stays the stored evidence.
5. Build the secret leak suite. Patterns cover AWS-style key ids and secrets, bearer and refresh tokens, PEM
   private-key headers, long base64 runs, provider key prefixes, plus every value written to the fake secure store
   during the test. Generate artefacts through the real writers — the export packager (task 113), the bundle writer
   (task 114) and the log export of the logger service (task 022) — never from hand-written fixtures, so the scan
   follows the code that ships. Scan file bytes and archive entry names, including nested entries, and report every
   hit with artefact, entry and offset rather than stopping at the first.
6. Finish with the permission review. Write one entry per `AppPermission` (task 026), naming the feature that needs it
   and the sentence shown before the system prompt. Delete every manifest and plist declaration not backed by an
   entry, including any pulled in transitively by a package. Request at the point of use through the permissions
   service; nothing is requested during bootstrap.

## Constraints

- The egress screen reads state and flips flags; it holds no client and composes no request, and a switch guards
  egress at the registry rather than in each screen (FE-SEC-03).
- Off is the default for every row that sends anything (FE-SEC-07).
- Both project switches are per project, not global preferences; a second project is unaffected (FE-SEC-07).
- Coordinate removal is an audited edit, not a silent rewrite of raw evidence (FE-SEC-08, FE-SEC-09).
- Consent lives on the record as data with an audit entry, never in preferences (FE-SEC-07, FE-SEC-09).
- Originals stay byte-identical; blur and redaction write derived copies under `.cache` (FE-SEC-08).
- Both image passes run off the UI isolate (FE-PERF-02).
- No sanitising in place: the record keeps the text exactly as captured (FE-SEC-08, FE-L10N-11).
- No query, prompt, path or shell argument is built by concatenation anywhere in the app (FE-SEC-05).
- The secret scan suite plants its own secrets at run time; no real or example credential is committed (FE-SEC-01).
- Its artefacts are generated into a temporary directory and removed afterwards (FE-TEST-05).
- The rationale string comes from the copy helper, not a literal in the manifest merge (FE-L10N-01).
- A permission a package declares for us is still ours to justify or remove (FE-SEC-07).
- The secret scan and the permission review are guardrails: each passes on the current tree, fails on a deliberate
  violation, ships a fixture proving both, and reports every violation it finds with file and line rather than
  stopping at the first.

## Definition of done

- [ ] Every outbound path can be seen and disabled from this one screen, and a newly registered provider or
      destination appears without editing the screen.
- [ ] A project can be delivered with no location data at all, and each coordinate removal is visible in the audit
      trail.
- [ ] Tests: widget test of `egress_summary_screen.dart` over empty, all-off, all-on and failure states.
- [ ] Tests: test asserting a new registry entry appears in the list.
- [ ] Tests: test asserting an export after exclusion carries no coordinates and `gps_privacy_section.dart` reports
      the changed record count.
- [ ] With AI off, no screen in the project offers an online action and the project runs end to end with no outbound
      call.
- [ ] With image egress off, no request carries an image path, including retries and refinement, and the result
      states that its values came from on-device OCR text alone.
- [ ] Tests: integration test asserting zero outbound calls for a project with AI off.
- [ ] Tests: widget tests of both switches, including their empty and failure states.
- [ ] Tests: unit test that the composed extraction request holds OCR text and no image for every entry point.
- [ ] Consent is recorded per record with who and when, and an export of a consent-requiring project omits records
      lacking it and lists them.
- [ ] A marked region and a detected face never reach a provider or an export in clear form, including on a re-send.
- [ ] The face count found is reported per photo, so a missed face is visible rather than silent.
- [ ] Every original photo is byte-identical after export, blur and redaction.
- [ ] Tests: unit tests of `consent_field.dart` with no Flutter binding, covering the export block.
- [ ] Tests: hash comparison of originals before and after a blurred export.
- [ ] Tests: test asserting the sent copy differs from the original inside the marked region and matches outside it.
- [ ] A crafted caption cannot change what the provider is asked to do, and still appears verbatim on the record.
- [ ] Passing a plain `String` from OCR, import or bundle content into the request builder fails to compile.
- [ ] Tests: fixture cases for an instruction-shaped caption, a delimiter-closing caption, an SQL fragment and a
      traversal file name, each asserting the composed request structure, the rendered widget and the written
      filename are unaffected.
- [ ] The suite fails when any artefact contains a key, token or credential, naming artefact, entry and offset, and
      reports every hit rather than the first.
- [ ] Tests: `frontend/test/security/secret_scan_test.dart` green over a clean run of the real export packager,
      bundle writer and log export.
- [ ] Tests: a fixture pair proving a token planted in a bundle entry name and one planted in a log line each fail
      the scan.
- [ ] A fresh install requests no permission until the user starts capture, recording, import or a folder upload.
- [ ] Every declared platform permission maps to exactly one rationale entry and one shipped feature.
- [ ] Tests: unit tests of `permission_rationale.dart` against the permissions fake.
- [ ] Tests: a test parsing the merged manifest and the plist that fails on any declaration without a rationale
      entry, and on any entry without a declaration, naming file and line for every one it finds.
- [ ] Tests: a fixture pair for that test, one manifest carrying an unjustified declaration and one rationale entry
      with nothing declared, proving the review fails on each and passes on the shipped pair.
