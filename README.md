# Tapture

**Tap it. It's data.**

A local-first Flutter app for field data capture. Photograph or describe a thing — equipment, a building, stock, a plot, a meeting — and Tapture turns the evidence into structured records you can export as XLSX, CSV, JSON, PDF or a portable ZIP bundle.

- **Offline by default.** Capture, edit, search, review, approve and export all work with no network, for weeks at a time. Only the online AI steps, the first sign-in and uploads you tap go out.
- **The device is the store of record.** Every record, photo and export lives on the device. A small required server holds people, permissions and AI keys — never project content, and never a backup.
- **Type as little as possible.** Context values persist across records, dates fill themselves, barcodes and reference data prefill the rest.
- **Nothing invented.** Raw input is kept beside the AI-refined version, and a person approves every record.
- **Anything, not just assets.** Behaviour comes from templates, so the same app inventories equipment, buildings, plants, animals, people or meetings.

## The backend, and what it is not

Every deployment includes one small server, run by the organisation that owns the data, one instance per organisation. It has five responsibilities and no others: **users, authentication, roles, AI functionality and custody of the AI provider keys** (specification Part XI).

It is required to **exist**. It is never required to be **reachable**. A device that has signed in once keeps capturing, reviewing, editing, merging and exporting with the server unreachable for weeks; the session and role grant are cached, and AI work queues until it returns. Being unable to reach the server never costs a user a record.

It never stores project content, never arbitrates a merge, and is never a backup — backup stays a manual ZIP export you keep where you choose. An optional change relay on the same server can carry encrypted bundles between devices; it is off by default for every project, and a deployment that never switches it on is complete.

## Repository layout

```text
frontend/        the Flutter application
  .rules/        13 rule files: structure, coding, state, theming, responsiveness, simplicity,
                 consistency, l10n, a11y, performance, security, testing, workflow
backend/         the required minimal server (specification Part XI)
  .rules/        11 rule files: structure, coding, API, data, security, the relay boundary,
                 AI proxy, observability, testing, deployment, workflow
resources/       the planning template catalogue and the generated list of every shipped template
dev-plan/        281 implementation prompts, in build order
branding/        the identity: logos, app icons, splash, palette, and the generator that draws them
  tool/          one geometry definition; every asset is regenerated from it
run-tools/        run the app locally, and build the three deployable artefacts
  deploy/        one build script and one update script per artefact
app-write-up.md  the product and technical specification
```

## Documentation

- [app-write-up.md](app-write-up.md) — the full product and technical specification.
- [resources/template-library.md](resources/template-library.md) — every shipped template: the 23 starter templates
  and the 2,349 catalogue templates, with their codes, keys, record types and fields (generated; see §13.7).
- [dev-plan/README.md](dev-plan/README.md) — how the build is sequenced, and where to start.
- [dev-plan/INDEX.md](dev-plan/INDEX.md) — all 281 tasks in one list.
- [dev-plan/STANDARD.md](dev-plan/STANDARD.md) — the standing prompt every task inherits.
- [branding/BRAND.md](branding/BRAND.md) — the identity: mark, wordmark, palette and how to use them.
- [run-tools/README.md](run-tools/README.md) — running the app locally, and building the APK, web bundle and backend archive.
- [frontend/.rules/](frontend/.rules/) and [backend/.rules/](backend/.rules/) — the conventions every task obeys.

## Status

Specification and plan complete; implementation starts at dev-plan task 001. The MVP is two artefacts that ship together — the app and the backend at its smallest useful size — and one release gate covers both.
