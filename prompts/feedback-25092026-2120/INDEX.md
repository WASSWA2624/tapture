# Feedback prompts — TAPTURE-25092026-2120.xlsx

12 entries → 1 prompt, 14 work items. Generated 25 September 2026. Repository commit: ce06e24.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Stop the shell applying the keyboard inset twice | FBK0000138, FBK0000142 | Defect | P2 | — |
| 001 | W2 | Show the photo on record rows | FBK0000136 | Defect | P3 | — |
| 001 | W3 | Count each template's records | FBK0000139 | Defect | P3 | — |
| 001 | W4 | Remove the project home count cards | FBK0000141 | Improvement | P5 | — |
| 001 | W5 | Remove the template and context sections from the home | FBK0000140 | Improvement | P5 | W4 |
| 001 | W6 | Say what a search looks for and when it misses | FBK0000138 | Improvement | P5 | W1, W5 |
| 001 | W7 | Hold Save and process until the device is online | FBK0000132 | Improvement | P5 | — |
| 001 | W8 | Send an export to another app | FBK0000133 | Improvement | P5 | W7 |
| 001 | W9 | Summarise the project on the export page | FBK0000134 | Improvement | P5 | W8 |
| 001 | W10 | Tick photos and caption the ticked ones | FBK0000132 | Improvement | P5 | W2, W7 |
| 001 | W11 | Read, edit and delete a caption in the photo preview | FBK0000132 | Improvement | P5 | W10 |
| 001 | W12 | Create a template with several fields at once | FBK0000144 | Gap | P5 | — |
| 001 | W13 | Open a record's page from its row | FBK0000137 | Gap | P5 | W2, W5 |
| 001 | W14 | Edit a saved record on the capture page | FBK0000135 | Improvement | P5 | W10, W11, W13 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000132 | General feedback | Capture | 001 W7, 001 W10, 001 W11 |
| FBK0000133 | General feedback | Projects › Testing › Ready to export | 001 W8 |
| FBK0000134 | General feedback | Projects › Testing › Ready to export | 001 W9 |
| FBK0000135 | General feedback | Projects › Testing | 001 W14 |
| FBK0000136 | General feedback | Projects › Testing | 001 W2 |
| FBK0000137 | General feedback | Projects › Testing | 001 W13 |
| FBK0000138 | General feedback | Projects › Testing | 001 W1, 001 W6 |
| FBK0000139 | General feedback | Projects | 001 W3 |
| FBK0000140 | General feedback | Projects › Testing › Templates | 001 W5 |
| FBK0000141 | General feedback | Projects › Eficon | 001 W4 |
| FBK0000142 | General feedback | Capture | 001 W1 |
| FBK0000144 | General feedback | Projects › Eficon › Templates | 001 W12 |

## Open questions

- 001 D1, default (a): delete the four home cards and every symbol only they use (`watchHome`, `ProjectHomeCounts`, the eight `Copy.home*` keys and the home's filter helpers). The filtered records, queue and export routes stay.
- 001 D2, default (a): remove the Templates radio group and the context caption from the home. Capture's Template field stays the one place to choose a template, and the shell's context bar still shows a set context.
- 001 D3, default (a): disable Save and process while the device is offline, with a caption, and keep Save raw enabled. The offline flag moves into `core/network` as `offlineNowProvider`, which capture and export share.
- 001 D4, default (a): keep one Share action that opens the system share sheet on Android and iOS, which reaches WhatsApp, email, Telegram and every other installed app, and say so on the page. No per-app buttons and no new dependency.
- 001 D5, default (a): the export page summarises the project and the file. The workbook keeps its Record, Status and Photos columns, and richer workbook content stays with task 018.
- 001 D6, default (a): capture tray thumbnails drop the photo-type badge, which always reads "Other", to make room for the checkbox. The preview title still names the type.
- 001 D7, default (a): the photo preview offers the five existing operations (rotate, crop, draw, type on the photo, undo an edit) and adds none.
- 001 D8, default (a): a record edit runs as a capture session stored under `edit:<recordId>`, and Save writes only the differences in one transaction. Raw captions and values are refined, never overwritten, and removed photos are tombstoned.
- FBK0000142 needs the reporter: "fix the search bar here" names no symptom. W1 fixes the keyboard collapse that this search field shows, the same fault FBK0000138 reports. If the reporter meant something else, it needs a new entry.
- FBK0000132 needs the reporter for D7: which photo operations "etc - add more" should add beyond rotate, crop, draw, type on the photo and undo.
- Noticed, not reported: the Delete action on a record archives it, and `exportProject` writes every record whose status is not `deleted`, so deleted records still reach the workbook. W9's summary uses the same rule, so the page matches the file. Raise a task with `dart run tool/new_task.dart` if deleted records should leave the export.
- Noticed, not reported: on Android, sharing an export first requests the photos permission (`openExternally` with `checkStorage: true`, mapped to `Permission.photos`), although the copy it shares sits in the app's cache. W8 makes that failure visible and does not change the request. Raise a task if the prompt should go.
- Noticed, not reported: on desktop the export's Share action opens the file in its default app. D4 keeps that behaviour.
