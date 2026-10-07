# Tapture — Product & Technical Specification

**Document status:** Revision 4 — consolidated specification, preserving sections 1–84. Requirements describe the
target product; [dev-tracker.md](dev-tracker.md) records implementation progress. The
[development plan](dev-tracker.md) defines implementation order, ending with hardening.

**Architecture:** Local-first with a required organisation-operated minimal backend for identity, permissions, AI access
and provider keys (Part XI). Project content remains authoritative on the device. Explicit AI requests may carry
selected content; the optional relay holds transient ciphertext. Backend unavailability never blocks field work.

## Table of Contents

| Part | Sections |
| --- | --- |
| [I — Product Definition](#part-i--product-definition) | 1–6: purpose, scope, principles, terminology and workflows |
| [II — Data & Storage](#part-ii--data--storage) | 7–10: outbound policy, files, database and identity |
| [III — Templates & Reference Data](#part-iii--templates--reference-data) | 11–18: fields, catalogue, detection, lookups, verification and versions |
| [IV — Capture](#part-iv--capture) | 19–28: context, photos, captions, voice, identifiers, deferred capture and meetings |
| [V — AI Processing](#part-v--ai-processing) | 29–36: pipeline, providers, on-device speech, validation, provenance, evidence and cost |
| [VI — Review & Data Quality](#part-vi--review--data-quality) | 37–43: editing, validation, duplicates, conflicts, lifecycle and audit |
| [VII — Collaboration](#part-vii--collaboration) | 44–48: bundles, import, merge and conflict resolution |
| [VIII — Output & Distribution](#part-viii--output--distribution) | 49–54: formats, Excel, photos, PDF, versions and cloud upload |
| [IX — Application Shell](#part-ix--application-shell) | 55–60: navigation, settings, usability, performance and security |
| [X — Engineering](#part-x--engineering) | 61–69: architecture, packages, tests, delivery, acceptance and coverage |
| [XI — The Minimal Backend](#part-xi--the-minimal-backend) | 70–75: boundaries, accounts, relay, AI proxy, API and retention |
| [XII — Documentation](#part-xii--documentation) | 76–84: sources, formats, prompts, generation, review, storage, screens and acceptance |
| [Appendix A](#appendix-a--worked-example) | End-to-end field example |
| [Appendix B](#appendix-b--core-product-principle) | Core product principle |

---

# Part I — Product Definition

## 1. Overview

**Tapture** is a Flutter app for structured capture of physical things — equipment, buildings, vehicles, stock,
land, plants, animals, people — and documents, meetings and events. Photographs, voice and typed input provide
evidence. Its project-scoped **Documentation** module turns existing resources and selected project evidence
into reviewed deliverables following user-defined output requirements (Part XII).

1. Capture photos, documents, audio and notes offline.
2. Extract information with OCR, vision AI and real-time on-device speech-to-text (§30.4) that needs no network.
3. Map it to user-defined spreadsheet or in-app templates.
4. Require human review and approval.
5. Export verified data as XLSX, CSV, JSON, PDF or a portable ZIP bundle.
6. Draft documents from selected inputs, output formats and optional instructions; review before final DOCX,
   PDF, XLSX, CSV or Markdown export (§78, §81).

All content stays on the device. Users enable online AI and explicitly trigger cloud uploads; permitted traffic
is defined in §7.

## 2. Scope

### 2.1 In scope

- Offline capture, storage, editing, search and export across concurrent projects with one or more templates.
- Persistent context (district, facility, department), automatic date/time/sequence/operator stamps, deferred AI
  processing and prefill from imported reference data.
- Peer collaboration through project bundles, merge and conflict resolution.
- Meeting capture, attendance photos and refined minutes.
- Project-scoped Documentation: captured-project inputs selected by default but optional; uploaded documents,
  media and project archives as additional or alternative sources; reusable output definitions; optional prompt
  file and/or rich text instructions; AI drafts, review and local rendering (Part XII).
- User-initiated cloud upload of exports.
- A required minimal organisation backend for accounts, authentication, identity, roles, AI functionality and
  provider-key custody (Part XI), without blocking offline capture, review, editing, validation or export (§70.4).
- An optional change relay on that server, per project and off by default (§72).

### 2.2 Out of scope

- **Server backup or durable readable project content.** Records, values, documents, media, prompts and generated
  files stay on device; backup is the user's ZIP export (§54). AI payloads exist on the proxy only for the request
  (§73); relay holds transient ciphertext (§70.2, §72.4, §72.6).
- Unrequested project uploads; relay requires explicit per-project configuration (§72.5).
- A backend connection required for field work. After first sign-in, capture, review, editing and export continue
  for weeks without it (§70.4).
- Multi-tenant hosting: each organisation runs its own backend instance.
- Model training on user data.

### 2.3 Where each responsibility lives

The backend is **required**, with five responsibilities: **users, authentication, roles, AI functionality and
provider keys**. Project content, merge, exports and backup remain device responsibilities (§70.3).

| Concern | Device (store of record) | Minimal backend (required) |
| --- | --- | --- |
| Authentication | Cached session for field work; optional PIN/biometric lock | Sign-in/out, password change/reset, tokens/refresh and device enrolment (§71.1) |
| User identity | Stamp records, edits and approvals with issued account ID | One organisation-wide identity per person (§71.2) |
| Roles & permissions | Mirror grants as affordances; use cached grant offline | Grant roles and enforce server-mediated permissions (§71.3) |
| AI functionality | Select content/timing; local OCR/STT; offline queue (§29, §30) | Proxy provider calls, enforce project quotas/budgets, account usage (§73, §36) |
| AI provider keys | None by default; administrator-permitted exception (§30.2) | Sole custody, entry, rotation/revocation; no endpoint returns keys (§73.1) |
| Project content | Records, values, photos, documents, audio, templates, reference data, exports | No durable readable content; transient AI requests and optional encrypted relay (§70.2) |
| Documentation | Resource import/extraction, prompts/definitions, scheduling, local rendering/approval (§76–§84) | Bounded AI proxy only; no workspace, parsing service or durable content (§73) |
| Merge & conflicts | Preview, merge, resolve and undo (Part VII) | Transport only; no arbitration (§72.1) |
| Multi-device work | Manual bundle export/transfer/import/merge, always available | Optional per-project relay of the same packages (§72) |
| Backup | Manual ZIP; optional upload to user's cloud (§54) | None (§70.3) |

## 3. Design Principles

1. **Local first.** Device-owned data; weeks of offline use; backend governs people, permissions and keys (§70.2).
2. **Extremely simple.** One obvious action per screen; a record takes a handful of taps (§56).
3. **Evidence first.** Trace every value to a photo, document, transcript or person.
4. **Never invent.** Unknown is `null`, not a guess (§34).
5. **Preserve originals.** Retain raw photos, captions and transcripts beside refined output (§32); explicit deletion follows retention rules (§38, §60.1).
6. **Human approval.** AI proposes; a person approves.
7. **Minimise typing.** Use context, automatic fields, lookups, barcodes and voice.
8. **Never block capture.** Network, AI or missing templates cannot prevent recording evidence.
9. **Template-driven.** Templates, not built-in object-specific behaviour, let the app inventory anything.
10. **Portable.** A whole project can leave the device and be reconstructed elsewhere.

## 4. Glossary

| Term | Meaning |
| --- | --- |
| **Project** | A data-collection exercise owning templates, records, files, reference data and exports |
| **Template** | Record shape: fields, types, validation, identity keys and output columns |
| **Field** | Named, typed template slot: `field_key`, label, type and rules |
| **Record** | Captured item: values and evidence |
| **Capture session** | Photos, captions, voice and typed input analysed together to create one record |
| **Context** | Pinned values applied to subsequent records until changed (§20) |
| **Reference dataset** | Imported prefill/lookup table: suppliers, manufacturers, assets, staff or locations (§16) |
| **Predefined row** | An expected item in a checklist (§15) |
| **Raw value** | Unmodified typed, spoken, scanned or read input |
| **Refined value** | Separately stored AI-cleaned or normalised raw value |
| **Bundle** | Complete project ZIP portable between devices (§45) |
| **Operator** | Device user identified by the backend-issued account (§71.2) |
| **Organisation** | Data owner running one backend instance |
| **Account** | Organisation-wide identity, credentials, roles and enrolled devices (§71) |
| **Device ID** | Stable random first-launch identifier used for merge |
| **Documentation workspace** | Project-owned source selections, output definitions, instructions and versions; no capture template required |
| **Input resource** | Factual evidence: file, immutable captured-project selection, or selected uploaded project-archive content |
| **Output resource** | Supplied format, example layout or requirements; not factual evidence by default |
| **Output definition** | Confirmed deliverable sections, columns, required content, file types and supported layout; distinct from a record template (§78, §11) |
| **Generation run** | Immutable input/definition/instruction snapshot, linked jobs and proposed document versions |

## 5. Primary Workflows

### 5.1 Immediate capture (network available)

```text
Open project
      |
Set / confirm context   (Kampala > Kasubi HC IV > Theatre)
      |
Capture photos + caption (typed or spoken)
      |
CAPTURE & ANALYSE
      |
AI: OCR -> vision -> template detection -> field extraction -> normalisation
      |
Review & edit
      |
Approve -> record saved
      |
(repeat) -> Export
```

### 5.2 Deferred capture (no network, or speed matters)

```text
Open project
      |
Set / confirm context
      |
Capture photos + caption -> SAVE RAW
      |
(repeat many times - nothing is analysed)
      |
Later, when convenient: Process queue -> Process all
      |
Review the processed records in a list
      |
Approve -> Export
```

### 5.3 Verification of an existing record

```text
Scan barcode / type asset or serial number
      |
Match found in reference data or existing records
      |
Record prefilled
      |
Confirm, edit, or photograph the differences
      |
Approve -> variance recorded (as-recorded vs as-found)
```

### 5.4 Collaboration

```text
Device A: Export bundle  ->  transfer (cable, SD card, share sheet, cloud)
                                       |
Device B: Import bundle -> merge preview -> resolve conflicts -> merged project
```

### 5.5 Documentation

```text
Open project > Documentation > New document
      |
Keep or remove the default current-project source; optionally add other projects
      |
Choose files, media or project archives as additional or alternative inputs
      |
Choose output(s); optionally attach formats or requirements
      |
Optionally type rich text instructions and/or attach a prompt file
      |
CREATE DOCUMENTS -> check readable sources, requirements and AI sending summary
      |
AI drafts from evidence -> render locally -> review sources, gaps and layout
      |
Approve -> export/share final files (or save and resume at any point)
```

## 6. Representative Use Cases

| Use case | Notes |
| -------------------------------------------- | -------------------------------------------------------------------------- |
| Medical equipment inventory across districts | Context: District › Facility › Department. Templates: Equipment, Building. |
| Building / facility condition assessment | Photo-heavy, condition scales, risk notes. |
| Verification audit of a known asset register | Reference dataset imported; verification mode; variance report. |
| Stock-taking and warehouse counting | Barcode-first capture, quantity fields, rapid mode. |
| Infrastructure and utility surveys | GPS enabled, map-ready export. |
| Document digitisation | PDF/scan input, OCR, field extraction. |
| Compliance and safety inspection | Predefined checklist rows, compliance and risk fields. |
| Meeting records | Meeting mode: minutes, attendance, actions (§28). |
| Reporting against terms of reference | TOR, field notes and photographs supply evidence; a reporting format defines sections and requirements (§76–§84). |
| Company profile or proposal | Existing profiles, service descriptions and approved project evidence supply content; a requested structure guides the draft. |
| Reports and registers from meeting material | Minutes, audio and attendance documents produce a narrative report and an action workbook from the same inputs. |
| Consolidated reporting across captured projects | Selected data from several projects and uploaded project archives produces a combined report/register with original project attribution (§77.4). |
| Biodiversity / agricultural surveys | Free-form templates: species, counts, condition, location. |
| Household or beneficiary registration | Person templates, consent flag, privacy controls (§60). |
| Dataset creation for downstream analytics | Stable field keys, data dictionary export, JSON/CSV output (§49). |

---

# Part II — Data & Storage

## 7. Local-Only Data Policy

Project databases, photos, documents, audio and exports live on device. Send content only on user action or
explicitly enabled record automation (§26.2); Documentation always requires Create documents or explicit resume
(§80.4). Only §7.1 operations and §7.3 backend traffic are permitted.

### 7.1 The only permitted outbound traffic

All these operations are optional; local work remains usable without them.

| Operation | Data sent | Trigger |
| --- | --- | --- |
| Cloud vision/extraction | Selected compressed images, captions and template fields | Analyse or processing queue |
| Cloud OCR, when local OCR is insufficient | Selected images | Analyse or processing queue |
| Cloud STT re-transcription of a saved recording, when no on-device transcript exists and the user opted into online processing | Saved audio clip | Processing queue or explicit re-transcription (§30.1) |
| Caption/minutes refinement | Raw text | Refine or enabled automatic refinement |
| Documentation AI | Selected text/chunks, permitted media derivatives, output requirements and effective prompt (§80.2) | Create documents or explicitly resume run; preparation/review/rendering remain offline |
| Manual cloud upload | Selected export | Upload (§54) |
| App/model versions and pricing metadata | No personal data | Manual update check |

Live speech never leaves the device: dictation, the caption recorder, meeting recording and Transcribe run
whisper.cpp on the device (§30.4), and a platform recogniser is used only where it provably stays on device (§24).
Speech models ship inside the app or are imported from a local file; the app never downloads a model.

### 7.2 Guarantees

- No project data in telemetry, analytics or crash reports.
- One **Offline mode** switch blocks every outbound call; capture, editing and export continue.
- Projects can disable AI entirely for manual entry, or set **Do not send images** to force local OCR.
- Before a session's first online call, show resource types, counts and approximate size. Documentation also shows
  each run's scope, exclusions and estimated cost before its first send (§80.2).

### 7.3 Backend traffic

Part XI adds only the traffic below. Authentication/directory calls carry no project content; authorised AI content
lasts only for the request, and enabled relay projects send ciphertext.

| Operation | Data sent | Trigger | Optional? |
| --- | --- | --- | --- |
| Sign-in/token refresh | Credentials, organisation/device IDs | First device launch; token expiry | No |
| Directory/role refresh | Organisation users, memberships and grants | Sign-in and periodically | No |
| AI proxy | Selected extraction/Documentation payload (§31, §80) | Analyse, explicit queue run/resume or enabled record automation; Documentation requires Create/resume | Yes; projects can disable AI |
| Relay push | Encrypted records/values/files changed since last acknowledged version | Explicit action or project schedule (§72.5) | Yes; per project, off by default |
| Relay pull | Acknowledgements and other devices' encrypted packages | Same | Yes |

Backend guarantees:

- Authentication/directory traffic contains identifiers and grants, never records, values, captions, photos or audio.
- AI retains no payload beyond the request and logs metadata only (§73.4).
- Client-encrypted relay packages are unreadable to the server (§72.6) and purged on acknowledgement or retention
  expiry (§72.4); no durable project copy remains.
- Offline mode also blocks proxy, relay and direct providers; capture/review/export use the cached session (§70.4).
- **Never relay** keeps a project device-local even where others relay.

## 8. On-Device Folder Layout

Use one app-visible root, accessible by file manager or USB:

```text
<Documents>/Tapture/
├── app.db                          # the local database (all projects)
├── app.db-wal / app.db-shm
│
├── projects/
│   └── 2026-medical-equipment-inventory__p7k2/
│       ├── photos/
│       │   ├── Kampala/
│       │   │   └── Kasubi-HC-IV/
│       │   │       ├── Theatre/
│       │   │       │   ├── AUTOCLAVE_SN458923_FRONT_01.jpg
│       │   │       │   ├── AUTOCLAVE_SN458923_RATING-PLATE_02.jpg
│       │   │       │   └── AUTOCLAVE_SN458923_FAULT_03.jpg
│       │   │       └── Laboratory/
│       │   └── _unfiled/                     # captured before a context was set
│       ├── documents/
│       ├── documentation/                    # original resources, extraction snapshots and run manifests (§82)
│       ├── audio/                            # voice notes, meeting recordings and live-transcription audio
│       ├── meetings/
│       ├── reference/                        # imported lookup tables
│       ├── templates/                        # original template workbooks, unmodified
│       ├── exports/
│       │   ├── 2026-09-08_v1/
│       │   └── 2026-09-15_v2/
│       └── imports/                          # bundles received from other devices
│
├── shipped_templates/                        # read-only library included with the app
└── .cache/                                   # compressed upload copies, thumbnails, PDF page renders
```

### 8.1 Rules

1. Never overwrite original photos; rotation/crop/compression creates `.cache/` derivatives. Photo removal is logical (§38); purge only under existing deletion/retention rules (§60.1, §82.2).
2. Photo paths mirror capture-time context (§20); sanitise names to length-capped letters, digits and hyphens.
3. No-context photos enter `_unfiled/`; applying context later moves them and updates database paths.
4. `.cache/` is disposable without data loss.
5. Project folder strategies: **By context** (default), **By template**, **By capture date**, **Flat**.
6. Store project-relative file paths so root moves and bundle restores preserve references.
7. Check storage before each capture session: warn below 500 MB; below 100 MB block new capture and offer export/cleanup.
8. Speech models are **derived application files** under the app-support directory (`StorageRoot.private`), never
   under `Tapture/`, in bundles or in exports. They are the one class of file removed outside the purge job, and
   only through `discardDerivedFile` (stale extracted copies, removal of an imported model; §30.4.2).

## 9. Database Overview

One SQLite/Drift database holds all projects. Binary files stay on disk; their database entries store paths and hashes.

### 9.1 Entities

```text
device_profile        one row: device_id, operator name, preferences
projects
templates             a template belongs to a project (or is a copy of a shipped template)
template_fields
template_rows         predefined checklist rows
context_definitions   the context hierarchy of a project (levels)
context_states        the currently pinned context values per project
records
record_fields         one row per field per record (raw + refined + provenance)
record_variances      as-recorded vs as-found differences (verification mode)
photos
documents
audio_clips
transcripts           one live or file transcription: owner, audio, language, model, status, coveredMs, skippedRanges, edit
transcript_segments   raw segments, written once in insertion order, read in time order; edits sit beside them (§30.4.6)
captions              record-level and photo-level, raw + refined
reference_datasets    imported lookup tables
reference_rows
meetings              meeting header (extends a record)
meeting_attendees
meeting_actions
processing_jobs       the deferred AI queue
processing_results    raw provider responses, kept for audit
documentation_workspaces  document preparation and saved instructions (§82)
documentation_resources   immutable file versions and extraction provenance
documentation_selections  workspace role assignments and selected project evidence
documentation_source_snapshots  selected captured-project/archive content with origin and policy (§77.4)
documentation_outputs     versioned output definitions and associated format resources
documentation_runs        immutable generation selection snapshots
documentation_jobs        run/output-owned durable stages; share the queue runner primitives (§80)
documentation_versions    draft/approved content, evidence links and rendered artifacts
field_evidence        links a value to the photo/document/transcript that produced it
duplicates            detected duplicate pairs and their resolution
merge_sessions        bundle imports
merge_conflicts       unresolved and resolved conflicts
exports               export history
audit_log             every change
tombstones            deletions, for merge
```

### 9.2 Core table shapes

```text
Project
  id                uuid
  name
  description
  organisation
  status            DRAFT | ACTIVE | PAUSED | COMPLETED | ARCHIVED
  start_date, end_date
  folder_name
  default_template_id
  settings_json     ai enabled, gps, folder strategy, refinement, thresholds
  created_at, updated_at, updated_by_device, rev

Template
  id                uuid
  project_id        (null for shipped library entries)
  name
  kind              GENERIC | EQUIPMENT | MEDICAL | ICT | VEHICLE | FURNITURE
                    | BUILDING | ROOM | UTILITY | STOCK | INSPECTION | WORK_ORDER
                    | METER | PERSON | STAFF | HOUSEHOLD | LAND | PLANT | LIVESTOCK
                    | DOCUMENT | MEETING | EVENT | INCIDENT | CUSTOM
  source            SHIPPED | XLSX_IMPORT | BUILT_IN_APP | DERIVED
  source_file_path  original imported template, preserved unmodified
  sheet_name
  header_row
  identity_fields   json list of field_keys used for duplicate detection
  detection_json    automatic-detection profile (§14)
  version
  created_at, updated_at, updated_by_device, rev

TemplateField
  id                uuid
  template_id
  field_key         stable machine key, e.g. serial_number
  label
  type              §12.1
  output_column     spreadsheet column letter or generated header
  required          REQUIRED | OPTIONAL | RECOMMENDED
  input_mode        ANY | MANUAL_ONLY | AI_ALLOWED | AUTO
  stickable         bool
  context_level     null, or 1..n when the field is a context level
  auto_fill         null | NOW | TODAY | TIME | SEQUENCE | OPERATOR | DEVICE | GPS | CONTEXT
  default_value
  options_json      choice list
  unit
  validation_json   pattern, min, max, length, custom message
  lookup_json       reference dataset binding (§16)
  refine            bool — store an AI-refined companion value
  sort_order

Record
  id                uuid
  project_id
  template_id
  template_row_id   null unless matched to a predefined row
  record_number     per-project sequence, displayed to the user
  status            §42
  processing_mode   IMMEDIATE | DEFERRED
  context_json      snapshot of the context in force at capture
  identity_hash     hash of identity field values, for duplicate detection
  source            CAPTURED | IMPORTED_TABLE | IMPORTED_BUNDLE
  captured_at, captured_by_operator, captured_on_device
  latitude, longitude, gps_accuracy       nullable
  approved_at, approved_by
  created_at, updated_at, updated_by_device, rev

RecordField
  id                uuid
  record_id
  field_key
  value_raw         exactly as captured/extracted
  value_refined     AI-cleaned/normalised counterpart, nullable
  value_final       the value the user approved (defaults to refined, else raw)
  confidence        0..1, nullable
  source            MANUAL | OCR | AI_VISION | AI_TEXT | STT | BARCODE | LOOKUP | CONTEXT | AUTO | IMPORT
  verified          bool
  verified_by, verified_at
  updated_at, updated_by_device, rev

Photo
  id                uuid
  record_id         nullable — photos may exist before a record is finalised
  capture_session_id
  original_filename
  stored_filename
  relative_path
  photo_type        FRONT | BACK | SERIAL | RATING_PLATE | DAMAGE | PANEL | LOCATION |
                    ATTENDANCE | DOCUMENT | OTHER
  caption_raw, caption_refined
  sort_order
  width, height, file_size, mime_type
  sha256            content hash — the merge identity of a photo
  captured_at
  latitude, longitude                      nullable
  created_at, updated_at, updated_by_device, rev
```

Documents, audio, meeting/reference rows, jobs and exports likewise use UUID, `updated_at`, `updated_by_device` and `rev`.

## 10. Identity, Versioning & Change Tracking

Merge runs on devices; the backend only transports unreadable packages (§72.1). The data model therefore requires:

1. **UUIDv7 per row**, generated on device: time-ordered, cross-device identity.
2. **Device ID**, random at first launch, stored in the device profile and never reused.
3. **Per-row `rev`**, incremented on each local change, plus UTC `updated_at` and `updated_by_device`.
4. **Per-field revisions** on `record_fields`, allowing independent field edits to merge without conflict.
5. **Per-record version vector** `{device_id: max_rev_seen}` to distinguish newer from concurrent changes (§47).
6. **SHA-256 identity** for photos, documents and audio; duplicate files are stored once.
7. **Tombstones** (`entity_type`, `entity_id`, `deleted_at`, `device`) to propagate deletions rather than resurrect them.
8. **UTC storage**, localised display and the device timezone offset on each capture.
9. **Display-only per-project `record_number`** sequences, re-labelled on merge collisions; never identity.

---

# Part III — Templates & Reference Data

## 11. Template System

Templates define record shapes; projects may hold several. Documentation output definitions describe deliverables
(§78): an output XLSX never creates capture fields or changes records. Both workflows share parsing/mapping
components but keep separate identities and versions.

### 11.1 Four ways to obtain a template

| Route | Description |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Use a shipped template** | Pick from the library included with the app (§13). Usable immediately, no configuration. |
| **Derive from a shipped template** | Copy a shipped template, then add, remove, rename or reorder fields. The original library entry is read-only and unaffected. |
| **Import a spreadsheet** | Upload an existing`.xlsx` / `.csv`. The app reads sheets, header row, columns, existing rows and formatting, and proposes a field mapping. |
| **Build from scratch** | Add fields one at a time in the in-app template builder. No spreadsheet needed; output columns are generated from the labels. |

Duplicate any template, export JSON/XLSX, or import it into another project/device.

### 11.2 Spreadsheet import

```text
Select workbook
      |
Detect sheets -> user picks the sheet (or "all sheets" -> one template each)
      |
Detect header row (first non-empty row of labels; user can correct it)
      |
Read columns, merged cells, data types, existing rows, formatting
      |
Suggest field_key, type and rules per column  (AI-assisted, editable)
      |
User confirms the mapping
      |
Template + field definitions stored; original workbook copied to templates/ unmodified
```

Suggested mapping is shown as a simple two-column list:

```text
Spreadsheet column        Field
-------------------------------------------
A  Asset ID           ->  asset_id          (Text, identity)
B  Equipment Name     ->  equipment_name    (Text, required)
C  Manufacturer/Brand ->  manufacturer      (Lookup: Suppliers)
D  Model              ->  model             (Text)
E  Serial Number      ->  serial_number     (Text, identity)
F  Location           ->  location          (Context level 3)
G  Condition          ->  condition         (Choice)
H  Purchase Year      ->  purchase_year     (Number)
I  Description        ->  description       (Long text, refine)
J  Photo              ->  photo             (Photo reference)
```

### 11.3 The internal schema is authoritative

Stable field keys identify fields; spreadsheet letters are only output attributes:

```text
Wrong:   if (column == "B") ...
Right:   field_key == "equipment_name"  ->  output_column "B"
```

Keys preserve records through template edits, CSV/JSON/PDF export and cross-device column-order differences.

## 12. Field Definitions

### 12.1 Field types

| Type | Notes |
| ---------------------- | --------------------------------------------------------------------- |
| Text | Single line |
| Long text | Multi-line; refinement typically enabled |
| Number / Decimal | Optional unit, min, max |
| Currency | Currency code per project |
| Percentage |  |
| Date / Time / DateTime | Auto-fill supported (§21) |
| Boolean | Rendered as a switch |
| Choice | Single-select from an option list |
| Multi-choice | Multi-select |
| Lookup | Bound to a reference dataset; matching prefills other fields (§16) |
| Barcode | Populated by the scanner, typeable as fallback |
| Photo reference | Names/paths of the record's photos |
| Document reference | Attached files |
| GPS location | Latitude, longitude, accuracy |
| Signature | Drawn on screen, stored as an image |
| Computed | Read-only expression over other fields (for example`qty * unit_cost`) |

### 12.2 Field attributes

```text
required        REQUIRED | OPTIONAL | RECOMMENDED
                set by whoever edits the template, never fixed by the app; shipped
                templates carry a suggested value only (§13.2)
required_when   optional expression over other fields, making a field required
                conditionally (for example fault_present == true)
hidden          kept out of capture and export; existing values are preserved (§18)
input_mode      ANY         - typing, AI, lookup or context may fill it
                MANUAL_ONLY - AI may never write it (for example financial value)
                AI_ALLOWED  - AI may propose, human confirms
                AUTO        - filled by the system, read-only unless unlocked
stickable       may be pinned as context (§20)
context_level   1..n when this field is a level of the project context hierarchy
auto_fill       NOW | TODAY | TIME | SEQUENCE | OPERATOR | DEVICE | GPS | CONTEXT
refine          store an AI-refined companion value beside the raw one (§32)
identity        participates in duplicate detection (§40)
options         choice list, optionally with codes for export
validation      pattern, length, range, custom message
unit            displayed and exported (for example L, kg, V)
help            one short line of guidance shown under the field
```

### 12.3 Field editor

The builder is a drag-reorder list. New fields ask only **Label**, **Type**, **Required?**; all other attributes
live under **Advanced**. **Required columns** bulk-edits the whole template using REQUIRED/RECOMMENDED/OPTIONAL
radio columns and a **Hide** toggle per field (§13.2).

## 13. Shipped Template Library

Shipped assets are immutable originals. Global **Templates** shows them beside saved **My templates** without
requiring a project. **Customize a copy** creates a durable editable library template; blank templates may also be
created in that library. Attaching either kind to a project makes an independent versioned copy with fresh template,
field and row IDs. Editors follow the saved template's owner, never the currently selected project. Delete offers
Undo for saved copies; restoration preserves earlier field/row tombstones and leaves shipped bytes unchanged.

### 13.1 Columns are atomic

Every shipped column holds **one fact**, enabling filtering, sums, charts, validation, matching and joins. Atomic
values can be concatenated for reports; merged prose cannot be reliably split.

```text
Wrong                                   Right
--------------------------------------  -------------------------------------------------------
Make / Model                            manufacturer_name  ·  model_name
Serial (S/N 4471, 2019)                 serial_number  ·  year_of_manufacture
Address                                 country · region_state · district · subcounty_division ·
                                        parish_ward · village_street · plot_house_number
Dimensions 1200x600x750                 length_mm · width_mm · height_mm
Cost                                    cost_amount · cost_currency
Condition                               condition_grade  ·  condition_note_raw
Rating 240V 50Hz 2.2kW                  voltage_v · frequency_hz · power_rating_w
Contact                                 phone_primary · phone_secondary · email_address
Name                                    name_prefix · given_name · middle_name · family_name
Service date                            last_service_date  ·  next_service_due_date
Toilets 4 (2M 2F)                       toilet_stance_count_male · toilet_stance_count_female
```

Column conventions:

```text
snake_case keys              stable, never renamed once shipped (§11.3)
unit in the key              length_mm, weight_kg, area_sqm, power_rating_w, income_amount + income_currency
one date per date column     acquisition_date, warranty_end_date, next_service_due_date
booleans read as questions   is_*, has_*, *_present, *_required, *_confirmed
codes beside names           supplier_id + supplier_name, district_code + district_name
grade beside prose           condition_grade (Choice) beside condition_note_raw (Long text)
raw beside refined           *_raw and *_refined for anything an AI may rewrite (§32)
counts are numbers           door_count, participants_female — never "several", never a sentence
```

### 13.2 Requiredness belongs to the user

Shipped requiredness is **suggested**. Template editors may change every field individually or in bulk (§12.3).

- `REQUIRED`: only identity/meaningful-record essentials by default. Blocks approval, never incomplete capture;
  missing values mark the record incomplete (§39.2, §42).
- `RECOMMENDED`: dismissible review prompt, requiring a reason. Other fields ship `OPTIONAL` or `RECOMMENDED`.
- **Hidden** fields leave capture/export but retain existing values (§18).
- Requiredness edits create versions; earlier records retain their original rules, never retrospective incompleteness (§18).
- `required_when` supports conditions, e.g. require `fault_description_raw` only when `fault_present` is true.

In the listings below:

```text
*   shipped as REQUIRED        +   shipped as RECOMMENDED        unmarked   shipped as OPTIONAL
```

### 13.3 Groups every template inherits

Every shipped template inherits these four groups, populated automatically (§21) or from evidence. Users may hide
any group; listings omit their repetition.

```text
record_admin            (input_mode AUTO)
  record_uid*  record_number*  template_key*  template_version*
  captured_date*  captured_time*  captured_by_user_id*  captured_by_name
  device_id*  created_at*  updated_at  updated_by_user_id  record_status*  sync_state

location_context        (context levels, §20)
  country  region_state  district  subcounty_division  parish_ward  village_street
  site_code+  site_name+  building_code  floor_code  room_code  room_name
  gps_latitude  gps_longitude  gps_accuracy_m  gps_captured_at  location_note

evidence                (§22, §23, §24, §32)
  photo_count  primary_photo_filename  photo_filenames  document_filenames  audio_filenames
  caption_raw  caption_refined  voice_transcript_raw  voice_transcript_refined  operator_note

review                  (§33, §37, §42)
  confidence_overall  fields_needing_review  source_conflict_present
  reviewed_by_user_id  reviewed_date  approved_by_user_id  approved_date  rejection_reason
```

### 13.4 The library

`resources/templates.md` catalogues 2,349 templates in 72 categories and 17 areas:
01 Cross-sector foundations, 02 Business and governance, 03 Collaboration and delivery, 04 Health and life sciences, 05 Education research and care, 06 Buildings land and infrastructure, 07 Agriculture and natural resources, 08 Production and industry, 09 Energy utilities and environment, 10 Transport and supply chains, 11 Digital systems and communications, 12 Finance public administration and law, 13 Risk resilience and sustainability, 14 Social impact culture and information, 15 Commerce hospitality and recreation, 16 Professional specialist and personal services, 17 Specialist and emerging domains.

Templates compose shared groups so column meanings remain consistent:

```text
record_admin  location_context  evidence  review      the four groups of §13.3
context_<category>                                    the category's shared context, stickable (§20)
pack_<record type>                                    the fields every template of its record type shares
own starter fields                                    what makes this template different
```

Each template uses one of 26 record-type packs defining identity fields (§40), choices, suggested requiredness
and guidance for capture, permitted AI, outputs and review:

| Pack | Record type | Kind | Templates | Identity |
| --- | --- | --- | ---: | --- |
| ASSESS | Assessment / analysis | `assessment` | 214 | `assessment_reference` |
| REQUEST | Request / approval workflow | `request` | 214 | `request_reference` |
| CHECK | Checklist / verification | `checklist` | 184 | `check_reference` |
| REG | Register / master data | `register` | 184 | `entry_identifier` |
| INSPECT | Inspection / field form | `inspection` | 174 | `inspection_reference` |
| PLAN | Plan / schedule | `plan` | 141 | `plan_reference` |
| DOC | Generated document | `document` | 125 | `document_reference` · `approved_version` |
| TRANS | Transaction / repeated line items | `transaction` | 124 | `transaction_reference` |
| LOG | Activity / event log | `log` | 122 | `activity_date` · `activity_type` · `start_time` |
| MEASURE | Measurement / calculation | `measurement` | 115 | `measurement_type` · `measurement_date` · `measurement_time` |
| ASSET | Register / master data | `asset` | 101 | `item_identifier` · `serial_number` |
| CASE | Case-management workflow | `case` | 87 | `case_reference` |
| REPORT | Generated report | `report` | 73 | `report_reference` |
| SURVEY | Survey / questionnaire | `survey` | 63 | `survey_version` · `respondent_or_sample_code` |
| OBS | Observation / evidence capture | `observation` | 61 | `observation_subject` · `observed_at` |
| INCIDENT | Incident workflow | `incident` | 57 | `incident_reference` |
| MEET | Meeting / collaboration | `meeting` | 48 | `meeting_title` · `meeting_date` |
| PROFILE | Profile / intake | `profile` | 48 | `profile_reference` · `display_name` |
| AGREEMENT | Agreement / approval | `agreement` | 40 | `agreement_reference` |
| TRACK | Tracker / follow-up | `tracker` | 35 | `tracker_reference` · `tracked_item` |
| MAINT | Maintenance workflow | `maintenance` | 33 | `work_order_reference` |
| VISIT | Visit / field workflow | `visit` | 31 | `visited_site_or_party` · `visit_date` |
| SAMPLE | Sample / chain-of-custody | `sample` | 25 | `sample_identifier` |
| LEARN | Learning / competency record | `learning` | 20 | `learning_record_reference` |
| PROPOSAL | Proposal-generation workflow | `proposal` | 16 | `proposal_reference` |
| COMM | Communication draft | `communication` | 14 | `communication_reference` |

Resolved templates have 62–72 atomic columns (§13.1). Starter fields and category context ship RECOMMENDED; only
identity and meaningful-record essentials are REQUIRED (§13.2).

Browse by area/category; rows show code, record type and column count. Search name, code, category, area, record
type and own field labels; filter area, record type or tier (foundation/expansion/specialist). Preview shows category,
type, suggested privacy/tier, guidance and all grouped columns with types/requiredness. Adding creates an editable
project copy at version 1.

Without a chosen template, start with **UNI-001 General observation** for immediate capture and later refinement.

### 13.5 Template definitions

`resources/template-library.md` lists template code/key/type/privacy/tier/own fields, pack fields with
types/units/requiredness, and category context. **UNI-001 General observation** (`uni_general_observation`) resolves to:

```text
record_admin      the fourteen admin columns of §13.3                          (AUTO)
location_context  country … site_code+ site_name+ … gps_latitude gps_longitude …
evidence          photo_count  primary_photo_filename … caption_raw  caption_refined …
review            confidence_overall … approved_by_user_id  approved_date  rejection_reason
context           organization_ref+  project_ref+  subject_ref+                 (stickable)
observation       observation_subject*  observed_at*  factual_description*  media_refs+
                  capture_context  observer_name  verification_status  verification_notes
specific_details  observation_category+  observed_details+

identity keys     observation_subject + observed_at
```

`frontend/tool/build_template_catalogue.dart` generates `resources/template-library.md` and
`frontend/assets/templates/` (one file/category, `_catalogue.json`, pack/context `_catalogue_groups.json`) from
`resources/templates.md`; typed packs/per-field corrections live in `frontend/tool/template_catalogue/`. Maintain
`_schema.json` and §13.3 `_groups.json` by hand. The checker enforces atomic columns; tests reject asset/source drift.

### 13.6 What a user does with these

```text
Use as-is                shipped defaults, capture immediately
Trim                     hide the two-thirds of columns this project does not need
Re-require               move columns between REQUIRED / RECOMMENDED / OPTIONAL (§13.2)
Extend                   add columns; they behave exactly like shipped ones
Derive                   copy a template, rename it, edit it — the original is untouched (§11.1)
Replace                  import a spreadsheet instead, and map its columns to fields (§11.2)
```

Trimming a building inspection to twelve required columns or an equipment register to eight is expected; the
library supplies reusable choices, not an obligation to fill everything.

## 14. Multi-Template Projects & Automatic Template Detection

Select each capture's template in this order:

### 14.1 Selection order

```text
1. Template pinned for this session (context bar)      -> use it, no detection
2. Only one template in the project                    -> use it
3. Barcode / identifier matches a reference dataset    -> use that dataset's template
4. Automatic detection (below)                         -> use it if confidence is high
5. Otherwise                                           -> ask the operator
```

### 14.2 Detection profile

Each template carries a `detection_json` profile:

```json
{
  "object_classes": ["autoclave", "microscope", "centrifuge", "medical device"],
  "keywords": ["serial", "model", "voltage", "rating plate"],
  "identifier_patterns": ["^AST-\\d{5}$", "^SN[0-9A-Z]{6,}$"],
  "reference_datasets": ["known_assets"],
  "negative_keywords": ["floor plan", "roof", "wall"],
  "weight": 1.0
}
```

Early, low-cost detection uses local OCR, scanned identifiers and low-cost vision classification (§29).

### 14.3 When detection is uncertain

Ask when the top score is below 0.75 (configurable) or the top two differ by at most 0.1:

```text
What is this?

[ Equipment ]   [ Building ]   [ Something else ]

[x] Use this template for the rest of this location
```

The checkbox pins the choice to the current context level, avoiding repeat questions per item.

### 14.4 Structuring per template

The chosen template governs fields, validation, identity, output sheet and export columns. Mixed projects export
one XLSX sheet or CSV/JSON file per template.

## 15. Predefined Rows (Checklists)

Templates may list expected register, equipment or room rows:

```text
TemplateRow: id, template_id, output_row_number, identifier, label, aliases[], metadata, status
```

- The capture screen can show these as a checklist with progress: `Found 12 / 40`.
- On capture, the app matches the item to a predefined row (exact → alias → semantic → AI classification, §35) and populates that row.
- Rows never found can be exported as **Not found**, which is often the point of the exercise.
- The operator may add rows where the template permits it.

## 16. Reference Datasets & Prefill Lookups

Reference datasets supply reusable known values.

### 16.1 What a reference dataset is

An imported table (CSV, XLSX or JSON) with one key column and any number of attribute columns.

```text
Suppliers
  supplier_id | supplier_name | contact | phone | email | address | country

Manufacturers
  manufacturer_code | manufacturer_name | country | warranty_months | service_agent

Known Assets
  asset_number | serial_number | name | category | manufacturer | model |
  purchase_date | cost | department | custodian

Facilities
  facility_code | facility_name | district | level | ownership

Staff
  staff_id | name | title | department | phone
```

Datasets may be project-owned or shared, edited in-app, extended during capture and exported.

### 16.2 Lookup fields

A field of type **Lookup** is bound to a dataset:

```json
{
  "dataset": "suppliers",
  "match_on": ["supplier_id", "supplier_name"],
  "fuzzy": true,
  "fills": {
    "supplier_name":    "supplier_name",
    "supplier_contact": "contact",
    "supplier_phone":   "phone",
    "supplier_country": "country"
  },
  "on_no_match": "ALLOW_FREE_TEXT_AND_OFFER_ADD"
}
```

Behaviour:

1. The operator types, scans or speaks a value — or the AI extracts one.
2. The app matches on exact key, then case-insensitive name, then fuzzy name.
3. Fill matched fields with `source = LOOKUP` and a link icon. Editing breaks only that field's link and marks it `MANUAL`.
4. On multiple matches, a short picker appears.
5. On no match, the value is kept as free text with an **Add to Suppliers** action.

### 16.3 Prefilled templates

Dataset-driven template defaults prefill groups:

```text
Template: Medical Equipment
  supplier      -> Lookup(Suppliers)      fills contact, phone, country
  manufacturer  -> Lookup(Manufacturers)  fills country, warranty, service agent
  facility      -> Lookup(Facilities)     fills district, level, ownership
```

Combined with context (§20), a typical equipment record needs only: photo, name, model, serial, condition.

## 17. Verification Mode (Known Records)

Confirm known data. Verification searches reference data first (§17.2); normal identifier capture searches
existing records first (§25).

### 17.1 Setup

Import a register as reference data or records (§46.3); set the project/session to **Verification**.

### 17.2 Flow

```text
Scan barcode / type asset number, serial number or any configured identifier
      |
Look up: reference datasets first, then existing project records
      |
Found  -> the whole record is prefilled and shown as "On record"
Not found -> offer to create a new record (flagged NOT_IN_REGISTER)
      |
Operator confirms each field, edits by typing, or captures a photo and lets OCR/AI correct it
      |
Approve
```

### 17.3 Variance

Every field that differs from the register is recorded in `record_variances`:

```text
Asset AST-00123  -  Kasubi HC IV / Theatre

Field          On record          As found          Status
--------------------------------------------------------------
Location       Laboratory         Theatre           CHANGED
Condition      Good               Faulty            CHANGED
Serial         SN458923           SN458923          MATCH
Custodian      J. Okello          M. Nabbosa        CHANGED
```

Export variance as a sheet/report; registered records never found export as **Missing**.

## 18. Template Versioning

- Every edit, including requiredness (§13.2), creates a version. Existing records keep their capture version and
  are never retrospectively incomplete.
- Recovery keeps the selected capture version and its defaults and identity fields. Legacy drafts without a
  recorded version use `0` (unknown); neither saving nor template remapping invents a current shape.
- Migrate records only on request, after previewing added/removed/retyped fields.
- Removed fields are hidden; retain values in the database and JSON, marked `retired`.
- Merge templates like other entities (§47); resolve conflicts by choosing a version or keeping both.

---

# Part IV — Capture

## 19. Capture Screen

One screen, one primary button.

```text
+--------------------------------------------------+
|  Medical Equipment Inventory            [ ... ]  |
|  Kampala  >  Kasubi HC IV  >  Theatre     [edit] |   <- context bar (§20)
|  Equipment  (pinned)                             |   <- template chip (§14)
+--------------------------------------------------+
|                                                  |
|   [ photo ] [ photo ] [ photo ]        + Add     |   <- photo tray (§22)
|                                                  |
|   Caption                              [ mic ]   |
|   "13 litre autoclave, pressure gauge faulty"    |
|                                                  |
|   Serial number            [ scan ] [ type ]     |   <- identity shortcut (§25)
|                                                  |
+--------------------------------------------------+
|         [  CAPTURE & ANALYSE  ]                  |
|         [  Save raw - analyse later  ]           |
+--------------------------------------------------+
```

- Opening a project goes here; the camera is one tap away.
- Require only a photo, caption or typed identifier.
- Both buttons save locally immediately; only AI timing differs (§26).
- Reset after save, retaining **context, pinned template and capture settings**.

## 20. Context Fields (Sticky Values)

Set once; apply to subsequent records until changed.

### 20.1 Hierarchy

Projects order template fields with `context_level` into a hierarchy:

```text
Level 1  Region        Central
Level 2  District      Kampala
Level 3  Facility      Kasubi Health Centre IV
Level 4  Department    Theatre
Level 5  Room          Recovery Room 2
```

Choose any levels (Site › Block › Floor; Farm › Field › Plot; Warehouse › Aisle › Shelf), or none.

### 20.2 Behaviour

1. A chip opens recent values, reference-data values (e.g. Facilities), or free text.
2. Values persist across records, screens and restarts until changed/cleared.
3. Changing a parent clears descendants after confirmation: *"Change district to Wakiso? Facility and Department will be cleared."*
4. Prefill new records as `source = CONTEXT`. Per-record edits **do not change project context**.
5. Store each record's `context_json` snapshot; later context changes never alter existing records.
6. Context controls photo paths (§8) and optionally filenames (§51).

### 20.3 Non-hierarchical pinned fields

Pin any `stickable` field as a context chip with the same behaviour: surveyor, funder, ownership, survey round,
currency or condition scale; no hierarchy level is required.

### 20.4 Context presets

A context set can be saved and re-selected in one tap:

```text
Saved locations
  Kasubi HC IV - Theatre          [ use ]
  Kasubi HC IV - Laboratory       [ use ]
  Mulago - Ward 4A                [ use ]
```

Project-owned presets support revisits/resumption and travel in bundles.

### 20.5 Auto-clear rules (optional, off by default)

- Clear the lowest context level after N minutes of inactivity.
- Prompt to confirm the context when the device has moved more than X metres (requires GPS).

Default: retain context; both rules require opt-in.

## 21. Automatic Fields

System-filled fields:

| Field | Source | Editable |
| ----------------------------------- | --------------------------- | ---------------------------------- |
| Capture date | Device clock at first save | Yes, with an audit entry |
| Capture time | Device clock | Yes |
| Captured at (UTC + offset) | Device clock | No |
| Last modified | Device clock on each change | No |
| Record number | Per-project sequence | No |
| Operator display name/profile | Device profile | Yes, choose another local display profile; account attribution stays unchanged |
| Attribution identity | Server-issued user ID (§71.2) | No historical rewrite; annotate pre-enrolment identity reconciliation |
| Device | Device ID | No |
| App / template version | System | No |
| GPS latitude / longitude / accuracy | Device GPS, when enabled | Cleared, not edited |
| Context values | Context bar (§20) | Yes, per record |
| Photo count | Derived | No |

Rules:

- Date/Time/DateTime fields support `auto_fill`; recognised capture dates default to `TODAY`.
- Show automatic values greyed with a clock icon.
- Store ISO-8601 UTC and device offset; display/export the project format, default `dd MMM yyyy`.
- Pin a differing survey date for backdated work until changed (§20.3).

## 22. Photos & Photo Editing

### 22.1 Capture

- Multiple photos per record, in any order.
- Sources: camera, gallery, file picker, PDF pages, scanned documents.
- Gallery JPEG, PNG and WebP originals retain their bytes; stored format and dimensions agree with the source.
- The camera stays open for rapid multi-shot; each shot is written to disk immediately.
- Camera controls: flash, tap-to-focus, pinch zoom, grid, document mode with edge detection, barcode overlay.
- Quality warnings are advisory, never blocking (§39.3).

### 22.2 The photo tray

Thumbnails show type and caption indicators. Tap to view; long-press to multi-select.

Available on one photo or on a selection:

```text
Preview        Retake         Delete
Reorder        Rotate         Crop
Set type       Add caption    Apply caption to selection (§23)
Move to another record         Duplicate to another record
```

### 22.3 Photo types

`FRONT · BACK · SERIAL · RATING_PLATE · DAMAGE · PANEL · LOCATION · ATTENDANCE · DOCUMENT · OTHER`

Analysis suggests types; operators may set them anytime. Types drive filenames (§51) and evidence (§33).

### 22.4 Editing after save

Add, remove, replace, rotate, retype, recaption or reorder saved photos anytime. After approval, changes return
the record to **Needs review** with an audit entry (§38). Removal unlinks the photo, retaining its original under
§38/§60.1 retention; affected values are flagged *evidence removed*, never deleted.

## 23. Captions & Caption Scope

### 23.1 Two levels

| Level | Purpose |
| ------------------ | ---------------------------------------------------------------------- |
| **Record caption** | Describes the item as a whole. The main context signal for extraction. |
| **Photo caption** | Describes one photo: "serial number plate", "cracked casing". |

Both can be typed or spoken, and both are stored **raw and refined** (§32).

### 23.2 Applying a caption to more than one photo

The caption sheet always shows an explicit target:

```text
Caption
+--------------------------------------------------+
| "Rating plate, model MED-1300"                   |
|                                       [ mic ]    |
+--------------------------------------------------+
Apply to:   ( ) This photo
            (o) Selected photos (3)
            ( ) All photos (7)

Mode:       (o) Replace     ( ) Append to existing

                       [ Apply ]
```

- **This photo** defaults from one thumbnail; **Selected photos** defaults from multi-select and shows the count.
- **All photos** includes every current-record photo, including earlier session additions.
- **Append** adds a new line; **Replace** overwrites with the prior caption recoverable from history.

Bulk application writes independent caption rows for later individual edits.

## 24. Voice Input

- Microphones appear on record/photo captions, free-text fields, the caption recorder, meeting mode and the
  Transcribe screen (§55).
- Speech-to-text runs on the device with whisper.cpp (§30.4) and never needs a network. Field dictation uses Whisper
  when it is ready; otherwise the platform recogniser, only where it is proven on device (Android 12+ with the
  on-device recogniser, iOS, macOS); otherwise it reports "works offline only with the speech model". The web uses
  the WebAssembly build of the same engine or reports unavailable (§30.4.8).
- Three long-form surfaces share one live transcription session (§30.4.5): meeting recording (§28), the Capture
  caption recorder (§26.1) and the standalone Transcribe screen with its history (§55). Each shows interim text and
  commits stable segments in order, without duplicates or gaps.
- Moving the app to the background pauses capture with everything captured so far durable; there is no background
  recording. Resume is always explicit. Cancel keeps the audio take; nothing captured is destroyed.
- Save the audio in `audio/`. Finalized segments are appended as they are produced, raw and write-once; edits are
  saved beside the raw text (§32). Skipped or untranscribed audio can be finished on the device later.
- Speech-derived values use `source = STT` and require the same review as AI output.
- The voice language comes from Settings (§57); English is the default. Whisper covers English, Swahili, French,
  Arabic and other languages. Luganda, Runyankole and Acholi are not supported by Whisper, and the app says so
  plainly; typing stays available, and a configured online service may re-transcribe a saved recording (§7.1).

## 25. Barcode / QR & Identifier-First Capture

Normal identifier capture searches existing records first; Verification uses the reference-first order (§17.2):

```text
Tap [scan]
      |
Read QR / barcode / asset tag
      |
Look up: existing records -> reference datasets
      |
+---------------------------------------------------------+
| Match found                                             |
|                                                         |
|  Existing record  -> open it, or add photos to it       |
|  Reference row    -> prefill a new record (§17)         |
|  No match         -> start a new record with the        |
|                      identifier already filled in       |
+---------------------------------------------------------+
```

- Supported symbologies: QR, Code 128, Code 39, EAN, UPC, Data Matrix, PDF417.
- Scanned values are `source = BARCODE` and carry full confidence.
- The scanner can stay open in **continuous mode** for stock counting: each scan increments a count or creates a stub record.

## 26. Capture Now, Map Later

Deferred processing is a first-class mode.

### 26.1 Saving raw

**Save raw — analyse later** stores photos, captions, transcripts, identifiers, context and automatic fields as
**Captured (unprocessed)**. No network or AI runs; capture continues immediately. A transcript produced live on
the device while recording (§24) is captured evidence, not processing.

### 26.2 The processing queue

```text
Process                                     Online

  Unprocessed          38 records
  Queued                0
  Failed                2

  [ Process all ]   [ Process selected ]

  Kasubi HC IV / Theatre       12 records   >
  Kasubi HC IV / Laboratory     9 records   >
  Mulago / Ward 4A             17 records   >
  Failed                        2 records   >
```

- Group by context, e.g. one facility at a time.
- Track resumable per-record progress; interruption loses no work.
- Show failure reasons and one-tap retry without harming raw records.
- **Auto-process when connected** is opt-in, optionally **Wi-Fi only**.
- While charging, opportunistically OCR unprocessed records locally before online calls.

### 26.3 Mixed projects

Immediate/deferred records coexist. Final exports differ only in timestamps and audit trail, regardless of
processing delay.

## 27. Rapid & Batch Capture

For large surveys where speed dominates.

```text
RAPID MODE - Kasubi HC IV / Theatre

  Item 1   3 photos   "autoclave"          saved
  Item 2   2 photos   "microscope"         saved
  Item 3   4 photos   -                    saved
  Item 4   1 photo    "ECG machine"        saved

  [ New item ]                [ Process all (4) ]
```

- One tap ends an item and starts the next; the camera never closes.
- The context and pinned template carry across items.
- Nothing is analysed until **Process all**.
- Review then happens as a list, one record after another, with **Approve and next** as the primary action.

## 28. Meeting Mode

A meeting is a record built on a Meeting template, with extra structure.

### 28.1 Fields

Meeting Mode uses a Meeting-type template, pack `MEET` (e.g. MTG-006 Meeting notes capture, §13.5). The pack defines
header, attendees, agenda, discussion, decisions and actions; repeating parts use child tables:

```text
Meeting          reference, title, type, date, start and end time, venue, mode
Officers         chairperson, secretary, facilitator, rapporteur      (name and title, separately)
Agenda items     child rows: number, title, presenter, discussion (raw + refined)
Attendees        child rows: given name, family name, title, organisation, contact,
                 attendance type, signature present
Apologies        child rows
Decisions        child rows: number, text (raw + refined), agenda item, voting counts
Action items     child rows: number, action text (raw + refined), owner, due date, status
Attachments      photos, documents, audio                             (inherited, §13.3)
Next meeting     date and venue
```

Atomic name/contact/time columns support counts, filtering and staff-register joins (§13.1); projects choose
requiredness (§13.2).

### 28.2 Inputs

| Input | Handling |
| ---------------------------------------------------- | ------------------------------------------------------------------------------ |
| Voice recording of the meeting | Saved to `audio/` with a live on-device transcript (§24), the meeting's transcript source; raw text is preserved verbatim, edits sit beside it, and older cloud transcript versions remain read-only legacy re-transcriptions |
| Typed notes | Preserved verbatim as the raw note |
| Photo of the attendance sheet | OCR to rows of`name / title / organisation / signature present`, each editable |
| Photos of participants, venue, whiteboards, handouts | Attached, captioned, classified`ATTENDANCE` or `DOCUMENT` |
| Documents (agenda, reports) | Attached as evidence |

### 28.3 Refinement

**Refine minutes** sends raw notes/transcript to the text service for agenda items, discussion summaries, decisions
and actions with owners/due dates.

- Permanently retain original notes/transcript. Working notes and refined minutes remain editable beside one another; serialized local saves retain failed text for retry and guard navigation/exit until durable. Store immutable `originalNotes` beside working `notes` in agenda JSON; legacy reads fall back to existing notes and the first write snapshots the prior value transactionally. Audit edits without making audit order the content authority; raw-notes exports use the immutable original. Delayed transcription preserves the latest notes/minutes and all source files.
- Review shows labelled summary counts, then recording/status, then multiline Notes and Minutes. Hide only the meeting recorder's empty idle transcript pane; live and saved transcripts remain available.
- Refine only on request.
- Match OCR attendee names to Staff reference data where available.
- Never add attendees, decisions or actions absent from the raw evidence (§34).

### 28.4 Output

- **PDF** — formatted minutes with attendance list and photo appendix.
- **XLSX / CSV** — attendance sheet and action-item register.
- **JSON** — the complete structured meeting.

---

# Part V — AI Processing

## 29. Processing Pipeline

Processing runs on-device in cancellable, resumable background jobs without blocking capture.

```text
Raw record (photos, captions, transcript, identifiers, context)
      |
Stage 0  Local preparation                       [offline]
         resize / compress copies, orientation, deskew, contrast,
         document boundary detection, quality scoring, perceptual hash
      |
Stage 1  On-device extraction                    [offline]
         ML Kit OCR text + blocks
         barcode decoding
         identifier pattern matching
         reference-dataset lookup on any identifier found
      |
         --> If a reference match fills the record, the online stages
             may be skipped entirely (a large cost saving).
      |
Stage 2  Template detection (§14)                [offline heuristics, optional cheap model]
      |
Stage 3  Online extraction                       [online, optional]
         vision analysis of the image group
         field extraction against the template's field list
         caption / transcript refinement
      |
Stage 4  Normalisation (§35)                     [offline]
         units, choice mapping, date parsing, casing, row matching
      |
Stage 5  Validation (§39)                        [offline]
         types, patterns, ranges, required fields, duplicates
      |
Stage 6  Confidence, evidence and provenance (§33)
      |
      v
Record -> Needs review
```

Stages 0–2, 4 and 5 work offline using local template-detection heuristics. Stage 2's optional network model and
Stage 3 require connectivity and permission under the project's AI policy. When offline or online AI is disabled,
use the heuristic fallback and skip online work. Projects may disable Stage 3 permanently.

### 29.1 Group analysis

Analyse each record's photos **together with** record/photo captions, context, template fields and matched predefined rows. Never analyse images independently and blindly merge results: different views provide complementary evidence.

### 29.2 Progress display

Show the record count (for example, **Analysing 12 of 38**) and each stage's done, busy or waiting state: preparing images, reading text on-device, identifying the template, extracting fields and checking values.

## 30. AI Providers, Keys & Offline Behaviour

### 30.1 Abstraction

All AI uses one provider-independent Dart interface:

```dart
abstract class AiService {
  Future<OcrResult>        readText(List<ImageRef> images);
  Future<ExtractionResult> extractFields(ExtractionRequest request);
  Future<String>           refineText(String raw, RefineStyle style);
  Future<String>           transcribe(AudioRef clip, String languageCode);
  Future<DocumentDraft>    composeDocument(DocumentGenerationRequest request);
}
```

Implement on-device ML Kit OCR, on-device speech (§30.4) and each configured online provider. Select per project, with per-operation overrides. `transcribe` uses the record's on-device transcript when one exists: processing takes each clip's complete on-device transcript as it reads (edit first; never a live or interrupted one), records it as `source: device` with no provider call and no charge against the daily cap, and sends only a clip without one to the opted-in online provider. Processing never runs speech recognition itself; live speech never passes through `AiService`.

### 30.2 Keys

- **Backend custody is the default** (§70.1, §73): administrators enter and rotate provider keys centrally; devices call the backend, which calls the provider.
- **Never compile keys into the app or return them through an endpoint** (§75).
- Optional personal accounts save their keys directly to an encrypted server keystore (§73.1); selecting one is
  an explicit billing choice. Removing its key leaves that selection unavailable until the operator changes it.
- Administrators may permit **device-held keys**, for example when an operator cannot reach the server. Enter them in Settings; store only in Android Keystore/iOS Keychain via `flutter_secure_storage`, never in the database, logs, exports or bundles.
- Mask entered keys and offer a one-call **Test connection** for server- or device-held keys.
- Each project may select a configured provider or none.

### 30.3 Behaviour without a network

| Capability                             | Offline                                                                               |
| -------------------------------------- | ------------------------------------------------------------------------------------- |
| Capture photos, captions, typed values | Works                                                                                 |
| Sign-in, identity and role checks      | Works from the cached session and the last cached grant (§70.4)                       |
| Speech-to-text                         | Works on-device (§30.4); unavailable only where neither a speech model nor an on-device platform recogniser serves the device and language (§24) |
| Text OCR                               | Works (on-device)                                                                     |
| Barcode / QR                           | Works                                                                                 |
| Reference lookup and prefill           | Works                                                                                 |
| Template detection                     | Works (heuristics)                                                                    |
| Vision extraction and text refinement  | Queued for later (§26)                                                                |
| Documentation preparation              | Import, supported local extraction, output mapping and prompt editing work (§77–§79) |
| Documentation AI drafting              | Waits for connectivity and explicit run/resume; existing drafts remain editable (§80) |
| Documentation rendering                | Existing draft/approved content renders locally to supported formats (§78); no fresh AI call |
| Review, edit, approve                  | Works                                                                                 |
| Export XLSX / DOCX / TXT / CSV / JSON / PDF / ZIP | Works                                                                                 |
| Cloud upload                           | Unavailable, queued as a pending user action                                          |

### 30.4 On-device speech engine

Live speech-to-text runs entirely on the device. This section is the durable engine contract; §24 states product
behaviour, §59 the targets and §7.1 the network rule. Plan tasks cite these subsections and inline only the
signatures they publish.

- **Engine.** whisper.cpp 1.9.4 (MIT), CPU-only, vendored with one recorded patch in the local plugin
  `frontend/packages/tapture_whisper` behind the flat `tw_*` C ABI v1 (§30.4.1). Native platforms call it through FFI
  on two long-lived worker isolates; the web runs the same shim compiled to WebAssembly in module Web Workers
  (§30.4.8).
- **Layering.** `core/speech`: `LiveTranscriptionService` → `SpeechPipeline` → `SpeechEngineLease` →
  `SpeechEngineHost` → `SpeechEngine`, plus dictation (`WhisperSttService`, `RoutedSttService`), the model catalogue
  and store, the device probe, the selector and readiness. `core/audio` owns capture (`AudioCaptureService`,
  `MicrophoneArbiter`), `core/ai` keeps the unchanged `SttService` contract and adds `PlatformRecogniserPolicy`, and
  `features/transcripts` owns persistence. Features reach them only through barrels.
- **No network.** `core/speech` sits outside `core/ai`, `core/cloud` and `core/backend`, so it is network-free by
  construction (no HTTP there). The only network use is the build-time `frontend/tool/speech_models.dart --fetch`.
- **Models.** Bundled: `tiny-q5_1`, `base-q5_1` and `silero-v6.2.0`, at exact bytes and SHA-256. Import only, native
  only: `small-q5_1`. The fetch tool downloads by pinned revision URL and hash into `frontend/assets/speech/`
  (gitignored), or copies from `--from <dir>`; the release gate row `speech-assets` fails without them. A
  development build without models reports `modelMissing`: long-form surfaces record only, and dictation uses the
  on-device platform fallback or reports unavailable. There is no in-app download.
- **Lifecycle.** `paused` and `hidden` pause capture behind an awaited pause flush (§30.4.5); `detached` stops
  sessions without waiting; a bare `inactive` never pauses. There is no background recording.

Single owners — a second implementation of any of these is a defect:

| Concern | The one implementation |
| --- | --- |
| Resampling | `core/audio/pcm_resampler.dart` |
| WAV header and repair | `core/audio/wav_header.dart`, `core/audio/wav_take.dart` |
| Publishing staged takes | `core/audio/staged_take.dart` (`publishStagedTake` over `FileWriter.adoptStaged`, plus `StagedTakeRecovery`) |
| Native worker protocol | `core/concurrency/worker_isolate.dart` + `worker_port.dart` |
| Web worker protocol | `frontend/web/whisper/whisper_worker.js` ↔ `core/speech/speech_worker_codec.dart` |
| Model integrity at load | the C shim (`tw_*_open_*` with expected size + SHA-256, hashing in-shim before parsing) |
| Model integrity at import and in settings | `verifySpeechModelFile` (size, header, `HashingService.sha256OfFile`) |
| Transcript store | tables `transcripts` + `transcript_segments`, reached through `TranscriptSink` (§30.4.6). Task 012's `TranscriptStore` caption-row record is kept, untouched |
| Meeting transcript text | the live `transcripts` row; `TranscriptVersion`s remain only for legacy cloud runs |
| Decode thresholds | `AppConstants.speechEngine` |
| Piece-to-text grouping | `core/speech/speech_piece_text.dart` (io and web) |
| Model catalogue | `core/speech/speech_model_catalogue.dart`, which also generates `assets/speech/manifest.json` |

#### 30.4.1 C ABI v1

**Vendored source.** Tarball `whisper.cpp-v1.9.4.tar.gz`, sha256
`57e280cee375ab02425b806ad5146b99f6eb9357e3c2b31357c8a6af2e2e44ae`, commit
`927cfce34f31707e17f2bff35c349632fb9e2c3a`. `frontend/tool/whisper_vendor.dart --from <tarball>` verifies the hash,
extracts only the KEEP list, applies `third_party/patches/*.patch` in order, writes `VENDOR.json`
(`{tag, commit, tarballSha256, patches:[{name, sha256, files:{path:{upstreamSha256, patchedSha256}}}], files:{path:{bytes, sha256}}}`)
and regenerates the Darwin forwarders. `--check` needs no network; it reports every missing, extra or drifted file,
every patch whose recorded hashes no longer match, every `whisper_sources.cmake` entry that is not vendored and
every stale forwarder as `path:line: message`, and exits 1 on any.

- **KEEP:** `LICENSE`, `AUTHORS`, `include/whisper.h`, `src/whisper.cpp`, `src/whisper-arch.h`;
  `ggml/include/{ggml.h,ggml-alloc.h,ggml-backend.h,ggml-cpp.h,ggml-cpu.h,ggml-opt.h,gguf.h}`;
  `ggml/src/{ggml.c,ggml.cpp,ggml-alloc.c,ggml-backend.cpp,ggml-backend-meta.cpp,ggml-backend-dl.cpp,ggml-backend-dl.h,ggml-backend-reg.cpp,ggml-backend-impl.h,ggml-common.h,ggml-feats.h,ggml-impl.h,ggml-opt.cpp,ggml-quants.c,ggml-quants.h,ggml-threading.cpp,ggml-threading.h,gguf.cpp}`;
  `ggml/src/ggml-cpu/{ggml-cpu.c,ggml-cpu.cpp,ggml-cpu-impl.h,common.h,arch-fallback.h,binary-ops.*,unary-ops.*,hbm.*,iqp.*,ops.*,quants.*,repack.*,simd-gemm.h,simd-mappings.h,traits.*,vec.*}`;
  `ggml/src/ggml-cpu/amx/*`, `ggml/src/ggml-cpu/arch/{arm,x86}/{quants.c,repack.cpp}`,
  `ggml/src/ggml-cpu/arch/wasm/quants.c`; loader fixtures (not usable weights) `samples/jfk.wav`,
  `models/for-tests-ggml-tiny.bin`, `models/for-tests-silero-v6.2.0-ggml.bin`.
- **DROP:** every upstream CMake, `cmake/`, Makefile and xcframework script; non-CPU backends; kleidiai, llamafile
  and spacemit; other architectures and `cpu-feats.cpp`; parakeet; `src/{coreml,openvino,vitisai}`; examples, tests,
  bindings, scripts, grammars and `*.md`.
- **Patch `0001-sched-abort-callback.patch`**, the only vendored modification: the `sched` overload of
  `ggml_graph_compute_helper` (`src/whisper.cpp:194`) gains `ggml_abort_callback abort_callback, void *
  abort_callback_data` and sets them on each scheduler backend through the `ggml_backend_set_abort_callback` proc
  address, as the first overload does (`:172-192`). The four call sites in `whisper_encode_internal`
  (`:2440,2480,2496`) and `whisper_decode_internal` (`:2993`) pass their abort callback through, so the CPU backend
  checks the abort once per graph node (`ggml-cpu.c:3150`) rather than once per encoder pass. The VAD call (`:5269`)
  is unchanged.

**Header** `src/tapture_whisper.h`, the only public header. `TW_API` is `__declspec(dllexport)` on Windows when
`TW_BUILD` is defined and `__declspec(dllimport)` otherwise, `EMSCRIPTEN_KEEPALIVE` plus default visibility on WASM,
and default visibility elsewhere; everything vendored is built with hidden visibility. Defines: `TW_ABI_VERSION 1`,
`TW_SAMPLE_RATE 16000`, `TW_MAX_SAMPLES (16000*600)`, `TW_MAX_THREADS 8`, `TW_LANGUAGE_CAPACITY 8`,
`TW_LOG_TEXT_CAPACITY 504`, `TW_LOG_RING_CAPACITY 256`, `TW_SHA256_BYTES 32`.

- **`tw_status`:** 0 OK, 1 INVALID_ARGUMENT (includes an empty or `auto` language), 2 ABI_MISMATCH,
  3 UNSUPPORTED_CPU, 4 FILE_OPEN, 5 MODEL_INVALID (magic or header), 6 MODEL_LOAD, 7 OUT_OF_MEMORY, 8 ABORTED,
  9 INFERENCE, 10 POISONED, 11 BUSY, 12 AUDIO_TOO_LONG, 13 ENGINE_NOT_BUILT, 14 INTERNAL, 15 MODEL_MISMATCH (size or
  SHA-256 differs from the expectation).
- **Enums:** `tw_struct_id` 1–10: CONTEXT_OPTIONS, TRANSCRIBE_OPTIONS, CPU_INFO, MEMORY_INFO, MODEL_FACTS, SEGMENT,
  TOKEN, SPAN, LOG_ENTRY, VAD_OPTIONS. `tw_object_kind`: CONTEXT, RESULT, VAD, SPANS, CELL, HASHER. `tw_arch`:
  UNKNOWN, X86_64, ARM64, ARM32, WASM32, X86. `tw_log_level`: 1..4. `tw_strategy`: GREEDY, BEAM.
- **CPU feature bits:** b0 SSE3, b1 SSSE3, b2 SSE42, b3 AVX, b4 AVX2, b5 FMA, b6 F16C, b7 BMI2, b8 AVX512F,
  b9 AVX_VNNI, b16 NEON, b17 ARM_FMA, b18 FP16_VA, b19 DOTPROD, b20 I8MM, b21 SVE, b22 SME, b32 WASM_SIMD.

**POD structs.** The layout is identical on 64-bit and wasm32. Each struct is `static_assert`ed and exposed as
`TW_SIZEOF_*`; layout tests parse `TW_SIZEOF_*` from the header rather than copying sizes.

| struct | size | fields |
| --- | --- | --- |
| `tw_context_options` | 16 | `u32 struct_size; i32 n_threads; u8 use_gpu(0); u8 flash_attn(1); u8 reserved[6]` |
| `tw_transcribe_options` | 84 | `u32 struct_size; i32 strategy, n_threads, best_of(5), beam_size(5), max_tokens(0), audio_ctx(0), n_max_text_ctx(16384); f32 temperature(0), temperature_inc(0.2), entropy_thold(2.4), logprob_thold(-1), no_speech_thold(0.6), length_penalty(-1), max_initial_ts(1), token_thold_pt(.01), token_thold_ptsum(.01); u8 translate(0), no_context(1), single_segment(0), no_timestamps(0), token_timestamps(0), suppress_blank(1), suppress_nst(1), carry_initial_prompt(0); char language[8]` |
| `tw_cpu_info` | 40 | `u32 struct_size; i32 n_logical, n_performance; u32 arch; u64 runtime_features, required_features; u8 supported, engine_built, reserved[6]` |
| `tw_memory_info` | 32 | `u32 struct_size, reserved; i64 total_bytes, available_bytes, process_limit_bytes` (−1 unknown) |
| `tw_model_facts` | 56 | `u32 struct_size; i32 n_vocab, n_audio_ctx, n_audio_state, n_audio_head, n_audio_layer, n_text_ctx, n_text_state, n_text_head, n_text_layer, n_mels, ftype, model_type, multilingual` |
| `tw_segment` | 48 | `i64 t0_ms, t1_ms; i32 text_offset, text_length, token_offset, token_count; f32 no_speech_prob, avg_logprob, mean_p, min_p` |
| `tw_token` | 32 | `i32 id, bytes_offset, bytes_length; f32 p; i64 t0_ms, t1_ms` |
| `tw_span` | 16 | `i64 t0_ms, t1_ms` |
| `tw_log_entry` | 512 | `i32 level, length; char text[504]` |
| `tw_vad_options` | 28 | `u32 struct_size; f32 threshold(.5); i32 min_speech_ms(250), min_silence_ms(100); f32 max_speech_s(FLT_MAX); i32 speech_pad_ms(30); f32 samples_overlap_s(.1)` |

`avg_logprob` is the mean of `plog` over all tokens of the segment, including timestamp tokens (whisper's
`sum_logprobs/result_len`); `mean_p` and `min_p` are taken over text tokens.

```c
/* library — any thread; the first two never initialise ggml */
int32_t tw_abi_version(void);  int32_t tw_struct_size(int32_t id);  const char* tw_version(void);  const char* tw_system_info(void);
int32_t tw_cpu_info_get(tw_cpu_info*);  int32_t tw_memory_info_get(tw_memory_info*);
void tw_debug_set_cpu_override(int32_t supported);       /* tests */
void tw_debug_abort_after_checks(int32_t n);              /* tests: abort after n abort checks; 0 = off */
int32_t tw_live_objects(int32_t kind);  int32_t tw_lang_id(const char* code);
/* SHA-256 (in-house tw_sha256.c, NIST-vector tested) */
int32_t tw_sha256(const void* data, size_t n, uint8_t out[32]);
tw_hasher* tw_sha256_new(void);  void tw_sha256_update(tw_hasher*, const void*, size_t);  int32_t tw_sha256_finish(tw_hasher*, uint8_t out[32]); /* frees */
/* logging */
void tw_log_set_min_level(int32_t);  int32_t tw_log_drain(tw_log_entry* out, int32_t cap);  uint32_t tw_log_dropped(void);  int32_t tw_set_crash_file(const char* path_utf8);
/* reference-counted atomic abort cells; shared memory on WASM mt */
int32_t* tw_cell_new(void);  void tw_cell_retain(int32_t*);  void tw_cell_release(int32_t*);  void tw_cell_store(int32_t*, int32_t);  int32_t tw_cell_load(const int32_t*);
/* whisper context — one thread at a time per handle */
void tw_context_options_init(tw_context_options*);
int32_t tw_context_open_file(const char* path_utf8, int64_t expected_bytes, const uint8_t* expected_sha256 /*required*/, const tw_context_options*, tw_context** out);
int32_t tw_context_open_buffer(const void* data, size_t size, const uint8_t* expected_sha256 /*nullable: test fixtures*/, const tw_context_options*, tw_context** out);
int32_t tw_context_open_js(int32_t file_id, int64_t expected_bytes, const uint8_t* expected_sha256, const tw_context_options*, tw_context** out); /* WASM only */
void tw_context_close(tw_context*);  int32_t tw_context_facts(tw_context*, tw_model_facts*);
float* tw_context_pcm_buffer(tw_context*, int32_t n_samples);  int32_t tw_last_whisper_code(const tw_context*);
void tw_transcribe_options_init(tw_transcribe_options*);
int32_t tw_transcribe(tw_context*, const float* pcm, int32_t n, const tw_transcribe_options*, const char* initial_prompt_utf8,
                      const int32_t* prompt_tokens, int32_t n_prompt_tokens, const int32_t* abort_cell, int32_t job_id, tw_result** out);
void tw_result_free(tw_result*);  const tw_segment* tw_result_segments(const tw_result*, int32_t* count);
const tw_token* tw_result_tokens(const tw_result*, int32_t* count);  const uint8_t* tw_result_text(const tw_result*, int32_t* length);
const char* tw_result_language(const tw_result*);  int64_t tw_result_wall_ms(const tw_result*);
/* Silero VAD */
int32_t tw_vad_open_file(const char*, int64_t expected_bytes, const uint8_t* expected_sha256, const tw_context_options*, tw_vad**);
int32_t tw_vad_open_buffer(const void*, size_t, const uint8_t* expected_sha256, const tw_context_options*, tw_vad**);
int32_t tw_vad_open_js(int32_t file_id, int64_t expected_bytes, const uint8_t* expected_sha256, const tw_context_options*, tw_vad**);
void tw_vad_close(tw_vad*);  int32_t tw_vad_window_samples(const tw_vad*);  float* tw_vad_pcm_buffer(tw_vad*, int32_t n);
int32_t tw_vad_feed(tw_vad*, const float* pcm, int32_t n, int32_t* out_n_probs);  const float* tw_vad_probs(const tw_vad*, int32_t* count);
int32_t tw_vad_pending_samples(const tw_vad*);  void tw_vad_reset(tw_vad*);  void tw_vad_options_init(tw_vad_options*);
int32_t tw_vad_segments(tw_vad*, const float* pcm, int32_t n, const tw_vad_options*, tw_spans** out);
const tw_span* tw_spans_data(const tw_spans*, int32_t* count);  void tw_spans_free(tw_spans*);
```

**Semantics.**

- **Init.** `std::call_once` installs `whisper_log_set(tw_log_sink)` and `ggml_set_abort_callback(tw_on_ggml_abort)`;
  on MSVC it also calls `_set_abort_behavior(0, …)`.
- **Verified open (single handle).** `open_file` returns a status at the first failing step: (1) open once — Windows
  `_wfsopen(utf16, L"rb", _SH_DENYWR)`, POSIX `open(O_RDONLY)` + `fstat`; (2) size must equal `expected_bytes`, else
  `MODEL_MISMATCH`; (3) stream the whole file through SHA-256 in 64 KiB reads and compare, else `MODEL_MISMATCH`;
  (4) rewind and check the `6C 6D 67 67` magic, else `MODEL_INVALID`; (5) parse through a `whisper_model_loader`
  over the **same** handle. Unverified bytes are never parsed. `open_js` does the same through an `EM_JS` import
  `tw_js_read(file_id, offset, dst, n)` (`offset` an i64 under WASM_BIGINT), served by the worker from an OPFS
  `FileSystemSyncAccessHandle` or a fetched `ArrayBuffer`, so the model is never copied whole into the WASM heap.
  `open_buffer` hashes only when a sha is given. Residual POSIX risk: the file can be modified in place between hash
  and parse; bundled files sit in app-private or install directories, and this is documented. No path is ever
  logged. Context params: `use_gpu=false`, `flash_attn` from the options, `dtw_token_timestamps=false`.
- **Explicit state.** The shim opens with `whisper_init_with_params_no_state`, then `whisper_init_state`; every
  transcription goes through `whisper_full_with_state`. On rc −7 the state has already been freed, so the shim nulls
  it and returns `POISONED` until close. `whisper_get_timings` is never called; the only timing reported is `wall_ms`.
- **Transcribe validation:** `1 ≤ n ≤ TW_MAX_SAMPLES`; `best_of` and `beam_size` in 1..8;
  `audio_ctx ∈ {0} ∪ [64, n_audio_ctx]`; language a known code, **never empty or `auto`**, so whisper's separate,
  non-abortable language-detection pass is unreachable; prompt ids `< n_vocab`; English forced on `.en` models.
- **Fixed overrides:** every `print_*` false, `debug_mode=false`, `tdrz=false`, `vad=false`,
  `detect_language=false`; `max_len=0`, `split_on_word=false`, no grammar; `encoder_begin_callback` and
  `progress_callback` unset; `n_threads` clamped to `[1, min(hw, 8)]`, and 1 on WASM st.
- **Copy-out:** segment text goes into one blob; text tokens (`id < eot`) carry piece bytes and `p`; times are
  converted from centiseconds ×10 to milliseconds.
- **Abort rule.** (1) The shim's `abort_callback` returns true iff `abort_cell && job_id > 0 &&
  atomic_load(abort_cell) >= job_id` (or the debug counter fires); patch 0001 makes the CPU backend consult it per
  graph node. (2) **After `whisper_full_with_state` returns, whatever its code**, the shim re-evaluates the
  condition; if it holds, it discards any partial result and returns `ABORTED`, so an aborted job is never mistaken
  for an empty success. (3) After `ABORTED` the state stays reusable; kv caches are cleared at the next run.
  (4) Latency is bounded by one graph node plus the non-abortable mel computation of at most 30 s of audio. There is
  no progress cell in ABI v1.
- **Cells.** `tw_cell_new` returns refcount 1; `tw_cell_retain` and `tw_cell_release` adjust it, and the cell is
  freed at 0. A worker lane retains the cell it borrows and releases it after its last native call has returned.
  `tw_live_objects(CELL)` counts cells not yet freed.
- **Concurrency.** An atomic `busy` flag makes a concurrent call on the same handle return `BUSY`; a close during a
  call is deferred; every free, close or release function is NULL-safe with the shape `void f(T*)`.
- **VAD streaming.** `tw_vad_feed` runs `whisper_vad_detect_speech_no_reset` only on whole multiples of `n_window`,
  keeps the remainder pending and never zero-pads mid-stream. `tw_vad_segments` resets the state first; its spans are
  converted from centiseconds ×10 to milliseconds.
- **Logging and privacy.** The sink drops DEBUG and CONT and anything below `min_level` (default WARN). Kept lines go
  into a mutex-guarded 256-entry ring with a drop counter; the shim's own lines are prefixed `tapture_whisper:`. A
  crash file, when set, receives `"<unix_ms>\t<msg>\n"` before ggml aborts.
- **Probes.** CPU features: x86 CPUID/XGETBV (with `XCR0&6`), arm64 Linux/Android `getauxval`, Apple
  `sysctlbyname`, wasm SIMD. Performance cores: Windows `EfficiencyClass`, Linux `cpuinfo_max_freq`, Apple
  `perflevel0`. Memory: Windows `GlobalMemoryStatusEx`, Linux `/proc/meminfo`, macOS `hw.memsize` +
  `host_statistics64`, iOS `os_proc_available_memory`, wasm −1.
- **Exceptions.** `std::bad_alloc` maps to `OUT_OF_MEMORY`; any other exception maps to `INTERNAL`.
- **Stub build** (`TW_ENGINE=0`): ABI, struct, cell, SHA-256, log, CPU and memory functions work and
  `engine_built=0`; every open returns `ENGINE_NOT_BUILT`.

**Builds.** One `src/CMakeLists.txt` serves NDK, MSVC and Emscripten, with no FetchContent, `file(DOWNLOAD)`,
`install()`, git probes, `GGML_NATIVE`, BLAS or Metal. `TW_OPENMP` is ON only for Android (static OpenMP).
Windows stays OFF (task 128 decision, 2026-10-05). A second MSVC build with `/openmp:llvm` and `GGML_USE_OPENMP` was
run against the default build in four interleaved pairs, with the machine 29–100% busy with other work. Median
tokens/s decoding jfk: tiny 8.06 ON against 6.74 OFF (+20%), base 3.71 against 3.87 (−4%). ON was also worse for
voice detection (median 60 against 33 ms per audio second) and abort latency. One 30 s base decode under load ran
past four minutes. The `libomp140` runtime ships only in Visual Studio's `debug_nonredist` folder, so it cannot be
redistributed. A review re-measure in three interleaved pairs (machine 23–87% busy) gave tiny 14.37 ON against
12.98 OFF (+11%), base 5.76 against 5.87 (−2%), with ON again worse for voice detection (22.6 against 12.1 ms per
audio second) and abort latency (71 against 40 ms). ON does not win by more than 15%, so no follow-up task.
`TW_BUILD_SMOKE` builds `tw_smoke --model <bin> --sha256 <hex> --wav <16k s16 mono> --expect "<phrase>"
[--abort-after-checks N]`, which exits non-zero on a missing phrase, or with `--abort-after-checks` unless the call
returns `ABORTED` and an immediate retry on the same context succeeds.

| Target | Engine |
| --- | --- |
| Windows x64 | `/arch:AVX2` (+ FMA, F16C, BMI2; required mask 0xFF); Dart preflight `IsProcessorFeaturePresent(40)` before `DynamicLibrary.open` |
| Linux x64 | `-msse4.2 -mavx -mavx2 -mfma -mf16c -mbmi2`; preflight from `/proc/cpuinfo` |
| Android arm64-v8a | armv8-a baseline, 16 KB page alignment, `c++_static`, OpenMP static |
| Android x86_64 | `-msse4.2 -mpopcnt` (emulator) |
| Linux arm64 | armv8-a |
| iOS / macOS | default + `GGML_USE_ACCELERATE` (vDSP only); generated forwarders; CocoaPods and SwiftPM |
| wasm32 | `-msimd128 -fwasm-exceptions`; mt adds `-pthread` (§30.4.8) |
| Android armeabi-v7a, Windows ARM64, x86 | stub: `engineNotBuilt` |

`frontend/tool/check_native_library.dart` rejects, listing every violation, each Android `PT_LOAD p_align < 16384`,
each dynamic export not matching `^tw_` and each `DT_NEEDED` outside `{libc.so, libm.so, libdl.so, liblog.so}`.

**Dart API.** `package:tapture_whisper/tapture_whisper.dart` exposes no `dart:ffi` type and one public type per
file. `WhisperLibrary.open` returns `WhisperLibraryLoaded` or `WhisperLibraryUnavailable` with a
`WhisperUnavailableReason` (`unsupportedPlatform`, `libraryMissing`, `abiMismatch`, `unsupportedCpu`,
`engineNotBuilt`). The x86_64 preflight runs before `DynamicLibrary.open`; after it, the ABI, all ten struct sizes,
`engine_built` and `supported` are checked. Every native-handle owner attaches a `NativeFinalizer` with
`externalSize` and `detach`, and `close()` detaches before the native close; a `WhisperCell` finalizer only
releases. Only `core/speech/speech_native_api_io.dart` imports the package (FE-STR-11), and its identifier word is
"piece", never "token".

#### 30.4.2 Engine contract

`frontend/lib/core/speech/`; the barrel `speech.dart` exports the public types and never `_io`, `_web`, `_stub` or
`pipeline/` files. Each file holds one public type named after the file.

```dart
abstract interface class SpeechEngine {
  factory SpeechEngine.platform({@visibleForTesting String? libraryPath,
      @visibleForTesting SpeechNativeApi Function(String? libraryPath)? openApi,
      @visibleForTesting SpeechAbortCell Function(String? libraryPath)? openAbortCell});   // conditional import io|web|stub
  const factory SpeechEngine.unavailable();
  Future<Result<SpeechRuntimeFacts>> probe();
  Future<Result<SpeechLoadReport>> load(SpeechModelSource model, {required int threads, CancellationToken? cancel});
  Future<Result<SpeechVadHandle>> openVad(SpeechModelSource vad);                     // one per lease
  Future<Result<SpeechDecodeResult>> decode(SpeechDecodeRequest request, {required int leaseId, CancellationToken? cancel});
  Future<Result<SpeechVadResult>> detectSpeech(SpeechVadHandle vad, Float32List samples, {bool resetState = false, CancellationToken? cancel});
  Future<void> closeVad(SpeechVadHandle vad);
  void abortLease(int leaseId);                       // pending jobs of the lease removed; its in-flight job aborted
  Future<Result<void>> unload(); Future<void> dispose();
  SpeechLoadReport? get loaded; Stream<SpeechEngineState> get states; @visibleForTesting int get debugLiveHandles;
}
final Provider<SpeechEngine> speechEngineProvider;      // default SpeechEngine.unavailable()
final class SpeechVadHandle { const SpeechVadHandle({required int id, required int frameSamples}); }
enum SpeechDecodeKind { interim, committed }
final class SpeechDecodeRequest { const SpeechDecodeRequest({required Float32List samples /*16 kHz mono, 1..maxDecodeSamples*/,
  required String language /*whisper code; never '' or 'auto'*/, required SpeechDecodeKind kind, int offsetSamples = 0, String prompt = '',
  required SpeechDecodeProfile profile, bool pieceTimings = false}); }
final class SpeechDecodeProfile { const SpeechDecodeProfile({required int threads, int bestOf = 1, int beamSize = 0, double temperatureStep = 0,
  double noSpeechThreshold, double logprobThreshold, double entropyThreshold, bool singleSegment = false, bool timestamps = true,
  int maxPieces = 0, int audioContextPad = 0, bool suppressBlank = true, bool suppressNonSpeech = true});
  int audioContextFor(int sampleCount);  // 0 when pad == 0, else min(maxAudioContext, roundUp(ceil(sec*encoderFramesPerSecond)+pad, 64))
  SpeechDecodeProfile copyWith({...}); }
final class SpeechDecodeResult { const SpeechDecodeResult({required List<SpeechSegment> segments, required String language,
  required int offsetSamples, required int sampleCount /*original, before padding*/, required Duration elapsed}); double get realTimeFactor; }
final class SpeechSegment { /* startSample, endSample: absolute = offset + ms*16, clamped to [offset, offset+originalCount); text raw;
  noSpeechProbability, averageLogProbability, confidence (mean p); pieces */ }
final class SpeechPiece { /* startSample, endSample, text (valid UTF-8), probability */ }
final class SpeechVadResult { const SpeechVadResult({required Float32List probabilities, required int frameSamples}); }
final class SpeechLoadReport { /* model entry, shape, threads, loadTime (includes in-shim verification) */ }
final class SpeechModelShape { /* nVocab, nAudioCtx, nAudioState, nAudioLayer, nTextLayer, nMels, ftype, multilingual */ }
enum SpeechUnavailableReason { platform, library, abi, cpu, engineNotBuilt, simd }
final class SpeechRuntimeFacts { /* available, unavailableReason, engineVersion, abiVersion, cpu features, is64Bit, total/available/processLimit
  memory, logicalCores, performanceCores, webThreads, webSimd */ }
enum SpeechCpuFeature { avx, avx2, fma, f16c, neon, armFma, dotProd, fp16, wasmSimd }
enum SpeechEngineState { idle, starting, ready, loading, loaded, busy, unloading, disposed, failed }

// Transcript value types shared by the session, the sink and features
final class TranscriptSegment { /* id (1-based insertion seq), utteranceId, startSample, endSample, text, languageTag, modelId,
  noSpeechProbability, averageLogProbability, confidence, words; start/end Durations; toJson/fromJson */ }
final class TranscriptWord { /* text, startSample, endSample, probability */ }
final class FinishedUtterance { const FinishedUtterance({required int utteranceId, required int fromSample, required int toSample,
  required List<TranscriptSegment> segments, bool skipped = false}); }       // skipped: range not transcribed, recorded as a gap
final class TranscriptOutcome { const TranscriptOutcome({required bool complete, required Duration captured, required int coveredToSample,
  required String languageTag, String? modelId}); }
abstract interface class TranscriptSink {
  Future<Result<void>> appendUtterance(FinishedUtterance utterance);   // durable before success
  Future<Result<void>> finish(TranscriptOutcome outcome);              // complete or interrupted; durable before success
}
abstract final class SpeechText { static String join(Iterable<String> texts); }
abstract final class SpeechPieceText { static List<SpeechPiece> group(List<({List<int> bytes, int startSample, int endSample, double probability})> raw); }
String? whisperLanguageFor(String tag);   // speech_languages.dart: 'en-UG'→'en', 'lg'→null
```

**Fakes and the contract suite.** `FakeSpeechEngine` is driven by a `SpokenScript` of `(word, startSample,
endSample)` with adversarial modes: `truncateEdgeWord`, `completeEdgeWord`, `dropEdgeWord`, `timeJitter: ±300 ms`,
`echoPrompt: p`, `loopAtSpeechRate`, `hallucinate` and a reported (never slept) `computeTime`. Every engine passes
`runSpeechEngineContract`: results in order; interim supersession per lease; committed preemption; `abortLease(A)`
never cancels lease B's jobs; two leases' interleaved VAD give each the probabilities of a solo run within 1e-4;
decode before load gives `ProviderFailure(unavailable)`; decode after dispose gives `ProviderFailure`;
`debugLiveHandles` returns to baseline; a partial VAD frame and a `''` or `'auto'` language give `ValidationFailure`.

**Native engine** (`speech_engine_io.dart`). Two `WorkerIsolate` lanes, spawned lazily on the first load:
`speech-decode` (one whisper context) and `speech-vad` (Silero, 1 thread, one `tw_vad` per lease, so LSTM state
never crosses sessions). `speech_native_api_io.dart` is the only importer of `package:tapture_whisper`:

```dart
abstract interface class SpeechNativeApi {   // worker side; throws only Failures
  SpeechRuntimeFacts facts();
  int loadModel(String path, {required int threads, required int bytes, required String sha256});   // in-shim verified open
  SpeechModelShape shape(int model);
  int loadVad(String path, {required int bytes, required String sha256}); int vadWindow(int vad);
  SpeechDecodeResult decode(int model, SpeechDecodeRequest request, {required int abortAddress, required int jobId});
  Float32List detectSpeech(int vad, Float32List samples, {required bool reset});
  void release(int handle); List<({int level, String line})> drainLog(int max); int get droppedLogLines; int get liveHandles; void close();
}
abstract interface class SpeechAbortCell { int get address; void abortThrough(int jobId); void close(); }   // main side; close = release
```

- **Abort and cell lifetime.** The main isolate creates the cell (refcount 1); the decode lane `borrowCell`s it
  (retain) and releases it in `onClose`, after its last `transcribe` has returned. **Job ids are assigned at
  dispatch**, monotonic per lane from 1; cancelling a pending request only dequeues it, and with at most one job in
  flight `abortThrough(J)` under the `≥` rule affects only job J. `abortLease(id)`, interim supersession and a
  request's `CancellationToken` act only on that lease's jobs. `ABORTED` maps to `CancelledFailure()`. `dispose()`:
  `abortThrough(int32 max)`, `close()` both lanes, **await `exited`**, then release the main reference.
- **Decode queue.** One job in flight per lane. Per lease, a new interim replaces that lease's pending interim. A
  committed request preempts an in-flight interim of **any** lease; interims are disposable. Committed requests are
  FIFO across leases and never dropped.
- **Samples.** Sent as `TransferableTypedData`; `1 ≤ n ≤ maxDecodeSamples`, otherwise `ValidationFailure`. Input is
  zero-padded to `minDecodeSamples`, and results are **clamped to the original count**: pieces starting at or beyond
  the original end are dropped. Pieces are grouped by `SpeechPieceText.group`; text is decoded with
  `utf8.decode(allowMalformed: true)`.
- **Load.** The lane prechecks size and the 48-byte header (`SpeechModelHeader`) → `CorruptionFailure` or
  `ProviderFailure(speechModelMissing)`; `loadModel` runs and the shim hashes before parsing; `shape` must equal the
  catalogue, otherwise the model is closed and the call fails with `CorruptionFailure`. A load cannot be interrupted;
  a cancelled load waits, frees and returns `CancelledFailure`.
- **Logs and probe.** Shim minimum level WARN; after each command a lane emits at most `logLinesPerDrain` lines of at
  most `logLineChars`, plus a suppressed-count line, logged on the main isolate as `warn` or `error` with tag
  `'speech'`. No transcript, prompt or audio text is ever logged. `probe()` is a one-shot `runIsolate` reading CPU
  and memory facts; it never starts lanes. The crash file `<private>/speech/crash.log` is diagnostic only; its line
  count is logged at start.

```text
idle → starting → ready → loading → loaded ⇄ busy
loading --fail--> ready
loaded --unload--> unloading → ready
any --lane exit--> failed --next load--> starting   (≤ maxWorkerRestarts per host session)
any --dispose--> disposed
```

An unexpected lane exit fails pending requests with `speechEngineStopped()`. The web engine is in §30.4.8.

**Device probe, quality and selection.**

```dart
abstract interface class SpeechDeviceProbe { factory SpeechDeviceProbe.platform({required SpeechEngine engine, required PowerSource power});
  factory SpeechDeviceProbe.fake(SpeechDeviceProfile profile); Future<SpeechDeviceProfile> read(); }
final class SpeechDeviceProfile { /* runtime, platform, isWeb, isMobile, charging, batteryPercent, batterySaver */ }
enum SpeechQuality { auto, fast, accurate; static SpeechQuality parse(String wire); }
final Provider<SpeechQuality> speechQualityProvider;      // default auto; main overrides from settings (task 126)
final Provider<String> speechLanguageProvider;            // default AppConstants.defaultLanguage; main overrides from voiceLanguageProvider (task 120 only)
enum SpeechVerdict { ready, engineMissing, unsupportedDevice, modelMissing, lowMemory, languageUnsupported }
final class SpeechSelection { /* model, vad, threads, language, interim profile, committed profile, reason */ }
final class SpeechAvailability { /* verdict, selection?, failure?, reason */ }
abstract final class SpeechModelSelector {
  static SpeechAvailability choose({required SpeechDeviceProfile device, required SpeechQuality quality, required List<SpeechModelStatus> inventory,
      required String languageTag, Set<String> suspectModelIds = const <String>{}});
  static bool fits(SpeechModelEntry entry, SpeechDeviceProfile device);
}
```

Selector rules, in order; every number is an `AppConstants.speechEngine` field (§30.4.3):

1. **engineMissing:** `!available` with reason `platform`, `library` or `abi`, or the ABI is not 1.
2. **unsupportedDevice:** `!available` with reason `cpu`, `engineNotBuilt` or `simd`; io and `!is64Bit`;
   `totalMemory < minTotalMemoryBytes` (1.5 GiB) or web `deviceMemory < 2`; or `logicalCores < 2`.
3. **languageUnsupported:** `whisperLanguageFor(tag) == null`.
4. **modelMissing:** VAD or tiny is absent or damaged.
5. **Tier.** `powerOk = charging || (!saver && (percent == null || percent ≥ 30))`. **fast:** tiny. **auto:**
   desktop base when memory ≥ 3 GiB (unknown counts as yes), performance cores (or logical/2) ≥ 4 and powerOk,
   otherwise tiny; web base only with mt threads and `deviceMemory ≥ 4`, otherwise tiny; mobile **tiny** until task
   131 records device evidence. **accurate:** desktop small when imported, memory ≥ 6 GiB, cores ≥ 6 and powerOk,
   otherwise base; mobile base when it fits and powerOk, otherwise tiny; web base under the auto-web conditions.
6. **Fit.** Step down while `available != null && memoryEstimate × 125/100 > available`, skipping suspect models; if
   tiny still does not fit, the verdict is **lowMemory**.
7. **Threads.** Desktop `clamp(logical ~/ 2, 2, 8)`; mobile `clamp(performance ?? (logical ≥ 8 ? 4 : logical ~/ 2),
   2, 4)`; `!powerOk || saver` → `min(t, 2)`; web mt `clamp(hc − 1, 1, 4)`; web st 1.
8. **Profiles.** Interim: `bestOf 1`, `temperatureStep 0`, `singleSegment true`, `timestamps false`,
   `maxPieces 96`, `audioContextPad 64`. Committed, on every device: `bestOf 1` (greedy) with `temperatureStep 0.2`
   fallback, `timestamps true`, and the encoder context sized to the utterance, `audioContextPad 128` over a floor of
   `minAudioContext 896` frames (17.9 s; `committedAudioContextPad`, `committedMinAudioContext`), and its length
   bounded: whisper's `max_tokens` is `ceil(seconds × committedPiecesPerSecond) + committedMinPieces` (10 per second
   plus 24) of the audio sent, at least `minDecodeSamples` (1 s) on native and web alike
   (`SpeechDecodeProfile.maxPiecesFor`, never more than a set `maxPieces`). From about 19.6 s it exceeds whisper's
   own 220-token window limit and changes nothing. Mobile **dictation** finals for utterances under 10 s use `mobileDictationCommittedPad` (256)
   with no floor, which task 131's WER gate can revert; they keep the length bound. Thresholds 0.6 / −1.0 / 2.4.
   `no_context = 1` always, and never `n_max_text_ctx = 0`.

   *Decision (2026-10-05, i7-1165G7, 4 cores, otherwise idle; tasks 117 and 118 verification).* The full 30 s
   context made every final cost a full encode (tiny p90 1.6 s, base 4.0 s over jfk × 6), so finals are sized. A
   context sized by a pad alone is not safe: with 64, 128 or 256 frames past the audio, tiny and base looped, invented
   words ("Episden", "hobbit", "I'm going to get") or dropped up to 35 of 138 words, because whisper, trained on 30 s
   windows, misbehaves when its context ends soon after the speech. With a floor of 768 tiny still heard "ask not" as
   one word; floors of 896 and 1024 kept every word with both models, and 896 is the cheaper. A second candidate
   (`bestOf 2`) changed no word in the same measurements and only added compute. Base cannot finalise within
   1000 ms on this 4-core machine at any context that keeps every word, so `speechBudgets` holds a finalize budget per
   model (§30.4.3) rather than `auto` falling back to tiny below a core threshold: base heard jfk × 6 with no
   substitution where tiny misheard "ask" six to nine times, its drafts still appear within `firstPartialCompute`,
   and its finals land within 2 s. `auto` therefore keeps choosing base where rule 5 allows it. The review's 16
   runs support the choice: base had no word edit in any run, and tiny, whose fallback finals cost 1.1–12.7 s, was
   not reliably faster at p90 (tiny 652–4404 ms, base 1239–3097 ms; §30.4.3).

   *Decision (2026-10-05, same machine; task 118 verification).* Finals are bounded by length. Unbounded, a final
   that looped ran every temperature fallback round to whisper's 220-token window limit and cost up to 12.7 s;
   English speech runs at 3 to 4 pieces a second, so there 10 a second plus 24 only stops a decode that loops or
   invents text, and `max_tokens` counts per decode pass: at the bound this whisper.cpp allows only a timestamp or
   the end, and seeks on from the pass's last timestamp, so a bounded pass does not drop the rest of the utterance.
   Open risk: whisper's tokenizer spends about 3 pieces a word on Swahili and Arabic (1.1–1.6 on English, French,
   Spanish and Portuguese), so their fast speech, about 7–10 pieces a second, nears the bound; it is measured on
   English (jfk) only. Over 25 jfk × 6 runs per model the bound kept 0 deleted words and cut tiny's slowest final
   from 12.7 s to 8.2 s: it shortens runaway finals but does not remove them (cause not yet traced; a pass that
   meets the bound is followed by further passes, each with its own fallback rounds). A tighter 6 a second plus 16 deleted a word, and a coarser `temperatureStep`
   of 0.4 deleted a word in 3 of 8 runs and inserted up to 7, so both were rejected and the step stays 0.2.

**Host, lease and readiness.**

```dart
final class SpeechEngineHost {
  SpeechEngineHost({required SpeechEngine engine, required SpeechModelStore store, required SpeechDeviceProbe probe,
    required SpeechQuality Function() quality, required Stream<AppLifecycleState> lifecycle, required Stream<void> memoryPressure,
    BlobStore? attempts, Clock clock = const SystemClock(), Future<void> Function(Duration)? delay, Logger? logger});
  Future<SpeechAvailability> availability({required String languageTag});   // never loads
  Future<Result<SpeechEngineLease>> acquire({required String languageTag, CancellationToken? cancel});
  Future<void> warmUp({required String languageTag}); int get activeLeases; Stream<void> get changes; Future<void> dispose();
}
abstract interface class SpeechEngineLease {
  factory SpeechEngineLease.over(SpeechEngine engine, SpeechSelection selection, {required int leaseId, required SpeechVadHandle vad});
  SpeechSelection get selection; String get modelId; int get vadFrameSamples;
  Future<Result<SpeechDecodeResult>> decode(SpeechDecodeRequest request, {CancellationToken? cancel});
  Future<Result<SpeechVadResult>> detectSpeech(Float32List samples, {bool resetState = false, CancellationToken? cancel});
  void abort();               // this lease only
  Future<void> release();     // idempotent; closes the lease's VAD handle
}
final class SpeechReadiness { /* verdict, selection?, reason?; static notReady; bool get ready */ }
final class SpeechReadinessNotifier extends Notifier<SpeechReadiness> { /* own file speech_readiness_notifier.dart */ }
final NotifierProvider<SpeechReadinessNotifier, SpeechReadiness> speechReadinessProvider;
```

- **Readiness.** `SpeechReadinessNotifier.build()` returns `notReady` with no `late final`, then refreshes
  asynchronously from `host.availability(languageTag: ref.watch(speechLanguageProvider))` and on `host.changes`.
- **Lease semantics.** One load serves many leases, and the model is never swapped while a lease is held. Each lease
  owns its own VAD handle; `abort()` and supersession reach only that lease's jobs; `release()` is idempotent.
- **Idle release.** After the last lease is released the host waits through the injected `delay`, then unloads:
  `idleRelease` (2 min) on mobile on battery, `idleReleaseExtended` (10 min) on desktop or while charging. With no
  lease held, `paused`, `hidden` or memory pressure release at once; `inactive` is ignored.
- **Load fallback.** `ProviderFailure` on base → retry once with tiny; tiny fails → `engineMissing` for the host
  session. `CorruptionFailure` on an Android extracted copy → `store.reextract(entry)` once, then retry; otherwise, or
  on a second failure → `store.markDamaged` and `speechModelDamaged`.
- **Crash-loop marker** (single owner). Before a load, write `BlobStore.platform('speech')['load-attempt'] =
  {modelId, appVersion, attempts, startedAtMs}`; delete it once the load returns, successful or not (only a load that
  ends the process leaves it). At start, a surviving marker for the current app version increments `attempts` and is
  removed, the count travelling with the next marker for that model; with `attempts ≥ maxLoadAttempts` (2) that model
  joins `suspectModelIds`.
- **Browser threads.** `probe()` reports `webThreads` only while the decode worker can run threaded: once it has
  fallen back to the single-thread build, it reports false. After loading a model larger than tiny in a browser, the
  host reads the probe again and loads the new choice when it differs.
- **Wiring.** `speechDeviceProbeProvider` defaults to the platform probe with unknown power, and
  `speechEngineHostProvider` to a host over the engine, store and probe providers with no marker store; `main`
  overrides the engine (`SpeechEngine.platform()`), the store, the probe (with `PowerSource()`) and the host (with
  `BlobStore.platform('speech')`). `PowerSource.read()` returns `({bool charging, int? percent, bool saver})` and
  `LifecycleObserver.memoryPressure` forwards `didHaveMemoryPressure`. After the first frame `main` calls
  `recordSpeechCrashes('<private>/speech/crash.log')`, which arms `tw_set_crash_file` and logs the file's line count.

**Models.** `core/constants/speech_assets.dart` (`SpeechAssets`: `folder`, `manifest`, `tinyModel`, `baseModel`,
`vadModel` under `assets/speech/`). `SpeechModelEntry` (pure Dart): `id`, `kind`, `fileName`, `asset?`, `bytes`,
`sha256`, `sourceUrl` pinned to a revision (`https://huggingface.co/<repo>/resolve/<commit>/<file>`), header facts,
`memoryEstimateBytes`, `tier`, `webAllowed`. `SpeechModelCatalogue` exposes `all`, `tiny`, `base`, `small`, `vad`,
`byId` and `matchImport(bytes, sha256)`. Repositories: `ggerganov/whisper.cpp` for the whisper models and
`ggml-org/whisper-vad` for Silero; each commit is resolved once and pinned. Header facts are pinned by native shape
tests. Memory estimates are the peak RSS a loaded model adds while decoding jfk with the desktop committed profile,
worker isolates included, measured on the Windows reference machine (task 128) and rounded up to 8 MiB (1 MiB for
Silero): tiny 126.4, base 166.2, small 349.7 and Silero 8.3 MiB.

| id | file | bytes | sha256 | header (vocab/state/aL/tL/mels/ftype%1000) | mem est. | packaging |
| --- | --- | --- | --- | --- | --- | --- |
| `tiny-q5_1` | ggml-tiny-q5_1.bin | 32,152,673 | 818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7 | 51865/384/4/4/80/9 | 128 MiB | bundled |
| `base-q5_1` | ggml-base-q5_1.bin | 59,707,625 | 422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898 | 51865/512/6/6/80/9 | 168 MiB | bundled |
| `small-q5_1` | ggml-small-q5_1.bin | 190,085,487 | ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb | 51865/768/12/12/80/9 | 352 MiB | import only, `webAllowed: false` |
| `silero-v6.2.0` | ggml-silero-v6.2.0.bin | 885,098 | 2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987 | magic only | 9 MiB | bundled (vad) |

`frontend/tool/speech_models.dart`: `--fetch [--only <id>] [--from <dir>]` streams each bundled entry into
`assets/speech/<file>.part`, hashing while writing, checks size and sha, renames, skips files already correct and
writes a deterministic `manifest.json`; `--check` (no network), `--verify <file>` and
`--import-model <id> --out <dir>` print one `path:0: problem` line per violation and exit 1 on any
(`List<String> checkSpeechModels(Directory frontendRoot)`).

| Platform | Model location |
| --- | --- |
| Windows/Linux | `<exeDir>/data/flutter_assets/<key>` (read in place) |
| macOS | `<exeDir>/../Frameworks/App.framework/Resources/flutter_assets/<key>` |
| iOS | `<exeDir>/Frameworks/App.framework/flutter_assets/<key>` |
| Android | `<support>/Tapture/speech/bundled/<sha256[0..12]>-<file>` |
| Imported (native) | `<support>/Tapture/speech/imported/<file>` |
| Web | worker OPFS `whisper-models/<id>-<sha12>` |

Android extraction streams the uncompressed asset (`noCompress "bin"`) into `<path>.part`, fsyncs and renames; it is
keyed by the sha prefix, so a catalogue change extracts afresh. At store start, `bundled/*` files whose prefix is not
in the catalogue are removed with `discardDerivedFile` (§8.1 rule 8); `reextract(entry)` discards the copy and
extracts again. `rootBundle.load` is never used. `verifySpeechModelFile(path, entry, {cancel, onProgress})` checks,
in order, size, the 48-byte header (magic `0x67676d6c` LE, the 11 hparams with `ftype % 1000`, magic only for VAD)
and `HashingService.sha256OfFile`; loads do only the size and header precheck in Dart, and the shim hashes.

```dart
abstract interface class SpeechModelStore {
  factory SpeechModelStore.platform({required StorageRoot privateRoot, required BundledAssets assets, SpeechEngine? webEngine});
  const factory SpeechModelStore.empty();
  factory SpeechModelStore.fake(Map<String, SpeechModelStatus> statuses, {Failure? importFailure});
  bool get canImport;
  Future<Result<List<SpeechModelStatus>>> inventory();          // cheap: no hashing
  Future<Result<SpeechModelSource>> locate(SpeechModelEntry entry, {CancellationToken? cancel});
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry);   // Android bundled only; else returns locate
  Future<Result<void>> verify(SpeechModelSource source, {CancellationToken? cancel, void Function(double)? onProgress});
  Future<Result<SpeechModelEntry>> import(PickedDocument picked, {CancellationToken? cancel, void Function(double)? onProgress});
  Future<Result<void>> remove(SpeechModelEntry entry);           // imported only; discardDerivedFile
  void markDamaged(String modelId);
}
final class SpeechModelSource { /* entry + exactly one of path | url */ }
final class SpeechModelStatus { /* entry, present, imported, damaged */ }
final Provider<SpeechModelStore> speechModelStoreProvider;      // default .empty()
```

Import: `DocumentPicker.pick(extensions: ['bin'], maxBytes: <largest importable>)`; size, header and hash, then
`matchImport`; `FileWriter(storageRoot: StorageRoot.private()).copyIn(..., 'speech/imported/<file>')`;
`discardPickedCopy`. An unknown file gives `ValidationFailure(speechImportUnknown)`; a cancel leaves no `.part`.

#### 30.4.3 Constants and budgets

All live in `frontend/lib/core/constants/app_constants.dart`; durations below are shorthand for `Duration` fields.

**`speechEngine`:**

| Field | Value | Field | Value |
| --- | --- | --- | --- |
| `workerStart` | 10 s | `workerCloseGrace` | 5 s |
| `idleRelease` | 2 min | `idleReleaseExtended` | 10 min |
| `minTotalMemoryBytes` | 1.5 GiB | `webMinDeviceMemoryGiB` | 2 |
| `webBaseDeviceMemoryGiB` | 4 | `balancedMemoryBytes` | 3 GiB |
| `accurateMemoryBytes` | 6 GiB | `balancedCores` | 4 |
| `accurateCores` | 6 | `memoryHeadroomPercent` | 125 |
| `lowBatteryPercent` | 30 | `mobileMaxThreads` | 4 |
| `desktopMaxThreads` | 8 | `saverThreads` | 2 |
| `webMaxThreads` | 4 | `maxDecodeSamples` | 30 × 16000 |
| `minDecodeSamples` | 16000 | `interimMaxPieces` | 96 |
| `committedPiecesPerSecond` | 10 | `committedMinPieces` | 24 |
| `interimAudioContextPad` | 64 | `reducedAudioContextPad` | 128 |
| `committedAudioContextPad` | 128 | `committedMinAudioContext` | 896 |
| `mobileDictationCommittedPad` | 256 | `mobileDictationShortUtterance` | 10 s |
| `encoderFramesPerSecond` | 50 | `maxAudioContext` | 1500 |
| `noSpeechThreshold` | 0.6 | `logprobThreshold` | −1.0 |
| `entropyThreshold` | 2.4 | `temperatureStep` | 0.2 |
| `logLineChars` | 160 | `logLinesPerDrain` | 8 |
| `maxWorkerRestarts` | 2 | `maxLoadAttempts` | 2 |

**`speechPipeline`:**

| Field | Value | Field | Value |
| --- | --- | --- | --- |
| `vadOnThreshold` | 0.5 | `vadOffThreshold` | 0.35 |
| `vadBatchWindows` | 4 | `minSpeech` | 250 ms |
| `onsetGapTolerance` | 96 ms | `preRoll` | 320 ms |
| `endSilence` | 800 ms | `postRoll` | 192 ms |
| `softMaxUtterance` | 20 s | `maxUtterance` | 25 s |
| `cutSearchWindow` | 3 s | `seamOverlap` | 1 s |
| `seamTolerance` | 200 ms | `noiseFloorWindow` | 5 s |
| `energyGateMarginDb` | 3 | `energyGateCeilingDbfs` | −60 |
| `interimMinAudio` | 800 ms | `interimMinStep` | 600 ms |
| `interimMaxStep` | 3 s | `interimMaxDutyDesktop` | 0.6 |
| `interimMaxDutyMobile` | 0.3 | `mobileInterimMaxUtterance` | 10 s |
| `interimEwmaAlpha` | 0.3 | `interimRepeatWords` | 3 |
| `carryPrompt` | false | `promptCarryChars` | 200 |
| `promptCarryMinUtterance` | 2 s | `promptCarryMinDbfs` | −55 |
| `promptResetGap` | 60 s | `hallucinationEnergyDbfs` | −55 |
| `hallucinationSpeechRatio` | 0.3 | `hallucinationLogProb` | −0.8 |
| `edgeTrimTolerance` | 96 ms | | |
| `loopMinRepeatsPhrase` | 3 | `loopMinRepeatsWord` | 4 |
| `loopMaxNgram` | 6 | `minSecondsPerWord` | 0.12 |
| `loopWordsPerSecond` | 4 | `ringDuration` | 30 s |
| `finalBacklogInterimsOff` | 10 s | `finalBacklogReducedContext` | 30 s |
| `finalBacklogRecover` | 3 s | `engineBehindNoticeInterval` | 30 s |
| `maxConsecutiveDecodeFailures` | 3 | `resamplerZeroCrossings` | 16 |
| `resamplerKaiserBeta` | 7.0 | `resamplerCutoffRatio` | 0.9 |
| `resamplerMaxPhases` | 512 | | |

**`speechSession`:** `fallbackCaptureRates` [48000, 44100], `wavFlushInterval` 5 s, `webChunkDuration` 5 s,
`maxSessionDuration` 4 h, `webMaxSessionDuration` 30 min, `storageCheckInterval` 60 s, `adoptLockBudget` 100 ms.

**`speechBudgets`** (desktop; recalibrated by benchmarks; §59):

| Field | Value | Field | Value |
| --- | --- | --- | --- |
| `tinyLoad` | 2 s (includes in-shim hash) | `baseLoad` | 4 s |
| `tinyRealTime` | 0.35 | `baseRealTime` | 0.5 |
| `abortLatencyDesktop` | 500 ms | `vadSecond` | 60 ms |
| `tinyPeakRssBytes` | 192 MiB | `basePeakRssBytes` | 256 MiB |
| `retainedRssBytes` | 32 MiB | `pipelinePerAudioSecond` | 15 ms |
| `firstPartialCompute` | 1500 ms | `tinyFinalizeCompute` | 1000 ms |
| `baseFinalizeCompute` | 2000 ms | `uiDrift` | 32 ms |
| `longSessionPeakRssBytes` | 64 MiB | `longSessionRetainedRssBytes` | 48 MiB |

Benchmarks check medians and record the processor load, because other work on the machine adds noise; `uiDrift`
bounds how much later than the idle median (the system timer's granularity, about 15.6 ms on Windows) the
99th-percentile tick of a 16 ms timer on the UI isolate fires during a 30 s decode (maxima follow the machine's
load: up to 188 ms with the engine idle). Task 128 recalibration (2026-10-05, i7-1165G7, 29–100% busy): peak RSS
budgets tightened to about 1.5× the measured peaks; `longSessionRetainedRssBytes` raised from 8 MiB because five
identical long sessions kept the live heap after a forced collection flat (121.3–122.2 MiB) while RSS retention,
garbage not yet collected, ranged from −38 to 40.5 MiB. The real-time factors are not loosened. With the committed
desktop profile of that time (best of 2, temperature fallback, full encoder context) they were met with the machine
29–60% busy (tiny 0.16–0.17, base 0.31–0.38) and missed at 66–100% (tiny 0.30–0.46, base 0.51–0.77).

The single 1000 ms `finalizeCompute` became a budget per model on 2026-10-05 (tasks 117 and 118, machine otherwise
idle). With finals sized over a floor (§30.4.2 rule 8) the live jfk × 6 host mirror finalises at p90 within the
original 1000 ms with tiny, which `tinyFinalizeCompute` keeps. Base needs more: the cheapest context that kept every
word with base still cost 1.1–2.2 s per final, against 3.1–4.3 s with the full context it replaces, so
`baseFinalizeCompute` is 2000 ms. The measured values are in the task 118 verification notes; the choice between
this and `auto` choosing tiny on four cores is recorded under §30.4.2 rule 8. The independent review's 16 runs on
the same machine (2026-10-05, 18–52% busy before each run) did not confirm the tiny figure: most tiny finals took
0.5–0.8 s, but one to three temperature-fallback finals per run (1.1–12.7 s) put its p90 above 1000 ms in 14 of 16
runs, and base met 2000 ms in 9 of 16. With finals bounded by length (§30.4.2 rule 8; 25 runs per model, every
run 0 deleted words) tiny's p90 met 1000 ms in 4 of 25 runs and base's 2000 ms in 14 of 25. The p90 of 13 finals is
the second-slowest, and one or two tiny finals per run still cost 1.5–8.2 s, even at 17–30% load (the review's 8
runs: tiny p90 1233–4187 ms, none within 1000; base 1747–2905 ms, 6 within 2000); with fallback turned off (two
diagnostic runs) one to three tiny finals per run still took 1.0–1.3 s. Background load roughly doubles a normal
final's compute. No tiny budget is yet backed by the evidence; the budgets are unchanged pending a decision
(task 118).
In headless Chrome 154 on the same loaded machine (task 112 harness, tiny, jfk, three alternating runs), the
threaded build with 4 threads was no faster than the single-thread one: real-time factor medians 1.88 and 1.85.

**`transcripts`:** `partialInterval` 250 ms, `dictationFinalize` 12 s, `paragraphGap` 1500 ms,
`paragraphMaxSegments` 6, `paragraphMaxChars` 600, `previewChars` 120, `historyPage` `listPageSize`,
`segmentWriteBudget` 20 ms, `historyQueryBudget` 150 ms, `benchmarkSegments` 5000, `benchmarkTranscripts` 2000.

Mobile device budgets come from `frontend/tool/devices.yaml` (task 131).

#### 30.4.4 Error mapping

Only existing `Failure` variants are used; builders live in `core/speech/speech_failures.dart`.

| Condition | Failure | Copy |
| --- | --- | --- |
| `libraryMissing`, `abiMismatch`, `unsupportedPlatform`, worker never ready, `fetch_failed`, `cross_origin` | `ProviderFailure(unavailable)` | `speechUnavailable` |
| `unsupportedCpu`, `engineNotBuilt`, `no_simd`, verdict `unsupportedDevice` | `ProviderFailure(unavailable)` | `speechDeviceUnsupported` |
| Model file absent, `fileOpen` | `ProviderFailure(unavailable)` | `speechModelMissing` / `speechModelMissingRecovery` |
| Dart size/header precheck, `modelInvalid`, `modelMismatch`, shape mismatch | `CorruptionFailure` | `speechModelDamaged` / `speechModelDamagedRecovery` |
| `modelLoad`, `outOfMemory`, verdict `lowMemory` | `ProviderFailure(unavailable)` | `speechLowMemory` / `speechLowMemoryRecovery` |
| Extraction `nospace` | `StorageFailure` | `failureFreeSomeSpaceThenTryAgain` |
| Extraction `io`, OPFS `storage` | `StorageFailure` | existing store copy |
| `aborted`, cancel, supersession | `CancelledFailure()` | — |
| `inference`, `internal`, `busy` | `ProviderFailure(unknown)` | `speechTranscriptionFailed`; the pipeline retries once, then skips (recorded as a gap) |
| `poisoned` | `ProviderFailure(unknown)` | `speechTranscriptionFailed`; the engine closes and reopens, then retries once |
| `invalidArgument`, `audioTooLong`, partial VAD frame, `''` or `'auto'` language | `ValidationFailure` (logged ERROR) | default |
| Verdict `languageUnsupported` | `ValidationFailure` | `speechLanguageUnsupported` |
| Lane exit, disposed engine | `ProviderFailure(unknown)` | `speechEngineStopped` |
| Unknown import | `ValidationFailure` | `speechImportUnknown` / `speechImportUnknownRecovery` |
| Platform route cannot stay on device | `NetworkFailure` | `dictationOfflineOnly` (existing) |

#### 30.4.5 Session state machine and durability

**Capture** (`core/audio`):

```dart
abstract interface class AudioCaptureService {
  factory AudioCaptureService({required FileWriter writer, required StorageRoot storageRoot, required MicrophoneAccess access,
      required MicrophoneArbiter arbiter, @visibleForTesting record.AudioRecorder Function()? recorderFactory}) = AudioCapturePlugin;
  const factory AudioCaptureService.unavailable();
  Future<Result<AudioCaptureSession>> start(AudioCaptureRequest request);
}
final Provider<AudioCaptureService> audioCaptureServiceProvider;   // default .unavailable()
final class AudioCaptureRequest { const AudioCaptureRequest({required MicrophoneOwner owner, String? relativePath /*null = memory only*/,
  Duration? maxDuration, VoidCallback? onPreempted}); }
abstract interface class AudioCaptureSession {
  Stream<PcmChunk> get chunks;            // contiguous; emitted only after the store append
  Stream<AudioCaptureEvent> get events;
  int get capturedSamples; PcmStore get store; CaptureFormat get format;
  Future<Result<void>> pause(); Future<Result<void>> resume();
  Future<Result<void>> checkpoint();      // io: patch header + flush(fsync); web: flush pending chunk
  Future<Result<AudioRecording?>> stop(); // publishes; the store stays readable (rebased onto the published file)
  Future<void> release();                 // closes the store; web deletes chunk keys; idempotent; required after stop
  Future<Result<String?>> abandon();      // header patched; staging kept byte-for-byte; returns staging path
}
final class PcmChunk { const PcmChunk(this.startSample, this.samples); }
abstract interface class PcmStore { int get length; Future<Result<Int16List>> read(int from, int to); }   // ring for recent audio, file/chunks otherwise
sealed class AudioCaptureEvent {}  // parts: CaptureLevel, CapturePaused{reason, atSample}, CaptureResumed, CaptureFailed, CaptureFormatChanged
enum CapturePauseReason { user, background, interruption, microphoneLost, permissionRevoked }
enum MicrophoneOwner { dictation, liveTranscription, fileRecorder }
```

- **Start:** arbiter claim; access; staging refused if `<path>.recording` or `<path>` exists, then a zero-length
  header; a new recorder; state and config listeners subscribed before starting;
  `startStream(pcm16bits, 16000, mono, audioInterruption: pause, androidConfig: voiceRecognition)`; a synchronous
  listen; fallback rates `[48000, 44100]`.
- **Bytes:** a 0–3-byte carry handles odd lengths, then downmix → `PcmResampler` → staging append → level meter →
  emit.
- **Staging:** io `<root>/<path>.recording`, one `RandomAccessFile`, `patchLengths` + `flush()` every
  `wavFlushInterval` and on every pause or checkpoint; web `BlobCaptureStaging`, one 5 s chunk per key plus a
  manifest.
- **Stop:** drain; flush the resampler tail; patch the header; close the writer handle and the store's read handle;
  `publishStagedTake` → `FileWriter.adoptStaged` (stream-hash the staged file outside the lock, fsync, then under
  `withWriteLock(dest.parent)` refuse an existing target and rename; `copyIn` across volumes), so no copy is made;
  `store.rebase(published)`; dispose the recorder and release the microphone lease. On web, publish streams the
  chunks through `BlobFileWriter`, and chunk keys remain until `release()`.
- **Recovery** (`StagedTakeRecovery`): a staging file whose header lengths match its size is adopted as-is;
  otherwise a repaired derivative is published and the raw `.recording` is kept (§8.1 rule 1).

**Session** (`core/speech`):

```dart
abstract interface class LiveTranscriptionService {
  factory LiveTranscriptionService({required AudioCaptureService capture, required SpeechEngineHost host, required LifecycleObserver lifecycle,
      required LeaveGuard leaveGuard, required StorageGuard storageGuard, AudioRecoveryService? recovery /*recoverAudio*/,
      StorageRoot? storageRoot, FileReader? reader /*transcribeRemaining reads the published take*/,
      @visibleForTesting Duration? sessionLimit, Logger? logger}) = _LiveTranscriptionService;
  const factory LiveTranscriptionService.unavailable();
  Future<Result<LiveTranscriptionSession>> start(LiveTranscriptionRequest request);
  Future<Result<AudioRecording?>> recoverAudio(String audioPath);
  Stream<LiveTranscriptionEvent> transcribeRemaining(String audioPath, {required List<(int, int)> gaps, required int fromSample,
      required int nextSegmentId, required String languageTag, required TranscriptSink sink});   // explicit user action; gaps first, then tail
  Future<void> dispose();
}
final Provider<LiveTranscriptionService> liveTranscriptionServiceProvider;   // default .unavailable(); main binds it
@visibleForTesting int get debugLiveTranscriptionSessions;
final class LiveTranscriptionRequest { const LiveTranscriptionRequest({required TranscriptionKind kind, required String languageTag,
  String? audioPath, TranscriptSink? sink, int nextSegmentId = 1, bool transcribe = true, bool interims = true,
  Duration? autoStopAfterSilence, Duration? maxDuration, VoidCallback? onPreempted}); }
abstract interface class LiveTranscriptionSession {
  Stream<LiveTranscriptionEvent> get events; LiveTranscriptionPhase get phase; CapturePauseReason? get pauseReason;
  Future<Result<void>> pause(); Future<Result<void>> resume();
  Future<Result<StoppedCapture>> stop();             // completes once the audio is published; transcript keeps draining (idempotent)
  Future<Result<LiveTranscriptionResult>> get done;  // after drain or skip; sink.finish has completed
  void skipRemaining(); Future<Result<CancelledTranscription>> cancel();
}
final class StoppedCapture { AudioRecording? audio; Duration captured; StopReason reason; }
final class LiveTranscriptionResult { List<TranscriptSegment> segments; String languageTag; String? modelId; Duration captured;
  bool transcriptComplete; int coveredToSample; List<FinishedUtterance> unsaved; StopReason stopReason; }
enum LiveTranscriptionPhase { preparing, listening, paused, stopping, draining, completed, cancelled, failed }
enum StopReason { user, silence, maxDuration, sessionLimit, storage, exit, captureFailed, preempted }
sealed class LiveTranscriptionEvent {}  // TranscriptionStateChanged · InputLevelChanged · InterimTranscript{utteranceId, startSample, stable, tentative}
  // · SegmentFinalized{segment, durable} · UtteranceFinalized · TranscriptionDraining{pending} · TranscriptionWarning{kind, lag, cause} · TranscriptionFailed
enum TranscriptionWarningKind { transcriptionUnavailable, engineBehind, utteranceSkipped, transcriptUnsaved, storageLow, storageStop, sessionLimit }
```

```text
start: preparing --(arbiter, permission, staging, stream)--> listening   [engine acquire in parallel]
       capture fails --> failed (nothing written; lease released)
       engine acquire fails: longForm → listening + Warning(transcriptionUnavailable) (record-only, Rule 3); dictation → failed
listening --pause()--> paused(user); --lifecycle paused|hidden--> paused(background)
listening --CapturePaused(interruption|microphoneLost|permissionRevoked)--> paused(that)
paused --resume()--> isGranted ? listening : paused(permissionRevoked) + PermissionFailure   (never auto-resumes)
listening|paused --stop()|auto-stop--> stopping: capture.stop() publishes → stop() completes → draining
draining: pipeline.finish(drain:true) --drained|skipRemaining--> sink.finish(outcome) → capture.release() → completed (done)
publish failure → failed(StorageFailure; staging kept)
any active --cancel()--> cancelled: pipeline.abort(); capture.abandon(); release()
detached: stop() without awaiting the drain
```

- **Durability.** The service holds **one** `lifecycle.addPauseFlush(_checkpointAll)` (and one exit check) while
  any session is active: registered with the first session and removed when the last one ends.
  `_checkpointAll` pauses every listening long-form session as `background` and awaits, for each,
  `capture.checkpoint()` and `pipeline.sinkIdle`; a dictation session stops instead.
  `LifecycleObserver.handle(paused|hidden)` therefore returns only after the take's header is patched and fsynced and
  the last transcript write has landed. `LifecycleObserver` stays the only `WidgetsBindingObserver`; its pause
  flushes run after `onPauseFlush`.
- **Draining ownership.** The kept-alive service owns draining sessions, independent of any feature controller, so
  leaving a page never loses a transcript; on service dispose it aborts the drains and calls
  `sink.finish(complete:false)`. Saving never waits on transcription (Rule 3).
- **Lifecycle rule.** `pausesCapture(s) => s == paused || s == hidden`; `inactive` is ignored and `detached` stops.
- **Dictation sessions:** background stops the session; `autoStopAfterSilence = AppConstants.dictation.pauseFor`;
  `maxDuration = AppConstants.dictation.listenFor`; memory-only; preempted by evidence owners.
- **Long-form guards:** `leaveGuard.hold(session)`; `addExitCheck` checkpoints all, marks the sessions for recovery
  and returns true — it never drains and never publishes, because recovery adopts the checkpointed take.
- **Storage and caps:** `StorageGuard.admitCapture()` at start; a check every 60 s of audio, stopping with
  `storageStop` or warning with `storageLow`; session caps of 4 h, or 30 min on web. Only a volume read as critical
  refuses a start; one that cannot be read never blocks capture (Rule 3).
- **Remaining transcription:** `transcribeRemaining` runs the same pipeline from each gap's first sample, then
  from `fromSample`, over the published take (read in place, or whole through `FileReader` in a browser), with ids
  continuing from `nextSegmentId`. A gap decoded to its end is closed by an empty utterance over the whole gap; the
  first range that cannot be finished ends the run, and the sink is always finished.
- **Decode failures:** retry once, then skip with a recorded gap and `utteranceSkipped`; after 3 consecutive
  failures the session goes record-only.
- **Logging:** tag `'speech'` (`'audio'` for capture): start, pause and resume reasons, warnings, failure types, and
  a stop summary (utterances, segments, dropped, collapsed, gated ratio, mean and p90 compute, RTF, ladder). **Never
  any text.** Counter `debugLiveTranscriptionSessions`; wired in `main.dart`, production only.
- **Interruptions and permission.** On mobile, revoking the microphone permission in system settings kills the
  process; that case is recovered through `TranscriptRecovery` and `StagedTakeRecovery`.

**Dictation** (§24). `WhisperSttService implements SttService` returns a lazy single-subscription stream: one empty
partial when the microphone opens; partials are `committed + stable` only (tentative words are never emitted), and
each final is aligned to the already-emitted stable prefix by `WordSequence.key` (drafts carry no word times, so a
final that diverges inside it is cut after the last word both agree on plus the shown words after it), so emitted
words never change, and a later utterance is shown only once every earlier one is final; partials are throttled to
`transcripts.partialInterval` with a trailing emit and never repeat; exactly one final follows, with language and
mean confidence. Heard words are never dropped: an error after words still
yields a final, `stop()` is bounded by `dictationFinalize`, and a new listen hands the previous words over; `cancel()`
drops unfinal words. Errors are raised only when nothing was heard: permission →
`PermissionFailure(dictationNoMicrophone)`, microphone busy → `ValidationFailure(microphoneBusy)`, silence →
`CancelledFailure(dictationNothingHeard)`, engine failures pass through, anything else `dictationFailed`.

`RoutedSttService({SttService Function()? whisper, SttService? platform, required PlatformRecogniserPolicy policy,
required bool Function() whisperReady, required MicrophoneArbiter arbiter})` chooses per listen: Whisper when ready;
else, if `platform != null && await policy.keepsSpeechOnDevice()`, `platform.listen(..., onDeviceOnly: true)` under a
`MicrophoneOwner.dictation` claim; else `NetworkFailure(dictationOfflineOnly)`. `PlatformRecogniserPolicy.platform()`
answers Android `onDeviceRecognitionAvailable` on `com.tapture.app/files` (`SDK_INT >= 31 &&
isOnDeviceRecognitionAvailable`), iOS/macOS true (the plugin sets `requiresOnDeviceRecognition`), Windows, Linux and
web false. `main` binds a platform recogniser only on Android, iOS and macOS, so on Windows, Linux and the web a
field offers the microphone only once Whisper is ready.

#### 30.4.6 Transcript persistence

Schema 32 (`core/db/tables/transcripts.dart` + part `transcript_segments.dart`, `MergeColumns`).

| `transcripts` column | Notes |
| --- | --- |
| `projectId` | write-once |
| `ownerKind` | `capture`/`meeting`/`standalone`; write-once |
| `ownerId?` | |
| `attachmentId?` | set once |
| `audioPath` | write-once |
| `title` | audited on rename |
| `languageTag`, `modelId` | |
| `status` | `live`/`complete`/`interrupted` |
| `startedAt` | write-once |
| `endedAt?`, `durationMs?` | |
| `coveredMs` | default 0: the highest sample processed, decoded or skipped |
| `skippedRanges` | TEXT JSON `[[fromMs,toMs],…]`, default `'[]'` |
| `textEdited?`, `editedAt?` | the edit beside the raw segments |

Indexes `(projectId, startedAt)`, `(attachmentId)`, `(ownerKind, ownerId)`. **`transcript_segments`:**
`transcriptId`, `seq` (1-based insertion order = `TranscriptSegment.id`), `startMs`, `endMs`, `textRaw` (written
once, at insert), `confidence?`; unique index `(transcriptId, seq)`. **Reading order** is `ORDER BY start_ms, seq`,
so segments that fill a gap later slot into time order.

Helpers, each returning `Result`:

- `insertTranscript`; `updateTranscript` strips the write-once columns and refuses a different `attachmentId`.
- `appendTranscriptUtterance`, in one transaction: `seq == count+1` → insert; `seq ≤ count` with identical text →
  ignore; anything else → `StorageFailure(transcriptSegmentOutOfOrder)`; a skipped utterance adds its range to
  `skippedRanges`; an utterance inside a recorded range removes that range; `coveredMs = max(coveredMs,
  toSample/16)`.
- `writeTranscriptEdit`: `text_edited`, `edited_at` and an `appendAudit` row with field `transcript`.
- `renameTranscript`: `title` and an `appendAudit` row with field `title`.

`migrateToV32` uses guarded create, then `RecordSchema.ensure`; `kDestructiveSteps` stays empty. Version-vector
triggers arrive with `migrateToV33` (bundles, merge and export). **Search:** `requiredTables` adds `transcripts`,
`transcript_segments` and `attachment_owners`; a record's search body adds raw segment text in reading order, then
`text_edited`, of non-live transcripts linked through `attachment_owners(owner_type='record')`, excluding
tombstones. Triggers: `transcripts_search_ai`, `_au` (`UPDATE OF status, attachment_id, text_edited`) and `_ad`, plus
`attachment_owners_search_ai` and `_ad`; segment inserts fire no trigger.

Domain types (pure, one file each): `TranscriptOwnerKind`, `TranscriptStatus`, `TranscriptLine`, `TranscriptGap`,
`TranscriptSummary` (with `coveredMs`, `gaps`, `remaining`), `Transcript` (`rawText`, `displayText`),
`TranscriptStart` (record) and `TranscriptParagraphs`.

```dart
abstract interface class TranscriptRepository {
  Future<Result<TranscriptSummary>> begin(TranscriptStart start);
  Future<Result<void>> appendUtterance(String transcriptId, FinishedUtterance utterance);
  TranscriptSink sinkFor(String transcriptId);     // finish → complete / markInterrupted
  Future<Result<void>> linkAttachment(String id, String attachmentId);
  Future<Result<TranscriptSummary>> complete(String id, {required Duration duration, required String languageTag, String? modelId});
  Future<Result<TranscriptSummary>> markInterrupted(String id, {Duration? duration});
  Future<Result<String>> fileStandaloneAudio(String id, AudioRecording audio);
  Future<Result<void>> discard(String id); Future<Result<TranscriptSummary>> rename(String id, String title, {String? operator});
  Future<Result<Transcript>> saveEdit(String id, String text, {String? operator}); Future<Result<Transcript>> clearEdit(String id, {String? operator});
  Future<Result<void>> reopenForRemaining(String id);   // complete|interrupted → live for transcribeRemaining; restored on finish
  Future<Result<Transcript?>> read(String id); Stream<Transcript?> watch(String id);
  Stream<List<TranscriptSummary>> watchProject(String? projectId, {String query = '', int limit});
  Stream<List<TranscriptSummary>> watchRecord(String recordId); Stream<List<TranscriptSummary>> watchMeeting(String meetingId);
  Future<Result<TranscriptSummary?>> completedForAttachment(String attachmentId);
  Future<Result<List<TranscriptSummary>>> stale();
}
```

- **Recovery.** `TranscriptRecovery.run` executes at boot, after merge recovery. Each stale `live` row: `capture` →
  `markInterrupted`; `meeting`/`standalone` → `recoverAudio` (adopt or repair), file the audio, then
  `markInterrupted`. It never deletes a file and logs counts only.
- **Finishing later.** **Finish the transcript** is offered whenever `gaps` is non-empty or
  `coveredMs < durationMs` and readiness is ready, on any status, through `reopenForRemaining` +
  `transcribeRemaining`.
- **Surface sessions** (`features/transcripts/presentation`). `LiveTranscriptController` is a
  `NotifierProvider.autoDispose.family` keyed by `LiveTranscriptKey` (`capture:`, `meeting:`, `standalone:`).
  `TranscriptSessionTarget({sessionKey, projectId, ownerKind, ownerId?, audioPath, beforeStart?, fileAudio, onDiscard?,
  mode = TranscriptMode.live|audioOnly, keepAlive = true})` is built only in `*_providers.dart` or `*_controller.dart`
  files (`state_test`). **Start:** `audioPath()` → `beforeStart()` → `begin` (row `live`, durable before the
  microphone) → `sinkFor` → `service.start(longForm, transcribe: mode == live)`; a failure before the microphone opens
  discards the row and calls `onDiscard`. **Stop** (`Result<String?>` attachment id): `session.stop()` (publish) →
  `fileAudio` → `linkAttachment`, then the keep-alive link, the leave guard and the controller's exit check are
  released while the transcript drains under the service. `retrySave` resumes from the failed step; a take that was
  never published is left to boot recovery. A session that stops itself is filed the same way, and a disposed
  controller files a take still open through references captured at start. **Discard** (the panel confirms first):
  `cancel` (staging kept) or `skipRemaining`, `discard`, `onDiscard`; audio is never deleted. Status
  (`LiveTranscriptStatus`) carries the phase, pause reason, warning, unsaved flag and draining; words travel through
  the `frames` `ValueListenable`. `LiveTranscriptPanel` renders notices, `AppRecordingBar` and `AppTranscriptView`;
  `TranscriptListSection` lists a record's or meeting's transcripts and renders nothing when there are none.
- **Owners.** Meetings: `MeetingRecord.transcript` resolves to non-empty `transcriptRaw` (legacy import), otherwise
  the latest non-live meeting `transcripts` row (`displayText`), otherwise `versions.last.text`, so Refine minutes and
  exports read it unchanged. Capture: Save awaits only the publish and `linkAttachment`; the transcript drains
  afterwards. Processing: `OnlineTranscripts.forJob` uses `completedForAttachment` first and calls the online
  `transcribe` only when no on-device transcript exists (§30.1).

#### 30.4.7 Pipeline invariants

`core/speech/pipeline/` is internal and pure Dart on the main isolate; VAD and decode run through the lease. The
timeline is the sample count of the 16 kHz take.

```dart
final class SpeechPipeline { SpeechPipeline({required PcmStore store, required SpeechPipelineConfig config, TranscriptSink? sink,
  required int nextSegmentId, required void Function(LiveTranscriptionEvent) emit, Logger? logger,
  int startSample = 0 /*detection starts here; earlier audio is accounted for elsewhere*/});
  void attachLease(SpeechEngineLease lease); void audioAvailable(int totalSamples); void markPause(int atSample, CapturePauseReason why);
  void markResume(int atSample); Future<void> finish({required bool drain}); Future<void> abort(); Future<Result<void>> retryUnsaved();
  int get coveredToSample; Duration get backlog; List<FinishedUtterance> get unsaved; Future<void> get sinkIdle;
  int get detectedTo; int get lastSpeechSample;   // the session's silence auto-stop
  ({int utterances, int segments, int dropped, int collapsed, double gatedRatio, Duration meanCompute, Duration p90Compute,
    double realTimeFactor, BackpressureLevel ladder}) get stats; }   // counts only, for the stop summary
```

- **VAD cursor.** Batches of 4 × `vadFrameSamples` are read from the `PcmStore`, one in flight, so a slow engine
  causes lag, never loss.
- **Energy pre-gate** (near-silence only, consulted only in silence): a window is quiet iff
  `dbfs < energyGateCeilingDbfs (−60)` **and** `dbfs < noiseFloor + energyGateMarginDb (3)`. An all-quiet batch
  skips the engine call (p = 0) and sets `needsReset`; the gated-batch ratio is reported in the stop summary.
- **VAD resets** at session start, after each utterance close, after resume and after a gated stretch, with 10
  warm-up windows.
- **Segmenter:** onset ≥ 250 ms, a hangover with 800 ms end silence, 320 ms pre-roll and 192 ms post-roll, a soft cut
  at 20 s, and a hard cut at 25 s at the minimum-energy 96 ms span with a 1 s seam overlap.
- **Scheduler.** One job in flight per pipeline; finals are FIFO and never dropped; interims use one slot. Interims
  are offered at ≥ 800 ms of utterance and ≥ `step` of growth, `step = clamp(ewma/duty, 600 ms, 3 s)`, where `duty`
  is `interimMaxDutyDesktop` (0.6) or `interimMaxDutyMobile` (0.3). Interims stop for an utterance when
  `ewma > 3 s × duty`, and on mobile once it exceeds `mobileInterimMaxUtterance` (10 s).
- **Backpressure ladder:** backlog > 10 s → `interimsOff` (interims off; `engineBehind`); > 30 s →
  `reducedContext` (a final that would encode the full context is sized, `audioContextPad` 128 over the committed
  floor; a final already sized keeps its profile, because below the floor whisper invents words at hard cuts); each
  level is left when backlog < 3 s.
- **Finals** read `[seamFromSample ?? start, end)` from the `PcmStore` **at dispatch**; after stop the store is
  rebased onto the published file, so backlog at stop is never lost.
- **`InterimStabiliser`** (LocalAgreement-2): `agree = commonPrefix(prev, H)`,
  `candidate = min(agree, |H|−1, repeatStart(H))`, where `repeatStart` is the first index at which a phrase of
  `interimRepeatWords` (3) words repeats one earlier in the same draft, compared by key; the stable part is
  append-only. A draft's repeated tail therefore stays tentative however many drafts agree on it, and dictation, which
  shows only stable words, never shows it. Drafts are decoded without a prompt.
- **`SegmentAssembler`**, per finished utterance in id order:
  1. reorder buffer;
  2. clamp segment and word times;
  3. `SegmentText.clean`: collapse whitespace; remove `[\[(][^\])]{0,40}[\])]` and `♪ ♫`; remove a space before
     punctuation; digits, URLs and ellipses untouched;
  4. **`HallucinationFilter`** drops a segment that is empty or punctuation only; or `noSpeech > 0.6 && avgLogprob <
     −1.0`; or a `HallucinationPhrases` phrase on weak audio (mean dB < −55, or speech ratio < 0.3, or
     `avgLogprob < −0.8`); or a prompt echo (normalised text is a substring of the prompt the final was decoded with
     and `avgLogprob < −0.8`; a final decoded without a prompt echoes nothing). Of several segments of an utterance
     not ended by a hard cut, the last is dropped when the detector heard less than `minSpeech` (250 ms) of speech
     under it: whisper decodes what follows its last timestamp as a window of its own and tends to hear a word there
     that was never said. Weak edge words (ln p < `hallucinationLogProb`) are trimmed when every window they overlap,
     and every window within `edgeTrimTolerance` (96 ms) of them, has `p < off`, only at an edge bordering silence
     (not the start of an utterance continuing a hard cut, nor the end of one a hard cut ended); a confident word is
     kept wherever whisper timed it, and the tolerance keeps a weak first word whisper timed just before the onset;
  5. **`RepetitionCollapse`:** for n = 6..1, a run repeated ≥ 3 times (n ≥ 2) or ≥ 4 times (n = 1) collapses to one
     copy when its word count exceeds the utterance's VAD speech seconds × `loopWordsPerSecond` (4), or it is faster
     than 0.12 s per word; a phrase that is itself a shorter phrase repeated collapses at that shorter length;
  6. **`SeamAligner`**, after hard cuts only: the cut utterance stores its words up to the seam and holds back the
     run of last words ending after `seamFrom − seamTolerance` (200 ms); the next utterance's final joins them by
     text: of the runs both decodes read alike (by key; an edge fragment matches its whole word; two words of 4+
     letters within one edit), the one best joining the held words' end to the next utterance's start wins, held
     words before it are kept, the next utterance's confident words before it follow (a weak one there is its
     misheard edge), then the run and the rest. With no run both sides are kept; nothing is dropped by time. The
     stored previous utterance is never edited;
  7. times made monotonic; ids from the session counter;
  8. **`sink.appendUtterance` is awaited**, then `SegmentFinalized` × n and `UtteranceFinalized` are emitted. A
     skipped utterance (two decode failures) is appended with `skipped: true` and recorded as a gap. A failing sink
     queues the utterance in order and retries it before the next one; events still go out with `durable: false`,
     plus a `transcriptUnsaved` warning;
  9. **`PromptCarry`**, only with `carryPrompt`, which is off by default as in whisper.cpp's streaming example:
     whisper skips speech its prompt already holds, which lost 30 of 138 words with tiny and 35 with base over
     jfk × 6. Drafts never carry a prompt. When on: the last 200 characters, cut at a word boundary; not passed for
     utterances under 2 s, with mean dB < −55, or continuing a hard cut (its seam re-decode already carries the
     context); reset after a loop collapse, a hallucination-only utterance or 60 s without speech.
- **Memory bound.** `debugPipelineRetainedSamples ≤ (ring + maxUtterance + seamOverlap) × 16000`.

#### 30.4.8 Web

The web runs the same shim (§30.4.1), built twice with Emscripten by `frontend/tool/whisper_wasm.dart --build`
(requires `$EMSDK` with `emcc --version` equal to `packages/tapture_whisper/wasm/emsdk_version.txt`; Ninja from
`$NINJA`, then the Android SDK CMake directory, then PATH). `src/CMakeLists.txt` is the single source of the flags and
`BUILD_INFO.json` records them. Common link flags:

```text
-O3 -msimd128 -fwasm-exceptions --no-entry -sMODULARIZE -sEXPORT_ES6 -sEXPORT_NAME=createTaptureWhisper
-sALLOW_MEMORY_GROWTH -sINITIAL_MEMORY=64MB -sMAXIMUM_MEMORY=2GB -sMEMORY_GROWTH_GEOMETRIC_CAP=2MB -sSTACK_SIZE=5MB
-sFILESYSTEM=0 -sEXPORTED_FUNCTIONS=@src/wasm_exports.txt
-sEXPORTED_RUNTIME_METHODS=HEAPU8,HEAP32,HEAPU32,HEAPF32,HEAP64,wasmMemory,UTF8ToString,stringToUTF8,lengthBytesUTF8,
  stackSave,stackRestore,stackAlloc
```

`wasm_exports.txt` holds exactly the header's `TW_API` names (no `_malloc`/`_free`): the worker places its scratch
(options, out-pointers, SHA bytes, prompt, log ring) on the 5 MB stack. BigInt is always on in Emscripten 6, so int64
crosses as BigInt without `-sWASM_BIGINT`. Web objects also define `GGML_SCHED_MAX_SPLIT_INPUTS=1`, which removes about
25 MiB of unused scheduler context per model; native builds are unchanged. Besides `tw_js_read`, the shim imports
`tw_js_size(file_id)` for the size check that precedes hashing. After loading base the heap is model bytes + 268.6 MiB in
Chromium (st and mt alike), the floor of whisper.cpp's per-state allocations; the budget is model bytes + 280 MiB.

- **Variants.** st: `-sENVIRONMENT=worker,node`. mt: `-sENVIRONMENT=worker,node -pthread -sPTHREAD_POOL_SIZE=8
  -sPTHREAD_POOL_SIZE_STRICT=2`, with web threads capped at 4 (3 secondaries). STRICT stays 2 deliberately: a worker
  cannot start a non-pooled pthread while ggml spin-waits, so pool exhaustion must fail loudly; with the cap of 4 and a
  pool of 8 it cannot occur.
- **Outputs**, committed under `frontend/web/whisper/`: `tapture_whisper_{st,mt}.{js,wasm}`, `BUILD_INFO.json`
  (`{abi, whisper, commit, patches, emsdk, flags, inputs:{path:sha256}, files:{name:sha256}}`) and `LICENSES.txt`.
  `--check` needs no emsdk: it verifies the hashes, that the ABI equals the header, that `wasm_exports.txt` equals the
  header's `TW_API` names and that the worker's struct-size table equals `TW_SIZEOF_*`. `--smoke` runs
  `node packages/tapture_whisper/wasm/smoke.mjs` for st and mt: the jfk phrase with tiny, VAD probability count
  `floor(n/512)`, struct sizes, a mismatched sha returning `MODEL_MISMATCH`, and for mt 50 consecutive decodes with
  `tw_live_objects` stable and no pool exhaustion.
- **Worker** `frontend/web/whisper/whisper_worker.js` (hand-written module worker). Requests `{id, op, args}`; replies
  `{id, ok:true, result}` or `{id, ok:false, error:{code, status, whisperCode}}`; events `{event:'log', entries}`.
  Typed heap views are never cached: a `heap()` helper re-derives them whenever `wasmMemory.buffer` changed, and all
  64-bit fields are read through `HEAP64`. Ops:
  - `init {variant}`: SIMD validate probe; mt iff `crossOriginIsolated && SharedArrayBuffer`; ABI and struct check;
    returns `{abi, variant, maxThreads, logicalCores, deviceMemoryGb, version, structSizes}`, plus `{memory,
    abortCell:{byteOffset}}` on mt.
  - `loadModel {kind, url, cacheKey, sha256, bytes, threads, flashAttn}`: only a same-origin URL is accepted
    (`cross_origin`); an OPFS hit (`whisper-models/<cacheKey>`) opens a sync access handle; a miss streams `fetch` into
    OPFS, then opens; without OPFS it fetches into an ArrayBuffer; the source is registered as a `file_id` and
    `tw_*_open_js` is called with the expected size and sha, so the shim hashes before parsing (no `crypto.subtle`;
    plain-HTTP LAN serving works); `MODEL_MISMATCH` deletes the OPFS entry, and a download longer than the expected
    bytes is cancelled and refused as `model_mismatch`. Returns `{handle, facts}` or `{handle, windowSamples}`, each
    with `servedFrom` (`opfs`, `network` or `memory`).
  - `verify {cacheKey, sha256, bytes}` streams the OPFS entry through `tw_sha256_*` for Settings;
    `transcribe {handle, jobId, pcm (transferred), options, initialPrompt}` returns the native copy-out shape;
    `vadFeed {handle, pcm}` → `{probs, pendingSamples}`; `vadReset {handle}`; `abort {leaseId, jobId?}` drops that
    lease's queued transcriptions with `jobId ≤` the given id (all of them without one) and returns `{dropped}`;
    `memory`, `liveObjects`, `close {handle}`, `dispose`. Log events carry `dropped`. Abort ordering does not rely on a
    message posted after `transcribe` overtaking the next queued job: browsers do not order task sources.
  - Error codes: snake-case `tw_status` names plus `no_simd`, `fetch_failed`, `storage` and `cross_origin`.
- **Web engine** (`speech_engine_web.dart`). Two module Workers from `Uri.base.resolve('whisper/whisper_worker.js')`:
  decode (`variant:'auto'`) and vad (`variant:'st'`), with VAD handles per lease inside the vad worker. Interop uses
  `dart:js_interop` extension types only (no `package:web`, no `dart:html`); the pure codec
  `speech_worker_codec.dart` is unit-tested on the VM. Model URL
  `Uri.base.resolve(ui_web.assetManager.getAssetUrl(SpeechAssets.tinyModel))`, asserted same-origin; the catalogue
  sha and byte count travel in `loadModel`. mt threads = `clamp(hardwareConcurrency − 1, 1, webMaxThreads 4)`.
  Counters `debugLiveHandles` (worker `liveObjects`) and `debugLiveSpeechWorkers`.
- **Abort.** mt: `Atomics.store(Int32Array(memory.buffer), abortCell.byteOffset >> 2, jobId)`. st: interim
  preemption is disabled, so a committed request waits for a short in-flight interim; `abortLease` drops queued jobs
  and terminates the worker only if the in-flight job belongs to that lease and is committed; `dispose` terminates
  the worker. After a terminate only the aborted lease's jobs fail with `CancelledFailure`: other leases' queued jobs
  are kept (`abortLease(A)` never cancels B), and the next pump respawns the worker and reopens the model from OPFS
  without refetching. If the decode worker's `auto` init does not answer within `speechEngine.workerStart` (for
  example a host that refuses the nested Workers the pthread pool needs), the engine retries with st and keeps st for
  later restarts.
- **Serving.** Threads (mt) need cross-origin isolation. `run-tools/run-web.py --isolated` adds COOP `same-origin`
  and COEP `credentialless`, and `.claude/launch.json` has `tapture-web-preview-isolated` (port 5181). Default
  development and **production** web use the single-thread build unless the host sends the COOP/COEP isolation
  headers; the plugin README gives the header snippet and notes that Safari lacks COEP `credentialless` and that COOP
  can affect popup sign-in. Sessions on web are capped at 30 minutes (§30.4.5).

## 31. Structured Output & Validation

Send the template field list; require JSON matching its derived schema.

Request (abridged):

```json
{
  "template": "Medical Equipment",
  "fields": [
    {"key": "equipment_name", "type": "text",   "required": true},
    {"key": "manufacturer",   "type": "lookup", "options_hint": ["ABC Medical", "XYZ Medical"]},
    {"key": "serial_number",  "type": "text",   "pattern": "^SN[0-9A-Z]{6,}$"},
    {"key": "condition",      "type": "choice", "options": ["Good","Fair","Poor","Faulty","Not Working","Missing","Unknown"]}
  ],
  "context": {"district": "Kampala", "facility": "Kasubi HC IV", "department": "Theatre"},
  "predefined_rows": ["Autoclave", "Microscope", "ECG Machine"],
  "caption": "13 litre autoclave, pressure gauge appears faulty",
  "ocr_text": "ABC MEDICAL  MED-1300  SN458923  13L  220V",
  "images": ["<image 1>", "<image 2>", "<image 3>"],
  "rules": [
    "Return only values supported by the supplied evidence.",
    "Use null when a value is not present. Never guess.",
    "Return valid JSON matching the schema."
  ]
}
```

Response:

```json
{
  "template": "Medical Equipment",
  "template_confidence": 0.97,
  "matched_row": "Autoclave",
  "fields": {
    "equipment_name": {"value": "Autoclave",    "confidence": 0.99, "evidence": ["image_1", "caption"]},
    "manufacturer":   {"value": "ABC Medical",  "confidence": 0.94, "evidence": ["image_2:ocr"]},
    "model":          {"value": "MED-1300",     "confidence": 0.91, "evidence": ["image_2:ocr"]},
    "serial_number":  {"value": "SN458923",     "confidence": 0.98, "evidence": ["image_2:ocr"]},
    "capacity":       {"value": "13 L",         "confidence": 0.96, "evidence": ["image_2:ocr", "caption"]},
    "condition":      {"value": "Faulty",       "confidence": 0.83, "evidence": ["image_3", "caption"]},
    "purchase_year":  {"value": null,           "confidence": 0.0,  "evidence": []}
  }
}
```

### 31.1 Enforcement

```text
Provider response
      |
Parse as JSON  -- fail --> repair attempt --> fail --> job FAILED, raw response stored
      |
Validate against the template-derived schema
      |
Drop unknown keys, coerce types, reject malformed values
      |
Apply to the record as proposals (never as approved values)
```

Store raw responses in `processing_results` for audit and reprocessing without re-uploading.

Documentation's separate, versioned schema (§80.3) carries sections/table cells, stable output keys, evidence references, unresolved requirements and conflicts. Never force narrative documents into record fields. Responses remain local proposals; validation and rendering do not grant approval.

## 32. Raw vs Refined Storage

**Preserve every captured text's original.**

| Stored as                           | Contents                                                                                             |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `value_raw` / `caption_raw`         | Exactly what was typed, spoken, scanned or read by OCR                                               |
| `value_refined` / `caption_refined` | The AI-cleaned, corrected or normalised counterpart                                                  |
| `value_final`                       | What the user approved — defaults to refined when present, otherwise raw; editing sets it explicitly |

Rules:

1. Refinement writes a separate column without overwriting raw text. Never refine an already-verified value automatically.
2. Review shows both versions through a one-tap toggle and per-field **Use raw** / **Use refined** switch; the operator decides authority.
3. Where requested by the template, export both as paired columns such as `Description` and `Description (AI refined)`. This per-project option defaults on for refined fields.
4. Apply the same pairing to record/photo captions, meeting notes and voice transcripts.

## 33. Confidence, Evidence & Provenance

Every field carries provenance and applicable confidence:

```json
{
  "field": "serial_number",
  "value_raw": "SN458923",
  "value_final": "SN458923",
  "source": "OCR",
  "confidence": 0.98,
  "evidence": [{"type": "photo", "photo_id": "…", "region": [412, 233, 690, 271], "text": "SN458923"}],
  "verified": true,
  "verified_by": "W. Wasswa",
  "verified_at": "2026-09-08T09:14:22Z"
}
```

- **Field-value sources**: `MANUAL · OCR · AI_VISION · AI_TEXT · STT · BARCODE · LOOKUP · CONTEXT · AUTO · IMPORT`. Field provenance `IMPORT` is distinct from the record-level import source (§46.3).
- **Confidence bands**, configurable per project: `>= 0.90` high, `0.70–0.89` medium, `< 0.70` review required. Always highlight low confidence.
- **Evidence** links to its photo and provider-supplied highlight region, document page, transcript segment or reference row. Open it through the evidence/confidence control; tapping the value edits it (§37).
- Manual and barcode values are authoritative without a confidence score.
- Confidence aids processing; it never approves a record.

## 34. The No-Invention Rule

If a value is not supported by the evidence, it is `null`.

Show **Not detected**, with actions to type the value or photograph its label.

- State this rule in extraction prompts; drop evidence-required field values with empty evidence lists during post-validation.
- Reject values contradicting identifier patterns or choice lists; do not coerce them.
- Refinement may reword and correct obvious transcription errors, never add absent facts, attendees, decisions, measurements or dates.

## 35. Normalisation & Row Matching

Normalisation follows extraction on-device and is fully configurable per project.

### 35.1 Value normalisation

```text
"13 litre", "13L", "13 Litre Capacity"          ->  13 L
"not working", "doesn't work", "dead"           ->  Not Working
"abc medical ltd", "ABC MEDICAL"                ->  ABC Medical      (via reference dataset)
"08/09/26", "8 Sept 2026"                       ->  2026-09-08
"220v", "220 volts"                             ->  220 V
```

Keep source sentences in the description or fault field when mapping free text to choices such as `Faulty`.

### 35.2 Row and item matching

```text
Exact identifier      ->  alias list       ->  normalised text match
      ->  fuzzy match  ->  AI classification (last resort, with confidence)
```

Aliases are editable per template:

```text
Blood Pressure Machine  <-  "BP machine", "blood pressure monitor", "sphygmomanometer"
```

### 35.3 Precedence when sources disagree

```text
1. Scanned barcode / QR
2. Value confirmed by a human
3. Reference dataset match on a scanned or typed identifier
4. OCR text from a clear label region
5. Vision analysis
6. Caption / transcript
7. Context and defaults
```

Reprocessing proposes changes to verified values; it never overwrites them.

## 36. Queue, Cost & Batching Control

- **Skip online calls** when local extraction plus reference lookup fills every required field.
- **Two-stage processing**: cheap classification, template detection and OCR first; use a capable model only when needed.
- **Group images** into one request per record (§29.1).
- **Deduplicate** by perceptual hash; never analyse the same photo twice.
- **Cache** OCR/extraction by image hash plus template version.
- **Compress upload copies** to a default 1600 px long edge, quality 80; preserve originals.
- **Batch** N records at a time, with retry and backoff for weak connections.
- **Budget guard**: optional per-project daily record cap and running request count.
- **Manual only**: send nothing until the user taps **Process**.

Documentation reuses runner primitives for run-owned typed jobs (§80), with exact content hashes, per-run budgets and bounded chunks. Never deduplicate document evidence or discard changed pages through perceptual similarity alone.

---

# Part VI — Review & Data Quality

## 37. Review Screen

- Show record number, item, status, context breadcrumb, photos with **Add**, field values/confidence, contextual location, automatic capture timestamp and raw/refined caption toggle.
- Sort attention-needed fields first; collapse confident fields under **All fields**. Show uncertain values in amber and **Not detected** in grey.
- Tap values to edit and percentages to open evidence (§33).
- **Approve & next** opens the next unreviewed record.
- **Re-analyse** reruns processing while preserving verified values (§35.3).

## 38. Editing Saved Records

All saved and approved content remains editable.

| Change                            | Effect                                                                                                    |
| --------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Edit a field value | Preserve history; set `source = MANUAL` and verified |
| Add photos | Append; re-analyse only on request |
| Delete a photo | Retain file until record deletion; flag affected values *evidence removed* |
| Reorder / rotate / re-type photos | Record history; preserve original file |
| Change template | Remap by `field_key`; retain and display unmapped retired fields |
| Change context | Affect this record only; update its photo folder paths |
| Re-run AI | Show proposals as a diff; preserve verified fields (§35.3) |
| Approve after editing | Return to Needs review, then Approved; write audit entry |
| Delete record | Tombstone; allow Recycle bin restoration for a configurable period, default 30 days |

The Recycle bin lists managed deleted projects, records and independently deleted photos/documents/audio. A deleted
project owns one entry for its cascade; records own their descendants. Restore clears only tombstones created by
that deletion, preserves prior independent deletions, restores the previous project status when recorded (legacy
rows use Active), and audits the change. A project folder moves back before database restoration, without overwriting
a live path; a failed or interrupted restore remains retryable. Browser bytes remain in the managed local store.
**Empty deleted records** retains the existing records-only retention/purge boundary. Templates use their own Undo;
arbitrary disk files, projects and independent files gain no new permanent-removal action.

## 39. Validation Rules

### 39.1 Field validation

Validate types, patterns, ranges, lengths, options, required fields and units on save and before export.

```text
Serial number must match SN + 6 or more letters or digits
Condition must be one of: Good, Fair, Poor, Faulty, Not Working, Missing, Unknown
Purchase year must be between 1950 and 2026
Quantity must be a positive number
```

### 39.2 Record validation

- All `REQUIRED` fields present.
- Identity fields present when the template declares them.
- At least one photo, when the template requires evidence.
- No unresolved duplicate (§40) and no unresolved source conflict (§41).

### 39.3 Image quality (advisory)

Warn about blur, darkness, overexposure, glare, small text and cropped subjects. Offer **Retake** or **Keep anyway**; never block saving.

### 39.4 Export validation

Before export, list incomplete/unapproved records and offer **Fix now**, **Exclude them**, or **Export anyway (marked incomplete)**.

## 40. Duplicate Detection & Override

### 40.1 Signals

```text
Identity fields (asset number, serial number, tag, plot number ...)
Identical photo hash
Near-identical photo (perceptual hash)
Same predefined row already captured in the same context
Same name + same context + close timestamp
```

### 40.2 When a duplicate is detected

Detect on save, table import and bundle merge. Show identity/context, the existing record's number, capture date and operator, and an existing/new comparison of fields and photo counts. The operator chooses:

- **Override existing**: replace with new values only after human comparison; retain previous values in history and audit the action. Never override automatically.
- **Keep both**: link records as `related_duplicate` for later review.
- **Discard new**.
- **Merge fields**: choose existing, new or both as a note per field.

Allow photos from the discarded side to attach to the survivor.

### 40.3 Bulk duplicate review

The project's **Duplicates** screen lists pending pairs with these four actions and **Apply this choice to all remaining pairs in this group**.

## 41. Source Conflicts

Review shows conflicting values with their evidence sources and confidence or match information. Offer each candidate and **Type another**. Require resolution before approval and record its reason.

## 42. Record Lifecycle & Status

Use one canonical status set. Export is a timestamp and export membership, not a status.

```text
DRAFT              being captured, not yet saved
CAPTURED           raw evidence saved, not processed        <- deferred mode rests here
QUEUED             waiting in the processing queue
PROCESSING         processing in progress
EXTRACTED          processing finished
NEEDS_REVIEW       has low-confidence, missing, duplicate or conflicting values
APPROVED           a human has verified and accepted it
FAILED             processing failed; raw evidence intact, retry available
ARCHIVED           excluded from active work and default exports
DELETED            tombstoned, recoverable until purged
```

```text
DRAFT -> CAPTURED -> QUEUED -> PROCESSING -> EXTRACTED -> NEEDS_REVIEW -> APPROVED
                                    |                          ^   |
                                    +--> FAILED --(retry)------+   +--> (edit) --> NEEDS_REVIEW
```

Manual-only records go `DRAFT -> NEEDS_REVIEW -> APPROVED`, skipping every processing state.

Flags carried alongside the status: `exported_at`, `has_duplicate`, `has_conflict`, `has_variance`, `not_in_register`, `merged_from_bundle`.

## 43. History & Audit Trail

Record every change in the authoritative local log. The optional relay transports audit entries without becoming their authority.

Entries store timestamp, operator, device, entity, action, field, previous/new values and any supplied reason. Cover capture, autofill, processing (provider, model, prompt version), extraction source/confidence, edits, photo additions, approval, merge/conflict choices and export membership/version. Bundles carry and merge audit rows, preserving every contributing device's history.

---

# Part VII — Collaboration

## 44. Multi-Device Collaboration Model

Each device holds a complete, independent project copy, usable offline and reconciled through exchanged bundles. The optional relay (§72) automates transport without changing merge semantics.

Users may transfer through the share sheet, cable, SD card, Bluetooth, local Wi-Fi, e-mail, manual cloud upload (§54), or project-enabled relay.

Principles:

1. **Additive and non-destructive**: delete only explicitly tombstoned data.
2. **Idempotent**: reimporting a bundle changes nothing.
3. **Order-independent** for non-conflicting changes.
4. Show automatic decisions; send ambiguous ones to a human.
5. Allow whole-merge **Undo** from history until purged.

### 44.1 Practical patterns

| Pattern                | How it works                                                                                                    |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| Team lead consolidates | Members export daily; the lead imports into the master copy. |
| Split by area | Assign different context values, such as facilities/blocks, to reduce conflicts. |
| Round-trip review | The lead merges, reviews, approves and returns the bundle as the team's new baseline. |
| Device replacement | Export/import a bundle to continue with full history on another device. |

## 45. Project Bundle Format

A bundle is a ZIP with a documented layout readable by other tools:

```text
medical-equipment-inventory__deviceA__2026-09-08T1030.zip
│
├── manifest.json           bundle identity, versions, counts, checksums, lineage
├── project.json            project settings and context definitions
├── templates.json          templates, fields, predefined rows, aliases
├── reference/              reference datasets as CSV + a JSON descriptor
├── records.json            records, field values (raw + refined + final), provenance
├── captions.json           record and photo captions, raw + refined
├── meetings.json           meetings, attendees, actions
├── documentation.json      workspace/resource metadata, definitions, runs and versions (§82.3)
├── variances.json          verification differences
├── audit.json              audit log entries
├── tombstones.json         deletions
├── sync_state.json         version vectors per entity
├── photos/                 original files, in the project's folder structure
├── documents/
├── documentation/          resource originals and retained extraction/run snapshots
├── generated/              included document artifacts, linked by hash in documentation.json
├── audio/
└── checksums.txt           SHA-256 of every file in the bundle
```

### 45.1 Manifest

```json
{
  "format": "tapture-bundle",
  "format_version": 1,
  "app_version": "1.4.0",
  "project_id": "0192f3c1-…",
  "project_name": "2026 Medical Equipment Inventory",
  "exported_at": "2026-09-08T10:30:00Z",
  "exported_by_device": "dev_A7F3",
  "exported_by_operator": "W. Wasswa",
  "scope": "FULL",
  "counts": {"records": 532, "photos": 1841, "documents": 12, "meetings": 3},
  "lineage": [
    {"device": "dev_A7F3", "max_rev": 5120},
    {"device": "dev_B21C", "max_rev": 3310, "merged_at": "2026-09-06T17:02:00Z"}
  ],
  "encrypted": false,
  "checksum": "sha256:…"
}
```

This base manifest needs a new format version and explicit capability marker for Documentation (§82.3). Old clients must reject unsupported required sections before writing. Full bundles include drafts as project data, never as approved deliverables.

### 45.2 Options

- **Scope**: full project, date range, context subtree (such as one facility), approved records only, or data without photos for smaller review bundles.
- **Photos**: originals (default) or compressed copies.
- **Password protection**: optional AES archive encryption.
- Bundles never contain API keys, cloud credentials or device secrets.

## 46. Bundle Export & Import

### 46.1 Export

```text
Project > Share > Export project bundle
      |
Choose scope, photos, password
      |
Bundle written to projects/<project>/exports/  and offered to the share sheet
```

### 46.2 Import

```text
Import > choose .zip
      |
Read manifest, verify checksums, check format version
      |
Same project id?
   yes -> MERGE (§47)
   no  -> import as a NEW project (optionally: "merge into an existing project" with template mapping)
      |
Merge preview -> resolve conflicts -> apply
```

Copy photos into the local project folder, deduplicating by SHA-256.

### 46.3 Importing plain tables

Import tables as **reference datasets** (§16) or **records**:

```text
Choose file (XLSX / CSV / JSON)
      |
Pick sheet and header row
      |
Map columns to template fields  (AI-suggested, editable)
      |
Choose: create records, or create a reference dataset
      |
Duplicate check against existing records (§40)
      |
Import summary: created, updated, skipped, conflicted
```

Imported records use record-level `source = IMPORTED_TABLE`, distinct from field-value provenance `IMPORT` (§33).
They support normal editing/photos and underpin verification (§17).

## 47. Merge Algorithm

Merging runs per entity, then per field.

```text
For each incoming entity:

  unknown id                          -> INSERT
  tombstoned locally, incoming older  -> keep deletion
  tombstoned incoming, local older    -> apply deletion
  incoming vector dominates local     -> UPDATE (fast-forward)
  local vector dominates incoming     -> IGNORE
  concurrent                          -> FIELD-LEVEL MERGE
```

Field-level merge, for records:

```text
For each field:
  changed on one side only            -> take that change
  changed on both sides, same value   -> no conflict
  changed on both sides, different    -> CONFLICT unless a rule below settles it
```

Automatic settlement rules, applied in order:

1. **Verified** beats unverified.
2. **Barcode or reference-matched** beats inferred.
3. **Non-empty** beats empty only if the empty side never edited the field.
4. Otherwise, require human resolution.

Other entity types:

| Entity                        | Rule                                                                                                                                          |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Photos, documents, audio | Union by SHA-256; one file per content. Merge captions per field. |
| Photo order | Keep importing device's order; append new photos. |
| Templates | Same version: no action. Different: conflict; choose one or keep both. Records retain their captured version (§18). |
| Reference datasets | Merge by key column; conflict per row for differing attributes. |
| Predefined rows | Union by identifier. |
| Audit log, processing results | Append-only union, deduplicated by id. |
| Context presets | Union by name. |
| Record numbers | Relabel collisions; preserve UUIDs and references. |
| Documentation | Union immutable runs/resource/output versions by UUID/hash; choose or keep both concurrent workspace/definition edits (§82.3). |

After structural merge, detect duplicates (§40), including independently captured records with different IDs.

## 48. Conflict Resolution

### 48.1 Preview before anything is written

Name the incoming bundle; count new/updated records, new photos, deletions, conflicts requiring resolution and possible duplicates for post-merge review. Offer **Resolve conflicts** and **Cancel**.

### 48.2 Resolving one conflict

Show conflict progress, record number/item/identifier and field, with local/incoming values, operator, timestamp, verification status and accessible photo evidence/counts.

- Offer **Keep mine**, **Take theirs**, **Type a value**, or **Decide later**. Support individual resolution and bulk choices by field or device, including **Apply this choice to all remaining conflicts on this field**.
- **Decide later** retains both values, flags `has_conflict` and prevents approval until settled.
- Audit both candidates and the choice.
- Show each merge in **Merge history**; **Undo merge** restores its pre-merge state (§44).

---

# Part VIII — Output & Distribution

## 49. Export Formats

All seven record-export formats work offline and reuse the same saved records. Approved records are the default
scope; an operator can export an incomplete set with an explicit mark. Documentation uses a distinct output selector
for saved narrative content (§78). Rendering requires no AI call; new AI content requires the selected online service (§80).

| Format   | Contents                                                                                                                                           | Typical use                                |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| **XLSX** | Standard records workbook with selected raw/refined, confidence and evidence columns and Photo index; separate filled copies of imported workbooks (§50) | Primary deliverable |
| **DOCX** | Editable records report and one filled imported Word template per record, where supplied (§49.4) | Word deliverable |
| **TXT** | UTF-8 records report and one filled imported text template per record, where supplied (§49.4) | Plain text deliverable |
| **CSV** | One file per template/sheet, UTF-8 BOM, configurable delimiter; ZIP multiple files | Analysis, data warehouses |
| **JSON** | Full fidelity: records, raw/refined values, provenance, confidence, evidence, context, templates and data dictionary | Programmatic/data-centre use |
| **PDF** | Photo reports, meeting minutes or variance reports | Sharing outside the app |
| **ZIP** | Chosen formats + photos + manifest, or a full project bundle (§45) | Archive, transfer, backup |

### 49.1 Export dialog

```text
Export

  Format      [x] XLSX  [ ] DOCX  [ ] TXT  [ ] CSV  [ ] JSON  [ ] PDF
  Package     [x] Include photos    -> produces a ZIP

  Records     (o) Approved only  ( ) All  ( ) This context  ( ) Date range
  Columns     [x] Raw values  [x] AI-refined values  [ ] Confidence  [ ] Evidence
  XLSX        Photo index included in the standard records workbook
  Extras      [ ] Variance  [ ] Not found  [ ] Audit log

                       [ EXPORT ]
```

### 49.2 Data dictionary

The optional **Data dictionary** is currently delivered as `dictionary.json`, containing the captured field
definitions for each template version. JSON records also include their captured definitions. These explain keys,
labels, types, units, options/codes, requiredness and descriptions independently of the app. A Data dictionary sheet
in the standard workbook remains a format requirement tracked by task 135; the source workbook is not extended
with new sheets.

### 49.3 Data package layout

Illustrative record-deliverable package; only selected formats, applicable templates and requested extras appear.
Multiple outputs or included photos produce a ZIP. A full project bundle uses the separate §45 contract.

```text
MEDICAL_EQUIPMENT_2026-09-08_v2.zip
├── outputs/
│   ├── records.xlsx
│   ├── records.docx
│   ├── records.txt
│   ├── Medical Equipment.csv
│   ├── records.json
│   ├── template-{id}-v{version}.xlsx
│   ├── template-{id}-v{version}-{record-number}.docx
│   ├── template-output-summary.json
│   └── dictionary.json
├── photos/
│   └── Kampala/Kasubi-HC-IV/Theatre/AUTOCLAVE_SN458923_FRONT_01.jpg
└── manifest.json
```

The manifest uses `exportId`, `createdAt`, `exportedBy`, the replayable `request` and `entries`. Each entry contains
`recordId`, `recordNumber`, `sheet`, `row` and `photoPaths`. The sheet/row locate the record in the standard workbook;
source-template mappings, captured versions and approved values are in the request. The template output summary
lists missing field keys per record, predefined rows not captured, unmatched records and preservation limitations.
PDF reports and filled TXT copies appear under `outputs/` when selected.

### 49.4 Word and text templates

Import DOCX or UTF-8 TXT templates with explicit `{{field_key}}` placeholders, then confirm the schema. Word fills
placeholders across text runs, table cells, headers and footers while retaining other package parts, formatting,
images and page settings. TXT substitutes placeholders while retaining surrounding wording and line endings.
Missing values leave blanks and appear in the output summary; the renderer never invents prose or values. The
standard `records.docx` and `records.txt` reports accompany filled copies and use the same selected record values.

Source files remain unchanged. Each output uses the record's captured template version and mappings; a changed
hashed source, invalid package or invalid mapping refuses the output. Office input is bounded to 15 MiB, declared
expanded package contents to 500 MiB and each parsed part to 15 MiB. Encrypted packages, unsafe paths and XML document
types are rejected. Existing Office digital signatures require signing the filled output again; the summary records
that limitation. Preserving package parts does not promise formula recalculation or identical pagination in every
Office reader.

## 50. Excel Generation

### 50.1 Rules

1. **Never modify the original workbook**; write a new file in `exports/`.
2. Emit a standard `records.xlsx` plus a filled copy for each captured imported workbook/version. The filled copy
   retains sheet order and untouched package contents, including styles, headers, widths, fonts, borders, frozen
   panes, formulas, images and charts. Only confirmed mapped cells on the selected sheet are filled.
3. Map `field_key -> output_column`. A captured predefined-row identity selects its original row; unmatched records
   are omitted from that source copy and listed in the summary. Without predefined rows, fill sequentially from
   `header_row + 1`, replacing any sample values in mapped cells in the copy. Do not claim append-after-last-used-row
   behavior. Duplicate row assignments and mapped formula cells refuse the output.
4. The source copy receives each field's final approved value. The standard workbook places selected raw/refined
   columns adjacently when field `refine` and the export option are both enabled:

```text
| Description (raw)                              | Description (AI refined)                        |
| uh this is a thirteen litre autoclave in ...   | 13 litre autoclave located in the theatre. ...  |
```

5. The standard workbook has one records sheet per template and a Photo index. Optional Variance, Not found,
   Duplicates and Audit sheets remain specialist export requirements; none are inserted into the filled source copy.
6. Preserve long text and identifiers, including leading zeros, as text. Explicit numeric field types accept finite
   numeric values; text fields are never inferred as numbers or dates.
7. Fill the existing Office package rather than rebuilding its unmodified parts. Invalid sources and mappings
   produce an error; do not silently substitute a clean workbook. Verify preservation against real client fixtures.
   Digital signatures and reader-specific layout/recalculation limits are disclosed under §49.4.

### 50.2 Photo references in the spreadsheet

Photo reference modes apply to the standard records workbook; source copies retain their existing layout:

| Mode                   | Cell content                                                              |
| ---------------------- | ------------------------------------------------------------------------- |
| **Filename** (default) | `AUTOCLAVE_SN458923_FRONT_01.jpg`                                         |
| **Relative path**      | `../photos/Kampala/Kasubi-HC-IV/Theatre/AUTOCLAVE_SN458923_FRONT_01.jpg`, from `outputs/` |
| **Stored path**        | The exported photo path without the workbook-relative prefix |
| **Embedded image** (required) | The image itself, inserted and row-height adjusted (larger files, slower) |

The standard `records.xlsx` always includes a **Photo index** sheet listing record number, photo type, caption and
path, including in filename mode. Filled source workbooks do not add a Photo index or new images. Filename and path
references are implemented. Embedded-image output remains a requirement: the current record writer uses the filename
and increased row height in that mode, without inserting the photo (task 135).

## 51. Photo Naming & References

Name photos meaningfully at capture; rename when record identity becomes known.

```text
Pattern (configurable):
{IDENTIFIER}_{OBJECT}_{PHOTO_TYPE}_{SEQ}.{ext}

Examples:
AUTOCLAVE_SN458923_FRONT_01.jpg
AUTOCLAVE_SN458923_RATING-PLATE_02.jpg
AST-00123_MICROSCOPE_SERIAL_01.jpg
REC000124_GENERIC_OTHER_03.jpg          <- no identifier available yet
```

Rules:

- Available tokens: `{PROJECT}` `{RECORD_NO}` `{IDENTIFIER}` `{OBJECT}` `{PHOTO_TYPE}` `{SEQ}` `{DATE}` `{TIME}` `{OPERATOR}` and any context level such as `{FACILITY}`.
- Sanitise to uppercase ASCII, hyphens for spaces, capped length and duplicate suffixes.
- Until identity is known, use the record number; rename automatically after serial/asset-number confirmation. Keep `original_filename` and rename history.
- Keep names short; folder paths supply context (§8).

## 52. PDF Reports

Generated on device, offline.

| Report                | Contents                                                                            |
| --------------------- | ----------------------------------------------------------------------------------- |
| **Record report**     | One record per page or per block: fields, photos, captions, context, operator, date |
| **Project summary**   | Counts by context, template, condition and status, plus charts                      |
| **Variance report**   | As-recorded vs as-found, plus items missing and items not in the register (§17)     |
| **Meeting minutes**   | Title, attendance, agenda, discussion, decisions, actions, photo appendix (§28)     |
| **Inspection report** | Checklist items, observations, compliance, risk, recommendations, photo evidence    |

Include a cover page with project, date, operator and applied filters, plus page numbers. Support thumbnails or full-size photos.

## 53. Export History & Versioning

- Log every export's timestamp, operator, format, filters, record count, path and hash.
- Version per project (`v1`, `v2`, …), using dated folders. **Never overwrite or delete previous exports.**
- Stamp included records `exported_at`; record the exact record versions in each exported file.
- Allow re-sharing/re-uploading from history without regeneration.
- Link Documentation artifacts to their exact document version, output definition, generation run and approval (§81–§82). Re-export saved content without AI calls or replacing previous files.

## 54. Manual Cloud Upload

Cloud storage receives user-selected files; it is never automatic or a synchronisation channel.

### 54.1 Behaviour

After export, show filename, size and **Share**, **Upload to cloud**, **Done**. **Upload to cloud** shows configured destinations, file size and destination folder; confirm before sending any bytes.

### 54.2 Destinations

| Destination                          | Credentials supplied by the user                    |
| ------------------------------------ | --------------------------------------------------- |
| Google Drive                         | OAuth sign-in, or a service-account key file        |
| Microsoft OneDrive                   | OAuth sign-in                                       |
| Dropbox                              | OAuth sign-in                                       |
| Amazon S3 or any S3-compatible store | Access key, secret, region, bucket, optional prefix |
| WebDAV / generic HTTPS endpoint      | URL plus credentials                                |
| Local / SD card / USB folder         | Path chosen with the system file picker             |

### 54.3 Rules

1. Require an explicit tap for each file, every time.
2. Store user-entered credentials only in platform secure storage, never the database, exports, bundles or logs.
3. Support resume/cancel; failed uploads change nothing locally.
4. Log destination, file, size, timestamp and result.
5. Delete stored credentials when removing a destination.
6. Coordinate devices through bundles (§44), never shared cloud-folder state.

---

# Part IX — Application Shell

## 55. Navigation & Screens

Compact/mobile screens have four controls, no intervening dashboard, and no repeat sign-in for local field work (§70.4).

```text
[ Projects ]      [ CAPTURE ]      [ Records ]      [ ... More ]
```

| Screen | Purpose |
| --- | --- |
| **Projects** | Project counts and last-worked timestamps; create, open, import, export, archive. |
| **Capture** | Current-project capture (§19); visually dominant centre button. |
| **Records** | Search, filter, open for review or editing. |
| **More** | Three-dot button; anchored, scrollable menu with labelled icons. Add Documentation when released (§83). |

Route map:

```text
/projects
/projects/new
/p/:projectId                     project home (counts, continue where you left off)
/p/:projectId/capture
/p/:projectId/records
/p/:projectId/records/:recordId
/p/:projectId/process              deferred queue
/p/:projectId/duplicates
/p/:projectId/templates
/p/:projectId/reference
/p/:projectId/export
/p/:projectId/merge
/p/:projectId/transcripts          transcript history; /new Transcribe; /:transcriptId detail (§24)
/more/transcripts                  the same across projects
/settings
```

This conceptual map uses the existing `RoutePaths` conventions: `/projects/:projectId/...` and secondary destinations under `/more`. Documentation follows these conventions without duplicate aliases; §83 specifies its routes and menu behaviour. Transcribe remains a project-home overflow action and a direct route, keeping four bottom controls (§56 rule 2); meetings start from **Start a meeting** and open their review by id.

### 55.1 Project home

Projects keeps search and pinned-first ordering, with one **Show archived** command to include archived projects. There is no Projects facet button, sheet or filter page; legacy filter links return to Projects. **Import a Project** opens the ZIP package picker directly and retains the existing validation/preview/approval flow. The generic import route remains available for other formats, with **Choose file** and collapsed **Supported files** help (§46).

A project with no attached template offers **Add template** as primary and **Capture now** as secondary. Raw capture also remains available while templates load or fail; attaching a template restores the usual capture primary action. No template is installed automatically. Create/Edit share trimmed-required project-name validation; touched errors clear as valid text is entered and save failures retain input.

Project commands use shared, nonselectable headings: Capture and review; Project setup; Exchange; Manage. Existing actions remain available, with Delete last. Header Back and Android Back honor overlays and dirty child routes first, then project home, Projects and finally native exit. Browser history, iOS stack gestures and desktop close guards retain their platform behavior.

```text
2026 Medical Equipment Inventory

  Records           532        Needs review        43
  Unprocessed        38        Duplicates           3
  Photos          1,841        Last export    07 Sep

  Kampala > Kasubi HC IV > Theatre                 [change]

  [  CONTINUE CAPTURING  ]

  Review 43   ·   Process 38   ·   Export   ·   Share
```

### 55.2 Records list

```text
Search: SN4589                        [ filters ]

  124  Autoclave        SN458923   Theatre      Approved
  121  Microscope       SN783421   Laboratory   Needs review
  118  ECG Machine      —          Ward 4A      Unprocessed
```

Filters: context, template, status, date, operator, condition, has photos, has duplicate, has conflict, not in register. Sorting by number, date or name. Search covers field values, captions, transcripts and OCR text.

## 56. Simplicity Rules

Testable interface rules:

1. **One primary action per screen**, using the largest control.
2. **Exactly four mobile bottom controls:** Projects, Capture, Records, More. New modules go in More.
3. **Three taps to create a record:** Capture → shutter → Save.
4. **Only sign-in is mandatory setup.** Capture within 30 seconds of first sign-in using a shipped template; General observation (UNI-001) is the universal fallback.
5. **No repeat login for local field work.** Cache the required account session and role grant (§70.4); no onboarding tour or dashboard.
6. **Advanced options** stay under Advanced or More; defaults show only field essentials.
7. **Sensible defaults:** today's date, current context, last template and camera settings.
8. **No dialog chains:** one decision at a time, with a safe default.
9. **Nothing blocks work:** warnings offer "Keep anyway"; errors never discard input.
10. **Plain language:** "Not detected", not `null`; "Analyse", not "invoke extraction pipeline".
11. **Touch targets ≥ 48 dp**; primary actions within one-thumb reach.
12. **Undo destructive actions**; keep deletions in a recycle bin.
13. **One visible status line:** context, template, online/offline, unprocessed count.
14. **Reusable components:** use existing design-system controls and the minimal corner radius (`Radii`, never zero). Menus, resource rows and document panels share controls; icons have readable labels.

## 57. Settings

```text
Server and account                               (AI settings/setup, Part XI)
  Name, initials, contact
  Organisation and server address
  Sign in, sign out, change password
  This enrolled device                           (name, enrolled on)
  Organisation role                              (read-only)
  Session and role-grant cache                   (last refreshed, expires)

Relay                                            (Project settings, optional, §72)
  Enable for this project                        off by default
  Schedule, Wi-Fi only
  Queued, sent and purged packages

Capture
  Default camera mode, flash, grid
  Auto-fill dates and times                      on
  GPS capture                                    off
  Photo files                                    collapsed; quality, folder strategy, naming
  Project contexts                               collapsed; existing defaults and controls

AI
  Supported providers                            searchable; validated server catalogue (§73)
  Required credential, then model                 searchable model choice; keyless hides credential
  Spending limit                                 collapsed with current-limit summary
  Test connection                                secondary; Save is the single primary action
  Device-held key                                (only where the administrator permits it)
  Use AI                                         on / off per project
  Do not send images                             off
  Auto-process when connected                    off
  Wi-Fi only                                     on
  Refine captions automatically                  off
  Confidence thresholds

Language
  App language
  Voice language                                 searchable choice
  Speech recognition                             (works offline, §30.4)
    Engine in use                                (read-only)
    Transcription quality                        Automatic / Fast / Accurate
    Speech models                                collapsed inventory; Verify; Remove imported
    Import a speech model                        (native only; verified before use)

Storage
  Storage used, by project
  Clear cache
  Recycle bin retention                          30 days

Data
  Export project bundle
  Import bundle or spreadsheet
  Cloud destinations
  Merge history

Security
  App lock (PIN / biometric)                     off
  Encrypt exports by default                     off

About
  Version, build and licences                     repository links omitted
```

Capture and speech disclosures change only the current screen's expansion state. Camera/date/location defaults,
selected speech health and repair remain visible; expanding a section never writes settings, requests permissions
or changes files. Global Settings omits Organisation and Relay: **Server and account** remains in AI settings and
setup; Relay belongs to the explicit project's settings. Legacy links recover to the same project controls or
Projects when no project is available. Opening those pages never enables relay or starts a transfer.

## 58. Accessibility & Field Usability

- Support large text and a high-contrast sunlight theme.
- Label every control for screen readers; make capture fully voice- and switch-operable.
- Use glove-friendly camera controls and haptic capture/save confirmation.
- Put primary actions in the lower third for one-handed use.
- Pair status colours with icons and text.
- Preserve in-progress captures through calls and screen locks.
- Live transcription pauses without losing audio or committed text when the app is backgrounded, a call arrives or
  the microphone is lost, and states the reason; resume is explicit (§30.4.5).

## 59. Performance

Targets on a mid-range Android device:

| Action | Target |
| --- | --- |
| Cold start to Projects | < 2 s |
| Project open to Capture | < 1 s |
| Shutter to photo saved and ready for the next shot | < 400 ms |
| Records list, 10,000 records | smooth scrolling, paged loading |
| Search across 10,000 records | < 300 ms (indexed) |
| XLSX export, 5,000 records | < 30 s, on a background isolate with progress |

Speech targets on the Windows desktop reference machine (`speechBudgets`, §30.4.3); mobile device-class targets are
recorded from physical-device evidence (task 131, `tool/devices.yaml`):

| Action | Target |
| --- | --- |
| Model load, including in-engine SHA-256 verification | ≤ 2 s tiny, ≤ 4 s base |
| Decoding speed | ≤ 0.35× real time tiny, ≤ 0.5× base |
| First interim text after speech starts | ≤ 1.5 s compute |
| Final segment after an utterance closes | ≤ 1 s compute |
| Abort of an in-flight decode (tiny) | ≤ 500 ms |
| Voice-activity detection | ≤ 60 ms per audio second |
| Pipeline overhead | ≤ 15 ms per audio second; UI timer drift ≤ 32 ms (p99 above idle, during a decode) |
| Engine memory | peak ≤ 192 MiB tiny, ≤ 256 MiB base; ≤ 32 MiB retained after release |
| Long live session | ≤ 64 MiB peak and ≤ 48 MiB retained RSS above the engine (live heap flat); no lost audio |

Page queries; index project, status, context, identity hash and timestamps. Generate thumbnails once and cache them; load full images only in the viewer. Run compression, hashing, exports, merge, audio resampling and speech inference off the UI thread (worker isolates; Web Workers on the web). Never perform file or database work on the UI thread.

## 60. Security & Privacy

### 60.1 On the device

- Optional PIN/biometric app lock.
- Store API keys and cloud credentials only in platform secure storage.
- Keep the database and project files at the configured local root (§8), respecting platform permissions; optionally encrypt the database with SQLCipher and encrypt export archives.
- Tombstone deleted records; purge them and their files after retention expires.

### 60.2 Data leaving the device

- Allow only §7.1/§7.3 operations; project-content transfers require user enablement.
- Before the session's first online call, show a one-screen summary of what will be sent.
- Never include credentials or device secrets in bundles or exports.

### 60.3 Personal data

- For projects collecting personal data, offer per-record consent flags, export face blurring, and marked-region redaction before image analysis. Photos may contain people, documents and identifiers.
- GPS is off by default, enabled per project.
- Coordinate exclusion and removal follow the original field shapes, including retained raw values, frozen context
  and history after an explicit template migration (§18). New ordinary values keep their current meaning.
- Store the operator's name and account ID locally for attribution and include them in shared bundles; no other user identifiers. The backend holds the account (§71), never its attributed records.

### 60.4 Input safety

- Validate import extensions, MIME signatures, size and structure before reading; reject malformed archives without unpacking.
- Verify bundle checksums before merge.
- Treat OCR, transcripts, imports and bundle text as data: never execute it, concatenate it into queries, or let it alter AI instructions.
- A file deliberately attached as **Prompt** supplies task instructions only after extraction into visible, editable text (§79). It cannot override privacy, evidence or approval rules. Other inputs, templates, archive members and links cannot promote themselves into prompts.
- Apply §77/§80 file inspection, bounded archive expansion, passive parsing and safe rendering. Attachments cannot execute macros, formulas, scripts or network requests.

---

# Part X — Engineering

## 61. Technology Stack

```text
Flutter (Android first; iOS, macOS, Windows, Linux and Web)
Dart
whisper.cpp         on-device speech: FFI on native platforms, WebAssembly on the web (§30.4)
Riverpod            state management
GoRouter            navigation
Material 3          theming
Drift + SQLite      local database
Isolates            image processing, export generation, merge
```

Every deployment requires the minimal Node.js/Express/PostgreSQL backend (Part XI): a versioned REST API for users, credentials, role grants and provider keys. Inject it as a service; use cached sessions/grants and queue processing when unreachable (§70.4). AI normally uses its proxy; direct HTTPS provider calls require administrator permission for a device-held key (§30.2).

Use standard camera, storage, speech and secure-storage plugins without further Android-only dependencies, preserving iOS/desktop portability. Speech recognition uses the local whisper.cpp plugin (§30.4.1), the only native code the project builds itself.

Android APK delivery retains every pinned bundled speech model (§30.4), with code/resource shrinking, one APK per
processor ABI, lossless native-library compression and separate debug symbols. Bundled offline functionality takes
priority over the requested 50 MB package target; build commands, measured sizes and feasibility are documented in
[the release-build guide](frontend/docs/release-build.md). Acceptance status belongs in the tracker.

## 62. Project Structure

Conceptual module map; the [frontend structure rules](frontend/.rules/01-structure.md) govern actual directory names and boundaries.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── db/               drift database, daos, migrations
│   ├── files/            folder layout, naming, hashing, cache
│   ├── ai/               AiService interface + implementations
│   ├── export/           xlsx, csv, json, pdf, zip writers
│   ├── import/           spreadsheet reader, bundle reader
│   ├── merge/            version vectors, merge engine, conflict model
│   ├── validation/       field, record and export validation
│   ├── normalise/        units, choices, dates, aliases
│   ├── security/         secure storage, app lock, redaction
│   ├── speech/           on-device speech engine, models, live transcription (no network)
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── projects/
│   ├── templates/        builder, spreadsheet mapping, shipped library
│   ├── reference/        datasets and lookups
│   ├── context/          context bar, presets
│   ├── capture/
│   │   ├── camera/
│   │   ├── gallery/
│   │   ├── documents/
│   │   ├── voice/
│   │   ├── barcode/
│   │   └── rapid/
│   ├── processing/       queue, jobs, progress
│   ├── review/
│   ├── records/
│   ├── duplicates/
│   ├── meetings/
│   ├── transcripts/      live transcripts, Transcribe screen and history
│   ├── documentation/     resources, output definitions, prompts, runs and document review
│   ├── exports/
│   ├── cloud/
│   ├── merge/
│   └── settings/
└── shared/
```

`frontend/packages/tapture_whisper` holds the native speech plugin outside `lib/`; only `core/speech` imports it
(frontend rules FE-STR-01, FE-STR-11).

Each feature uses `data/ · domain/ · presentation/`:

```text
capture/
├── data/          capture_repository_impl.dart, local data sources
├── domain/        capture.dart, capture_repository.dart, capture_service.dart
└── presentation/  capture_screen.dart, capture_controller.dart, widgets/
```

## 63. State Management

```text
deviceProfileProvider        operator, device id
projectsProvider             list, create, archive
currentProjectProvider
templatesProvider            per project
contextProvider              pinned context values and presets      <- §20
captureProvider              in-progress capture session
photoTrayProvider
processingQueueProvider      deferred jobs and progress             <- §26
recordsProvider              paged, filtered
recordProvider(recordId)
duplicatesProvider
mergeProvider                preview, conflicts, apply, undo
exportProvider
connectivityProvider         online / offline / metered
aiConfigProvider             providers, keys, per-project switches
documentationProvider(projectId)  local workspaces and history
documentWorkspaceProvider(id)     resource selections, definitions and saved rich text prompt
documentRunProvider(runId)        typed jobs, coverage, progress and proposed versions
```

Persist context across restarts. Documentation's captured-project inputs are optional despite being selected by default; each workspace still belongs to an owning project (§76).

## 64. Key Packages

```text
camera / image_picker / file_picker          capture and selection
image                                        resize, rotate, quality checks
google_mlkit_text_recognition                on-device OCR
mobile_scanner                               barcode / QR
tapture_whisper (local) + ffi                whisper.cpp on-device speech engine (§30.4)
speech_to_text                               platform dictation fallback, on device only (§24)
record + just_audio                          audio recording, microphone streaming and playback
drift + sqlite3_flutter_libs                 database (sqlcipher_flutter_libs when encryption is on)
path_provider                                storage roots
crypto                                       SHA-256
uuid                                         UUIDv7 identifiers
archive                                      ZIP bundles
excel / syncfusion_flutter_xlsio             XLSX read and write
csv                                          CSV read and write
pdf + printing                               PDF generation
flutter_secure_storage                       keys and credentials
geolocator                                   optional GPS
connectivity_plus                            network state
share_plus                                   share sheet
googleapis + google_sign_in / minio          cloud destinations
flutter_local_notifications                  processing and export notifications
```

Library choice for XLSX must be validated early against a real client template; see §50.1 rule 7.

The speech plugin and the web build ship licence blocks for the shim, whisper.cpp/ggml, the OpenAI Whisper weights
and Silero VAD (all MIT), shown under Settings → About → Licences.

Documentation needs PDF extraction, DOCX read/write, media decoding and shared rich text adapters (§77–§80). Select them using real fixtures and platform, licence, memory and fidelity checks in tasks 080–085; listed packages do not establish capability. Reuse file, queue, AI, export, security and bundle interfaces.

## 65. Testing Strategy

| Level | Coverage |
| --- | --- |
| **Unit** | Field validation, normalisation, alias and row matching, identity hashing, file naming, folder pathing, context inheritance and clearing, auto-fill, merge algorithm and version vectors, duplicate detection, spreadsheet schema parsing, export writers, audio resampling, voice-activity gating, utterance segmentation, transcript assembly |
| **Widget** | Capture screen, context bar, photo tray and caption scope, review screen, conflict resolution, template builder |
| **Integration** | Camera to saved record; deferred queue to processed record; import spreadsheet to records; export to XLSX/CSV/JSON/PDF/ZIP; bundle export to import on a second database; live transcription of a recorded fixture through the real engine |
| **End-to-end** | Create project → shipped template → set context → capture 3 records offline → process → review → approve → export ZIP → import on a second device → merge with conflicts → resolve → export again |

Critical test cases:

```text
1  Single photo                   fields extracted, record created
2  Multiple photos                information combined, not overwritten
3  Missing information            value is null, nothing invented
4  Context inheritance            5 records inherit context; editing one does not change the others
5  Context change                 changing district clears facility and department
6  Auto dates                     date and time filled without input, editable, audited
7  Caption to all photos          7 photos each receive an independent caption row
8  Deferred capture               40 records captured offline, processed later, none lost
9  Duplicate serial               warning shown; override applies only after review
10 Known-asset prefill            scan fills the record; variance recorded for differences
11 Template detection             building photos choose the Building template
12 Meeting mode                   transcript preserved, minutes refined, attendance OCR'd
13 Raw vs refined                 both stored, both exportable, raw never overwritten
14 Bundle round trip              export, import, merge, conflict resolved, undo works
15 Photo dedupe on merge          identical photo imported twice is stored once
16 AI failure                     raw record intact, retry available
17 Offline export                 XLSX, CSV, JSON, PDF and ZIP all generated with no network
18 Storage full                   graceful warning, no corrupted record
19 Documentation multi-output     source pack + requirements -> grounded report + matching workbook (§84)
20 Documentation interruption     offline, restart, cancel and retry preserve sources and draft versions
21 Mobile More menu               three dots, icons, dismissal, route state, keyboard and large-text access
22 Live transcript                30-minute live session with pauses: no duplicated, missing or reordered words
23 Corrupt speech model           refused before parse; typing and capture continue
```

## 66. Delivery Plan

The five phases below are **product delivery milestones**, not numbered implementation steps. Follow the canonical [development-plan task index](dev-tracker.md#task-index): steps 01–22 establish the application; **23 Backend → 24 Product refinements → 25 Baseline testing/release gates → 26 Documentation → 27 Hardening**. Hardening is last. Task IDs remain stable; step/sub-step numbers determine implementation order.

### Phase 1 — Vertical slice (build this first)

```text
Create project -> pick a shipped template -> set context -> capture photos + caption
   -> save raw -> process (on-device OCR + one online extraction) -> review -> approve
   -> export XLSX + photos
```

The slice also requires the smallest working backend:

```text
Register an organisation -> create an account -> sign in -> enrol the device
   -> issue the operator identity used to stamp the record above
   -> grant one role -> hold one provider key -> proxy the extraction call
```

Prove this flow end to end before expanding it. Grow the backend only as needed within §70.1 boundaries; add no other device dependency.

### Phase 2 — Field-ready

```text
Deferred processing queue and batch review
Rapid capture mode
Reference datasets, lookups and prefill
Barcode / QR and identifier-first capture
Verification mode and variance
Duplicate detection and override
Spreadsheet import (templates and records)
CSV / JSON / PDF export, ZIP packaging
Editing saved records, history and audit trail
```

### Phase 3 — Teams and breadth

```text
Project bundles: export, import, merge, conflict resolution, undo
Change relay over those same bundles (optional, §72)
Role enforcement and project membership on the server (§71.3, §71.4)
Meeting mode
Multi-template projects and automatic template detection
In-app template builder and the full shipped library
Manual cloud upload destinations
Documents and PDF input
GPS and map view
```

### Phase 4 — Advanced

```text
Automatic photo classification and real-time on-camera recognition
Face blurring and document redaction
Risk and condition scoring suggestions
Local analytics: correction rates, accuracy by field, progress by context
Additional voice languages
Desktop build for consolidation and reporting
```

### Phase 5 — Documentation

Implement §84 through [step 26](dev-plan/26-documentation.md): validate real document/media fixtures, then import → output definition → optional prompt → AI draft → human review → local export → bundle round trip. Captured projects are default inputs, never required. Extend the same adapters later for more codecs, archive formats and complex Office layouts. Mobile More (task 079, step 24) ships independently before Documentation; final hardening follows in step 27.

## 67. Definition of Done — MVP

The MVP includes accounts, authentication, organisation-wide identity, role grants, provider-key custody and the AI proxy (§70.1). Optional relay is excluded; hand-carried bundles support teams. After first sign-in, all local work below must continue offline; sign-in, online AI and cloud upload require connectivity.

- Sign in, use organisation-wide attribution and run backend AI without a device-held key.
- Create a project; choose or import a template.
- Persist a context hierarchy across records.
- Capture multiple photos; type or speak captions for one, selected or all photos.
- Auto-fill dates, times, operator and record number.
- Save raw for later processing or analyse immediately.
- Extract text on-device and fields online, without invention.
- Compare and choose raw/AI-refined values side by side.
- Review, correct, approve and subsequently edit records, including adding/removing photos.
- Warn of duplicates; allow override after reviewing differences.
- Scan or type identifiers to prefill known records from reference imports.
- Export XLSX, CSV, JSON, PDF and ZIP with organised photo folders.
- Export/import project bundles across devices and merge with conflict resolution.
- Upload exports to cloud destinations only by explicit action.

## 68. Product Naming

Product name: **Tapture** — *tap* + *capture*: turn real-world observations into structured data.

```text
App display name   Tapture              (shown to users, in stores, in the UI)
Repository         tapture              (lowercase, like the folder)
Project folder     tapture
Package / app id   com.tapture.app      (Dart package name: tapture)
Storage folder     <Documents>/Tapture/ (user-visible, so it uses the display name)
Bundle format      tapture-bundle
Tagline            Tap it. It's data.
```

The name is domain-neutral: equipment, buildings, stock, plants, people and meetings are first-class (§6, §13).

Before public release, check Google Play name availability and Uganda/EAC trademarks; secure the package ID and domain.

## 69. Requirements Coverage Matrix

| Requirement | Where it is specified |
| --- | --- |
| Fields enabled once and reused while collecting (district, facility, department) | §20 Context fields; §12.2`stickable`, `context_level` |
| Context hierarchy with per-record override | §20.2 |
| Dates and times set automatically | §21 Automatic fields |
| Captions applied to one photo, selected photos, or all photos | §23.2 |
| Adjusting captured data: adding and removing photos, editing values | §22.4, §38 |
| Extremely simple user interface | §3 (principle 2), §19, §55, §56 |
| Photos saved on the device in organised folders with subfolders | §8 |
| Database stored locally on the device | §8, §9 |
| Everything local except online AI, OCR and STT | §7 |
| Real-time speech-to-text on the device, without a network | §24, §30.4 |
| Prefill from existing data by asset or serial number, then edit | §16, §17, §25 |
| Supplying the existing data record | §16.1, §46.3 |
| Record raw data first, map later | §26 |
| Whole project exportable, importable and analysable on another device | §45, §46 |
| Meeting minutes, refinement, attendance photos | §28 |
| Different templates auto-detected and data structured accordingly | §14 |
| Several people on one project, merge with conflict resolution | §44, §47, §48 |
| Original captions preserved, AI-refined stored in a separate column | §32, §50.1 rule 4 |
| Inventory of anything | §3 (principle 9), §6, §11, §13 |
| Predefined shipped templates, derived templates, templates from scratch | §11.1, §13 |
| Duplicate entries overridden after human review | §40 |
| No backend backup; local storage only; manual cloud upload button | §2.2, §7, §54, §70.3 |
| Required minimal backend for users, authentication, roles, AI functionality and keys | Part XI (§70–§75) |
| Optional change relay for multi-device work, off by default | §72 |
| Default templates with atomic columns, requiredness chosen by the user | §13, §12.2 `required` |
| Data suitable for data centres | §49.2 data dictionary, §49 JSON/CSV |
| Export and import: CSV, PDF, JSON, ZIP, XLSX | §49 |
| Upload to Google Drive, AWS and similar with user credentials | §54.2 |
| Prefilled templates: supplier or manufacturer lists matched by ID | §16.2, §16.3 |
| Multiple document/media/archive inputs, distinct from output resources | §76–§77 |
| Optional captured projects selected by default; multiple projects, uploaded files or project archives in any combination | §76–§77.4, §80, §82 |
| Report requirements and Excel headers defining one or more deliverables | §78 |
| Optional .md/.docx/.txt prompt file and rich text instructions | §79 |
| Create documents using AI, evidence-linked review and local file generation | §80–§81 |
| Portable document resources, versions and reusable definitions | §82 |
| Mobile three-dot More button with an icon menu | §55–§56, §83 |
| Documentation implementation sequence and release acceptance | §84; dev-plan/26-documentation.md |

---

# Part XI — The Minimal Backend

## 70. Purpose and Boundaries

Every deployment requires one organisation-run backend; there is no serverless mode. It supplies identity, authentication, permissions and AI access without becoming the project store or obstructing field work.

| Responsibility | Device | Minimal backend |
| --- | --- | --- |
| Required | Yes | Yes; one per organisation |
| Project store of record | All project content | Never (§70.2) |
| Users, credentials, keys | Cached session/grant; permitted device keys (§73.3) | Authoritative custody |
| Independent operation | Weeks offline (§70.4) | No dependency on a particular device |
| Backup | Manual ZIP export (§54) | None (§70.3) |

### 70.1 What the backend provides

Exactly five responsibilities:

1. **Users:** one organisation-wide identity per person for attribution and merge (§71.2).
2. **Authentication:** sign-in/out, password change/reset, token issue/refresh and device enrolment (§71.1).
3. **Roles/permissions:** central grants, server-side enforcement and mirrored device affordances (§71.3–§71.4).
4. **AI proxy:** provider calls, per-project quotas/budgets, model selection and usage accounting (§73, §36).
5. **Provider keys:** custody, rotation and revocation, so devices need not hold keys (§73.1).

Everything else stays on-device, except the optional, per-project, default-off change relay (§72). A deployment without relay is complete.

### 70.2 What the backend must never do

- Become the project store of record or keep durable project copies; relay data is transient (§72.4).
- Serve as backup; use manual ZIP export (§54).
- Receive project content except selected payloads for explicit AI requests (§7.1, §73), or encrypted packages with project-manager-enabled relay (§72.5).
- Require connectivity for capture, review, editing, validation, export, bundle exchange or merge (§70.4).
- Decrypt or interpret relay content (§72.6). The AI proxy handles selected readable payloads only for the request, without content persistence or logging.
- Train on user data or retain provider payloads beyond the request (§73.4).
- Weaken raw-evidence preservation, no-invention or human-approval rules.

### 70.3 Why backup is deliberately excluded

Durable relay copies would make the server a backup and project store, changing data-protection obligations and required operator disclosures. Transient encrypted packages make the boundary testable.

For an organisation-held archive, explicitly export a bundle/data package (§45, §49) and upload it to controlled storage (§54). This existing, auditable path remains the backup mechanism.

### 70.4 Behaviour when the backend is unreachable

After initial sign-in:

- Capture, review, editing, validation, export and manual bundle exchange continue offline.
- Cache the session and last role grant for the same configurable lifetime: **30 days by default**. No field login screen during that period.
- Queue AI proxy calls like direct-provider calls (§26).
- Queue enabled relay packages locally until connectivity returns.

After cache expiry, retain full read, capture, review, edit and export access to held projects. Require sign-in before relay, AI proxy use or receipt of changed grants. Server unavailability must never lose a record.

## 71. Accounts, Identity and Roles

### 71.1 Accounts

Support registration/invitation, sign-in/out and password change/reset. Optional future SSO must not require application changes. Sign-in enrols the device, binding its identifier (§10) to the account for server-side role enforcement.

### 71.2 Identity

Use the server-issued user ID on every record, edit, approval and audit entry for consistent cross-device attribution and merge. At enrolment, reconcile the local operator profile; annotate prior history without rewriting it.

### 71.3 Roles

| Role | May |
| --- | --- |
| **Administrator** | Manage users and devices, create projects, hold and rotate provider keys, configure relay and retention |
| **Project manager** | Create and configure projects and templates, assign members, review, approve, export |
| **Reviewer** | Review, correct, approve and reject records; resolve duplicates and conflicts |
| **Field operator** | Capture, edit their own unapproved records, run processing, export their own work |

Enforce roles on server-mediated membership, relay, key use, directory changes and administration. Mirror permissions in the UI, hiding unavailable actions.

For Documentation, operators prepare their own workspaces and request permitted drafts; managers configure shared output definitions; reviewers/managers approve final versions. Own-work exports may contain labelled drafts, without granting approval. Key administration alone grants no document-approval right. The proxy checks membership, generation permission and project budget (§80); local review uses cached grants (§70.4).

**Security boundary:** local role affordances are guidance because devices hold complete copies. The server enforces relay/key-proxy access; do not place projects on untrusted devices when stronger control is required.

### 71.4 Membership and assignment

Assign each project member a project role and, optionally, context subtrees such as districts or facilities. Subtree assignments reduce overlapping edits and merge conflicts (§44.1).

## 72. Change Relay (Optional)

Relay is optional, default-off per project and explicitly enabled by a project manager. Hand-carried bundles (Part VII) already support teams; enabled relay provides transport only.

### 72.1 The model

Carry Part VII packages unchanged. Merge, conflict resolution, duplicate detection and undo remain on-device.

```text
Device A ── encrypted change package ──▶ ┌──────────┐ ──▶ Device B  (merge on device)
                                         │  Relay   │
Device C ◀── other devices' packages ─── └──────────┘ ◀── acknowledgements
                                    (ciphertext, purged once acknowledged)
```

### 72.2 The package

Send a delta bundle (§45) of changes since the receiving device's last acknowledged version, including version vectors (§47). Classify entities as for hand-carried bundles. Transfer photos/documents by content hash; never resend files already held.

### 72.3 The flow

```text
Local change ──▶ pending queue ──▶ (explicit action or schedule) ──▶ encrypt ──▶ push
Pull ──▶ decrypt ──▶ merge preview (§48) ──▶ conflicts to a human ──▶ apply ──▶ acknowledge
```

Never apply relay merges silently: use the same §47–§48 preview and conflict rules.

### 72.4 Retention — the rule that keeps this from being a backup

- Delete packages once every enrolled project device acknowledges them.
- Delete every remaining package after the configurable retention window: **30 days default, 90 days maximum**.
- Retain only version vectors, package metadata and acknowledgements; never project content.
- Devices missing the window recover a full bundle from a peer.
- Purge automatically; log deletions and let administrators verify them.

### 72.5 Relay rules

- Default-off per project; explicit project-manager enablement.
- Push manually or on the project's schedule, e.g. daily.
- Avoid metered connections unless permitted; large packages wait for Wi-Fi.
- Honour **never relay** projects even when others relay.
- Show queued, sent and purged packages.

### 72.6 Encryption

Encrypt packages on-device with a project key shared among member devices and distributed at enrolment. The server holds unreadable ciphertext (§70.2). Losing every member device loses the project unless deliberately backed up (§54).

## 73. AI Key Custody and Proxy

### 73.1 Arrangement

The organisation holds managed provider keys on the backend. Optional personal keys are encrypted there with
AES-256-GCM and a deployment-held wrapping key, bound to the signed-in user and provider. Status/save/delete APIs
never retrieve a key. Devices explicitly select the managed or personal account; failures never switch provider,
model or billing account. Administrator configuration may add providers speaking the existing Gemini generate-content
or OpenAI Responses protocols, with exact HTTPS endpoints, declared operations/models and positive configured cost
ceilings. The device receives validated nonsecret metadata only and retains the last valid catalogue offline.
Required-key descriptors keep `personal-<providerId>` identity; keyless descriptors use `keyless-<providerId>` and
managed billing bound to that exact provider, with no credential lookup. Both use the same permissions and quotas.
Catalogue refresh reaches Settings and processing; missing or removed accounts stay explicitly unavailable without
blocking capture. Legacy administrator-permitted device adapters remain the exception (§30.2).

### 73.2 Why this is better than keys on devices

- Lost/stolen devices expose no backend-managed key.
- Rotate keys centrally.
- Enforce per-project budgets, quotas and request counts (§36).
- Attribute costs to project, user and record.

### 73.3 Behaviour

Use record (§31) or typed Documentation (§80.3) schemas. Validate request envelopes, capabilities, permissions and budgets; call providers and return structured proposals. Keep parsing, chunk selection, orchestration, review and rendering on-device; expose no persistent document workspace or provider file store. Queue unavailable proxy calls (§70.4). Organisation-permitted device-held keys support emergency direct calls.

Record processing submits a versioned project evidence snapshot per record/batch. Content hashes cover the captured
template, context, original/edited evidence, explicit caption/photo/audio/transcript relationships and selected
provider/model. Durable local checkpoints preserve the exact source snapshot before dispatch; unchanged inputs
reuse valid local responses. Source changes invalidate cached extraction and prevent stale proposals. Provider
evidence must reference supplied source IDs; missing values, conflicting candidates and uncertain grouping remain
review findings. Only a person approves reusable records, and Excel/Word/text rendering uses those local records.

The backend reserves configured cost ceilings atomically and stores metadata-only idempotency tombstones bound to
the actor/device/project, source revision, exact payload hash, operation, model, provider and billing account plus its configuration fingerprint. A concurrent
duplicate may share an active request; a later replay never charges again. An interrupted or lost response requires
explicit retry approval rather than a promise that the provider was not paid. Low-cost base models are configured
per adapter; escalation requires a configured model and an explicit sufficient maximum cost. Usage exposes actual
provider token counts when reported and conservative reserved cost in the deployment's budget units.

### 73.4 Retention

Retain no images, audio, source documents, prompts, output requirements, generated content or extracted text beyond the request. Log only project, user, model, size, duration, outcome and cost, consistent with §75.

Only credential ciphertext and usage/idempotency metadata persist server-side. Originals, source snapshots,
responses and approved records stay in private device storage. Record retention purge removes its processing jobs,
snapshots and responses alongside owned evidence; it does not currently purge stored transcript headers/segments.
Transcript discard only hides them with a tombstone, so record deletion must not be described as complete transcript
erasure. Deleting a personal key prevents future reservations; a previously dispatched request may still complete.
Confirmed deployment destruction removes credentials and receipt metadata. Output templates stay local; imported
Office packages are filled at confirmed mappings/placeholders while untouched package entries and original bytes
are retained.

## 74. Deployment and API Surface

### 74.1 Deployment

```text
One container:  Node.js + Express  ·  PostgreSQL  ·  secrets store for provider keys
                local disk for transient relay packages   (only where relay is enabled)
```

Self-host one instance per organisation, without multi-tenancy. No durable media storage keeps a fifty-person deployment viable on a modest VM. Provide single-command administrative export and destruction of the entire server state.

### 74.2 API surface

Only relay endpoints are optional; all other listed endpoints are required. Unlisted capabilities belong on-device. Paths omit `/api/v1` for readability; new operations, including `/ai/compose`, use that prefix and client/backend capability checks.

```text
POST /auth/register           POST /auth/login            POST /auth/refresh
POST /auth/logout             POST /auth/reset            POST /auth/change-password
GET  /auth/me                 POST /devices/enrol         GET  /devices

GET  /org/users               POST /org/users             PATCH /org/users/:id
GET  /projects                POST /projects              GET   /projects/:id
GET  /projects/:id/members    POST /projects/:id/members

POST /projects/:id/relay/packages        push an encrypted package        (optional, §72)
GET  /projects/:id/relay/packages        list packages this device has not acknowledged
GET  /projects/:id/relay/packages/:pid   download one
POST /projects/:id/relay/ack             acknowledge, which permits purging
GET  /projects/:id/relay/state           version vectors and queue state

POST /ai/extract              POST /ai/ocr                POST /ai/transcribe
POST /ai/refine               GET  /ai/usage
GET  /ai/providers            GET /ai/credentials/:provider
PUT  /ai/credentials/:provider           DELETE /ai/credentials/:provider
POST /ai/compose              bounded Documentation draft request (§80.3)

GET  /health                  GET  /version
```

### 74.3 Compatibility

Version the API; tolerate older/newer servers and clearly explain mismatches. Fall back to cached-session behaviour (§70.4) rather than blocking work.

## 75. Backend Security and Retention

- HTTPS only; certificate pinning when the organisation supplies its certificate.
- Short-lived access tokens with refresh, bound to enrolled devices.
- Memory-hard password hashing; authentication rate limits and lockout.
- Provider keys in a secrets store, never returned by endpoints or logged.
- Client-encrypted relay packages; verifiable purging under §72.4.
- Metadata-only server logs: no record values, captions or images.
- Audit user, role, key, retention and purge changes.
- Validate files and enforce upload-size limits; never unpack opaque relay packages server-side.
- Durable state is limited to users/identities, credentials/authentication state, roles/memberships, provider keys, settings, and audit, usage/quota/rate and relay metadata. Relay ciphertext is transient (§72.4); never persist readable project content, source documents, prompts or AI responses. A server dump contains no readable records, values, captions, photos or audio.
- All §60 device-side rules remain applicable.

---

# Part XII — Documentation

## 76. Purpose & Simple Workflow

**Documentation** produces reports and other deliverables from evidence. **Captured projects are the default
inputs, never required inputs.** Keep or remove the current project, select other projects, and/or add documents,
media or project archives. Generation needs at least one readable source of any supported kind (§77.4).

Each autosaved **documentation workspace** belongs to one project, which need not contain capture records or
templates. Its source projects may differ from its owner. A project can have several named workspaces with
separate version histories. Duplicating a workspace reuses its setup and stored bytes without carrying approval
to the new task.

| Area | Purpose | Example |
| --- | --- | --- |
| **Input resources** | Supply facts and evidence | Captured projects, TOR, company profile, meeting notes, recordings, photos, reports, spreadsheets or archives |
| **Output documents** | Define deliverables and their required structure | DOCX report following a reporting format/requirements document; XLSX register with supplied headers |
| **Instructions (optional)** | Specify task, audience, language and emphasis | “Prepare the September board report; limit the summary to one page.” |

### 76.1 The shortest useful path

1. Open **Documentation** from project home or **More**, then **New document**.
2. Review the current project's approved-record count under Inputs. Keep it, **Add projects**, or **Remove** it
   and use **Add files** / **Add project archive**. No file picker opens automatically.
3. Keep **Report · DOCX** or choose another supported output. Optionally attach format/requirements files;
   **Add output** creates a separate deliverable from the same sources.
4. Optionally type rich text instructions, attach a prompt file, or use both.
5. Review the preparation/sending summary and tap **Create documents**. A ready, authorised run starts immediately;
   otherwise show the blocking issue to resolve.
6. Review drafts, sources and gaps, then **Approve** and **Export**.

The title may be derived locally from the first file and date and edited later. Show reading status beside resources and keep
advanced controls collapsed. No wizard, prompt engineering, capture-form setup or model choice is required.
Incomplete or offline preparation can always be saved.

### 76.2 Worked documentation example

Keep the current project and optionally add `terms-of-reference.pdf`, `company-profile.docx`, site-photo ZIP and
meeting audio. Define “Progress report” as DOCX/PDF using `report-format.docx` and `report-requirements.pdf`, and
“Action register” as XLSX using `actions-headers.xlsx`. Add `instructions.md` and an audience note: two deliverables,
three rendered files.

The app drafts the confirmed report sections and workbook columns with evidence links. Missing due dates stay
blank and appear as issues; template example names are not facts. Resolve gaps or explicitly change requiredness,
inspect layouts, approve each version and export a ZIP. Originals and older drafts remain local. Adding a second
project and a colleague's archive enables comparisons grouped by source without merging their live projects.

## 77. Resources, Supported Formats & Archives

### 77.1 Import and resource roles

Project selection (§77.4) is the primary input control. **Add files** supports multiple files and desktop/web drag
and drop where available. Here, “upload” means copying into the local project store. Each row shows name, type,
size, role and reading status; its overflow offers preview, replace, remove and retry.

- Roles are explicit associations: **Input**, **Output format** or **Prompt**. Neither extension nor AI determines
  them; a file has several roles only when deliberately assigned.
- Before confirming import, preserve original bytes, detected MIME, filename, SHA-256 and attribution through shared
  attachment storage/deduplication. Renaming affects presentation; replacement creates an immutable resource version.
- Removing a selection cannot delete bytes referenced by another workspace, run or approved document (§82.2).
- Native sources default to approved record versions. Selecting unapproved content explicitly flags its derived
  content for review; unselected projects are never read.
- Resource states are **Reading**, **Ready**, **Needs attention**, **Stored only** and **Excluded**, independently of
  run status. Stored only retains an original that available adapters cannot read.
- Unreadable, encrypted, malformed or unsupported content cannot silently disappear. Offer a readable copy/transcript,
  reader retry or explicit exclusion with its reason saved in the run.

### 77.2 Capability matrix

Distinguish **store**, **preview**, **extract** and **generate**. This baseline is a delivery target verified per
platform/provider, not a claim that every current adapter exists or every accepted file is readable.

| Resource | Reading behaviour | Boundary shown to the user |
| --- | --- | --- |
| PDF | Text/tables by page; scanned-page OCR; page locators | Accessible copy needed for protected files; complex tables/poor scans may need correction |
| DOCX | Paragraphs, headings, lists and tables with paragraph/table IDs | Report coverage of tracked changes, text boxes, embedded objects and complex layouts |
| MD / TXT | Supported encodings, headings and line locators | HTML/scripts/links remain passive; linked material is not fetched |
| XLSX / CSV | Selected sheets, headers, ranges, sheet/cell or row locators | Stored values/formulas are data; no execution of imported formulas, macros or external links |
| Images | Preview plus permitted OCR/vision derivatives and image/region locators | Baseline JPEG, PNG, WebP; other formats need tested decoders |
| Audio | Timestamped transcription; language selection where needed | Baseline WAV, MP3, M4A where supported; report unreadable codecs |
| Video | Audio transcript and selected timestamped frames; sampling/coverage summary | Tested MP4 codec profile, not every MP4; sampled frames do not cover every moment |
| ZIP | Inspect/select entries and safely expand supported files (§77.3) | Packaging alone is not extracted evidence |
| Tapture project archive | Validate and snapshot selected records/meetings with their evidence (§77.4) | Supported bundle versions and dependencies required; no live-project import/merge |
| Other documents, media and archives | Retain bounded valid attachments as **Stored only** | DOC/XLS, RAR/7z/TAR and other codecs need later adapters or user conversion |

Support all media categories through extensible adapters. Reject failed safety/structure checks with a reason;
retain other bounded unknown files passively. Never launch executable content. Use sandboxed previews or an explicit
user action to open a trusted local file, never automatic OS execution.

Prefer local reading. Online OCR/transcription/vision requires explicit action and §80.2 sending controls.
**Do not send images** also covers PDF page renders and video frames. Disabling AI preserves local resources,
editing and existing outputs.

### 77.3 Archive and large-file handling

Resource extraction never imports or merges project records, even when a ZIP contains a Tapture manifest.
Preserve the archive and each selected member's hash and archive/member-path lineage. Members inherit the adding
picker's role: `prompt.md` inside an input archive remains input evidence.

Proposed initial import limits may be lowered; increases require platform testing:

| Limit | Initial value |
| --- | --- |
| Original file size, including archives | 250 MB |
| Selected files per batch | 100 |
| Enumerated ZIP entries / selected expansion count | 1,000 / 100 |
| Actual uncompressed bytes per archive | 500 MB |
| Per-entry and aggregate compression ratio | 100:1 maximum |
| Automatic nested expansion | None; retain nested archives without recursion |

Enforce limits on streamed bytes, not just headers. Before extraction reject absolute/parent/device paths,
symlinks, duplicate normalised paths, collisions and unsupported encryption; never overwrite project files.
Bound parsing memory/time, check disk space and write atomically. A failed member leaves valid selections visibly
intact; rejecting an archive produces no partial resource set.

Generation has separate adapter/provider page, duration, frame, token and cost limits. Do not truncate to fit:
identify affected resources/ranges and offer splitting, narrower selection, another capability or explicit exclusion.
Long mobile work may pause on OS suspension and resumes from durable checkpoints (§80.4).

### 77.4 Optional captured projects by default; archives as additional or alternative sources

A new workspace visibly preselects the **current project · All approved records**, showing its name, record/meeting
counts, evidence size and **Remove**. Preselection neither starts AI nor sends data. This source alone supports the
default report without uploads, a prompt or a format file; removing every project is equally valid. The owning
project is an organisational container, not a required evidence source.

**Add projects** is a searchable multi-select picker. Filter each source by template, context/location, dates or
records; explicitly choose attachments and unapproved records. Saved workspaces retain their selections. With no
current project, use the existing owner-project picker, then apply the default. An empty project remains editable,
is labelled empty and does not count as readable evidence or block other readable sources. Offer another project,
explicit unapproved captures or uploads; require no dummy record or capture template.

Include selected field values with raw/refined/final distinctions, units, required template/field metadata, context,
timestamps, operators, review status, meeting structures and chosen photos/captions/documents/audio/transcripts.
Copy only dependencies needed to interpret that scope, never an entire audit history/reference dataset merely
because it exists. Prefer approved values; retain raw evidence and unresolved differences for review.

**Add project archive** uses the shared bundle reader in isolated staging to validate manifest/version, paths,
hashes, relationships and expansion limits. Preview the same scope as native projects and interpret records,
templates, context, meetings and evidence as typed content. Do not create a live project, overwrite records, merge
or start imported jobs; restoration/import remains §46.

When **Add files** detects a project archive, offer **Use captured project content** or **Choose contained files**.
Corrupt/unsupported recognised archives cannot count as readable project sources. Generic ZIPs can supply files,
not reconstructed record relationships. Supported protected project bundles use existing decryption with passwords
held only in memory; otherwise request an accessible copy. Generic archive encryption rules remain §77.3.

Opening the picker saves scopes without copying entire projects. **Create documents** materialises a durable,
immutable source snapshot in the destination's shared store: selected values, required schema and evidence bytes,
deduplicated by hash. Freeze revisions consistently; retry preparation if dependencies change during capture.
Retain origin organisation/project UUID and name, record/meeting UUID and revision, field/template keys and versions,
evidence/archive hashes and capture/review attribution. Source deletion, movement or lost access cannot orphan an
existing run; a live ID/path alone is insufficient. Refreshing for a new run is explicit and shows changes.

Group sources by project/archive and support **Project A + Project B + archive C + loose files**. Namespace by
origin organisation/project and snapshot. Matching display numbers/labels do not establish identity or meaning.
Deduplicate repeated inclusion of one origin record revision, preserving both selection origins; flag differing
revisions and possible cross-project duplicates before final totals. Preserve units and field keys, and confirm
ambiguous mappings before aggregation. Attaching projects never merges their stores.

Apply destination and native-source permissions, including cached offline grants (§70.4). Enforce the most
restrictive AI, image and redaction/export policies; save source-policy snapshots and recheck locally known tighter
restrictions before sending. The proxy checks membership of referenced projects in its organisation. External
archives remain usable under destination permissions and sending consent without an origin project on that backend.
Preserve their declared restrictions and known policies of matching local projects. Archive metadata cannot grant
membership, relax policy or approve outputs. Charge the destination run; attribute facts to their origins.

Later restrictions govern new use without silently deleting historical evidence. Offline copies retain §71.3's
trusted-device revocation limitation. Review labels each **Source snapshot from [date]**, distinct from live data.

## 78. Output Definitions & Format Fidelity

### 78.1 One reusable definition per deliverable

An output definition has a name, compatible format set, optional format/requirements resources, confirmed structure
and revision. One narrative can render as DOCX/PDF/MD; a table/register as XLSX/CSV. A different structure needs a
separate definition. Changing an extension is not conversion.

Derive and preview **Output structure** from format resources:

- **Narrative:** ordered sections, required headings, tables, length guidance, supported styles, headers/footers and
  explicitly chosen branding.
- **Tabular:** chosen sheets, header row, exact labels/order, stable column keys, types, required columns, allowed
  values and an empty data region. XLSX supports several sheets; CSV exports one file per chosen sheet, packaged as needed.
- **Requirements:** checks linked to sections/columns and source references, distinguishing hard requirements from
  guidance. Ambiguity becomes an issue/question, not an invented interpretation.

Without format files, preview a built-in report/table structure. Every run needs a valid definition and readable
input, but no prompt. Prefer local structural extraction; AI interpretation requires sending consent. Confirm
derived/changed definitions before composition; unchanged saved definitions need no repeat confirmation. Common
instructions apply to all outputs; output-specific instructions stay under Advanced.

Output resources supply structure and rules, not sample facts, signatures, rows or approval stamps. Use such
content as evidence only when separately selected; it never becomes a current approval. Retained static text and
branding require explicit selection. Originals remain unchanged.

### 78.2 Rendering contract

| Format | First-release behaviour | Fidelity boundary |
| --- | --- | --- |
| DOCX | Editable headings, paragraphs, lists, tables, captioned images, breaks, margins and supported headers/footers | Supported structure/styles; no exact pagination, complex-field or arbitrary Office-object round-trip guarantee |
| PDF | Paginated reviewed content with tables, images and readable typography | Supplied PDF guides requirements/layout; not automatically an editable form or exact template |
| XLSX | Required sheets, exact header labels/order, typed cells, supported widths/styles and selected data region | Identify unsupported formulas, charts, pivots or macros before generation; no silent loss |
| CSV | UTF-8 values and confirmed headers; one file per chosen sheet | Preserve leading-zero identifiers; no styles, embedded images or merged cells |
| MD | Headings, paragraphs, lists, tables and relative links to selected assets | Assets travel with the package; no DOCX/PDF page layout |

Offer **Use supported template formatting** or **Create a clean document with this structure**. When an element
cannot be preserved, disclose the loss and require a fidelity choice before proceeding; save it with the run. Do not claim to fill an original
template when recreating its structure. DOCX/PDF have separate previews and may paginate differently. Arbitrary PDF
form filling and generated audio, video, images or slides are later capabilities.

Write generated spreadsheet values as literals and neutralise formula-triggering CSV text. Preserve existing XLSX
formulas only through tested passive round trips; Tapture executes neither imported formulas, macros nor external
links. Disclose unavailable recalculation and do not claim its results are validated. AI-requested calculations use
an allowlisted local path with evidence for operands, never executable model code.

Name, duplicate and reuse definitions within a project. Changes create revisions retained by old runs. Cross-project
copy/import requires a dependency preview so shared formats cannot carry private source resources accidentally.

## 79. Optional Prompt & Evidence Rules

### 79.1 Instructions without a mandatory prompt

The shared rich text field supports paragraphs, headings, bold/italic, ordered/bulleted lists and safe links.
Persist a sanitised, versioned representation plus a deterministic text/Markdown projection for AI; restore its
formatting on reopen. Pasted HTML cannot execute scripts or fetch assets.

**Attach prompt file** accepts one replaceable `.md`, `.docx` or `.txt` per workspace. Show filename, reading status
and extracted instructions beside the editor; preserve original bytes and extraction separately from user edits.
When combined, preview the effective prompt: typed instructions win for ordinary preferences; unresolved factual
or required-structure contradictions become issues before composition.

With neither supplied, show: “Create the selected outputs from the selected input resources, follow the confirmed
output requirements, and identify missing information without inventing facts.” Use the project language by
default. No prompt is a normal successful path.

### 79.2 Instruction and evidence boundaries

1. Always enforce product privacy, evidence rules, safe rendering and human approval.
2. Confirmed output definitions govern structure/required content; deviations require explicitly editing them.
3. Effective user instructions govern audience, style, emphasis and synthesis within those definitions.
4. Input content is evidence; output resources are structural references. Neither may issue commands, access other
   files, change roles, enable network tools or promote itself into a prompt.

The Prompt field deliberately adopts its file's visible text as instructions within these boundaries; ordinary
attachments/archive members do not. Never auto-fetch links. The run's selected projects, snapshots and files are
its source allowlist; the model cannot search other projects or the web.

### 79.3 Grounded synthesis

- Link every factual claim, table value and calculation to a resource version and locator: PDF page, DOCX
  paragraph/table, text line, sheet/cell, image region or media timestamp. Native/archive records retain exact
  origin project, snapshot and record/field revision.
- Missing facts stay blank/**Not provided** and requirements stay unmet. Required gaps block approval until
  supported content is added or requiredness is explicitly changed and audited. Never invent names, signatures,
  decisions, dates, figures, references or approvals.
- Keep conflicting sources visible. Neither filename order, recency nor confidence determines truth silently;
  a user may designate an authoritative source with a recorded reason.
- Label requested recommendations, proposals and conclusions, linking supporting observations without presenting
  them as recorded events or verified facts.
- Summaries retain original evidence links through intermediate synthesis. Valid citation syntax does not prove
  support; human review remains required.
- Record manual correction author/reason. New reviewer-supplied facts are explicit user assertions/evidence notes,
  never represented as extracted source text.

## 80. Generation Pipeline, Queue & Offline Behaviour

### 80.1 Pipeline and reuse

```text
Save workspace and originals locally
  -> inspect/read; OCR/transcribe permitted sources
  -> confirm output structures and show coverage
  -> snapshot resources, instructions, definitions and record revisions
  -> bounded extraction/synthesis through the AI proxy
  -> validate content, citations, required structure and conflicts
  -> render locally -> save draft versions, previews and issues -> human review
```

Reuse storage, picker/validation adapters, hashing, transactions, AI policy, queue runner, usage accounting,
export history and share/upload services through typed contracts. Add run/output-owned durable jobs without
changing record-owned processing semantics, dummy records or duplicate retry/budget/network-policy logic.
Screens use repositories/providers and shared widgets, never direct filesystem, HTTP or database calls.

The device owns extraction, ordered chunks, local indexing, intermediate summaries and assembly; no hosted workspace,
vector database or tool-using file/network agent is needed. Carry locators through every synthesis stage and report
read, sampled, excluded and failed portions. Cover each relevant selected chunk or visibly exclude it; analysing
first pages alone cannot count as analysing a whole document.

### 80.2 Sending scope and budget

Before online work, disclose selected resources/ranges, text/media sizes, modalities, output count, provider/model
and estimated cost. Unknown pricing is **Unknown**, never zero. Include prompt/format-file content. Apply project
AI/offline settings, **Do not send images**, metered-network policy, roles and quotas. Send minimum approved text
and derivatives, never whole archives or unrelated project content.

Save authorised scope and budget. Unchanged retries within them need no repeated consent; changed sources,
modalities, provider or spending cap do. Repair/retry calls share the budget; exceeding it pauses work.
Uploading final documents remains a separate action (§54).

### 80.3 Typed AI contract

Add versioned `composeDocument` and `POST /ai/compose` behind the existing AI abstraction. Implement and contract-test
the Dart/TypeScript schemas together from these logical fields:

```text
Request
  schema_version, project_id, run_id, output_id, request_id
  source_groups[] { snapshot_id, origin_project_id, source_kind, policy_scope }
  provider/model capability selection, stage, budget/size bounds
  effective_instructions, confirmed_output_definition
  sources[] { resource_version_id, chunk_id, locator, text/permitted_media }

Response
  schema_version, output_id, finish_reason, usage
  sections[] / tables[] with stable section/column/row keys and typed content
  evidence[] linking each claim/cell to supplied resource/chunk/locator ids
  missing_requirements[], source_conflicts[], coverage[], warnings[]
```

The backend enforces membership, permission, limits and budget, adapts provider requests and returns proposals.
It neither hosts resources, extracts archives, renders/approves outputs nor persists content. Capability discovery
rejects unsupported models/modalities. Provider transport must meet organisational retention policy without persistent
provider file uploads; reject incompatible adapters rather than claiming control beyond the provider contract.

The device validates schema, output identity, allowed keys/types, cited IDs/locators and required structure, rejects
executable content and records coverage/unsupported claims/issues. Missing required citations block approval.
Allow at most one bounded schema-repair call per response; continued failure saves local diagnostics and fails
the stage. Render validated models, never generated scripts or arbitrary binaries; malformed output cannot be approved.

### 80.4 Durable jobs and partial success

Workspaces remain editable; runs have immutable selection snapshots and mutable execution states: **Queued**,
**Running**, **Paused**, **Needs review**, **Partially complete**, **Failed**, **Cancelled**. Stage and approval
states are separate. Generation finishes when drafts exist, not when approved; each output succeeds/fails independently.

- Persist stage/checkpoint, local lease, attempt number, request identity, hashes, progress, usage and errors. Restarted interrupted
  stages become paused/retryable, never indefinitely Running.
- Respect platform background limits without blocking capture. Offline creation queues locally as **Waiting for
  connection**. Connectivity alone never starts Documentation AI; the user explicitly resumes it.
- Cache successful preparation/synthesis by exact source/extraction hashes, definition revision, effective prompt,
  model and pipeline version; reuse saved responses to avoid repeated charges.
- An accepted request that times out may have uncertain billing. Retain request IDs, disclose uncertainty and
  require explicit retry; do not promise exactly-once charging or create a durable backend response cache.
- Cancellation stops further dispatch; in-flight calls may cost money. Preserve completed stages/artifacts and
  reject all late results from cancelled/superseded attempts so they cannot overwrite newer work.
- Retry outputs/renderers independently. Render retries and alternate formats use saved content without AI;
  regeneration creates a version. Source edits never mutate an in-flight run.

## 81. Review, Approval & Versions

Document states are **Draft**, **Needs review**, **Approved**, **Archived**, separate from record states (§42).
Generation produces drafts. Review shows content, evidence and issues side by side on wide screens or through
compact switches. Shared rich text/table controls edit the structured model; rendered previews check layout.
Reviewers can edit text/cells, resolve conflicts, inspect sources, fix mappings and regenerate selected outputs.
First-release Word/Excel edits are not silently reimported as approved versions; no full desktop editor is required.

Approval requires readable renders of every selected format, resolved required gaps/conflicts, valid evidence and
acknowledged advisory coverage/fidelity warnings. A reviewer/project manager approves exact content, definition
and selected-format hashes, recorded with account, device and timestamp; approval never fabricates a signature.

Edits to approved content, definition changes and regeneration create new drafts. Prior approved versions remain
immutable/exportable. Changed inputs mark **Sources changed** without rewriting history or revoking historical
approval. Clearly distinguish latest approved and latest draft versions.

**Export final** includes approved versions only. Explicit **Export draft** labels filenames, metadata and, where
supported, the document itself DRAFT without changing status. Partial runs may export approved outputs while
listing omissions. Share/download individually or ZIP outputs/assets through existing export services.

Retain source mappings locally. If the requested layout has no citation space, offer an optional references
appendix/evidence sheet or separate manifest; do not add unsolicited columns/prose. Export provenance only for
selected outputs and originals only when explicitly chosen.

## 82. Data Model, Storage & Portability

### 82.1 Logical entities

Reuse attachment, audit, processing-result and export tables; the logical entities below must not duplicate byte
stores. Apply §10 IDs, attribution, revisions and tombstones as appropriate.

| Entity | Required information |
| --- | --- |
| `documentation_workspaces` | Project, title, owner, saved rich text/text projection, prompt selection, definition references, timestamps/revision |
| `documentation_resources` | Immutable version, attachment/hash, MIME/size/original filename, archive/member lineage, extraction revision, reader capability/status and locators |
| `documentation_selections` | Workspace, resource/native-record version, explicit `INPUT`/`OUTPUT_FORMAT`/`PROMPT` role, output association, ranges/order, exclusions/reasons |
| `documentation_source_snapshots` | Run, native/archive scope, origin organisation/project, immutable records/schema/evidence dependencies, policies, archive hash and timestamps (§77.4) |
| `documentation_outputs` | Stable deliverable ID; immutable definition revisions with name, formats, structures, requirements, format resources and fidelity choices |
| `documentation_runs` | Immutable selection/prompt/definition snapshot, model/pipeline versions, stage results, coverage, budget/usage and queue jobs |
| `documentation_jobs` | Run/output owner, stage, checkpoint, attempt/request identity, progress/error and local execution lease using shared scheduling/retry primitives |
| `documentation_versions` | Output/run/parent version, original AI draft/current edited revision, evidence/issues, review/approval binding and artifact hashes/paths |

Store large originals/extractions/content in the shared file store; SQLite holds descriptors, associations and
hashes. Native paths are project-relative; web uses durable IndexedDB adapters, not permanent object-URL references.
Execution leases are device-local, not portable. Cross-project snapshots are self-contained, with origin identity
and restrictions; deduplicated bytes must retain distinct provenance associations.

### 82.2 Storage and retention

```text
projects/<project>/documentation/
  resources/<resource-id>/<version>/...     preserved originals via shared attachment store
  extracted/<hash>/<reader-version>/...    source text/tables/transcripts referenced by runs
  runs/<run-id>/...                        immutable manifests and structured content snapshots
projects/<project>/exports/<dated-version>/...  generated files and optional evidence manifest
.cache/...                                disposable thumbnails, page previews, temporary conversions
```

These are logical areas, not mandatory duplicate copies. Referenced originals, extractions, drafts and approved
artifacts are durable evidence/history; **Clear cache** removes only previews and recomputable unreferenced work.
Stage imports/renders, hash/validate and commit links atomically. Crashes preserve recoverable drafts and leave
unreferenced staging cleanable. Removal is soft deletion; purge follows retention policy and requires no live
selection, historical run or approved-version reference. Preserve exports (§53); cleanup cannot remove sole evidence.

### 82.3 Bundles, merge and reuse

Full bundles contain resources, roles, definitions, effective prompts, extraction/locator snapshots, versions,
approvals and artifacts. Add section versions, counts, SHA-256 checksums and required capabilities to the manifest.
Data-only packages explicitly list omitted bytes/previews without claiming reproducibility.

Include selected cross-project/archive dependencies, not entire source projects or recreated live projects.
Restored workspaces must explain/render historical outputs without their original projects. New clients treat
missing Documentation sections in older bundles as empty; older clients reject required unsupported capabilities
before mutation. Validate paths, hashes, relationships and evidence/approval references; apply merge preview/undo
(§47–§48).

Union immutable resource/run/version IDs. Reused IDs with different immutable content mean corruption/conflict,
never last-writer-wins. Concurrent mutable selections/definition pointers require human resolution or **Keep both**;
never splice rich text or transfer approval to changed content. Copy-as-new remaps every reference and creates
drafts with historical attribution, not fresh approvals. Imported queued/running jobs become paused; never copy
leases/credentials or infer permission to dispatch AI/spend money.

Reusable definitions contain only chosen format assets. Workspace copies show their resource dependencies;
source/prompt references cannot leak through template exports. The optional relay carries the same versioned
data as ciphertext, with no new durable document-storage responsibility.

## 83. Screens & Navigation

### 83.1 Mobile More menu

Keep exactly **Projects**, **Capture**, **Records**, **More** in compact navigation. More has a horizontal three-dot
icon and visible label, opening an anchored menu above the bar. Use shared square-corner menu/list styling,
safe-area scrolling, icon/text entries, at least 48 dp targets and screen-reader labels.

Expose working **Templates** (library/template), **Recycle bin** (restore) and **Settings** (cog). Queue and transcript history remain reachable through project actions and existing deep links; they have no global More/Settings shortcut (task143 W7). Add **Documentation** (document) when its route works. Other secondary tools also require usable
screens; no inert placeholders. Share destination labels/icons/routes across layouts.

Opening/dismissing More preserves the primary branch and work; outside tap, Back and Escape dismiss it. Selecting
an entry closes and navigates, marking More selected on secondary branches. Retain draft/navigation protections,
avoid duplicate routes on reopening and safely close/reposition on resize. Medium/expanded rails keep their
existing controls; add Documentation through the secondary hub and project-home action, never a fifth mobile tab.

### 83.2 Documentation screens

```text
Documentation                         [New document]
  September report       Needs review      2 outputs
  Company profile        Approved          v3

September report                       [history / ...]
  Input resources                       [Add sources]
    Current captured project   42 approved records  [Remove]
    [Add projects]  [Add files]  [Add project archive]
    TOR.pdf                 Ready
    Meeting audio.m4a       Needs transcription
  Output documents                      [Add output]
    Progress report · DOCX, PDF    Report format.docx
    Action register · XLSX        Headers.xlsx
  Instructions (optional)              [Attach prompt file]
    [shared rich text field]
  [Create documents]
```

The project-scoped list searches title/status and shows resource counts, progress, latest approved/draft versions.
Its empty state explains optional project defaults and offers **New document**. With no current owner, use the
existing project picker and return destination; never silently create/switch projects. Keep extraction diagnostics
in details, not the main form.

Proposed routes follow `RoutePaths`; register canonical paths once and preserve return navigation:

```text
/more/documentation                         current-project entry/picker
/projects/:projectId/documentation          workspace list
/projects/:projectId/documentation/:workspaceId
/projects/:projectId/documentation/:workspaceId/runs/:runId
/projects/:projectId/documentation/:workspaceId/versions/:versionId
```

Reuse file rows, output cards, progress/errors and rich text controls. Wide layouts show source/result panes;
mobile stacks them or switches source/review. Verify 200% text, keyboard focus, Back, offline status and recovery.
Avoid duplicate visual components and rounded panels.

## 84. Delivery & Acceptance Criteria

### 84.1 Delivery order

[Development step 26](dev-plan/26-documentation.md), tasks 080–086, implements Documentation after the
independent More-menu task 079. Final whole-product hardening follows in [step 27](dev-plan/27-hardening/).

1. Validate adapters, platform capabilities, security and real fixtures; publish measured format/fidelity support
   and update architectural guardrails for the feature and explicitly adopted prompts.
2. Add durable multi-file resources, roles, safe ZIP inspection/extraction and source snapshots.
3. Add confirmed output definitions, reusable mappings and autosaved optional rich text/file instructions.
4. Connect typed durable jobs to a real provider through the proxy, enforcing scope, cost, evidence and recovery.
5. Render/review/version/export DOCX/PDF/XLSX/CSV/MD; integrate bundles/merge and verify end-to-end workflows.

First release covers text/scanned PDF, DOCX, MD/TXT, XLSX/CSV, baseline images/audio/video, ZIP packs and all five
renderers. Advertise support only after platform fixtures pass. Additional codecs/archives, exact Office round
trips, arbitrary PDF forms and external-editor round trips are later extensions, not barriers to the standard
report/register flow or claims of current support. Fake providers are test aids, not release implementations.

### 84.2 Release gate

- Approved current-project records generate a default report without uploads, prompt or format file. Additional
  projects are selectable; saved scopes never switch silently. Removing all defaults permits uploaded-files-only
  or project-archive-only generation; validation never restores or requires a source project.
- A run combines two projects, a Tapture archive and loose files. Preserve source labels, keys, revisions and
  evidence; prevent double counting and enforce source/destination restrictions without modifying/merging originals.
- Source-project edits/deletion cannot break completed runs or full-bundle round trips. Unsupported archives,
  missing dependencies and conflicting revisions raise visible issues.
- Empty capture projects support multi-document reports with optional formats and no-prompt, typed-only,
  prompt-file-only and combined instructions.
- The worked example produces editable DOCX, readable paginated PDF and exact confirmed XLSX headers/order.
  Inspect every format's fixture renders; tables/captions cannot overflow.
- Recordings/video supply timestamped evidence with sampling coverage. Unsupported, unreadable and over-limit
  content remains visible with an action, never silently omitted.
- Injected source instructions, output-template samples, conflicting figures and missing dates cannot override
  policy or become invented facts. Review opens original source locations.
- Traversal, symlinks, nested bombs, MIME spoofing and expansion-limit violations cannot escape staging, corrupt
  projects or exhaust unbounded resources. Evidence archives cannot trigger merges.
- Offline preparation, saved-draft editing, approval and rendering work. Fresh AI requires explicit start/resume;
  network loss, restart, cancellation, ambiguous timeouts and full storage preserve originals/completed outputs.
  Render retries make zero provider calls.
- Real client/backend/provider contracts enforce membership, quota and capabilities. Inspect logs, persistence
  and temporary files for absence of retained source text, prompts or document content.
- Edits/regeneration create drafts; prior approvals/files stay bound to original content. Required gaps block
  approval and draft exports are visibly labelled.
- Bundle export/import/merge/undo preserves roles, hashes, evidence, history and approvals. Test old-version
  compatibility/new-version rejection; import cannot start AI or incur charges.
- More opens an accessible three-dot icon menu, preserves drafts, navigates only on selection and leaves the
  branch unchanged on dismissal. Documentation works at 200% text scaling.
- Existing capture, processing, meetings, exports and bundles pass regression checks. Plans and plausible mock
  responses alone never establish completion.

---

# Appendix A — Worked Example

**Setting.** An operator is inventorying medical equipment across Uganda. Today: Kasubi Health Centre IV, Kampala.

**1. Context, set once.**

```text
District   Kampala            (set on arrival in the district)
Facility   Kasubi HC IV       (set on arrival at the facility)
Department Theatre            (set on entering the theatre)
```

Subsequent records inherit all three values.

**2. Capture, offline.** Three photos of an autoclave: front, rating plate, faulty pressure gauge. The operator speaks:

> "Thirteen litre autoclave in theatre, pressure gauge appears faulty."

Taps **Save raw — analyse later**. The record is saved immediately with automatic date, time, operator, number and context. Photos go to:

```text
projects/2026-medical-equipment-inventory__p7k2/photos/Kampala/Kasubi-HC-IV/Theatre/
```

Eleven more items follow in the next twenty minutes, none of them analysed.

**3. Processing, at the guest house that evening.** **Process all (12)**. On-device OCR has already read the rating plates; the online step extracts fields against the Medical Equipment template, which was detected automatically from the photos and the OCR text.

**4. Review.**

```text
Equipment name   Autoclave         99%
Manufacturer     ABC Medical       94%   (matched to the Suppliers dataset)
Model            MED-1300          91%
Serial number    SN458923          98%
Capacity         13 L              96%
Condition        Faulty            83%   <- confirm
Purchase year    Not detected
Location         Theatre                 (context)
Captured         08 Sep 2026 09:12       (automatic)

Caption (raw)      "thirteen litre autoclave in theatre pressure gauge appears faulty"
Caption (refined)  "13 litre autoclave located in the theatre. Pressure gauge appears faulty."
```

Confirm the condition and tap **Approve & next**. Supplier contact and country are prefilled from the reference dataset.

**5. Duplicate.** Record 131 has the serial number SN458923 again. The app shows the comparison; the operator sees it is the same machine photographed twice, chooses **Override existing**, and the extra photos are attached to record 124.

**6. Merge.** A colleague covering the laboratory sends a bundle. Import shows 41 new records, 18 updates and 7 conflicts. Six are settled in bulk ("prefer the field team's values"); one — a condition disagreement backed by photos on both sides — is decided by looking at the evidence. **Undo merge** stays available.

**7. Export.**

```text
MEDICAL_EQUIPMENT_2026-09-08_v2.zip
├── data.xlsx              template columns, plus raw and AI-refined caption columns
├── data.csv
├── data.json              full provenance and confidence
├── report.pdf             photo report by facility
├── data_dictionary.csv
├── photos/Kampala/Kasubi-HC-IV/Theatre/AUTOCLAVE_SN458923_FRONT_01.jpg
└── manifest.json
```

The operator confirms **Upload to cloud** and sends the ZIP to the organisation's Google Drive folder. Outbound project content was limited to the authorised evening AI calls and this explicit upload; capture stayed offline.

---

# Appendix B — Core Product Principle

Capture templates define required information; Documentation output definitions define deliverables. Photos,
files, project records, captions and voice supply evidence. AI proposes supported values and drafts; people
review and approve exact versions. Preserve raw evidence beside refinements, with source links and history.
Final exports use approved content; explicit draft exports are labelled and project bundles preserve work history.

The device owns project content and can render saved documents offline. Only authorised actions send content;
the minimal backend governs identity, permissions and keys without becoming a project-content store. Optional
instructions guide synthesis within confirmed requirements and evidence rules.
