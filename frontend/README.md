# tapture

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database code generation

Drift schema and companions are generated and committed (FE-CODE-13). After
changing `lib/core/db/app_database.dart` or a table it includes, regenerate in
the same change:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Template catalogue generation

The shipped templates under `assets/templates/` (one file per category, the
index `_catalogue.json` and the groups in `_catalogue_groups.json`) and the list
of every template in `../resources/template-library.md` are generated from
`../resources/templates.md` (specification §13.4–13.5). `_schema.json` and the
groups of §13.3 in `_groups.json` are kept by hand. The typed record-type packs
and per-field corrections live in `tool/template_catalogue/`. After changing any
of them, regenerate in the same change and check the result:

```sh
dart run tool/build_template_catalogue.dart
dart run tool/check_templates.dart
```

`dart run tool/build_template_catalogue.dart --check` exits 1 when a committed
file has drifted from its source.

## Project AI processing

Configure the authenticated backend using [the AI setup and accounting instructions](../backend/RUNBOOK.md).
Build with `--dart-define=BACKEND_URL=https://your-server` or enter the HTTPS address in Organisation settings,
then sign in and obtain a project grant. Capture, originals, Whisper transcripts, records and processing jobs stay
on the device. An unavailable backend leaves online analysis queued; capture remains available.

In AI settings, the organisation-managed account is the default. A personal Gemini or OpenAI account must be
selected explicitly. Saving its key sends it to the authenticated server for encryption; the client stores only
the selection and nonsecret model capabilities. Remove deletes the server credential and keeps that account selected
until a person chooses another. The configured request reservation is shown when available; an escalated model
requires an explicit maximum cost covering that reservation. These are conservative budget units, not an invoice.

Process previews the evidence and selected account before sending. Complete device transcripts replace their audio
uploads. Source IDs retain photo-to-caption and audio-to-photo relationships. Missing values, conflicting evidence
and uncertain grouping remain in review. AI proposals never approve a record. If a response was lost after dispatch,
resume uses the same identifier and the backend refuses another charge. An explicit new attempt warns that the prior
attempt may already have been charged. The client preserves raw replies beside originals for recovery.
Transcription and caption refinement use the same durable request protocol. A processing request freezes its
approved spending limit before media preparation; later settings edits cannot raise that request's approval.
Older replies without a verifiable input snapshot remain available as raw evidence and are excluded from automatic
proposal reuse.

Import a client Excel workbook and confirm its sheet, columns and predefined rows. Import Word or UTF-8 text
templates using `{{field_key}}` placeholders, then confirm the resulting schema. Approve the reusable records and
select the matching export format. Outputs use the record's captured template version: Excel fills mapped cells
while preserving other sheets, styles and formulas; Word fills placeholders across text runs, headers and footers;
text retains surrounding wording. Standard records reports accompany these filled source copies. Excel uses captured
predefined row identities; without predefined rows it starts below the confirmed header, replacing mapped sample
values in the copy. A source hash mismatch or a mapped formula cell refuses the output. The output summary lists
missing fields, unmatched rows and the need to sign any previously signed Office output again. Original templates
stay intact. Existing Office package parts are preserved; formula recalculation and identical pagination across
readers are not guaranteed.
