# Feedback prompts — TAPTURE-24092026-2143.xlsx

25 entries → 1 prompt, 12 work items. Generated 25 September 2026. Repository commit: 9baaeff.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Name and file the export copy | FBK0000114, FBK0000115, FBK0000116 | Gap | P2 | — |
| 001 | W2 | Show the active page title | FBK0000094, FBK0000097, FBK0000101, FBK0000105, FBK0000109 | Defect | P3 | — |
| 001 | W3 | Rebuild the capture photo tray | FBK0000111, FBK0000112 | Defect | P3 | — |
| 001 | W4 | Shorten the project delete label | FBK0000092 | Improvement | P5 | — |
| 001 | W5 | Separate the project filters | FBK0000093 | Improvement | P5 | — |
| 001 | W6 | Shorten the home count cards | FBK0000095 | Improvement | P5 | — |
| 001 | W7 | Name the home capture action | FBK0000107 | Improvement | P5 | — |
| 001 | W8 | Stack the capture save actions | FBK0000108 | Improvement | P5 | W3 |
| 001 | W9 | Pin the add-photo actions | FBK0000110 | Improvement | P5 | W8 |
| 001 | W10 | Rebuild context levels | FBK0000097, FBK0000098, FBK0000099, FBK0000100 | Gap | P5 | W2 |
| 001 | W11 | Search and add project templates | FBK0000101, FBK0000102, FBK0000103, FBK0000104, FBK0000106 | Gap | P5 | W2 |
| 001 | W12 | List captured items on the home | FBK0000098, FBK0000113 | Gap | P5 | W6, W7, W10 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000092 | General feedback | Projects | 001 W4 |
| FBK0000093 | General feedback | Projects · Project filters | 001 W5 |
| FBK0000094 | General feedback | New project | 001 W2 |
| FBK0000095 | General feedback | Projects · Unprocessed | 001 W6 |
| FBK0000096 | General feedback | Projects | Needs clarification (the projects list shows more than one project and is titled Projects; which title should that list use?) |
| FBK0000097 | General feedback | Projects | 001 W2, 001 W10 |
| FBK0000098 | General feedback | Projects | 001 W10, 001 W12 |
| FBK0000099 | General feedback | Projects · Context levels | 001 W10 |
| FBK0000100 | General feedback | Projects · Context levels | 001 W10 |
| FBK0000101 | General feedback | Projects · Templates | 001 W2, 001 W11 |
| FBK0000102 | General feedback | Projects · Templates | 001 W11 |
| FBK0000103 | General feedback | Projects · Templates | 001 W11 |
| FBK0000104 | General feedback | Projects · Templates | 001 W11 |
| FBK0000105 | General feedback | Projects · Templates | 001 W2 |
| FBK0000106 | General feedback | Projects · Templates | 001 W11 |
| FBK0000107 | General feedback | Projects | 001 W7 |
| FBK0000108 | General feedback | Projects · Capture | 001 W8 |
| FBK0000109 | General feedback | Projects · Capture | 001 W2 |
| FBK0000110 | General feedback | Projects · Capture | 001 W9 |
| FBK0000111 | General feedback | Projects · Capture | 001 W3 |
| FBK0000112 | General feedback | Projects · Capture | 001 W3 |
| FBK0000113 | General feedback | Projects | 001 W12 |
| FBK0000114 | General feedback | Projects · Ready to export | 001 W1 |
| FBK0000115 | General feedback | Projects · Ready to export | 001 W1 |
| FBK0000116 | General feedback | Projects · Ready to export | 001 W1 |

## Open questions

- 001 D1, default (a): allow several context fields to share a level by changing the stored unique key and keeping existing rows.
- 001 D2, default (a): keep the project home hub and add the captured-item list under the count cards.
- 001 D3, default (a): the home switches templates; the project overflow menu opens the template list.
- 001 D4, default (a): add an optional export subfolder on `DownloadService.save` so feedback downloads stay where they are.
- 001 D5, default (a): name the folder Tapture/Exports. The message spelled the product name wrong.
- 001 D6, default (a): one context hierarchy per project; the template control only filters which fields can be added.
- 001 D7, default (a): Delete archives a captured item and keeps the photo and the original value; Edit writes a refined value beside it.
- FBK0000096 needs the reporter: the projects list is titled Projects while showing more than one project. Which title should that list use?
