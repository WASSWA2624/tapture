# 019 — Bundles and merge: a project leaves whole and rejoins safely

**Phase** 19 · Bundles and merge  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](../02-foundation/002-foundation-services.md), [004](../04-data-layer/004-local-database.md), [005](../05-file-storage/005-file-storage.md), [008](../08-projects/008-projects.md), [018](../18-export/018-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

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

## Files

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

## Contract

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

## Steps

### Writing a bundle

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

### Reading one

4. Reject path traversal, absolute paths, checksum mismatches and unknown format versions before any row is written,
   each with its own message, reusing the archive gate of task 071 rather than sniffing bytes again. Where the project
   is new to this device, recreate its folder tree through project creation (task 084), copy files in, insert rows in
   dependency order and preserve every UUID, record number and template version from the bundle. Record the bundle's
   lineage on the new project so a later merge knows where it came from.

### The merge engine

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

### The operator's screens

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

### Applying and undoing

11. Snapshot rows and the files the plan will touch before opening the transaction, and roll back completely on any
    failure, including a failure while copying files. Store per merge: source device, bundle id, timestamp, counts per
    category and every resolution with its chooser or rule. State the undo deadline in the history entry, stop
    offering undo once the snapshot is purged, and restore deleted rows and removed files on undo, not only changed
    ones.
12. Run the post-merge duplicate scan. Compare only across the merge boundary — an incoming record against a local one
    — so pre-existing duplicates are not re-reported. Score pairs with the duplicate detector of data quality (task
    110) and attach the resulting pairs to the merge record so they survive a restart. Run the scan off the UI thread
    after the transaction commits, and never block the merge on it.

## Constraints

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

## Definition of done

### Writing a bundle

- [ ] The written layout matches the specification file for file, manifest field for field.
- [ ] Every entry carries a checksum, and the manifest carries the version vectors and the lineage.
- [ ] A bundle containing two thousand photos writes without memory exceeding its baseline budget.
- [ ] Tests: schema test of a written manifest, a round-trip test writing then re-reading a seeded project, and a
      measured memory assertion for the two-thousand-photo case.
- [ ] A data-only bundle of a large project is small enough to send by email, and its size is stated before writing.
- [ ] Receiving a bundle by any transport lands in the same import screen.
- [ ] Tests: widget tests of `bundle_scope_section.dart` covering each of the five scopes and the four states, and of
      `bundle_share_actions.dart` asserting share and incoming-file handling both route through the wrapper.
- [ ] A wrong password fails cleanly, leaving no extracted file behind.
- [ ] The redaction check runs over every produced bundle and fails the write when a secret-shaped string appears.
- [ ] Tests: unit tests of `bundle_encryption.dart` over correct and wrong passwords asserting no partial extraction,
      and of `bundle_redaction.dart` with a fixture bundle seeded with a secret-shaped value.

### Reading one

- [ ] A corrupted, tampered or newer-format bundle is refused before any row is written, with a message naming the
      check that failed.
- [ ] An imported project is fully editable and exportable, with identifiers, record numbers and template versions
      unchanged.
- [ ] An imported project carries the bundle's lineage, so a later merge knows where it came from.
- [ ] Tests: unit tests of `bundle_reader.dart` over tampered fixtures for each `BundleRejection` value, and an
      integration test importing a bundle written by this phase's own writer and comparing the result to the source
      project.

### The merge engine

- [ ] Every pair of vectors classifies as exactly one `VectorRelation`, including empty vectors on either side.
- [ ] No merge ever brings back an entity that was deliberately deleted later.
- [ ] An edit made after a delete surfaces as a conflict for a person to settle, and a third device receiving the same
      delete twice reaches the same result.
- [ ] Tests: unit tests of `version_vectors.dart` over all four relations and empty vectors, and of
      `tombstone_merge.dart` over both orderings and a repeated delete, with no Flutter binding.
- [ ] Planning the same bundle twice over an unchanged project produces an identical plan with nothing to apply.
- [ ] Every automatic decision carries the rule that made it, and the fall-through produces a conflict rather than a
      guess.
- [ ] One-sided field changes apply, identical values raise nothing, differing values escalate.
- [ ] Tests: unit tests of `merge_entities.dart` over all four decisions and dependency ordering, `merge_fields.dart`
      over the three field cases, and `merge_rules.dart` per rule plus the fall-through, with no Flutter binding.
- [ ] The same photo imported twice occupies one file, with both sides' captions preserved.
- [ ] Records keep the template version they were captured under, whichever template resolution is chosen.
- [ ] A reference key whose attributes differ appears as a conflict, never as a silent overwrite.
- [ ] Tests: unit tests of `merge_photos.dart` asserting a single stored file and merged captions,
      `merge_templates.dart` over same version, choose one and keep both, and `merge_reference.dart` over new,
      identical and differing rows, with no Flutter binding.
- [ ] After merging two projects that each allocated the same numbers, every record number in the project is unique.
- [ ] No reference breaks, and each relabelled record still shows the number it arrived with.
- [ ] Tests: unit tests of `merge_numbering.dart` over full collision, partial collision and no collision, asserting
      local records keep their numbers, with no Flutter binding.

### The operator's screens

- [ ] Every category of the plan is shown with its count and can be expanded to the entities it covers.
- [ ] The source device and the bundle's creation time are named before the operator confirms.
- [ ] Cancelling leaves the project and its files entirely unchanged.
- [ ] Tests: widget test of `merge_preview_screen.dart` over a plan with every category populated, an empty plan and a
      load failure, plus an assertion that cancelling writes nothing.
- [ ] All four choices resolve a conflict, and typing a value is validated like any other edit.
- [ ] A record with an unresolved conflict cannot be approved.
- [ ] A bulk action appears in the audit log as one entry per conflict it settled, not as a single line.
- [ ] Tests: widget tests of `conflict_screen.dart` over each of the four choices and the four states, and of
      `conflict_bulk_actions.dart` asserting per-conflict audit entries.

### Applying and undoing

- [ ] A failure part-way through leaves the project exactly as it was, files included.
- [ ] History lists every past merge with its source device, bundle id, timestamp, counts per category and
      resolutions, and states the undo deadline.
- [ ] Undo restores rows and files exactly, including deleted ones, and disappears once its snapshot is purged.
- [ ] Tests: unit tests of `merge_apply.dart` simulating a mid-merge failure and of `merge_undo.dart` comparing
      project state before the merge with state after undo, plus a widget test of `merge_history_screen.dart`
      covering the four states.
- [ ] The scan runs automatically after every merge and lists candidate pairs with their scores for review.
- [ ] Pairs survive a restart, and a merge whose scan finds nothing shows that plainly.
- [ ] The scan never blocks the merge, and compares only across the merge boundary.
- [ ] Tests: unit tests of `post_merge_scan.dart` over a fixture where the same asset was captured on both devices,
      asserting cross-boundary-only comparison, with no Flutter binding.

## Out of scope

- Pushing or pulling changes through the relay; that optional server slice belongs to the minimal backend (task 119).
- Continuing an inventory from a spreadsheet or table someone else produced; that is data import (task 115).
- Using a cloud destination as a transport for bundles; uploads are a destination for files, never a merge channel
  (task 116).
- Resolving the pairs the post-merge scan proposes; the duplicate review screen belongs to data quality (task 110).
