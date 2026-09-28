# 080 — Establish document adapters and approved dependencies

**Implementation step:** 26.01

**Phase** 26 · Documentation  |  **Depends on** [005](../05-file-storage/005-file-storage.md), [018](../18-export/018-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Establish the supported formats and platform adapters required by §§77–78, before promising that any attachment
can be read or reproduced. This is the dedicated dependency task under FE-FLOW-06. It must leave executable
adapter probes and fakes, an explicit capability registry, and pinned, licensed dependencies where existing code
cannot do the job; a package shortlist alone is not completion.

Evaluate the existing archive/XML, CSV/XLSX, OCR, file and export facilities first. Inspect real fixture outputs:
the current PDF writer is not a paginated document renderer, and DOCX, PDF reading, video extraction and rich text
editing are not demonstrated by a checked task elsewhere in the plan. Reuse existing public contracts where
possible; wrap chosen packages in `core/`, with pure domain-facing interfaces and platform implementations.

## Files

- `frontend/pubspec.yaml`, `frontend/pubspec.lock`, `frontend/tool/allowlist.yaml`
- `frontend/lib/core/documents/` (new capability models, decoder/render adapter interfaces and platform bridges)
- `frontend/lib/core/files/document_picker*.dart`, platform file-channel implementations
- `frontend/lib/core/export/` (adapter bridges to existing writers)
- `frontend/test/core/documents/`, `frontend/test/fixtures/documentation/`
- `frontend/tool/check_structure.dart`, architecture fixtures and `frontend/.rules/11-security-privacy.md` with
  its enforcing tests, only to register the new feature and explicitly adopted prompt boundary
- `dev-plan/26-documentation/capabilities.md` (new verified matrix, dependency/licence decisions and fidelity limits)

## Contract

- `DocumentCapabilities` reports by format and platform: retain, inspect, extract text/tables/media, render and
  template fidelity. `supported`, `partial`, `onlineRequired`, `passwordRequired` and `unsupported` are distinct.
- A shared decoder interface returns typed blocks, source locators and warnings, never a success flag without
  usable content. A renderer capability describes the actual supported output structures and template features.
- Extend `DocumentPicker` with a backwards-compatible multi-file operation and bounded file metadata/stream access;
  preserve `pick` for package import and all existing callers. Domain models do not expose plugins or file handles.

## Steps

1. Run a capability probe against representative TXT/MD, text PDF, scanned PDF, DOCX, XLSX, CSV, JPEG/PNG, audio,
   video and ZIP fixtures on the supported runtime families. Record where extraction is local, proxy-assisted or
   unavailable. Include corrupt and password-protected samples; do not infer support from an extension.
2. Choose the smallest maintainable adapter set for PDF text/rendering, DOCX reading/writing, rich text editing,
   media inspection/extraction and multi-file picking. Reuse the existing archive, image and XLSX code where its
   fixture behaviour meets the contract. Pin approved new dependencies, record licences and replacement rationale,
   and add each to the allowlist in this task.
3. Implement thin adapter bridges and deterministic fakes. Text/Markdown, document headings/tables, spreadsheet
   sheets/cells, image OCR, bounded audio transcription and video audio/frames must have an explicit capability
   path. A missing native codec must report unsupported; it must never fabricate a transcript.
4. Prove basic editable DOCX and XLSX, paginated PDF, Markdown and CSV output viability. Prove a supported DOCX
   placeholder/table and XLSX header/row example can be filled without treating template examples as input facts.
   Record format-specific limits before later tasks use them.
5. Update the feature scaffold allowlist and FE-SEC-05 prompt-injection rule/fixtures for the deliberate Prompt
   role: explicitly adopted prompt-file text is user instruction, while input/format/archive content stays
   untrusted evidence. Preserve existing network, layering and raw-evidence boundaries; do not weaken them globally.

## Constraints

- No feature-specific SDK calls or duplicated file pickers (FE-STR-11, FE-CONS-01). No `dart:io` imports in a web
  path. Avoid loading entire videos, expanded archives or large spreadsheets into memory.
- No promise of pixel-identical Office/PDF reproduction, every media codec or arbitrary executable archive content.
- Do not enable macros, external links, remote HTML, document scripts or network retrieval while decoding.
- Adapter evaluation is not permission to add a server document store or conversion service. Conversion stays on
  device; provider-assisted extraction uses the existing governed proxy path when available in task 084.

## Definition of done

- [ ] The checked-in capability matrix matches executable fixture results for Android, desktop and web, including
      explicit limitations and the release formats in §84.
- [ ] Baseline media fixtures cover JPEG/PNG/WebP, WAV/MP3/M4A and a named tested MP4 codec profile with both
      timestamped audio and sampled visual evidence; platform limits are explicit.
- [ ] Added dependencies are pinned, allowlisted, licensed and wrapped; rejected/unused packages are not installed.
- [ ] Existing single-document selection still works; multi-selection supports cancellation, unreadable files and
      metadata inspection without reading unbounded content into memory.
- [ ] Adapter probes can read representative supported input and generate independently readable DOCX, XLSX, PDF,
      Markdown and CSV outputs; missing functionality fails with a typed capability reason.
- [ ] Tests cover malformed files, unsupported codec/platform, safe cancellation and a fake for every new platform
      interface; format-reader assertions inspect contents rather than only file extensions.

## Out of scope

Documentation database, workspace UI, archive expansion policy, production generation and release-ready renderers.
Those are the following tasks; this task establishes the usable adapter boundary they depend on.
