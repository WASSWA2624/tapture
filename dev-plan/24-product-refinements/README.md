# 24 — Product refinements

Complete the field-feedback, storage, template, capture and navigation refinements that extend the core app before
Documentation is built. The backend is available before task 077; project packages from task 076 support document
archive inputs, and task 079 applies compact More navigation after the earlier Settings-label change. The final
whole-app hardening pass follows every feature in [step 27](../27-hardening/README.md).

<!-- dev-plan:generated:start -->

## Implementation progress

**Step 24 — Partially complete**

56 total · 51 Complete · 5 Partially complete · 0 Pending. Status is generated from each task’s Definition of done; follow sub-step order below.

| Sub-step | Task ID | File / implementation | Status | Done | Dependencies / readiness |
| --- | --- | --- | --- | ---: | --- |
| 24.01 | 026 | [In-app feedback: floating button, capture, download and delete](026-in-app-feedback.md) | **Complete** | 6/6 | None; Dependencies complete |
| 24.02 | 027 | [Feedback screens: compact layout, dictation and reopen safety](027-feedback-dictation-and-layout.md) | **Complete** | 10/10 | 12.01 (012), 24.01 (026); Prerequisite review: 012 |
| 24.03 | 028 | [Feedback archive: ship the prompts generator](028-feedback-prompts-generator.md) | **Complete** | 3/3 | 24.01 (026), 24.02 (027); Dependencies complete |
| 24.04 | 029 | [Enable AppDatabase on web](029-enable-app-database-on-web.md) | **Complete** | 4/4 | 04.01 (004), 07.01 (007); Prerequisite review: 004 |
| 24.05 | 030 | [Fix storage settings on web](030-fix-storage-settings-on-web.md) | **Complete** | 3/3 | 07.01 (007), 24.04 (029); Dependencies complete |
| 24.06 | 031 | [Dock feedback panel beside app](031-dock-feedback-panel-beside-app.md) | **Complete** | 3/3 | 24.02 (027); Dependencies complete |
| 24.07 | 032 | [Rename More nav to Settings](032-rename-more-nav-to-settings.md) | **Complete** | 3/3 | 06.01 (006); Dependencies complete |
| 24.08 | 033 | [Fix feedback search remount](033-fix-feedback-search-remount.md) | **Complete** | 3/3 | 24.01 (026); Dependencies complete |
| 24.09 | 034 | [Fix feedback camera browse](034-fix-feedback-camera-browse.md) | **Complete** | 4/4 | 24.01 (026); Dependencies complete |
| 24.10 | 035 | [Mark required optional fields](035-mark-required-optional-fields.md) | **Complete** | 3/3 | 03.01 (003), 07.01 (007); Dependencies complete |
| 24.11 | 036 | [Add email phone fields](036-add-email-phone-fields.md) | **Complete** | 4/4 | 03.01 (003), 24.10 (035); Dependencies complete |
| 24.12 | 037 | [Add feedback close control](037-add-feedback-close-control.md) | **Complete** | 4/4 | 24.01 (026); Dependencies complete |
| 24.13 | 038 | [Split operator contact fields](038-split-operator-contact-fields.md) | **Complete** | 5/5 | 07.01 (007), 24.10 (035), 24.11 (036); Dependencies complete |
| 24.14 | 039 | [Include feedback UI screenshot](039-include-feedback-ui-screenshot.md) | **Complete** | 4/4 | 24.06 (031); Dependencies complete |
| 24.15 | 040 | [Add other window screenshot](040-add-other-window-screenshot.md) | **Complete** | 5/5 | 24.01 (026); Dependencies complete |
| 24.16 | 041 | [Warn before closing the tab with a draft](041-warn-before-closing-tab-with-draft.md) | **Complete** | 5/5 | None; Dependencies complete |
| 24.17 | 042 | [Confirm desktop exit with a draft](042-confirm-desktop-exit-with-draft.md) | **Complete** | 4/4 | 24.16 (041); Dependencies complete |
| 24.18 | 043 | [Align the feedback shot controls](043-align-feedback-shot-controls.md) | **Complete** | 5/5 | None; Dependencies complete |
| 24.19 | 044 | [Soften input placeholder text](044-soften-input-placeholder-text.md) | **Complete** | 3/3 | None; Dependencies complete |
| 24.20 | 045 | [Number feedback rows with their message](045-number-feedback-rows-with-message.md) | **Complete** | 5/5 | None; Dependencies complete |
| 24.21 | 046 | [Add a window share session to screen capture](046-add-window-share-session-api.md) | **Complete** | 5/5 | None; Dependencies complete |
| 24.22 | 047 | [Add repeat external window screenshots](047-add-repeat-external-window-screenshots.md) | **Complete** | 5/5 | 24.21 (046); Dependencies complete |
| 24.23 | 048 | [Fix the storage root on Android](048-fix-storage-root-on-android.md) | **Complete** | 4/4 | 05.01 (005), 07.01 (007); Dependencies complete |
| 24.24 | 049 | [Save downloads to a public Tapture folder](049-save-downloads-to-public-tapture-folder.md) | **Complete** | 5/5 | 24.01 (026); Dependencies complete |
| 24.25 | 050 | [Keep the feedback bar above the keyboard](050-keep-feedback-bar-above-keyboard.md) | **Complete** | 5/5 | 24.01 (026), 24.02 (027); Dependencies complete |
| 24.26 | 051 | [Move the storage root to public Documents](051-move-storage-root-to-public-documents.md) | **Complete** | 5/5 | 05.01 (005), 24.23 (048), 24.24 (049); Dependencies complete |
| 24.27 | 052 | [Unify the confirmation dialog design](052-unify-confirmation-dialog-design.md) | **Complete** | 5/5 | 03.01 (003), 24.01 (026); Dependencies complete |
| 24.28 | 053 | [Add screenshot help for other screens](053-add-screenshot-help-for-other-screens.md) | **Complete** | 4/4 | 24.01 (026), 24.12 (037); Dependencies complete |
| 24.29 | 054 | [Persist the theme mode in the settings store](054-persist-theme-mode-in-settings-store.md) | **Complete** | 5/5 | 03.01 (003), 07.01 (007); Dependencies complete |
| 24.30 | 055 | [Add the Appearance settings screen](055-add-appearance-settings-screen.md) | **Complete** | 4/4 | 03.01 (003), 07.01 (007), 24.29 (054); Dependencies complete |
| 24.31 | 056 | [Show the feedback download location](056-show-feedback-download-location.md) | **Complete** | 5/5 | 24.01 (026), 24.24 (049); Dependencies complete |
| 24.32 | 057 | [Add a Save to a folder option](057-add-save-to-folder-option.md) | **Complete** | 5/5 | 24.01 (026), 24.24 (049), 24.31 (056); Dependencies complete |
| 24.33 | 058 | [Show a collapse icon on the feedback form](058-show-collapse-icon-on-feedback-form.md) | **Complete** | 5/5 | 24.12 (037); Dependencies complete |
| 24.34 | 059 | [Show a single feedback image as a thumbnail](059-show-single-feedback-image-as-thumbnail.md) | **Complete** | 4/4 | 24.01 (026), 24.02 (027); Dependencies complete |
| 24.35 | 060 | [Borderless overflow menus](060-borderless-overflow-menus.md) | **Complete** | 5/5 | None; Dependencies complete |
| 24.36 | 061 | [Resolve shell, settings and capture feedback](061-resolve-shell-capture-feedback.md) | **Complete** | 1/1 | None; Dependencies complete |
| 24.37 | 062 | [Resolve feedback archive 23092026-1635](062-resolve-feedback-23092026.md) | **Complete** | 8/8 | 11.01 (011), 12.01 (012), 13.01 (013), 24.36 (061); Prerequisite review: 012, 013 |
| 24.38 | 063 | [Resolve projects, capture and template feedback](063-resolve-feedback-23092026-2222.md) | **Partially complete** | 9/11 | 12.01 (012), 24.37 (062); Waiting for: 012 |
| 24.39 | 064 | [Resolve projects and capture feedback](064-resolve-feedback-24092026.md) | **Complete** | 11/11 | 12.01 (012), 24.38 (063); Prerequisite review: 012, 063 |
| 24.40 | 065 | [Place the audio record control in the caption field](065-place-audio-record-in-caption.md) | **Complete** | 5/5 | None; Dependencies complete |
| 24.41 | 066 | [Resolve project, capture and export feedback](066-resolve-project-capture-feedback.md) | **Complete** | 7/7 | None; Dependencies complete |
| 24.42 | 067 | [Resolve project, template and capture feedback](067-resolve-project-template-capture-feedback.md) | **Complete** | 11/11 | None; Dependencies complete |
| 24.43 | 068 | [Resolve project, record, capture and export feedback](068-resolve-project-record-capture-export-feedback.md) | **Complete** | 14/14 | None; Dependencies complete |
| 24.44 | 069 | [Resolve record, capture markup and project photo feedback](069-resolve-record-capture-markup-feedback.md) | **Complete** | 12/12 | None; Dependencies complete |
| 24.45 | 070 | [Resolve web capture, caption and template feedback](070-resolve-web-capture-caption-template-feedback.md) | **Complete** | 14/14 | None; Dependencies complete |
| 24.46 | 071 | [Enable processing, export and list thumbnails on web](071-enable-processing-export-on-web.md) | **Partially complete** | 0/5 | 24.45 (070); Ready |
| 24.47 | 072 | [List processed records on the project home](072-list-processed-records-on-project-home.md) | **Complete** | 3/3 | 24.45 (070); Dependencies complete |
| 24.48 | 073 | [Keep resumed capture photos](073-keep-resumed-capture-photos.md) | **Complete** | 3/3 | 24.45 (070); Dependencies complete |
| 24.49 | 074 | [Ship the full template catalogue](074-ship-full-template-catalogue.md) | **Complete** | 6/6 | None; Dependencies complete |
| 24.50 | 075 | [Replace the starter templates with the catalogue](075-replace-starter-templates-with-catalogue.md) | **Complete** | 5/5 | 24.49 (074); Dependencies complete |
| 24.51 | 076 | [Resolve project, capture and template feedback, and add project packages](076-resolve-project-capture-package-feedback.md) | **Complete** | 26/26 | None; Dependencies complete |
| 24.52 | 077 | [Suggest shipped templates with AI](077-suggest-shipped-templates-with-ai.md) | **Complete** | 4/4 | 23.01 (024), 24.51 (076); Prerequisite review: 024 |
| 24.53 | 078 | [Keep the device id in the storage root](078-keep-device-id-in-storage-root.md) | **Complete** | 3/3 | 24.51 (076); Dependencies complete |
| 24.54 | 079 | [Show a mobile More menu in the bottom navigation](079-mobile-more-menu.md) | **Partially complete** | 4/5 | 06.01 (006), 24.07 (032), 24.35 (060); Ready |
| 24.55 | 093 | [Audit implementation and efficiency against the full plan](093-audit-codebase-against-plan.md) | **Partially complete** | 2/7 | None; Ready |
| 24.56 | 095 | [Generate platform branding reproducibly from vector sources](095-generate-platform-branding.md) | **Partially complete** | 5/6 | 02.01 (002), 03.01 (003), 24.29 (054); Ready |

<!-- dev-plan:generated:end -->
