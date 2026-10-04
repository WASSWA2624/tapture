# 19 — Bundles and merge

Collaboration that never touches the backend: a project leaves whole, by hand, and rejoins safely.

## 019 — Bundles and merge: a project leaves whole and rejoins safely

**Depends on** [001](01-orchestration.md), [002](02-foundation.md), [004](04-data-layer.md), [005](05-file-storage.md), [008](08-projects.md), [018](18-export.md)

### Production reconciliation — 2026-10-01

The original template/reference acceptance relied on isolated pure helpers. The production planner kept differing
reference attributes silently and did not offer template choices; those two criteria are reopened until the real
writer → reader → planner → SQLite apply regressions pass. The planner now raises structural conflicts, the UI
offers choose one or keep both, distinct historical shapes use the existing template version store, and a separate
copy retains same-version forks without rewriting captured metadata. Reference choices retain matched local row
identities and append per-conflict audit. The focused structural verification is pending. Merge history, undo,
causal vectors and lineage have production implementations and regressions; final verification remains pending.

On 2026-10-04, 46 bundle and merge tests passed, including the writer round-trip, manifest clocks,
production lineage, the four conflict choices, snapshot undo and the history screen's four states.
The 2,000-photo package stayed inside its memory budget. Email size, every incoming transport,
captured template version under each resolution, differing reference attributes as a production
conflict, conflict-screen empty/loading/failure states and a scan limited to the merge boundary
stay open.

### Implement

**Implementation started:** Yes

2026-09-30 audit: the native package memory test writes and independently reopens 2,000 valid JPEG files
(496,086,000 source bytes). Its 496,853,885-byte package completed in 30,261 ms with 28,262,400 bytes additional
process RSS, below the 96 MiB regression budget. The measured interval excludes fixture setup and includes native
table serialization, hashing and ZIP publication. The desktop result does not establish mobile frame timing.

2026-10-01 production audit: merge sessions persist source, timestamp, bundle id and category counts, but
`MergeHistoryScreen` has no registered route or production caller, and `MergeRepository` has no production
implementation. `PackageImportRepositoryImpl._session` stores an empty `undoSnapshotPath`; the current
`MergeApply` and `MergeUndo` tests exercise copied string maps rather than durable database rows or evidence files.
The history, undo and combined apply/undo acceptance below are reopened until the real route, persisted history,
snapshot publication, recovery and restore paths are implemented and verified. The existing merge transaction and
failed-copy cleanup remain separate evidence; they do not establish post-commit undo.

The same audit found that `ConflictScreen` exposes Type a value and Decide later, but its handlers pass only an
enum (`conflict_screen.dart:248,256`), and `MergeController.choose` stores no typed payload
(`merge_controller.dart:88`). `_settle` resolves every choice before branching only on `theirs`
(`package_import_repository_impl.dart:557,590`), so typed and deferred choices currently act as Keep mine rather
than validating a typed value or leaving the conflict unresolved. The production post-commit call is
`qualityRepository.scanProject(projectId)` (`merge_controller.dart:233`), which scans the project rather than
only incoming versus pre-existing records; the isolated `PostMergeScan` unit fixture does not verify that boundary
in the production path. The corresponding behaviour and four-choice widget coverage are reopened below.

The production package path now reuses `BundleScopeSection` for full project, date, context, approved-only and
data-only selection, and estimates the selected package before writing. Passwords remain ephemeral in the export
request and import prompt. Native and browser writers/readers use the shared authenticated AES-256-CTR/HMAC-SHA256
cipher with independent purpose-derived keys and salted PBKDF2; authentication completes before any plaintext
output is published. Actual writer/reader regressions cover correct and wrong passwords, encrypted native/browser
interop and tampering. A production export with approved-only selection, no photos and a password independently
reopens with the selected row and leaves the original database unchanged. Every writer scans generated names,
tables and attachment contents using the canonical secret-pattern asset, including bounded recursive compressed
archive inspection. Secret columns and nested JSON settings are stripped before serialization. Production secret
refusal, compressed attachment, source-integrity and bounded-output cases pass; the real email-size acceptance
remains open because it depends on the chosen project and transport limit.

The bounded reader now verifies and extracts native stored/DEFLATE media with a 64 KiB output buffer and a
32 KiB dictionary, without retaining inflated `ArchiveFile.content` arrays. An inspected package leases one
streamed entry at a time; completion, cancellation and owner disposal release its generated plaintext. Inspection
and extraction use cancellable workers with parent-owned temporary directories. Both writers and readers cap
combined manifest/table/reference JSON at 32 MiB, with a separate 1 MiB manifest ceiling before decoding; oversized
metadata asks the exporter to choose a smaller scope. Native media keeps the 4,000,000,000-byte package contract.
New memory, compressed-entry, cancellation, declared-size and real 5,000-record metadata regressions are pending
the final source-stable verification run.

New password writes use `TAPBND03`, a random 16-byte salt and a stored PBKDF2-HMAC-SHA256 factor of 600,000,
following the [OWASP work-factor guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
Readers refuse v3 factors outside 600,000–1,200,000 before derivation, and retain read-only `TAPBND02` compatibility
with its fixed 1,000-round legacy factor. Native byte encryption/decryption and KDF work run on the standard
cancellable worker; browser derivation uses asynchronous
[WebCrypto PBKDF2](https://www.w3.org/TR/webcrypto/#pbkdf2) and HMAC. Its compatible AES counter advances in
aligned 64 KiB chunks with an event-loop yield and cancellation check between chunks. Readers authenticate before
allocating a ciphertext snapshot and authenticate that snapshot again before decrypting, preventing a caller's
buffer mutation during an asynchronous browser operation from publishing unauthenticated plaintext.
Independent Node crypto fixtures, legacy/modern file
interop, modified salt/factor, wrong-password and cancellation regressions are prepared; their final verification
and the browser WebCrypto run remain pending.

Native KDF work keeps the approved `crypto` HMAC implementation for the RFC 8018 single 256-bit block and checks
cancellation every 1,024 rounds. A 600,000-round native benchmark derived the same 32-byte frozen Node key in
3,186 ms; the SHA-256 compression block is 64 bytes, not a second derived-key block. Maintained PointyCastle,
cryptography and hashlib trials offered no measured gain and were removed. The byte/file format, strong factor,
browser WebCrypto path and purpose separation are unchanged. Independent Node fixtures cover empty, binary-salt,
long-password, Unicode and NUL dimensions. Independent multi-derivation unit cases are split under the original
30-second per-case deadline, retaining every functional check and the exact product/cancellation budgets.

The final combined native run exposed ZIP cancellation skipping worker `finally` cleanup on Windows and a
2,000-record manifest exceeding its 1 MiB cap after causal vectors were added. File workers now use an empty
parent-owned cancellation lease, removed on cancellation without allocating new disk data, and close their
handles before returning. Manifests now use compact JSON within the same cap. The memory and combined round-trip
criteria below are reopened pending the repaired regression run; neither the budget nor the timing gates changed.

The repaired focused native run passed all 58 encryption/protection/ZIP/reader/lock/history cases. Independent
Node legacy/modern fixtures, 600,000-round 32-byte derivation, tampered salt/factor, invalid-factor refusal and
cancellation pass under the unchanged per-case deadline. Writer and reader cancellation now prove worker exit,
actual Windows source-handle release and owned scratch removal. The real 128 MiB compressed-entry fixture added
25,411,584 bytes process RSS, below its unchanged 80 MiB ceiling; all 5,000 stored records fit the metadata budget.
The larger writer memory run, broader final-tree suite and actual browser WebCrypto integration remain pending.

`BundleManifest` and `BundleTables` now carry entity version vectors and project lineage. Export gathers scoped
components; inspection validates table/entity/counter identity; import merges component maxima while suppressing
local-write triggers, and conflict decisions/undo become new local edits without lowering observed clocks.
`MergePlanner` classifies equal, dominating and concurrent received clocks before applying content decisions.
Focused vector/planner regressions passed during implementation; the acceptance remains open until the final
production package round-trip and structural conflict suite pass together against the final tree.

Everything a project needs to leave one device whole and come back changed without losing a fact, with no server
anywhere in the path. A declared bundle layout with a versioned manifest, a lineage record naming the devices the
project has already passed through and a checksum per entry, produced by a writer that streams every entity table and
every file into it; a scope section offering full project, date range, context subtree, approved records only or data
without photos, with the estimated size stated before writing starts, a share action that hands the file to the system
and a registered extension and MIME type so an incoming bundle opens the import flow from mail, a file manager or
removable media; optional password protection whose key is derived from a salt in the archive header and stored
nowhere, and a redaction pass that keeps every key, credential, token and device secret out of the archive whether it
is sealed or not; a reader that verifies the manifest, the format version and every checksum, refuses anything
suspicious with a message naming the failed check, and — where the project is one this device has never seen —
recreates it whole with every identifier, record number and template version intact and its lineage recorded; version
vectors maintained on each local write and comparable as equal, dominating, dominated or concurrent, with tombstones
that travel between devices without ever resurrecting data silently; a merge engine that classifies each entity as
insert, fast-forward, ignore or concurrent, compares concurrent records field by field, settles what the four
automatic rules can settle and escalates the rest, unions photos by content hash, resolves templates by version,
merges reference rows by key and relabels colliding record numbers without moving an identifier; a preview screen
showing the plan's counts before a byte is written and a conflict screen that settles the remainder one at a time or
in bulk with the evidence beside either side; and an apply step that snapshots first, writes every row and file in one
transaction, records the merge with its counts and resolutions, keeps undo available until the snapshot is purged, and
scans across the merge boundary afterwards for the same asset captured twice.

Task [076](24-product-refinements.md#076--resolve-project-capture-and-template-feedback-and-add-project-packages) ships part of this phase ahead of it, and
this task builds on those parts rather than replacing them: the package format, writer and reader
(`core/bundle/`), import as a new project, the template compatibility check, a content-based merge with its preview
and one-at-a-time conflicts, and duplicate decisions taken before a merge is written. This task still owns the
bundle scopes, password protection, the secret-pattern scan over every entry, version vectors kept on every write,
tombstone vectors, snapshots and undo, merge history, the Type a value and Decide later conflict choices, and
registering the bundle extension so an incoming file opens the import flow.

### Files

Bundle core:

- `frontend/lib/core/bundle/bundle_format.dart` (new)
- `frontend/lib/core/bundle/bundle_writer.dart` (new)
- `frontend/lib/core/bundle/bundle_encryption.dart` (new)
- `frontend/lib/core/bundle/bundle_redaction.dart` (new)
- `frontend/lib/core/bundle/bundle_reader.dart` (new)

Merge domain:

- `frontend/lib/features/merge/domain/bundle_import_new.dart` (new)
- `frontend/lib/features/merge/domain/version_vectors.dart` (new)
- `frontend/lib/features/merge/domain/tombstone_merge.dart` (new)
- `frontend/lib/features/merge/domain/merge_entities.dart` (new)
- `frontend/lib/features/merge/domain/merge_fields.dart` (new)
- `frontend/lib/features/merge/domain/merge_rules.dart` (new)
- `frontend/lib/features/merge/domain/merge_photos.dart` (new)
- `frontend/lib/features/merge/domain/merge_templates.dart` (new)
- `frontend/lib/features/merge/domain/merge_reference.dart` (new)
- `frontend/lib/features/merge/domain/merge_numbering.dart` (new)
- `frontend/lib/features/merge/domain/merge_apply.dart` (new)
- `frontend/lib/features/merge/domain/merge_undo.dart` (new)
- `frontend/lib/features/merge/domain/post_merge_scan.dart` (new)

Merge presentation:

- `frontend/lib/features/merge/presentation/bundle_scope_section.dart` (new)
- `frontend/lib/features/merge/presentation/bundle_share_actions.dart` (new)
- `frontend/lib/features/merge/presentation/merge_preview_screen.dart` (new)
- `frontend/lib/features/merge/presentation/conflict_screen.dart` (new)
- `frontend/lib/features/merge/presentation/conflict_bulk_actions.dart` (new)
- `frontend/lib/features/merge/presentation/merge_history_screen.dart` (new)

### Contract

```dart
class BundleManifest {
  const BundleManifest({
    required this.formatVersion,
    required this.bundleId,
    required this.projectId,
    required this.sourceDeviceId,
    required this.createdAt,
    required this.versionVectors,
    required this.lineage,
    required this.entries,
  });
  factory BundleManifest.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}

class BundleEntry {
  const BundleEntry(this.path, this.bytes, this.sha256);
}

class BundleWriter {
  Stream<double> write({
    required File target,
    required BundleScope scope,
    required CancellationToken token,
  });
}

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

class BundleReader {
  /// Validates and returns the manifest, or a `BundleRejection` naming the failed check.
  Future<Result<BundleManifest, BundleRejection>> inspect(File bundle);
  Stream<BundleEntry> entries(File bundle);
}

enum BundleRejection { unreadable, unknownFormatVersion, checksumMismatch, unsafePath, missingEntry }

// `VectorRelation` and `compareVectors` belong to the merge tables of task 061 and are reused, not redeclared.
enum VectorRelation { equal, dominates, dominated, concurrent }

class VersionVector {
  const VersionVector(this.counters);
  final Map<String, int> counters; // deviceId -> counter
  VersionVector increment(String deviceId);
  VersionVector merge(VersionVector other);
  VectorRelation compareTo(VersionVector other);
}

enum TombstoneOutcome { applyDelete, ignoreDelete, conflictEditAfterDelete }

enum EntityDecision { insert, fastForward, ignore, concurrent }

class MergePlan {
  const MergePlan(this.inserts, this.updates, this.deletes, this.conflicts, this.autoResolutions);
  final List<FieldConflict> conflicts;
  final List<AutoResolution> autoResolutions; // each names the rule that decided it
}

enum SettlementRule { verifiedBeatsUnverified, scannedBeatsInferred, valueBeatsUntouchedEmpty, none }

class MergeRules {
  SettlementRule settle(FieldSide mine, FieldSide theirs);
}

class MergeNumbering {
  /// New numbers for incoming records whose number is already taken; keys are record UUIDs.
  Map<String, String> relabel(Iterable<IncomingRecord> incoming, Set<String> takenNumbers);
}

class MergeApply {
  /// Snapshots, applies [plan] in one transaction, writes the merge record, returns its id.
  Future<String> apply(MergePlan plan, {required CancellationToken token});
}

class MergeUndo {
  Future<bool> isAvailable(String mergeId);
  /// Restores rows and files to the snapshot taken before [mergeId].
  Future<void> undo(String mergeId);
}
```

### Steps

#### Writing a bundle

1. Declare the file list, the manifest schema, the format version and the lineage record — which devices the project
   has already passed through — in `bundle_format.dart`, so reader and writer share one definition. Then serialise
   every entity table plus the files they reference through `bundle_writer.dart`, streaming each entry over the
   archive package of task 113 and hashing it as it is written. Carry the entity version vectors held by the merge
   tables of task 061 into the manifest; a bundle without them cannot be merged.
2. Offer five scopes in `bundle_scope_section.dart`: full project, date range, context subtree, approved records only,
   and data without photos. Show the estimated bundle size for the chosen scope before writing starts. Share through
   the platform wrapper, and register the bundle extension and MIME type so opening one from mail, a file manager or
   removable media lands in the import screen with no content shown until the reader has validated it.
3. Derive the encryption key from the password with a salt stored in the archive header, keeping neither the password
   nor the derived key anywhere on the device. Decrypt to a temporary directory and verify the whole archive before a
   single file is placed, so a wrong password leaves no partial extraction. Filter secret-bearing columns and settings
   out of the write path in `bundle_redaction.dart`, and run the patterns of `frontend/tool/secret_patterns.yaml`
   (task 015) over every produced entry as the writer streams it.

#### Reading one

4. Reject path traversal, absolute paths, checksum mismatches and unknown format versions before any row is written,
   each with its own message, reusing the archive gate of task 071 rather than sniffing bytes again. Where the project
   is new to this device, recreate its folder tree through project creation (task 084), copy files in, insert rows in
   dependency order and preserve every UUID, record number and template version from the bundle. Record the bundle's
   lineage on the new project so a later merge knows where it came from.

#### The merge engine

5. Increment the local device's counter on every write to a mergeable entity; an empty vector compares as dominated by
   any non-empty one. Resolve a delete against an older edit as `applyDelete`; an edit whose vector post-dates the
   delete becomes `conflictEditAfterDelete` rather than a silent resurrection. Keep tombstones after they are applied,
   so a third device receiving the same delete twice reaches the same result.
6. Build the plan. Process in dependency order — project, templates, reference data, records, record fields, files —
   and classify each entity from its version vectors: absent locally is `insert`, dominated locally is `fastForward`,
   dominating locally is `ignore`, otherwise `concurrent`. For a concurrent record, compare field by field: a change
   on one side only applies, identical values are not a conflict, differing values go to the rules. Apply the four
   rules in order — verified beats unverified, a barcode or reference value beats an inferred one, a non-empty value
   beats a never-edited empty one, otherwise conflict — and record an `AutoResolution` naming the rule.
7. Handle the three entity types whose merge is not a field comparison. Photos: match on SHA-256 so identical content
   is stored once, merge captions per field, keep the importing device's order and append incoming photos after it.
   Templates: the same version on both sides is no action; different versions raise a conflict offering choose one or
   keep both, and records keep the version they were captured under either way, as template versioning (task 099)
   requires. Reference data: merge the rows of task 056 by their key, and a key present on both sides with differing
   attributes raises a conflict rather than overwriting.
8. Relabel colliding record numbers. Continue the project's own sequence through the record-number allocator of
   capture (task 107) rather than inventing a suffix, so relabelled records read like the rest. Keep the number the
   record arrived with in its history, so a field note referring to the old number is still traceable, and never
   renumber a record that already exists on this device; only the incoming side moves.

#### The operator's screens

9. Show the plan before anything is written: counts of new, updated, deleted, conflicting and duplicate entities in
   the order and wording the specification's preview uses, on the shared card of task 038, each expandable to the
   entities behind it. Name the source device and the bundle's creation time, so the operator knows what they are
   about to take in. Confirm hands the plan to the apply step; cancel discards it.
10. Settle what the rules could not. Show one conflict at a time with both values, their authors, their timestamps and
    the evidence viewer of review (task 111) available for either side, resolved as keep mine, take theirs, type a
    value or decide later. Offer "apply to all remaining conflicts on this field" and "prefer this device for the
    rest". Write each resolution — including every one implied by a bulk action — as its own audit entry naming the
    chooser. Leave a decide-later conflict unresolved on the record and block approval of that record until it is
    settled.

#### Applying and undoing

11. Snapshot rows and the files the plan will touch before opening the transaction, and roll back completely on any
    failure, including a failure while copying files. Store per merge: source device, bundle id, timestamp, counts per
    category and every resolution with its chooser or rule. State the undo deadline in the history entry, stop
    offering undo once the snapshot is purged, and restore deleted rows and removed files on undo, not only changed
    ones.
12. Run the post-merge duplicate scan. Compare only across the merge boundary — an incoming record against a local one
    — so pre-existing duplicates are not re-reported. Score pairs with the duplicate detector of data quality (task
    110) and attach the resulting pairs to the merge record so they survive a restart. Run the scan off the UI thread
    after the transaction commits, and never block the merge on it.

### Constraints

- Collaboration never touches the backend. A project travels as a file and merges on the device, whether or not a
  server exists or is reachable; nothing here is a sync channel.
- Entries stream in and out; no table, photo or archive is materialised whole in memory (FE-PERF-07).
- The format version is compared, never inferred: a reader must be able to refuse a newer bundle (FE-SEC-06).
- Everything arriving in a bundle is untrusted input, validated before use, and imported text is data, never
  instructions (FE-SEC-06, FE-SEC-05). Typing a conflict value is a normal field edit and passes the field's
  validation (FE-SEC-06).
- Share and file-open both go through the platform wrapper, not `dart:io` or a plug-in call in the widget
  (FE-STR-11).
- Encryption is real where it is claimed: no home-grown cipher, no key in shared preferences (FE-SEC-11, FE-SEC-01).
- No key, credential, token or device secret is written to a bundle even when the device holds one (FE-SEC-02), and
  the redaction check reads the shared pattern file rather than a second copy of it (FE-CONS-02).
- Import, apply and undo each run as one durable transaction; a rejected bundle leaves no row and no file, and a merge
  is never half-applied (FE-STATE-07). Nothing is written before confirmation, including no partial file copy.
- Preview counts come from the plan; the screen recomputes nothing (FE-STATE-04).
- The plan is a value: nothing in `domain/` opens a transaction or touches a table, and the merge, tombstone and
  template tables are reached through their repositories (FE-STR-05, FE-STATE-05).
- The version-vector tables of task 061 own `VectorRelation` and the comparison over it; this phase reuses both and
  redeclares neither (FE-CONS-01, FE-CONS-02).
- Every automatic settlement, every operator resolution and the merge record itself belong to the audit trail and are
  written inside the same transaction (FE-SEC-09). The post-merge scan proposes; nothing is merged or deleted without
  a person (FE-SEC-09).
- Photo bytes are never rewritten during a merge — deduplication changes rows, not files — and the recorded conflict
  values are kept verbatim so undo can replay them (FE-SEC-08).
- Identity is the UUID: relabelling touches no foreign key, photo filename or manifest entry, and keeping both
  templates rewrites no record's `templateVersion` (FE-STATE-06).
- One decision at a time; bulk conflict actions are an explicit second control, never the default (FE-SIMP-07).
- Reuse the duplicate detector of task 110 unchanged; a second similarity implementation is a defect (FE-CONS-02).

### Definition of done

#### Writing a bundle

- [x] The written layout matches the specification file for file, manifest field for field.
- [x] Every entry carries a checksum, and the manifest carries the version vectors and the lineage.
- [x] A bundle containing two thousand photos writes without memory exceeding its baseline budget.
- [x] Tests: schema test of a written manifest, a round-trip test writing then re-reading a seeded project, and a
      measured memory assertion for the two-thousand-photo case.
- [ ] A data-only bundle of a large project is small enough to send by email, and its size is stated before writing.
- [ ] Receiving a bundle by any transport lands in the same import screen.
- [x] Tests: widget tests of `bundle_scope_section.dart` covering each of the five scopes and the four states, and of
      `bundle_share_actions.dart` asserting share and incoming-file handling both route through the wrapper.
- [x] A wrong password fails cleanly, leaving no extracted file behind.
- [x] The redaction check runs over every produced bundle and fails the write when a secret-shaped string appears.
- [x] Tests: unit tests of `bundle_encryption.dart` over correct and wrong passwords asserting no partial extraction,
      and of `bundle_redaction.dart` with a fixture bundle seeded with a secret-shaped value.

#### Reading one

- [x] A corrupted, tampered or newer-format bundle is refused before any row is written, with a message naming the
      check that failed.
- [x] An imported project is fully editable and exportable, with identifiers, record numbers and template versions
      unchanged.
- [x] An imported project carries the bundle's lineage, so a later merge knows where it came from.
- [x] Tests: unit tests of `bundle_reader.dart` over tampered fixtures for each `BundleRejection` value, and an
      integration test importing a bundle written by this phase's own writer and comparing the result to the source
      project.

#### The merge engine

- [x] Every pair of vectors classifies as exactly one `VectorRelation`, including empty vectors on either side.
- [x] No merge ever brings back an entity that was deliberately deleted later.
- [x] An edit made after a delete surfaces as a conflict for a person to settle, and a third device receiving the same
      delete twice reaches the same result.
- [x] Tests: unit tests of `version_vectors.dart` over all four relations and empty vectors, and of
      `tombstone_merge.dart` over both orderings and a repeated delete, with no Flutter binding.
- [x] Planning the same bundle twice over an unchanged project produces an identical plan with nothing to apply.
- [x] Every automatic decision carries the rule that made it, and the fall-through produces a conflict rather than a
      guess.
- [x] One-sided field changes apply, identical values raise nothing, differing values escalate.
- [x] Tests: unit tests of `merge_entities.dart` over all four decisions and dependency ordering, `merge_fields.dart`
      over the three field cases, and `merge_rules.dart` per rule plus the fall-through, with no Flutter binding.
- [x] The same photo imported twice occupies one file, with both sides' captions preserved.
- [ ] Records keep the template version they were captured under, whichever template resolution is chosen.
- [ ] A reference key whose attributes differ appears as a conflict, never as a silent overwrite.
- [x] Tests: unit tests of `merge_photos.dart` asserting a single stored file and merged captions,
      `merge_templates.dart` over same version, choose one and keep both, and `merge_reference.dart` over new,
      identical and differing rows, with no Flutter binding.
- [x] After merging two projects that each allocated the same numbers, every record number in the project is unique.
- [x] No reference breaks, and each relabelled record still shows the number it arrived with.
- [x] Tests: unit tests of `merge_numbering.dart` over full collision, partial collision and no collision, asserting
      local records keep their numbers, with no Flutter binding.

#### The operator's screens

- [x] Every category of the plan is shown with its count and can be expanded to the entities it covers.
- [x] The source device and the bundle's creation time are named before the operator confirms.
- [x] Cancelling leaves the project and its files entirely unchanged.
- [x] Tests: widget test of `merge_preview_screen.dart` over a plan with every category populated, an empty plan and a
      load failure, plus an assertion that cancelling writes nothing.
- [x] All four choices resolve a conflict, and typing a value is validated like any other edit.
- [x] A record with an unresolved conflict cannot be approved.
- [x] A bulk action appears in the audit log as one entry per conflict it settled, not as a single line.
- [ ] Tests: widget tests of `conflict_screen.dart` over each of the four choices and the four states, and of
      `conflict_bulk_actions.dart` asserting per-conflict audit entries.

#### Applying and undoing

- [x] A failure part-way through leaves the project exactly as it was, files included.
- [ ] History lists every past merge with its source device, bundle id, timestamp, counts per category and
      resolutions, and states the undo deadline.
- [x] Undo restores rows and files exactly, including deleted ones, and disappears once its snapshot is purged.
- [x] Tests: unit tests of `merge_apply.dart` simulating a mid-merge failure and of `merge_undo.dart` comparing
      project state before the merge with state after undo, plus a widget test of `merge_history_screen.dart`
      covering the four states.
- [x] The scan runs automatically after every merge and lists candidate pairs with their scores for review.
- [x] Pairs survive a restart, and a merge whose scan finds nothing shows that plainly.
- [ ] The scan never blocks the merge, and compares only across the merge boundary.
- [x] Tests: unit tests of `post_merge_scan.dart` over a fixture where the same asset was captured on both devices,
      asserting cross-boundary-only comparison, with no Flutter binding.

### Out of scope

- Pushing or pulling changes through the relay; that optional server slice belongs to the minimal backend (task 119).
- Continuing an inventory from a spreadsheet or table someone else produced; that is data import (task 115).
- Using a cloud destination as a transport for bundles; uploads are a destination for files, never a merge channel
  (task 116).
- Resolving the pairs the post-merge scan proposes; the duplicate review screen belongs to data quality (task 110).
