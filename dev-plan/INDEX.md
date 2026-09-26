# Tapture — task index

74 implementation prompts across 25 phases. Work top to bottom.

Every task inherits [STANDARD.md](STANDARD.md); read it once before the first task. Phases 01 to 25 are one
task each except phase 23, which still holds the leftover field-feedback extras. Old numbers are listed in
[RETIRED.md](RETIRED.md).

## 01 — Project setup and guardrails

*The repository, and the executable guardrails that enforce every architectural rule. Policies here are code — lints, checkers and tests — not prose.*

- [x] [001 — Project setup and guardrails](01-orchestration/001-project-setup.md)

## 02 — Foundation services

*The empty app that boots, logs, fails safely, and the small services every later feature injects.*

- [x] [002 — Foundation services](02-foundation/002-foundation-services.md)

## 03 — Design system

*Built before any feature. Every later screen is assembled from these parts and never invents its own.*

- [x] [003 — Design system: tokens, themes and the whole widget vocabulary](03-design-system/003-design-system.md)

## 04 — Local database

*Every table the app will ever need, with merge columns from the first migration.*

- [x] [004 — Local database: every table, with merge columns from the first migration](04-data-layer/004-local-database.md)

## 05 — File storage

*The organised folder tree and every service that writes into it.*

- [x] [005 — File storage: the organised folder tree and every service that writes into it](05-file-storage/005-file-storage.md)

## 06 — Application shell

*Navigation, routing and the always-visible status line.*

- [x] [006 — Application shell: navigation, the status line and the frame every feature plugs into](06-app-shell/006-application-shell.md)

## 07 — Account and settings

*The local identity that later becomes an account, the app lock, and the switches every later feature reads.*

- [x] [007 — Account and settings: local identity, the app lock and the switches later features read](07-account-and-settings/007-account-and-settings.md)

## 08 — Projects

*Create, open and manage the container that owns everything else.*

- [x] [008 — Projects: the container that owns everything else](08-projects/008-projects.md)

## 09 — Templates

*The definition of every record shape: shipped, built in the app, or read from a spreadsheet. Columns are atomic (§13.1) and requiredness belongs to the user (§13.2) — both are enforced here, not assumed.*

- [x] [009 — Templates: record shapes with atomic columns, and requiredness the user owns](09-templates/009-templates.md)

## 10 — Reference data

*Imported tables that prefill records and remove repeat typing.*

- [x] [010 — Reference data: datasets, lookups and prefill](10-reference-data/010-reference-data.md)

## 11 — Context

*Set a value once, and it applies to every record until changed.*

- [x] [011 — Context: hierarchy, bar and inheritance](11-context/011-context.md)

## 12 — Capture

*The heart of the app: evidence in, with as little typing as possible, always saved before anything else happens.*

- [x] [012 — Capture: evidence in, saved before anything else](12-capture/012-capture.md)

## 13 — Processing

*On-device first, online only when it earns its place, always resumable and always optional.*

- [ ] [013 — Processing: on-device first, online only when it earns its place](13-processing/013-processing.md)

## 14 — Records

*Find, read and change what has been captured, at any time after capture.*

- [ ] [014 — Records: find, read and change what was captured](14-records/014-records.md)

## 15 — Data quality

*The checks that make the output trustworthy, each with a human in the loop.*

- [ ] [015 — Data quality: validation, duplicates, conflicts and variance](15-data-quality/015-data-quality.md)

## 16 — Review

*Where a person turns proposals into data. Fast for the common case, thorough when needed.*

- [ ] [016 — Review: turning proposals into approved data](16-review/016-review.md)

## 17 — Meetings

*A meeting is a record with structure: minutes, attendance and actions.*

- [ ] [017 — Meetings: minutes, attendance and actions](17-meetings/017-meetings.md)

## 18 — Export

*Five formats, all produced on the device, all reproducible and all recorded.*

- [ ] [018 — Export: XLSX, CSV, JSON, PDF and ZIP, all produced on device](18-export/018-export.md)

## 19 — Bundles and merge

*Collaboration that never touches the backend: a project leaves whole, by hand, and rejoins safely.*

- [ ] [019 — Bundles and merge: a project leaves whole and rejoins safely](19-bundles-and-merge/019-bundles-and-merge.md)

## 20 — Data import

*Continue an inventory someone else started, as records or as a register to verify against.*

- [ ] [020 — Data import: continue an inventory someone else started](20-data-import/020-data-import.md)

## 21 — Cloud upload

*A destination for files the user chooses to send. Never automatic, never a sync channel.*

- [ ] [021 — Cloud upload: a destination the user chooses, never a sync channel](21-cloud-upload/021-cloud-upload.md)

## 22 — Privacy and security

*The controls that decide what leaves the device and what is visible in it.*

- [ ] [022 — Privacy and security: what leaves this device, and what never does](22-privacy-and-security/022-privacy-and-security.md)

## 23 — Hardening

*Making the finished app fast, legible, reachable and unbreakable in the field.*

- [ ] [023 — Hardening: fast, legible, reachable and unbreakable in the field](23-hardening/023-hardening.md)
- [x] [026 — In-app feedback: floating button, capture, download and delete](23-hardening/026-in-app-feedback.md)
- [x] [027 — Feedback screens: compact layout, dictation and reopen safety](23-hardening/027-feedback-dictation-and-layout.md)
- [x] [028 — Feedback archive: ship the prompts generator](23-hardening/028-feedback-prompts-generator.md)
- [ ] [029 — Enable AppDatabase on web](23-hardening/029-enable-app-database-on-web.md)
- [ ] [030 — Fix storage settings on web](23-hardening/030-fix-storage-settings-on-web.md)
- [x] [031 — Dock feedback panel beside app](23-hardening/031-dock-feedback-panel-beside-app.md)
- [x] [032 — Rename More nav to Settings](23-hardening/032-rename-more-nav-to-settings.md)
- [x] [033 — Fix feedback search remount](23-hardening/033-fix-feedback-search-remount.md)
- [x] [034 — Fix feedback camera browse](23-hardening/034-fix-feedback-camera-browse.md)
- [x] [035 — Mark required optional fields](23-hardening/035-mark-required-optional-fields.md)
- [x] [036 — Add email phone fields](23-hardening/036-add-email-phone-fields.md)
- [x] [037 — Add feedback close control](23-hardening/037-add-feedback-close-control.md)
- [x] [038 — Split operator contact fields](23-hardening/038-split-operator-contact-fields.md)
- [x] [039 — Include feedback UI screenshot](23-hardening/039-include-feedback-ui-screenshot.md)
- [x] [040 — Add other window screenshot](23-hardening/040-add-other-window-screenshot.md)
- [x] [041 — Warn before closing the tab with a draft](23-hardening/041-warn-before-closing-tab-with-draft.md)
- [x] [042 — Confirm desktop exit with a draft](23-hardening/042-confirm-desktop-exit-with-draft.md)
- [x] [043 — Align the feedback shot controls](23-hardening/043-align-feedback-shot-controls.md)
- [x] [044 — Soften input placeholder text](23-hardening/044-soften-input-placeholder-text.md)
- [x] [045 — Number feedback rows with their message](23-hardening/045-number-feedback-rows-with-message.md)
- [x] [046 — Add a window share session to screen capture](23-hardening/046-add-window-share-session-api.md)
- [x] [047 — Add repeat external window screenshots](23-hardening/047-add-repeat-external-window-screenshots.md)
- [x] [048 — Fix the storage root on Android](23-hardening/048-fix-storage-root-on-android.md)
- [x] [049 — Save downloads to a public Tapture folder](23-hardening/049-save-downloads-to-public-tapture-folder.md)
- [x] [050 — Keep the feedback bar above the keyboard](23-hardening/050-keep-feedback-bar-above-keyboard.md)
- [x] [051 — Move the storage root to public Documents](23-hardening/051-move-storage-root-to-public-documents.md)
- [x] [052 — Unify the confirmation dialog design](23-hardening/052-unify-confirmation-dialog-design.md)
- [x] [053 — Add screenshot help for other screens](23-hardening/053-add-screenshot-help-for-other-screens.md)
- [x] [054 — Persist the theme mode in the settings store](23-hardening/054-persist-theme-mode-in-settings-store.md)
- [x] [055 — Add the Appearance settings screen](23-hardening/055-add-appearance-settings-screen.md)
- [x] [056 — Show the feedback download location](23-hardening/056-show-feedback-download-location.md)
- [x] [057 — Add a Save to a folder option](23-hardening/057-add-save-to-folder-option.md)
- [x] [058 — Show a collapse icon on the feedback form](23-hardening/058-show-collapse-icon-on-feedback-form.md)
- [x] [059 — Show a single feedback image as a thumbnail](23-hardening/059-show-single-feedback-image-as-thumbnail.md)
- [x] [060 — Borderless overflow menus](23-hardening/060-borderless-overflow-menus.md)
- [x] [061 — Resolve shell, settings and capture feedback](23-hardening/061-resolve-shell-capture-feedback.md)
- [ ] [062 — Resolve feedback archive 23092026-1635](23-hardening/062-resolve-feedback-23092026.md)
- [ ] [063 — Resolve projects, capture and template feedback](23-hardening/063-resolve-feedback-23092026-2222.md)
- [ ] [064 — Resolve projects and capture feedback](23-hardening/064-resolve-feedback-24092026.md)
- [ ] [065 — Place the audio record control in the caption field](23-hardening/065-place-audio-record-in-caption.md)
- [ ] [066 — Resolve project, capture and export feedback](23-hardening/066-resolve-project-capture-feedback.md)
- [ ] [067 — Resolve project, template and capture feedback](23-hardening/067-resolve-project-template-capture-feedback.md)
- [ ] [068 — Resolve project, record, capture and export feedback](23-hardening/068-resolve-project-record-capture-export-feedback.md)
- [ ] [069 — Resolve record, capture markup and project photo feedback](23-hardening/069-resolve-record-capture-markup-feedback.md)
- [ ] [070 — Resolve web capture, caption and template feedback](23-hardening/070-resolve-web-capture-caption-template-feedback.md)
- [ ] [071 — Enable processing, export and list thumbnails on web](23-hardening/071-enable-processing-export-on-web.md)
- [ ] [072 — List processed records on the project home](23-hardening/072-list-processed-records-on-project-home.md)
- [ ] [073 — Keep resumed capture photos](23-hardening/073-keep-resumed-capture-photos.md)
- [ ] [074 — Ship the full template catalogue](23-hardening/074-ship-full-template-catalogue.md)

## 24 — The minimal backend

*The minimal backend of specification Part XI. It is **required**: accounts, authentication, roles, AI functionality and provider-key custody — the five things a single device cannot supply for itself, and nothing more. The change relay (§72) is the one optional capability inside this phase; every other task here is part of the MVP. Required to exist, never required to be reachable (§70.4).*

- [ ] [024 — The minimal backend, and the app that runs on it](24-backend/024-minimal-backend.md)

## 25 — Testing and release

*The suites, the pipeline and the gate that makes a build shippable. A release is two artefacts now, the app and the backend it requires, and neither ships alone.*

- [ ] [025 — Testing and release: the suites, the pipeline and the gate over both artefacts](25-testing-and-release/025-testing-and-release.md)
