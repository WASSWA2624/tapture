# 013 — Processing: on-device first, online only when it earns its place

**Phase** 13 · Processing  |  **Depends on** [002](../02-foundation/002-foundation-services.md), [004](../04-data-layer/004-local-database.md), [007](../07-account-and-settings/007-account-and-settings.md), [009](../09-templates/009-templates.md), [010](../10-reference-data/010-reference-data.md), [012](../12-capture/012-capture.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole path from a captured record to proposed data, on the device first and online only when local work leaves a
required field unfilled. One job per record — stage, attempt count, outcome and failure reason — persists through a
repository behind a queue that leases a job to exactly one runner and hands it back after a crash, and a runner walks
the stages in order, resumes where it stopped, cancels cleanly, and classifies every failure so transient ones retry
with bounded backoff and permanent ones stop at once. Derived copies are prepared for extraction — resized,
orientation-corrected, deskewed, contrast-improved, document boundaries detected — and read on the device with the
radio off, their output cached by content hash and by a perceptual hash so a resized or recompressed copy of a photo
is never recognised or uploaded twice, and serials, asset tags and registrations are pulled from that text by the
patterns on the template's identity fields. Every provider implementation is registered and chosen per project and
per operation behind one interface, with the organisation's backend proxy a first-class keyless entry, a preview
before the first online call of a session stating exactly what will leave the device, and a screen where a lone
operator may hold a key on the device as the permitted exception and prove it with one test call. What does go online
goes as one request per record, capped and split deterministically, its response stored as it arrived, repaired once
if it will not parse, validated against the schema the template implies, and written to `record_fields` as proposals
carrying source, confidence and a band — never as approved data and never over a verified or manual value. Around
that sit the decisions: a template chosen from local signals before any model call and from the operator last; units,
choices, dates and numbers normalised into one stored value with the original phrasing intact; extracted text
resolved to a predefined row by five strategies in order; every applied value tied to the photo region, block or
transcript that produced it and stamped with how it was made; captions refined beside the raw text and never beyond
it; a gate that drops any value the evidence does not support; a rule that skips the online stage outright when local
extraction and a reference match already suffice; and a per-project daily cap with visible counters. The queue
screen, its process actions and its failures list make all of it visible and retryable, two unattended paths — on
connectivity gain and while charging — run it without a tap when they are switched on, and one local notification
reports each batch.

## Files

### Processing domain — `frontend/lib/features/processing/domain/`

- `processing_job.dart` (new)
- `job_queue.dart` (new)
- `job_runner.dart` (new)
- `job_retry.dart` (new)
- `image_preprocess.dart` (new)
- `identifier_extraction.dart` (new)
- `extraction_request.dart` (new)
- `request_batching.dart` (new)
- `response_parser.dart` (new)
- `response_repair.dart` (new)
- `proposal_application.dart` (new)
- `confidence.dart` (new)
- `template_detection.dart` (new)
- `template_detection_ai.dart` (new)
- `row_matching.dart` (new)
- `evidence_linking.dart` (new)
- `provenance.dart` (new)
- `caption_refinement.dart` (new)
- `no_invention_guard.dart` (new)
- `online_skip_rule.dart` (new)
- `cost_guard.dart` (new)
- `auto_process.dart` (new)
- `background_ocr.dart` (new)

### Processing data — `frontend/lib/features/processing/data/`

- `processing_repository_impl.dart` (new)
- `ocr_cache.dart` (new)
- `response_store.dart` (new)
- `notifications.dart` (new)

### Processing presentation — `frontend/lib/features/processing/presentation/`

- `egress_preview_dialog.dart` (new)
- `template_choice_sheet.dart` (new)
- `queue_screen.dart` (new)
- `process_actions.dart` (new)
- `failed_jobs_screen.dart` (new)

### Core services

- `frontend/lib/core/ai/ocr_service.dart` (new)
- `frontend/lib/core/ai/provider_registry.dart` (new)
- `frontend/lib/core/hash/perceptual_hash.dart` (new)
- `frontend/lib/core/normalise/units.dart` (new)
- `frontend/lib/core/normalise/choices.dart` (new)
- `frontend/lib/core/normalise/dates.dart` (new)

### Settings presentation

- `frontend/lib/features/settings/presentation/api_key_screen.dart` (new)
- `frontend/lib/features/settings/presentation/provider_test_action.dart` (new)

## Contract

```dart
enum JobStage { prepare, onDevice, detect, online, normalise, validate }

abstract interface class JobQueue {
  Future<String> enqueue(String recordId);
  Future<ProcessingJob?> claim(Duration lease);
  Future<void> complete(String jobId);
  Future<void> fail(String jobId, String reason, {required bool permanent});
}

class OcrBlock {
  const OcrBlock({required this.text, required this.bounds, required this.confidence});
  final String text;
  final Rect bounds;
  final double confidence;
}

abstract interface class OcrService {
  Future<OcrResult> recognise(String imagePath);
}
```

## Steps

### The queue and the runner

1. Build the job model, the queue and the repository implementation. Stages run in the Contract's order and the job
   records the last one completed. Claim inside one transaction (task 050) and stamp a lease, so two runners cannot
   take the same job; release an expired lease on the next claim, so a job killed mid-run becomes claimable again.
   Read the concurrency cap from the settings store rather than a literal.
2. Build the runner and the retry classifier. Persist stage completion before moving on, so a resumed job does not
   redo finished work. Honour a cancel token between stages: the record stays intact and the job stays resumable.
   Classify failures as transient — network, timeout, rate limit, provider 5xx — or permanent — authentication,
   unparseable response after repair, unsupported media, missing template. Retry transient failures with exponential
   backoff up to a capped attempt count and fail permanent ones on the first attempt. Write the failure reason onto
   the job so the queue screen can show it verbatim.

### Reading the image on the device

3. Build image preprocessing and the on-device recognition service: resize, correct orientation, deskew, improve
   contrast and detect document boundaries, then return text, blocks and bounding boxes. Write preprocessed output
   beside the compressed copy of task 068 as a new derived file; never rewrite an original. Run preprocessing and
   recognition through the isolate runner. Add the recognition package to the dependency allowlist (task 005) before
   using it.
4. Build the OCR cache and the perceptual hash. Key the cache on the content hash from task 024 and store text,
   blocks and bounding boxes against it. Compute a difference hash and expose a distance function with the threshold
   read from `AppConstants`. Treat a perceptual match inside the threshold as a cache hit, so a re-encoded photo
   reuses the stored result. Hash and look up off the UI thread through the isolate runner.
5. Build identifier extraction. Apply each identity field's pattern to the recognised text. Rank candidates by
   position on the plate, pattern specificity and OCR confidence, and return all of them, best first. Carry the
   originating block forward so the value can be linked to evidence later.

### Providers, keys and the egress preview

6. Build the provider registry and the egress preview. Resolve selection per project and per operation through the
   interface of task 029, so no caller learns which implementation answered. A registry entry carries where its key
   lives, never the key itself; the default entry — the organisation's backend proxy of Part XI — holds none,
   because custody belongs to the backend (A30.2, A73.1). The preview states image count, approximate payload size,
   and that captions and field names are included, and is raised through the dialog service of task 041. Declining
   leaves the session offline: the queue is untouched and every job stays claimable.
7. Build the device-held key screen and its test action, as the exception A30.2 permits and not the norm; it exists
   for the lone operator an administrator has allowed to work with the server out of reach. Store only in platform
   secure storage; never in the database, a log, an export or a bundle. State on the screen, in one line, that the
   key lives on this device only and that the usual arrangement is for the organisation's backend to hold it. Offer
   removal in one action that also clears the selection. Test connection sends the smallest possible request through
   the registry in `frontend/lib/core/ai/`, never imports an HTTP client itself, and reports success, authentication
   failure and network failure distinctly.

### The online call

8. Build the extraction request and its batching: one request per record, composed from the template field list,
   context, OCR text, captions and compressed images. Carry the explicit rules in the request — only
   evidence-supported values, null when unknown, valid JSON. Attach compressed copies, never originals. Group every
   photo of a record into one request, read the per-request image cap from `AppConstants`, and split larger sets by
   capture order so the same record always splits the same way.
9. Build the parser, the single repair attempt and the response store. Store the raw response and a request summary
   against the job (task 057) before parsing; never store the key. Validate against the schema derived from the
   template's field types (task 089); drop unknown keys; coerce types safely; reject anything malformed rather than
   guessing. On a parse failure, re-request once with the parse error described, then fail the job as permanent
   through the retry classifier.
10. Build proposal application and the confidence bands. Write `valueRaw` with source and confidence; skip any field
    already verified or entered by hand and record the skip. Band each score as high, medium or review-required
    against the project thresholds in the settings store; one banding function serves every screen that shows a
    band. Set the record status to NEEDS_REVIEW when any applied value lands in the review-required band or a
    required field is still empty.

### Choosing the template, normalising the value, matching the row

11. Build template detection: local scoring, the model assist and the operator's sheet. Score OCR keywords,
    identifier patterns and reference matches against the detection profile with no network, then implement the
    selection order from the specification, stopping as soon as a rule decides; a pinned template short-circuits the
    whole ladder. Call the model only when local scoring is inconclusive, and only for the shortlist local scoring
    produced. The sheet offers two or three large buttons plus the option to pin the choice to the current context
    level, so the question is asked once per room rather than once per item.
12. Build the three normalisers. Units: parse value plus unit, convert to the unit configured on the field, and keep
    the original text beside it. Choices: match on option label, code and alias from the options editor of task 095,
    and leave the descriptive sentence in its own field. Dates and numbers: parse common day-month-year forms with
    the project locale, and never coerce an identifier to a number.
13. Build row matching. Try exact, alias, normalised, fuzzy and then model classification in that order, returning as
    soon as one clears its confidence threshold. Return the matched row, the strategy name and the score, so review
    can show why the row was chosen. Return no match rather than a weak one when every strategy falls short.

### Provenance, refinement and the no-invention gate

14. Build evidence linking and the provenance stamp. Write at least one evidence row (task 057) per applied value:
    photo id with the bounding region when the provider supplies one, the OCR block when the value came from local
    extraction, the whole photo otherwise. Stamp source, method, provider, model and prompt version on the value, and
    write the application to the audit table (task 051) with the same stamp.
15. Build caption refinement. Refine only on explicit request or when the project setting is on, writing the cleaned
    caption into its own column beside the raw one. Reject a refinement that introduces an identifier, quantity or
    date absent from the raw text: the refiner may reword, not add.
16. Build the no-invention guard, between parsing and application. Drop values with an empty evidence list for fields
    marked evidence-required. Reject values contradicting an identifier pattern or an option list. Record each
    rejection and its reason on the job, so review can show why a field stayed empty.

### Skipping online work and capping what it costs

17. Build the skip rule and the cost guard. Skip the online stage when every required field is filled and confidently
    banded, and write the skip reason onto the job. Count requests and images as they are made and expose today's
    totals for the queue screen. Block further online work at the cap with a message naming the cap and when it
    resets; the job stays queued rather than failing.

### The screens and the unattended paths

18. Build the queue screen, the process actions and the failures list. Show unprocessed, queued and failed counts
    from queries; group by context; offer a process action per group. Process all and process selected report
    per-record progress through `AppProgressSteps` (task 042), allow cancel at any point, and end with a summary of
    succeeded and failed. Failures show the reason recorded by the retry classifier, rendered through `AppErrorState`
    (task 040), and retry in one tap.
19. Build the two unattended paths, each off by default. Trigger automatic processing on a connectivity gain (task
    025) when the setting is on, honouring the Wi-Fi-only restriction and the budget guard. Run opportunistic OCR
    only while charging and idle, and stop it immediately when the app resumes (task 019), so later online work is
    smaller.
20. Build processing notifications: one local notification when a batch finishes or fails, carrying the succeeded and
    failed counts and opening the review list when tapped. Local notifications only — no push, no remote service —
    and the plugin passes the dependency allowlist of task 005 first. Ask for the notification permission at first
    use and continue silently when it is refused.

## Constraints

- Nothing reaches a record that the evidence does not support. The no-invention guard sits between parsing and
  application, and an unsupported value is dropped with its reason recorded rather than written as a plausible guess.
- Enqueue, claim, complete and fail are each one transaction; a half-written claim is a defect (FE-STATE-07).
- Drift types stop at `data/`; the job model, the queue interface and `core/normalise/` are pure Dart, with no
  Flutter, Drift or HTTP import (FE-STR-05).
- Stage work goes through the isolate runner with progress and cancellation; none of it touches the UI thread
  (FE-PERF-02).
- Backoff is bounded: a provider outage must not produce a tight retry loop, and both unattended paths run only
  through `BackgroundPolicy`, so nothing runs while the app is in the foreground (FE-PERF-08).
- Raw photos are append-only: preprocessing produces new files and leaves originals byte-identical. Raw captions and
  transcripts are append-only too; refinement writes a separate column and never edits the original row (FE-SEC-08).
- HTTP imports stay inside `core/ai/`; the egress dialog asks the registry what would be sent and never builds a
  request itself; on-device recognition and opportunistic OCR make no outbound call of any kind and work with the
  radio off (FE-SEC-03, FE-SEC-04).
- OCR text, captions, field names and file names are data: they are matched against patterns and quoted into the
  request, never interpolated into an instruction (FE-SEC-05).
- Everything that arrives is validated for structure and type before use (FE-SEC-06).
- The provider key goes to secure storage and nowhere else, and the stored request summary contains no key and no
  secret (FE-SEC-01). Device custody stays framed as the permitted exception under backend key custody (FE-SEC-02).
- A notification carries counts and a route, never field values or project data (FE-SEC-07, FE-SEC-10).
- Nothing written by proposal application is approved data; the raw-data safety test of task 018 must stay green.
- Thresholds, the concurrency cap and the per-project daily cost cap come from the settings store, never from a
  literal (FE-CODE-09).
- Detection carries the on-device-first rule of this phase: a model call happens only after local scoring fails to
  decide, and model classification in row matching runs only after all four local strategies have failed. Local
  matching never calls out.
- One parser per concept; features call the normalisers and never reimplement them (FE-CONS-09).
- The key entry field is `AppTextField` from task 035, obscured after save, and the template choice sheet is
  `AppBottomSheet` from task 041; neither screen builds its own (FE-CONS-01, FE-SIMP-07).
- The egress preview is raised through the dialog service of task 041, not a bespoke `showDialog` (FE-CONS-05).
- Async state renders through `AsyncValueView` (task 040); every list carries all four states (FE-CONS-04).
- Counts come from queries and the list is virtualised; the queue is never materialised to draw the screen
  (FE-PERF-03).

## Definition of done

### The queue and the runner

- [ ] Killing the app mid-job leaves the job claimable again once the lease expires, not lost.
- [ ] Two concurrent claims never return the same job.
- [ ] Cancelling mid-run leaves the record intact and the job resumable from the next stage.
- [ ] A resumed job skips stages already marked complete.
- [ ] A provider outage backs off instead of burning battery; a permanent failure stops without a second attempt.
- [ ] Tests: unit tests over stage ordering and lease expiry.
- [ ] Tests: repository tests for `processing_repository_impl.dart` against an in-memory database, covering the
      round-trip mapper, plus the fake later tests use.
- [ ] Tests: unit tests over resume, cancellation and both failure classes, with no Flutter binding.

### Reading the image on the device

- [ ] Originals are byte-identical after preprocessing.
- [ ] A rating-plate photo yields readable text, blocks and bounding boxes offline.
- [ ] Reprocessing a record reuses stored OCR text and performs no recognition and no upload.
- [ ] A resized or recompressed copy of a photo matches; an unrelated photo does not.
- [ ] A record can be identified with no online call at all.
- [ ] Tests: unit tests hashing an original before and after preprocessing.
- [ ] Tests: recognition test against a fixture image with known text, with the network disabled.
- [ ] Tests: repository tests for `ocr_cache.dart` against an in-memory database, plus the fake later tests use.
- [ ] Tests: unit tests of the distance function over resized, recompressed and unrelated images.
- [ ] Tests: unit tests over realistic plate text covering one candidate, several competing candidates and none.

### Providers, keys and the egress preview

- [ ] Switching provider requires no change outside settings.
- [ ] A registry entry can declare that its key is held by the backend, and no caller behaves differently.
- [ ] A user can decline the preview and carry on working offline.
- [ ] A key is unreadable after saving and removable in one action.
- [ ] The screen never presents device custody as the recommended arrangement.
- [ ] Test connection tells authentication failure and network failure apart.
- [ ] Tests: unit tests over selection per project and per operation, including a keyless entry.
- [ ] Tests: widget test of `egress_preview_dialog.dart` covering its empty and failure states.
- [ ] Tests: test asserting the key never appears in the database or an export.
- [ ] Tests: widget test of `provider_test_action.dart`, including its empty and failure states.

### The online call

- [ ] A five-photo record produces exactly one extraction call.
- [ ] The request matches the specification example in shape.
- [ ] A malformed or hostile response never corrupts a record.
- [ ] A failed job leaves the raw response stored for inspection.
- [ ] A record can be reprocessed from stored output with no new call.
- [ ] A verified field survives reprocessing untouched.
- [ ] Thresholds are configurable per project and yield the same band everywhere they are read.
- [ ] Tests: golden test of a serialised request.
- [ ] Tests: unit tests of batching below, at and above the cap, with no Flutter binding.
- [ ] Tests: unit tests over valid, partial, hostile and unparseable responses, including the single repair attempt,
      with no Flutter binding.
- [ ] Tests: repository tests for `response_store.dart` against an in-memory database, plus the fake later tests use.
- [ ] Tests: unit tests that verified and manual values are preserved, that banding follows the configured
      thresholds, and that a review-required value forces NEEDS_REVIEW, with no Flutter binding.

### Choosing the template, normalising the value, matching the row

- [ ] A pinned template short-circuits detection entirely.
- [ ] No detection call is made when local scoring is confident.
- [ ] The question is asked once per room, not once per item.
- [ ] "Gauge damaged and requires repair" maps to Faulty while the sentence remains.
- [ ] Leading zeros in asset numbers are preserved, and the original phrasing survives in the raw value.
- [ ] "Sphygmomanometer" reaches "Blood Pressure Machine" without a model call.
- [ ] Every match records its strategy and score, and a weak match becomes no match.
- [ ] Tests: unit tests over the full decision table and the inconclusive path, with no Flutter binding.
- [ ] Tests: widget test of `template_choice_sheet.dart`, including its empty and failure states.
- [ ] Tests: unit tests over the specification examples for units, choices and dates, including ambiguous dates,
      zero-prefixed identifiers and text matching no option.
- [ ] Tests: unit tests for each matching strategy in order, plus the no-match path, with no Flutter binding.

### Provenance, refinement and the no-invention gate

- [ ] Every extracted value can be traced to a source in the review screen.
- [ ] Raw and refined captions are both retrievable and both exportable.
- [ ] A missing purchase year stays "Not detected" rather than becoming a guess.
- [ ] Tests: unit tests that each applied value writes at least one evidence row and a complete provenance stamp, and
      that a value with no locatable region still links to its photo, with no Flutter binding.
- [ ] Tests: unit tests asserting the raw caption row is unchanged and that a refinement introducing a new fact is
      rejected.
- [ ] Tests: unit tests over fabricated responses — unsupported value, pattern violation and off-list option — each
      asserting the rejection reason, with no Flutter binding.

### Skipping online work and capping what it costs

- [ ] A scanned known asset completes with no online call.
- [ ] A user can always see how many calls have been made today.
- [ ] Reaching the cap stops online work with a clear message and leaves the queue intact.
- [ ] Tests: unit tests proving zero calls on the fully matched path, and counter and cap behaviour below, at and
      above the limit, with no Flutter binding.

### The screens and the unattended paths

- [ ] A user can process one facility at a time.
- [ ] Interrupting a batch keeps everything already processed, and a failed job never damages the raw record.
- [ ] With both unattended settings off, nothing processes without a tap.
- [ ] Opportunistic OCR stops on resume, uses no network, and leaves battery use negligible.
- [ ] A refused notification permission never stops or delays processing.
- [ ] Tests: widget tests of grouping and counts in `queue_screen.dart`.
- [ ] Tests: widget tests of progress, cancellation and the end-of-run summary in `process_actions.dart`.
- [ ] Tests: widget test of `failed_jobs_screen.dart`, including its empty and failure states.
- [ ] Tests: unit tests over the connectivity trigger with the metered restriction and the cap, and over the
      charging-and-idle gate with a resume interrupt, with no Flutter binding.
- [ ] Tests: tests for `notifications.dart` against a fake notification platform asserting one notification per
      batch, its counts and its tap route, plus the fake later tests use.

## Out of scope

- The screen where a person accepts or rejects a proposal. This phase produces proposals, bands, evidence and
  rejection reasons; 111 · Review is where they become approved data.
- The backend AI proxy itself and the client that speaks to it. The registry carries a keyless entry for the proxy
  here; the proxy, and the key custody behind it, belong to 119 · The minimal backend.
- The standing egress report and the per-project AI switch. The preview before the first online call of a session is
  here; the summary screen and the switch are 117 · Privacy and security.
