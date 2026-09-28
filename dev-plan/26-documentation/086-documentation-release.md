# 086 — Carry Documentation in project packages and pass release acceptance

**Phase** 26 · Documentation  |  **Depends on** [019](../19-bundles-and-merge/019-bundles-and-merge.md), [025](../25-testing-and-release/025-testing-and-release.md), [085](085-documentation-review.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Complete the portability, lifecycle and release boundary in §§82–84. A full project package carries retained
Documentation resources, source/provenance snapshots, workspace configuration, output definitions, prompts and
document versions alongside the project's existing data. Import reconstructs the workspace locally with no server.
Bundle inspection, hashes, version compatibility, merge preview, conflicts and undo stay the existing mechanism.
Then pass the complete user workflows on Android, desktop and web against the capability matrix.

## Files

- `frontend/lib/core/bundle/` (format version, tables, manifest, safe reader/writer and redaction)
- `frontend/lib/features/merge/`, package import and project lifecycle public contracts
- `frontend/lib/features/documentation/` (portable snapshots, merge rules and history/source health)
- `frontend/test/core/bundle/`, `frontend/test/features/merge/`, package import and migration fixtures
- `frontend/integration_test/`, `backend/test/`, relevant release verification/run tooling
- `dev-plan/26-documentation/capabilities.md`, release/operator documentation and §84 traceability

## Contract

- Bump the bundle format/schema deliberately. Documentation table/artifact entries identify their schema versions,
  owners, hashes, sizes and referenced revisions in the existing manifest. Older app compatibility is explicit:
  refuse an unsupported bundle with a recoverable explanation rather than silently dropping documents.
- Completed runs and immutable document versions travel as history. In-flight leases, machine paths, cached auth,
  provider keys and active network attempts do not travel. Imported draft work is inert and can be resumed only
  as an explicit new local run after readiness and egress checks.
- Workspace/configuration edits use existing merge vectors and conflict review. Immutable resource/version hashes
  deduplicate safely; independent versions form branches, never an automatic winner. Approval applies to the exact
  approved revision and is not transferred to a merged or edited revision.

## Steps

1. Extend bundle table/file collection, manifest validation, scope/redaction preview and package reader/writer
   for Documentation. Reuse byte hashing and storage; verify all transitive source/template/prompt/version
   references. A partial/redacted package clearly reports missing provenance instead of claiming reproducibility.
2. Integrate explicit merge, conflict resolution and undo. Restoring a project restores workspaces and their retained
   originals. Audit parent/version/source links survive export/import. Deletion follows existing tombstone and
   retention rules; pending work cannot restart automatically after a bundle is imported.
3. Add end-to-end fixtures for the five common workflows: ToR/company profile/meeting files to DOCX+PDF report;
   XLSX headers with typed required columns; mixed media/archive evidence; several outputs and an optional prompt
   file plus rich instructions; offline preparation followed by online generation and offline review/export.
   First verify the default path: current-project approved capture data to a report with zero file uploads and no
   prompt, visible source counts and an editable saved scope. Include no-eligible-record and upload-only paths.
   Include a single run combining native projects A and B, uploaded project archive C and loose documents/media.
   Give projects A/B identical display record numbers and different privacy settings, then edit/delete an origin
   and prove retained snapshots, attribution, filtered selection and policy enforcement remain correct.
4. Exercise failure workflows: unsupported/corrupt/encrypted source, partial OCR or transcript, unsafe ZIP, missing
   required information, contradictory sources, inaccessible backend, old server, exhausted quota, expired session,
   timeout with uncertain billing, cancellation/restart, render failure, missing blob and full storage.
5. Verify device/platform capabilities and resource budgets with documented reference fixtures. Import/extraction
   and generation queues must keep capture responsive; large videos/archives/workbooks must stay within bounded
   memory/storage limits. Web quota/codec limitations are visible, never silent data loss.
6. Run accessibility and UI consistency checks at narrow/medium/expanded widths, 200 percent text, keyboard and
   screen reader, light/dark/outdoor themes. More opens the menu, Documentation resumes project context, and changes
   in width do not lose edits, progress or selection.
7. Run the app/backend gates and record exact capability results, limits and any intentionally deferred formats.
   No unchecked task or failed acceptance is hidden by the general release checklist. Update phase acceptance
   tracking only from evidence, and leave unrelated existing backlog tasks open.

## Constraints

- A project ZIP is the user-controlled backup; the backend gains no document persistence, automatic upload or
  backup responsibilities. Cloud sharing is an explicit use of existing export/upload services.
- The optional encrypted relay may carry the same versioned bundle content only under existing project permission
  and retention controls. Relay support must not make document generation depend on a server copy.
- Packaging unsupported files preserves their bytes and unsupported status; import does not mark them read.
- Source caches may be rebuilt, but originals, prompts, approved versions and provenance cannot be omitted from
  a package labelled complete.

## Definition of done

- [ ] A complete package round trip onto a clean offline device reconstructs inputs, roles, definitions, prompt,
      source links, canonical revisions, approved files and history with matching hashes.
- [ ] Multi-project/archive source snapshots and their full chosen evidence dependency closure survive bundle
      round trip without creating/merging live origin projects; origin-scoped IDs and source policy are preserved.
- [ ] Bundle tests cover mixed old/new versions, missing/corrupt resources, duplicate files, redacted/partial scope,
      concurrent workspace edits, independent document versions, merge preview/undo and deletion/restoration.
- [ ] No active job, secret, credential or local absolute path travels in a package; importing never calls AI.
- [ ] End-to-end report and spreadsheet scenarios in §84 pass with documented fidelity and valid independently read
      artifacts; multiple outputs preserve successful results when another fails.
- [ ] The default-project, zero-upload/no-prompt workflow passes; a saved workspace retains its exact selection,
      and source snapshots are materialized at run creation without copying all records on screen open.
- [ ] Captured projects remain optional: removing all project sources permits files-only and archive-only runs;
      saving/reopening preserves removal and readiness never demands a captured project.
- [ ] Offline/restart/limits/unsafe-input failures preserve local work and expose recovery; source coverage and
      unresolved requirements remain visible through review/export.
- [ ] Android, desktop and web capability results are recorded, including codec/storage/platform limitations and
      bounded performance fixtures; capture stays responsive during large-file work.
- [ ] Accessibility and responsive navigation acceptance pass, including More, no-project routing and draft-state
      preservation at all supported widths.
- [ ] Release checks include metadata-only backend logs/retention, key custody, role/quota enforcement and evidence
      that no server document store or durable provider payload was introduced.
- [ ] `dart run tool/check_plan.dart`, the frontend standard gate and `npm run verify` pass; the phase README and
      capability matrix identify all remaining unsupported/deferred behaviour accurately.
