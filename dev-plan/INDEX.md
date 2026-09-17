# Tapture — task index

281 implementation prompts across 25 phases. Work top to bottom.

Every task inherits [STANDARD.md](STANDARD.md); read it once before the first task.

## 01 — Project setup and guardrails

*The repository, and the executable guardrails that enforce every architectural rule. Policies here are code — lints, checkers and tests — not prose.*

- [ ] [001 — Create the Flutter project](01-orchestration/001-flutter-project-init.md)
- [ ] [002 — Repository hygiene files](01-orchestration/002-repo-hygiene.md)
- [ ] [003 — Strict analyzer configuration](01-orchestration/003-strict-lints.md)
- [ ] [004 — Create the folder skeleton](01-orchestration/004-folder-scaffold.md)
- [ ] [005 — Dependency allowlist checker](01-orchestration/005-dependency-allowlist.md)
- [ ] [006 — Plan integrity checker](01-orchestration/006-plan-integrity-checker.md)
- [ ] [007 — Task scaffolding tool](01-orchestration/007-task-scaffolder.md)
- [ ] [008 — The verify command](01-orchestration/008-verify-command.md)
- [ ] [009 — Git hook installer](01-orchestration/009-git-hooks.md)
- [ ] [010 — Layering enforcement test](01-orchestration/010-layering-test.md)
- [ ] [011 — Naming and file-layout checker](01-orchestration/011-naming-checker.md)
- [ ] [012 — Canonical domain names](01-orchestration/012-domain-names.md)
- [ ] [013 — Design-token and responsive boundary tests](01-orchestration/013-design-token-test.md)
- [ ] [014 — State and error-handling convention tests](01-orchestration/014-riverpod-test.md)
- [ ] [015 — Logging discipline and secret scan](01-orchestration/015-logging-checker.md)
- [ ] [016 — Test presence checker](01-orchestration/016-test-presence-checker.md)
- [ ] [017 — Accessibility test matchers](01-orchestration/017-accessibility-matchers.md)
- [ ] [018 — Network boundary and raw-data safety tests](01-orchestration/018-network-test.md)

## 02 — Foundation services

*The empty app that boots, logs, fails safely, and the small services every later feature injects.*

- [ ] [019 — Application bootstrap, flavours and lifecycle](02-foundation/019-app-bootstrap.md)
- [ ] [020 — Shared constants](02-foundation/020-app-constants.md)
- [ ] [021 — Result type, failure taxonomy and error boundary](02-foundation/021-result-and-failures.md)
- [ ] [022 — Logger, diagnostics export and provider observer](02-foundation/022-logger-service.md)
- [ ] [023 — Clock, identifiers and device identity](02-foundation/023-clock-service.md)
- [ ] [024 — Hashing service and isolate runner](02-foundation/024-hashing-service.md)
- [ ] [025 — Connectivity service](02-foundation/025-connectivity-service.md)
- [ ] [026 — Runtime permissions service](02-foundation/026-permissions-service.md)
- [ ] [027 — Secure storage service](02-foundation/027-secure-storage-service.md)
- [ ] [028 — Serialisation conventions](02-foundation/028-json-codec-setup.md)
- [ ] [029 — AI service interface](02-foundation/029-ai-service-interface.md)

## 03 — Design system

*Built before any feature. Every later screen is assembled from these parts and never invents its own.*

- [ ] [030 — Design tokens: colour, type, spacing and elevation](03-design-system/030-color-tokens.md)
- [ ] [031 — Material 3 themes and the theme mode controller](03-design-system/031-theme-assembly.md)
- [ ] [032 — Breakpoints, responsive builder and readable width](03-design-system/032-breakpoints.md)
- [ ] [033 — Page scaffold](03-design-system/033-app-page.md)
- [ ] [034 — Buttons, icon buttons and the primary action](03-design-system/034-app-button.md)
- [ ] [035 — Text, number, date and search fields](03-design-system/035-app-text-field.md)
- [ ] [036 — Choice, multi-choice and boolean fields](03-design-system/036-app-choice-field.md)
- [ ] [037 — Chip and chip row](03-design-system/037-app-chip.md)
- [ ] [038 — Card, list tile and section header](03-design-system/038-app-card.md)
- [ ] [039 — Status pill and badge](03-design-system/039-app-status-pill.md)
- [ ] [040 — Empty, error and loading states, and the async value view](03-design-system/040-app-empty-state.md)
- [ ] [041 — Dialog, sheet, snackbar and banner services](03-design-system/041-app-dialog-service.md)
- [ ] [042 — Step progress list](03-design-system/042-app-progress-steps.md)
- [ ] [043 — Photo thumbnail](03-design-system/043-app-photo-thumb.md)
- [ ] [044 — Form scaffold, validation display and focus behaviour](03-design-system/044-app-form-scaffold.md)
- [ ] [045 — Haptics service](03-design-system/045-haptics-service.md)
- [ ] [046 — User-facing copy helper](03-design-system/046-copy-helper.md)
- [ ] [047 — Widget gallery screen](03-design-system/047-widget-gallery.md)
- [ ] [048 — Golden test baselines for the catalogue](03-design-system/048-golden-baselines.md)

## 04 — Local database

*Every table, with the merge columns present from the first migration.*

- [ ] [049 — Drift database bootstrap and migration strategy](04-data-layer/049-drift-setup.md)
- [ ] [050 — Shared columns, DAO base and transaction helper](04-data-layer/050-column-mixins.md)
- [ ] [051 — Tombstones, audit log and device profile tables](04-data-layer/051-tombstones-table.md)
- [ ] [052 — Projects and context tables](04-data-layer/052-projects-table.md)
- [ ] [053 — Templates, template fields and template rows tables](04-data-layer/053-templates-table.md)
- [x] [054 — Records and record fields tables](04-data-layer/054-records-table.md)
- [ ] [055 — Photos, attachments and captions tables](04-data-layer/055-photos-table.md)
- [ ] [056 — Reference dataset tables](04-data-layer/056-reference-tables.md)
- [ ] [057 — Processing jobs, results and field evidence tables](04-data-layer/057-jobs-table.md)
- [ ] [058 — Duplicates and variances tables](04-data-layer/058-duplicates-table.md)
- [ ] [059 — Meeting tables](04-data-layer/059-meetings-tables.md)
- [ ] [060 — Exports table](04-data-layer/060-exports-table.md)
- [ ] [061 — Merge session, conflict and version vector tables](04-data-layer/061-merge-tables.md)
- [ ] [062 — Repository interfaces and test factories](04-data-layer/062-repository-interfaces.md)
- [ ] [063 — Database integrity check](04-data-layer/063-db-integrity-check.md)
- [ ] [064 — Optional database encryption](04-data-layer/064-db-encryption.md)

## 05 — File storage

*The organised folder tree on the device, and every service that writes into it.*

- [ ] [065 — Storage root resolution](05-file-storage/065-storage-root.md)
- [ ] [066 — Project folder tree, name sanitiser and photo path builder](05-file-storage/066-project-folder-service.md)
- [ ] [067 — Atomic file writer and context relocation](05-file-storage/067-file-writer.md)
- [ ] [068 — Derived image cache: thumbnails, compressed copies and cleanup](05-file-storage/068-thumbnail-cache.md)
- [ ] [069 — Storage headroom guard](05-file-storage/069-storage-guard.md)
- [ ] [070 — Orphan file scanner](05-file-storage/070-orphan-scanner.md)
- [ ] [071 — Imported file validation](05-file-storage/071-file-validation.md)

## 06 — Application shell

*Navigation, the always-visible status line, and the frame every feature plugs into.*

- [ ] [072 — Router, route table and guards](06-app-shell/072-router-setup.md)
- [ ] [073 — Adaptive navigation shell](06-app-shell/073-nav-shell.md)
- [ ] [074 — First-run flow](06-app-shell/074-first-run.md)
- [ ] [075 — Global status line and offline banner](06-app-shell/075-status-line.md)
- [ ] [076 — Global error and crash recovery screen](06-app-shell/076-global-error-page.md)

## 07 — Account and settings

*The local identity that later becomes an account, the app lock, and the switches every later feature reads.*

- [ ] [077 — Operator profile](07-account-and-settings/077-operator-profile.md)
- [ ] [078 — Settings store](07-account-and-settings/078-settings-store.md)
- [ ] [079 — Settings shell and its section screens](07-account-and-settings/079-settings-shell.md)
- [ ] [080 — App lock: PIN and biometric unlock](07-account-and-settings/080-app-lock-pin.md)
- [ ] [081 — Manual offline mode switch](07-account-and-settings/081-offline-switch.md)

## 08 — Projects

*Create, open and manage the container that owns everything else.*

- [ ] [082 — Project domain model and repository](08-projects/082-project-model.md)
- [ ] [083 — Project list and the current project](08-projects/083-project-list.md)
- [ ] [084 — Create and duplicate a project](08-projects/084-project-create.md)
- [ ] [085 — Project home screen](08-projects/085-project-home.md)
- [ ] [086 — Project details and per-project settings](08-projects/086-project-edit.md)
- [ ] [087 — Archive, unarchive and delete a project](08-projects/087-project-archive.md)

## 09 — Templates

*The definition of every record shape: shipped, built in the app, or read from a spreadsheet. Columns are atomic (§13.1) and requiredness belongs to the user (§13.2) — both are enforced here, not assumed.*

- [ ] [088 — Template domain model and repository](09-templates/088-template-model.md)
- [ ] [089 — Field type registry](09-templates/089-field-type-registry.md)
- [ ] [090 — Shipped template asset format and atomicity checker](09-templates/090-shipped-templates-assets.md)
- [ ] [091 — Author the shipped template library](09-templates/091-shipped-template-library.md)
- [ ] [092 — Template list, blank create and duplicate](09-templates/092-template-list.md)
- [ ] [093 — Shipped template loader and library picker](09-templates/093-shipped-template-loader.md)
- [ ] [094 — Field list editor, reorder and delete](09-templates/094-field-list-editor.md)
- [ ] [095 — Add and edit a field, with Advanced, validation and options](09-templates/095-field-add-basic.md)
- [ ] [096 — Required columns screen](09-templates/096-required-columns-screen.md)
- [ ] [097 — Field editor widget](09-templates/097-field-editor-inline.md)
- [ ] [098 — Identity fields and output column mapping](09-templates/098-identity-fields.md)
- [ ] [099 — Template versioning and record migration](09-templates/099-template-versioning.md)
- [ ] [100 — Export and import a template as JSON](09-templates/100-template-export-json.md)
- [ ] [101 — Read a spreadsheet and infer its shape](09-templates/101-xlsx-read-workbook.md)
- [ ] [102 — Confirm the column mapping and create the template](09-templates/102-xlsx-mapping-screen.md)
- [ ] [103 — Predefined rows, aliases and the capture checklist](09-templates/103-predefined-rows-import.md)
- [ ] [104 — Detection profile editor](09-templates/104-template-detection-profile.md)

## 10 — Reference data

*Imported tables that prefill records and remove repeat typing.*

- [ ] [105 — Reference dataset model and repository](10-reference-data/105-dataset-model.md)
- [ ] [106 — Import a dataset from CSV, a spreadsheet or JSON](10-reference-data/106-dataset-import-csv.md)
- [ ] [107 — Choose the key column](10-reference-data/107-dataset-key-selection.md)
- [ ] [108 — Dataset list and row browser](10-reference-data/108-dataset-list.md)
- [ ] [109 — Edit a dataset row, and add one from capture](10-reference-data/109-dataset-row-edit.md)
- [ ] [110 — Configure a lookup field](10-reference-data/110-lookup-binding-config.md)
- [ ] [111 — Lookup matching, picking, prefill and unlink](10-reference-data/111-lookup-exact-match.md)
- [ ] [112 — Export a dataset](10-reference-data/112-dataset-export.md)

## 11 — Context

*Set a value once, and it applies to every record until changed.*

- [ ] [113 — Context model, repository and persistence](11-context/113-context-model.md)
- [ ] [114 — Define the context hierarchy](11-context/114-context-hierarchy-editor.md)
- [ ] [115 — Context bar, level picker and pinned fields](11-context/115-context-bar.md)
- [ ] [116 — Cascade clearing](11-context/116-context-cascade-clear.md)
- [ ] [117 — Apply context to records and the folder path](11-context/117-context-apply-to-record.md)
- [ ] [118 — Context presets: save and apply](11-context/118-context-presets-save.md)
- [ ] [119 — Optional auto-clear and movement prompt](11-context/119-context-auto-clear.md)

## 12 — Capture

*The heart of the app: evidence in, with as little typing as possible, always saved before anything else happens.*

- [ ] [120 — Capture session model and controller](12-capture/120-capture-session-model.md)
- [ ] [121 — Capture screen shell and inline template fields](12-capture/121-capture-screen.md)
- [ ] [122 — Camera permission and preview](12-capture/122-camera-permission-flow.md)
- [ ] [123 — Shutter, immediate save and quality warning](12-capture/123-camera-shutter.md)
- [ ] [124 — Camera controls and document mode](12-capture/124-camera-controls.md)
- [ ] [125 — Import photos, documents and PDF pages](12-capture/125-gallery-picker.md)
- [ ] [126 — Photo tray with order, type and multi-select](12-capture/126-photo-tray.md)
- [ ] [127 — Photo viewer, rotate and crop](12-capture/127-photo-viewer.md)
- [ ] [128 — Delete, retake and move photos](12-capture/128-photo-delete.md)
- [ ] [129 — Record and per-photo captions](12-capture/129-record-caption.md)
- [ ] [130 — Caption scope and apply mode](12-capture/130-caption-scope-selector.md)
- [ ] [131 — Voice input: permission, dictation and transcript](12-capture/131-voice-permission.md)
- [ ] [132 — Long-form audio recording](12-capture/132-audio-recording.md)
- [ ] [133 — Barcode scanner and continuous scan mode](12-capture/133-barcode-scanner.md)
- [ ] [134 — Identifier-first lookup](12-capture/134-identifier-lookup.md)
- [ ] [135 — Automatic values: clock, sequence and GPS](12-capture/135-auto-fields.md)
- [ ] [136 — The two save paths](12-capture/136-save-immediate.md)
- [ ] [137 — Reset for the next item](12-capture/137-capture-reset.md)
- [ ] [138 — Crash recovery for an unsaved session](12-capture/138-capture-recovery.md)
- [ ] [139 — Rapid capture mode](12-capture/139-rapid-mode.md)
- [ ] [140 — Storage guard in capture](12-capture/140-capture-storage-guard.md)
- [ ] [141 — Choose or pin a template](12-capture/141-template-pick-on-capture.md)

## 13 — Processing

*On-device first, online only when it earns its place, always resumable and always optional.*

- [ ] [142 — Processing job model, repository and queue](13-processing/142-job-model.md)
- [ ] [143 — Job runner, retry and backoff](13-processing/143-job-runner.md)
- [ ] [144 — Image preprocessing and on-device OCR](13-processing/144-image-preprocessing.md)
- [ ] [145 — OCR cache and perceptual image hashing](13-processing/145-ocr-result-store.md)
- [ ] [146 — Identifier pattern extraction](13-processing/146-identifier-extraction.md)
- [ ] [147 — Provider registry, selection and the egress preview](13-processing/147-provider-registry.md)
- [ ] [148 — Device-held API key: the permitted exception](13-processing/148-api-key-entry.md)
- [ ] [149 — Build and batch the extraction request](13-processing/149-extraction-request.md)
- [ ] [150 — Parse, repair and persist the response](13-processing/150-response-parse.md)
- [ ] [151 — Apply proposals with confidence bands](13-processing/151-proposal-application.md)
- [ ] [152 — Template detection: local signals, model assist, operator's choice](13-processing/152-template-detection-heuristics.md)
- [ ] [153 — Normalise units, choices, dates and numbers](13-processing/153-normalise-units.md)
- [ ] [154 — Match to a predefined row](13-processing/154-row-matching.md)
- [ ] [155 — Evidence links and provenance](13-processing/155-evidence-linking.md)
- [ ] [156 — Refine captions](13-processing/156-caption-refinement.md)
- [ ] [157 — No-invention enforcement](13-processing/157-no-invention-guard.md)
- [ ] [158 — Skip the online stage, and cap what it costs](13-processing/158-skip-online-when-complete.md)
- [ ] [159 — Queue screen, process actions and failed jobs](13-processing/159-queue-screen.md)
- [ ] [160 — Unattended processing: on connect and while charging](13-processing/160-auto-process-on-connect.md)
- [ ] [161 — Processing notifications](13-processing/161-processing-notifications.md)

## 14 — Records

*Find, read and change what has been captured, at any time after capture.*

- [ ] [162 — Record model, repository and status lifecycle](14-records/162-record-model.md)
- [ ] [163 — Records list, filters and sort](14-records/163-records-list.md)
- [ ] [164 — Search records](14-records/164-records-search.md)
- [ ] [165 — Record detail screen](14-records/165-record-detail.md)
- [ ] [166 — Edit a saved record: fields, photos and template](14-records/166-record-edit-fields.md)
- [ ] [167 — Record history view](14-records/167-record-history.md)
- [ ] [168 — Delete, recycle bin and retention purge](14-records/168-record-delete.md)
- [ ] [169 — Bulk actions on records](14-records/169-record-bulk-actions.md)

## 15 — Data quality

*The checks that make the output trustworthy, each with a human in the loop.*

- [ ] [170 — Validation engine and validators](15-data-quality/170-validation-engine.md)
- [ ] [171 — Validation display](15-data-quality/171-validation-display.md)
- [ ] [172 — Identity hash and duplicate detection](15-data-quality/172-identity-hash.md)
- [ ] [173 — Duplicate prompt and resolution](15-data-quality/173-duplicate-prompt.md)
- [ ] [174 — Duplicates review screen](15-data-quality/174-duplicates-screen.md)
- [ ] [175 — Source conflicts: detect and resolve](15-data-quality/175-source-conflict-detection.md)
- [ ] [176 — Verification mode and register prefill](15-data-quality/176-verification-mode.md)
- [ ] [177 — Variance and missing-item computation](15-data-quality/177-variance-computation.md)
- [ ] [178 — Variance screen](15-data-quality/178-variance-screen.md)
- [ ] [179 — Project quality summary](15-data-quality/179-quality-summary.md)

## 16 — Review

*Where a person turns proposals into data. Fast for the common case, thorough when needed.*

- [ ] [180 — Review screen and attention-first ordering](16-review/180-review-screen.md)
- [ ] [181 — Review row controls: raw, refined, confidence and gaps](16-review/181-raw-refined-toggle.md)
- [ ] [182 — Evidence viewer](16-review/182-evidence-viewer.md)
- [ ] [183 — Mark a field verified](16-review/183-verify-field.md)
- [ ] [184 — Approve and next, and the batch queue](16-review/184-approve-record.md)
- [ ] [185 — Re-analyse a record](16-review/185-reanalyse-record.md)

## 17 — Meetings

*A meeting is a record with structure: minutes, attendance and actions.*

- [ ] [186 — Meeting template, model and creation](17-meetings/186-meeting-template.md)
- [ ] [187 — Agenda and attendee editors](17-meetings/187-agenda-editor.md)
- [ ] [188 — Attendance sheet: capture, read and match](17-meetings/188-attendance-photo.md)
- [ ] [189 — Record and transcribe the meeting](17-meetings/189-meeting-audio.md)
- [ ] [190 — Refine the minutes](17-meetings/190-minutes-refinement.md)
- [ ] [191 — Decisions and action items editors](17-meetings/191-decisions-editor.md)
- [ ] [192 — Meeting review and approval](17-meetings/192-meeting-review.md)

## 18 — Export

*Five formats, all produced on the device, all reproducible and all recorded.*

- [ ] [193 — Export request model and pre-export validation](18-export/193-export-model.md)
- [ ] [194 — Scope and options sections](18-export/194-export-scope.md)
- [ ] [195 — Export value formatter](18-export/195-value-formatter.md)
- [ ] [196 — Photo naming and renaming on identification](18-export/196-photo-naming-service.md)
- [ ] [197 — XLSX writer core, column pairs and sheets](18-export/197-xlsx-writer.md)
- [ ] [198 — Write into a copy of the client workbook](18-export/198-xlsx-template-copy.md)
- [ ] [199 — Photo columns and photo index sheet](18-export/199-xlsx-photo-references.md)
- [ ] [200 — CSV, JSON and data dictionary writers](18-export/200-csv-writer.md)
- [ ] [201 — PDF engine and shared layout](18-export/201-pdf-engine.md)
- [ ] [202 — Record and inspection reports](18-export/202-pdf-record-report.md)
- [ ] [203 — Project summary and variance reports](18-export/203-pdf-summary-report.md)
- [ ] [204 — Meeting minutes PDF](18-export/204-pdf-minutes.md)
- [ ] [205 — ZIP data package and manifest](18-export/205-zip-package.md)
- [ ] [206 — Export screen, progress and cancellation](18-export/206-export-screen.md)
- [ ] [207 — Export history, versioning and sharing](18-export/207-export-history.md)

## 19 — Bundles and merge

*Collaboration that never touches the backend: a project leaves whole, by hand, and rejoins safely.*

- [ ] [208 — Bundle format, manifest and writer](19-bundles-and-merge/208-bundle-format.md)
- [ ] [209 — Bundle scope, sharing and receiving](19-bundles-and-merge/209-bundle-scope.md)
- [ ] [210 — Bundle encryption and secret exclusion](19-bundles-and-merge/210-bundle-encryption.md)
- [ ] [211 — Bundle reader, validation and import as a new project](19-bundles-and-merge/211-bundle-reader.md)
- [ ] [212 — Version vectors and tombstone propagation](19-bundles-and-merge/212-version-vector-service.md)
- [ ] [213 — Entity and field merge with automatic settlement](19-bundles-and-merge/213-merge-entity-level.md)
- [ ] [214 — Merge photos, templates and reference data](19-bundles-and-merge/214-merge-photos.md)
- [ ] [215 — Relabel colliding record numbers](19-bundles-and-merge/215-merge-record-numbers.md)
- [ ] [216 — Merge preview screen](19-bundles-and-merge/216-merge-preview.md)
- [ ] [217 — Conflict resolution, one at a time and in bulk](19-bundles-and-merge/217-conflict-screen.md)
- [ ] [218 — Apply, record and undo a merge](19-bundles-and-merge/218-merge-apply.md)
- [ ] [219 — Post-merge duplicate scan](19-bundles-and-merge/219-post-merge-duplicates.md)

## 20 — Data import

*Continue an inventory someone else started, as records or as a register to verify against.*

- [ ] [220 — Map spreadsheet columns to template fields](20-data-import/220-import-records-mapping.md)
- [ ] [221 — Create records from rows, with duplicate handling](20-data-import/221-import-records-create.md)
- [ ] [222 — Import entry point and purpose step](20-data-import/222-import-entry.md)
- [ ] [223 — Import summary](20-data-import/223-import-summary.md)

## 21 — Cloud upload

*A destination for files the user chooses to send. Never automatic, never a sync channel.*

- [ ] [224 — Destination abstraction and model](21-cloud-upload/224-destination-model.md)
- [ ] [225 — Destinations screen with test and removal](21-cloud-upload/225-destination-list.md)
- [ ] [226 — S3, WebDAV and folder destinations](21-cloud-upload/226-destination-s3.md)
- [ ] [227 — Google Drive, OneDrive and Dropbox destinations](21-cloud-upload/227-destination-google-drive.md)
- [ ] [228 — Upload confirmation](21-cloud-upload/228-upload-confirm.md)
- [ ] [229 — Upload runner, progress and history](21-cloud-upload/229-upload-runner.md)

## 22 — Privacy and security

*The controls that decide what leaves the device and what is visible in it.*

- [ ] [230 — What leaves this device, and location control](22-privacy-and-security/230-egress-summary-screen.md)
- [ ] [231 — Per-project AI and image egress switches](22-privacy-and-security/231-ai-disable-per-project.md)
- [ ] [232 — Consent, face blurring and redaction](22-privacy-and-security/232-consent-flag.md)
- [ ] [233 — Treat imported text as data](22-privacy-and-security/233-untrusted-text-handling.md)
- [ ] [234 — Automated secret leak test](22-privacy-and-security/234-secret-scan-test.md)
- [ ] [235 — Permission minimisation review](22-privacy-and-security/235-permission-minimisation.md)

## 23 — Hardening

*Making the finished app fast, legible, reachable and unbreakable in the field.*

- [ ] [236 — Layout, accessibility and text-scale audit](23-hardening/236-responsive-audit.md)
- [ ] [237 — Landscape and foldables](23-hardening/237-orientation-support.md)
- [ ] [238 — Copy pass and localisation scaffolding](23-hardening/238-copy-review.md)
- [ ] [239 — Empty-state coverage test](23-hardening/239-empty-states-review.md)
- [ ] [240 — Performance pass: lists, indexes, start-up, memory and background work](23-hardening/240-list-performance.md)
- [ ] [241 — Failure injection suite](23-hardening/241-error-recovery-review.md)
- [ ] [242 — App icon, splash and store branding](23-hardening/242-branding-assets.md)
- [ ] [243 — Device matrix runner](23-hardening/243-device-matrix-testing.md)
- [ ] [244 — In-app friction log](23-hardening/244-field-trial.md)

## 24 — The minimal backend

*The minimal backend of specification Part XI. It is **required**: accounts, authentication, roles, AI functionality and provider-key custody — the five things a single device cannot supply for itself, and nothing more. The change relay (§72) is the one optional capability inside this phase; every other task here is part of the MVP. Required to exist, never required to be reachable (§70.4).*

- [ ] [245 — Initialise the backend project and its gate](24-backend/245-be-project-init.md)
- [ ] [246 — Configuration loading and validation](24-backend/246-be-config.md)
- [ ] [247 — Structured logger, typed errors and the error envelope](24-backend/247-be-logger.md)
- [ ] [248 — HTTP server, middleware chain and limits](24-backend/248-be-http-server.md)
- [ ] [249 — Database connection, pooling and migrations](24-backend/249-be-db-connection.md)
- [ ] [250 — Schema: organisations, users, devices, projects and members](24-backend/250-be-schema-identity.md)
- [ ] [251 — Schema: relay packages, acknowledgements, version vectors and audit](24-backend/251-be-schema-relay.md)
- [ ] [252 — Repository base and transactions](24-backend/252-be-repositories.md)
- [ ] [253 — Password hashing and the account lifecycle](24-backend/253-be-auth-passwords.md)
- [ ] [254 — Login with rate limiting and lockout](24-backend/254-be-auth-login.md)
- [ ] [255 — Tokens, authentication middleware and device enrolment](24-backend/255-be-auth-tokens.md)
- [ ] [256 — Role matrix and permission checks](24-backend/256-be-permissions.md)
- [ ] [257 — Organisation user endpoints](24-backend/257-be-users-api.md)
- [ ] [258 — Project and membership endpoints](24-backend/258-be-projects-api.md)
- [ ] [259 — Relay: accept, list and download packages](24-backend/259-be-relay-push.md)
- [ ] [260 — Relay: acknowledge, delete and report state](24-backend/260-be-relay-ack.md)
- [ ] [261 — Relay purge job and storage ceilings](24-backend/261-be-retention-job.md)
- [ ] [262 — AI provider abstraction and key custody](24-backend/262-be-ai-provider.md)
- [ ] [263 — AI proxy endpoints, quotas and resilience](24-backend/263-be-ai-proxy.md)
- [ ] [264 — Audit, security events and metrics](24-backend/264-be-audit-service.md)
- [ ] [265 — OpenAPI specification and contract tests](24-backend/265-be-openapi.md)
- [ ] [266 — Export, destroy, deploy and the pipeline](24-backend/266-be-admin-commands.md)
- [ ] [267 — App: backend connection, sign in and enrolment](24-backend/267-fe-backend-config.md)
- [ ] [268 — App: role affordances, cached grants and offline authority](24-backend/268-fe-role-affordances.md)
- [ ] [269 — App: change relay client and controls](24-backend/269-fe-relay-client.md)
- [ ] [270 — App: route AI through the backend](24-backend/270-fe-ai-proxy-client.md)

## 25 — Testing and release

*The suites, the pipeline and the gate that makes a build shippable. A release is two artefacts now, the app and the backend it requires, and neither ships alone.*

- [ ] [271 — Test harnesses: unit, widget and integration](25-testing-and-release/271-test-harness-unit.md)
- [ ] [272 — End-to-end: capture to export, immediate and deferred](25-testing-and-release/272-e2e-capture-to-export.md)
- [ ] [273 — End-to-end: context inheritance and caption scope](25-testing-and-release/273-e2e-context-inheritance.md)
- [ ] [274 — End-to-end: known-asset verification and duplicate override](25-testing-and-release/274-e2e-known-asset.md)
- [ ] [275 — End-to-end: bundle merge and every export format](25-testing-and-release/275-e2e-merge.md)
- [ ] [276 — End-to-end: meeting](25-testing-and-release/276-e2e-meeting.md)
- [ ] [277 — Continuous integration pipelines](25-testing-and-release/277-ci-pipeline.md)
- [ ] [278 — Release build configuration](25-testing-and-release/278-release-build.md)
- [ ] [279 — Release gate program](25-testing-and-release/279-release-checklist.md)
- [ ] [280 — Backlog report generator](25-testing-and-release/280-post-release-backlog.md)
- [ ] [281 — End-to-end: sign in, proxy AI, then go offline](25-testing-and-release/281-e2e-signin-proxy-offline.md)
