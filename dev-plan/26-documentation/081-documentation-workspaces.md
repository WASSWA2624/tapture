# 081 — Persist Documentation workspaces and resources locally

**Phase** 26 · Documentation  |  **Depends on** [004](../04-data-layer/004-local-database.md), [080](080-documentation-capabilities.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Add the durable project-scoped Documentation domain and persistence in §82. A workspace holds a title, selected
resource roles, optional prompt, output definitions, generation runs and immutable document versions. It must
survive process death before generation exists. Reuse project identity, attachments/blob storage, audit fields,
version vectors, tombstones and storage checks; do not create a second filesystem or pretend the workspace is a
capture record.

## Files

- `frontend/lib/features/documentation/documentation.dart` and layered `domain/`, `data/`, `presentation/`
- `frontend/lib/core/db/tables/` (new Documentation tables), `app_database.dart`, `migrations.dart`
- `frontend/lib/core/files/` (project-folder, attachment ownership and derivative paths as required)
- `frontend/lib/core/db/tables/attachments.dart`, `attachment_owners.dart`
- `frontend/lib/features/projects/` through its public repository contract for lifecycle integration
- `frontend/test/features/documentation/`, `frontend/test/core/db/`, migration fixtures

## Contract

- `DocumentationRepository` exposes project-scoped watch/create/update, resource registration and role selection,
  output-definition persistence, atomic run snapshots/checkpoints and immutable version writes through typed
  `Result` values. Publish only the contracts needed by subsequent tasks through the feature barrel.
- Workspace/resource/selection/output definition/run/document version are distinct identities. Resource content
  has an immutable hash, original name, detected MIME, bytes, attachment reference and extraction status. A
  selection assigns input, output-format or prompt role without duplicating the physical bytes.
  Native/project-archive source snapshots include origin project/entity/record/template identities and revisions,
  original attribution, evidence hashes, approval state and captured source policy; origin scope disambiguates
  identical display record numbers from different projects.
- Extracted derivatives record source hash, extractor version, page/paragraph/sheet/cell/time locators and warnings.
  A run snapshots selected resource hashes/versions, confirmed output definitions, canonical prompt, schema/parser
  versions and later model/settings metadata. A mutable workspace never changes an already queued run.
- A document version records its parent, canonical content, source/run links, validation findings, review state,
  creator/approver and output-file hashes. Review state is separate from a job's execution state.

## Steps

1. Define the model and an append-only schema migration from the current version, with foreign keys, project
   indexes and existing merge/audit columns. Prefer normalized entity tables and versioned JSON for rich blocks or
   definitions; do not use one unversioned settings blob for every domain entity.
2. Store originals through the existing attachment writer under the project's documentation paths; extracted
   content, run snapshots and output artifacts are distinct derivatives. Stage bytes, validate hash/size, commit
   metadata only once durable, and recover interrupted staging on startup.
3. Implement deterministic IDs, timestamps and repository fakes using injected existing services. Duplicate bytes
   may reuse storage, while filename, logical role and provenance remain separate. Replacing a resource creates a
   new revision and makes future use explicit; historical runs keep their original reference.
   Materialize the full selected native/archive dependency closure in the destination workspace's attachment
   store, including values, captions, meeting structure, template interpretation and chosen evidence bytes. Do not
   use only live foreign keys into another project. Preserve origin links as attribution, not storage ownership.
   Native project selections stay lightweight while editing; freeze/materialize their selected revisions and
   evidence when creating a run, before dispatch. Opening a new workspace does not copy every project record.
   Reopening a saved workspace preserves its exact stored scope and does not silently add current-project defaults.
4. Implement project archive/delete/restore and workspace/resource removal through existing lifecycle semantics.
   Removing a selection does not delete raw evidence. Permanent purge requires existing explicit retention rules
   and cannot remove bytes referenced by a retained run/version or another attachment owner.
5. Persist editor state incrementally and atomically; wire local repositories/providers in the existing composition
   root. Browser state uses existing durable blob storage and exposes quota/storage failures.

## Constraints

- Every confirmed write is local and durable. Storage exhaustion cannot leave a success state with missing bytes.
- `core/` may not depend on Documentation; other features access only its barrel (FE-STR-04, FE-STR-08).
- Sources and approved document versions are immutable. Human edits create a revision and keep earlier versions.
- No network upload, AI request or server content persistence occurs in this task.

## Definition of done

- [ ] Migration preserves existing projects, capture records, attachments and exports, and opens the new schema on
      native and web database implementations.
- [ ] Repository round trips reconstruct workspace, selections, prompt, definitions, run snapshots and revisions
      after closing and reopening storage.
- [ ] One source can have multiple explicit roles and owners without accidental physical duplication or deletion.
- [ ] Interrupted import/version writes recover safely; quota failure, missing blob and hash mismatch are visible
      typed failures and never confirmed as successful saves.
- [ ] Changing/removing a selected source leaves past run and approved-version provenance intact.
- [ ] A run combining several native projects and an imported project archive retains all selected snapshots and
      source policy/identity after the originating projects are edited, archived or deleted; equal display IDs
      cannot collide or cause citations to point at the wrong project.
- [ ] Tests cover transactions, source revision invalidation, duplicate content, concurrent saves, project
      archive/delete/restore and referenced-file retention with injected clock/IDs/file services.
