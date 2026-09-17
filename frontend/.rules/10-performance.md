# 10 — Performance

Budgets, not aspirations. Each one has a test that measures it.

*Enforced by dev-plan task 240 and the performance suites in phase 25.*

## FE-PERF-01 — The budgets
Cold start to project list under 2s. Shutter to ready for the next shot under 400ms. Search over 10,000 records under
300ms. Smooth scrolling at 10,000 rows. XLSX export of 5,000 records under 30s with progress.

## FE-PERF-02 — The UI thread does no work
No file input or output, database write, hashing, image decode, compression, export or merge on the UI thread. Heavy
work goes through the isolate runner with progress and cancellation.

## FE-PERF-03 — Lists are virtualised and paged
Page size from `AppConstants`. Never materialise a whole project's records or photos to draw a screen.

## FE-PERF-04 — Thumbnails in lists, full images only in the viewer
Cached by hash and size, with a cap on concurrent decodes. Decoding a full photo to draw a 96dp square is a defect.

## FE-PERF-05 — Rebuild narrowly
`const` constructors wherever possible; `select` to watch one field; families instead of rebuilding a list on one row's
change.

## FE-PERF-06 — Index before optimising, measure before claiming
Every query behind a screen is measured against a realistically seeded database, and the measurement goes in the pull
request.

## FE-PERF-07 — Stream large files
Hashing, copying, packaging and uploading read in chunks. Nothing loads a 100MB file into memory.

## FE-PERF-08 — Background work is governed
Only through `BackgroundPolicy`: charging and idle for on-device OCR, settings and network permitting for automatic
processing, nothing while the app is in the foreground.

## FE-PERF-09 — Memory returns to baseline
After a 200-record capture session, a large export or a large merge, memory returns to where it started. Leaks are
caught by the ceiling test, not by users.

## FE-PERF-10 — Degrade, never freeze
A slow provider, a full disk or a huge project produces progress and a cancel button — never a frozen screen.
