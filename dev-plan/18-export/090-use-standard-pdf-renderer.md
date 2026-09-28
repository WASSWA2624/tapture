# 090 — Use the standard PDF renderer for deliverable reports

**Implementation step:** 18.02

**Phase** 18 · Export  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [003](../03-design-system/003-design-system.md), [018](018-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

**Implementation started:** Yes

Replace task 018's hand-written PDF byte stub with the standard pure-Dart `pdf` package, pinned to 3.11.3.
This release supports the existing archive 3.6.1 and image 4.3.0 dependencies. Its Apache-2.0 licence was checked at
[the publisher's versioned licence](https://pub.dev/packages/pdf/versions/3.11.3/license). Keep report composition
behind PdfEngine, with shared typography, page headers/footers, wrapping, pagination and embedded photo blocks.
No network font fetches occur during export; all rendering stays local.

This task builds on 018's PdfEngine contract and reports. Task 018's reopened PDF-family acceptance — the cover and
body golden and the record report in both photo layouts — closes only once this renderer's Definition of done is
verified.

## Files

- `frontend/pubspec.yaml` and `frontend/pubspec.lock`
- `frontend/tool/allowlist.yaml`
- `frontend/lib/core/export/pdf/pdf_engine.dart`
- `frontend/test/core/export/pdf_engine_test.dart`

## Definition of done

- [ ] Dependency is pinned, licence recorded, and the allowlist check passes.
- [ ] PdfEngine emits valid PDFs with wrapped text, multiple pages, page numbers and actual images.
- [ ] Cancellation emits no completed artefact and originals remain unchanged.
- [ ] Tests: real PDF structure and multipage/image regression tests; independent parser/render verification of a generated fixture.
