# 142 — Verify standalone audio ownership in project packages

**Depends on** [019](../19-bundles-and-merge.md), [022](../22-privacy-and-security.md), [119](../24-product-refinements.md), [123](../24-product-refinements.md), [127](../24-product-refinements.md)

## Implement

Reconcile standalone transcription's project ownership with the project-package privacy and scope policy.
The Transcribe screen records into the open project and files its take as an audio attachment linked to its
transcript. The package snapshot selects finished project transcripts, but outbound privacy filtering retains
attachments through exported attachment-owner rows and removes a transcript when its linked audio is excluded.
Verify the policy for a project-owned take with no record owner, then repair the confirmed ownership or snapshot
gap through the existing attachment helpers and package filter.

Keep original audio and raw segments unchanged; export, recovery and import must not rewrite or silently remove
them. This is whole-product hardening under task 023 and does not become a dependency of task 136's APK delivery.

## Files

- `frontend/lib/features/transcripts/data/transcript_repository_impl.dart`
- `frontend/lib/features/transcripts/data/transcript_recovery.dart`
- `frontend/lib/features/transcripts/presentation/transcript_providers.dart`
- `frontend/lib/core/db/tables/attachments.dart` and the existing attachment-owner helpers
- `frontend/lib/core/bundle/bundle_tables.dart`, `frontend/lib/core/bundle/bundle_privacy.dart`
- `frontend/lib/features/merge/data/package_import_repository_impl.dart`
- `frontend/test/features/transcripts/data/` (standalone filing and recovery ownership)
- `frontend/test/core/bundle/` and `frontend/test/features/merge/data/` (real snapshot/export/import scenarios)
- `frontend/integration_test/` (Android restart and project-package round-trip acceptance)
- `app-write-up.md`, `frontend/docs/release-build.md` (reconciled policy and verification limits)

## Constraints

- Reuse project/record attachment ownership and audit helpers; do not add another ownership store or bypass consent.
- Preserve the approved-record scope, consent, coordinate removal, photo protection and other existing outbound filters.
- Live transcripts and device-local OCR/cache/queue data remain excluded according to their existing contracts.
- A raw-file path under a project folder is not sufficient evidence of exported ownership; verify actual metadata,
  manifest entries, checksums and imported relationships.
- Keep owned Android fixture media, raw text and detailed validation artifacts local and ignored.

## Definition of done

- [ ] Standalone project-audio ownership and package inclusion are explicit and consistent across filing, recovery, outbound privacy filtering and import, including full and approved-record scopes.
- [ ] Eligible finished standalone audio, its transcript header and raw segments travel together in a full project package and import with valid local audio paths and ownership; live or policy-excluded data remains excluded.
- [ ] Tests: real repository and package-snapshot fixtures cover completed/interrupted standalone takes without record owners, existing project owners, recovery/retry idempotency, and approved/privacy exclusions.
- [ ] Tests: an actual Android APK records and saves a standalone take, restarts, exports a project package, and round-trips that package through the production reader/importer; manifest counts, audio SHA-256, raw segment bytes and ownership remain consistent.
- [ ] Export and round-trip checks preserve the original audio checksum and raw segment text; repeated filing/import creates no duplicate owners, attachments or transcript segments.
- [ ] Release documentation and task 023's integrated acceptance record the verified result and any remaining explicit policy exclusions, without asserting that an omitted outbound copy destroyed local source evidence.

## Discovery evidence — 2026-10-07

Task 136's owned Android 16/API 36 emulator recorded the vendored speech sample through the actual microphone
recorder and native speech engine. The saved transcript screen remained available after app restart. The retained
local WAV is 1,570,860 bytes, 16 kHz mono 16-bit PCM, with SHA-256
`3810806211ffae4a9c46fcc53029f6cb80b49c4ff50b9033ac9eca62a31cf966`.
The original audio and transcript remain local; package inspection did not delete or rewrite either source.

The production project-package export succeeded and the app/Downloads copies had the same SHA-256. Independent
inspection verified ZIP CRC, all 18 manifest entry sizes/hashes, all checksum-file entries, two records, two photos,
the original 13-page PDF's unchanged source hash, and the original typed record caption. The full-project package
contains `transcripts.json` with zero transcripts and zero segments and no WAV/audio entry. This demonstrates
an outbound omission rather than local source loss.

`TranscribeScreen` uses the current project even from the global app bar. `fileStandaloneAudio` creates an audio
attachment and transcript link without creating a project attachment-owner row. `BundleTables` selects project
transcripts whose status is not live; `BundlePrivacy` then keeps attachments through exported owner rows and keeps
a linked transcript only when its audio remains. The policy/owner-creation mismatch requires reconciliation and
the end-to-end tests above. No repair has started and all acceptance items remain open.

The preserved package and concise verification evidence are under the ignored local
`frontend/build/apk-validation/android-project-package-before-decimal-fix.zip` and
`android-project-package-before-decimal-fix-validation.json`; the retained WAV and transcript-relaunch screenshots
are siblings. Task 127's seeded package round-trip evidence does not verify this actual standalone filing path.
