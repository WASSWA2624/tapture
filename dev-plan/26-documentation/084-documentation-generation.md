# 084 — Generate grounded document drafts through resumable jobs

**Phase** 26 · Documentation  |  **Depends on** [024](../24-backend/024-minimal-backend.md), [083](083-documentation-editor.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Make **Create documents** run the §80 pipeline: snapshot, prepare sources, draft against confirmed definitions,
validate and leave evidence-backed canonical drafts for local rendering/review. Persist the work on the device
before making any network call. The backend is a request-lifetime AI proxy; it does not own workspaces, documents,
file uploads, vector stores or background generation jobs.

Close the current production integration gaps explicitly. `AiService` has no document operation; its current proxy
request shape does not match the backend envelope; startup uses a keyless registry. A fake returning prose is not
an implementation of this feature. Wire authenticated production transport and a configured provider, with clear
capability and recovery states where unavailable. Reuse existing auth, quotas, cost controls, egress consent,
redaction and provider resilience rather than building parallel versions.

## Files

- `frontend/lib/features/documentation/domain/` and `data/` (run orchestration, grounding and validation)
- `frontend/lib/features/documentation/presentation/` (generation controller, egress preview and run status)
- `frontend/lib/core/ai/`, `frontend/lib/core/concurrency/`, `frontend/lib/main.dart`
- Existing processing primitives under `frontend/lib/features/processing/`, promoted to `core/` only when shared
- `backend/openapi.yaml`, `backend/src/routes/ai.ts`, `backend/src/services/ai/`, provider wiring/dependencies
- `frontend/test/features/documentation/`, `frontend/test/core/ai/`, record-processing regression suites
- `backend/test/routes/ai_proxy.test.ts`, provider/service and frontend/backend contract fixtures

## Contract

- Extend the AI abstraction with a typed document composition operation. Publish `POST /api/v1/ai/compose`
  (specification shorthand `/ai/compose`) in OpenAPI with a versioned request/response schema. Reuse the project's
  authentication and permission checks, model selection, request limits, quota and usage accounting.
- A composition request includes project/run/output/attempt IDs, schema version, bounded selected evidence blocks
  with source locators, confirmed output structure, normalized instructions and generation settings. Content and
  instructions are separate structured fields. It contains no local absolute paths or unselected project data.
- A response is validated canonical content: sections/tables/cells, claim/field source references, unresolved
  requirements, conflicts and coverage; include provider/model and usage metadata. AI returns structured data,
  never scripts, executable formulas, arbitrary file paths or trusted final binary documents.
- Persist run states **Queued**, **Running**, **Paused**, **Needs review**, **Partially complete**, **Failed** and
  **Cancelled**, with a typed pause/failure reason. Separate stage checkpoints describe preparing/reading/
  generating/validating/rendering, and each output keeps its own result. Task 085 owns rendering and document
  approval states. Required-input failures cannot be disguised as a successful complete run.

## Steps

1. Extract minimal reusable lease, bounded retry, cancellation and connectivity primitives from record processing.
   Keep existing `ProcessingJob`/`JobQueue` APIs backward compatible; Documentation runs are project/workspace jobs,
   never fake capture records. Add durable `documentation_jobs` owned by run/output with explicit stage/lease and
   attempt state; share runner primitives without invasively generalizing record queue tables. Persist checkpoints
   and immutable selections before scheduling.
2. Assemble the source context locally using task 082's chunks and locators. Apply explicit size/token budgets;
   when sources exceed one request, split by section/source and retain coverage across bounded summarization and
   synthesis. Retained summaries cite their original chunks. Show omitted/partial material; no silent truncation.
3. Present the selected provider/model, sources/excerpts or media to leave the device, purpose and available cost
   estimate under existing egress controls. Respect offline-by-choice, project AI disable, connection/metered
   rules, membership and cached-session expiry. Changed source selection requires refreshed preview/consent.
   Check the destination and every originating project's captured source restrictions; apply the strictest AI,
   no-image, connection and permission policy to each selected source. Destination approval cannot override a
   source project's no-AI/no-image rule. Show blocked sources with a repair/exclusion path and evaluate cached
   permissions explicitly; a snapshot's relocation is not new permission to send its bytes.
   Organisation project selections require actual accessible source membership. External archives instead use
   destination import/generation permission and disclosed sending consent, retaining known restrictive metadata;
   do not require an archive's origin project to be registered on the backend or infer privileges from its manifest.
4. Implement the real compose transport and provider adapter. Keep request bodies/transcripts/templates out of
   logs, databases, caches and error telemetry on the backend. Add capability negotiation for older servers; an
   absent compose route yields a recoverable unavailable state. Existing extraction/OCR/transcription/refinement
   calls continue to pass contract tests through the corrected transport.
5. Validate provider output against the definition and supplied source IDs/locations. Detect missing required
   content, invalid data types, unsupported citations, source contradictions and unsupported assertions. Never
   treat an AI confidence score as proof. Represent unknown values and gaps explicitly, with repair/edit paths.
   Allow at most one bounded schema-repair call per response; failed repair is a visible failure, not a blank success.
6. Add per-output progress, cancel and retry; successful outputs survive another output's failure. Restart makes
   interrupted jobs paused/retryable from durable checkpoints. Connectivity alone never dispatches Documentation
   AI: the user explicitly resumes queued offline work. Local run/attempt IDs prevent duplicate revision commits.
   An uncertain provider timeout is shown as potentially charged and requires explicit retry; do not promise
   exactly-once remote billing. Reject late responses from cancelled or superseded attempts.
7. Complete the production wiring used by the module, including proxy-assisted OCR/transcription where task 082
   declared it. Verify a configured staging provider end to end with non-sensitive fixtures and keep deterministic
   tests for offline CI; document missing configuration honestly instead of marking that acceptance complete.

## Constraints

- Source documents and format files are untrusted data (FE-SEC-05); embedded instructions cannot override system
  grounding, select more sources, request secrets, browse or upload. Explicit prompt text still cannot override
  product safety/grounding rules or confirmed output constraints.
- No persistent project-content schema, raw body logs, provider file store or remote asynchronous job is added.
  Metadata-only request receipts may track IDs/status/usage; they must not retain generated text or input payloads.
- A network outage never blocks capture, editing, review or local rendering of an existing draft.
- No AI output becomes approved automatically. A completed run produces a draft only.

## Definition of done

- [ ] Real authenticated app-to-backend-to-provider generation returns a structured evidence-linked draft, with
      provider/model/usage shown and no provider key on the device.
- [ ] Shared request/response fixtures pass frontend/backend contract tests, including old-server capability
      absence, malformed output and corrected transport for existing AI operations.
- [ ] Offline preparation and queueing survive restart; reconnection alone makes no provider call, and explicit
      resume respects auth expiry, budget, metered policy and prior consent. Cancellation and bounded retries
      preserve work, reject stale late results and expose an actionable status.
- [ ] Multi-output partial success and an ambiguous timeout never overwrite completed work or create duplicate
      committed versions; usage remains attributable per attempt/output/run.
- [ ] Grounding tests reject invented source IDs and unsupported required claims; contradictory inputs, missing
      values, context-limit truncation and partial extraction remain explicit findings.
- [ ] Adversarial fixture instructions in source/template content cannot trigger external actions, hidden-source
      selection or transmission of credentials/unselected content.
- [ ] Mixed-project/native/archive payloads preserve origin-scoped citations and strictest source/destination
      privacy; a destination that permits AI cannot send a source whose policy forbids it, including derived images.
- [ ] Backend retention/logging tests prove no request content, prompt, template or generated text remains after
      success, cancellation, timeout and error paths; quota/auth checks happen before provider calls.
- [ ] Existing record processing/capture tests pass after any promotion of shared queue or AI primitives.
