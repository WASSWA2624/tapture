# Feedback prompts — TAPTURE-26092026-0434.xlsx

10 entries → 1 prompt, 11 work items. Generated 26 September 2026. Repository commit: c5b76bc.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Route the record page | FBK0000147 | Defect | P2 | — |
| 001 | W2 | Keep typed captions and say where they go | FBK0000149 | Defect | P2 | — |
| 001 | W3 | Decode thumbnails where the isolate can | FBK0000146 | Defect | P3 | — |
| 001 | W4 | Crop the photo that is shown, and show the result | FBK0000150 | Defect | P3 | — |
| 001 | W5 | Keep page content clear of the folded feedback bar | FBK0000145 | Defect | P3 | — |
| 001 | W6 | Put photo corner controls flush and visible | FBK0000153 | Defect | P3 | — |
| 001 | W7 | Add markup ink and size tokens | FBK0000151, FBK0000152 | Improvement | P4 | — |
| 001 | W8 | Choose ink colour and size in Draw | FBK0000151 | Improvement | P5 | W4, W7 |
| 001 | W9 | Type on a photo with a live preview | FBK0000152 | Improvement | P5 | W4, W7 |
| 001 | W10 | Edit a saved record on the capture page | FBK0000148 | Improvement | P5 | W1, W2, W4, W6 |
| 001 | W11 | Give a project an optional photo | FBK0000154 | Suggestion | P6 | W3 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000145 | General feedback | Projects › Testing | 001 W5 |
| FBK0000146 | General feedback | Projects › Testing | 001 W3 |
| FBK0000147 | General feedback | Projects › Testing › Records | 001 W1 |
| FBK0000148 | General feedback | Projects › Testing › Records | 001 W10 |
| FBK0000149 | General feedback | Capture | 001 W2 |
| FBK0000150 | General feedback | Capture | 001 W4 |
| FBK0000151 | General feedback | Capture | 001 W7, 001 W8 |
| FBK0000152 | General feedback | Capture | 001 W7, 001 W9 |
| FBK0000153 | General feedback | Capture | 001 W6 |
| FBK0000154 | General feedback | Projects | 001 W11 |

## Open questions

- 001 D1, default (a): thumbnails decode with the pure-Dart `image` package inside the isolate runner, because `dart:ui` cannot run in a spawned isolate. No FE-PERF-02 exception is needed.
- 001 D2, default (a): captions keep going to the ticked photos, and to all photos when none is ticked, as they are typed. The field stops dropping keystrokes and says where the text goes. No Add button.
- 001 D3, default (a): while feedback is minimized, the app is inset by the folded bar's height, above the keyboard when it is open, so every page scrolls clear of the bar.
- 001 D4, default (a): draw and type-on keep painting with the `image` package in the isolate. Six ink tokens and three sizes are shared, and text uses the bundled bitmap Arial scaled to size.
- 001 D5, default (a): type-on shows live text with several lines, dragging, three sizes, the shared inks and a backing switch, one block per save.
- 001 D6, default (a): a record edit runs as a capture session stored under `edit:<recordId>`. Save writes only photo and caption differences in one transaction, raw captions are refined rather than overwritten, and field values stay on the record page.
- 001 D7, default (a): a project photo is a file under `projects/<folder>/cover/`, recorded in the settings JSON as `coverPhoto`. It replaces the row number where set, and the photo picker moves to `core/files`.
- FBK0000145 is read as "the minimized feedback bar hides the bottom of each page, and no scroll reaches it". The screenshots show long pages with nothing marked. If the reporter meant that the page cannot be dragged at all while the bar is folded, W5 does not cover it and the reporter needs to say so.
- FBK0000152 asks for "much more … maximum versatility". D5 names what W9 builds, and the reporter is asked which further text features matter: rotation, several blocks per save, fonts, shapes.
- Noticed, not reported: the capture tray's thumbnails are the whole photo written as a "thumbnail" (`DriftPhotoRepository.cachedThumbnailForBytes`), because the default decoder fails (W3). W3 removes the cause and leaves the fallback in place.
- Noticed, not reported: in landscape, a keyboard that leaves less than about 260dp for the shell overflows the navigation rail's four destinations (`nav_shell.dart`, `_Rail`). Raise a task with `dart run tool/new_task.dart` to let the rail scroll.
- Carried over: task 068's record page and record editing work (from the 25 September 21:20 archive, whose prompt folder has been removed) is completed here by W1 and W10.
