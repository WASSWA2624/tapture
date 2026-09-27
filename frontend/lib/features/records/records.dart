/// The records feature: the records themselves, and browsing them.
library;

// Wave A3 (task 014 scaffold). Presentation reaches the store through this
// barrel (`import '../records.dart' show recordRepositoryProvider;`), never
// through data/ (FE-STR-04); other features reach everything else here.
//
// Exports stay in one alphabetical run (directives_ordering), so each wave
// adds its lines in place and says what it added in its block below.
export 'data/record_repository_impl.dart' show recordRepositoryProvider;
export 'domain/domain.dart';
export 'presentation/record_delete_action.dart';
export 'presentation/record_delete_controller.dart';
export 'presentation/record_edit_screen.dart';
export 'presentation/record_field_sheet.dart';
export 'presentation/record_history_screen.dart';
export 'presentation/record_photos_editor.dart';
export 'presentation/record_providers.dart';
export 'presentation/record_selection.dart';
export 'presentation/record_template_change.dart';
export 'presentation/records_list_screen.dart';
export 'presentation/records_list_view.dart';

// Wave B (task 014 data and screens): append one block per agent below,
// exporting only what main, the router or another feature needs.

// Wave B, list, filters and sort (014 step 2): records_list_screen.dart,
// the page the router builds for `/records` (with `?filter=` as its
// initialStatus) and `/projects/:id/records`, and records_list_view.dart,
// the list itself, which the project home and the expanded nav-shell pane
// embed (`RecordsListView(projectId:, pane: true, currentRecordId:, onOpen:)`).

// Wave B, editing values (014 step 5): record_edit_screen.dart, the values
// page the router builds for `AppRoutes.recordValuesEdit`, and
// record_field_sheet.dart, the one-value sheet the record detail opens when
// a value is tapped.

// Wave B, photos and template change (014 step 5): record_photos_editor.dart
// (`RecordPhotosEditor.open`, the photo edit with the offer to process
// again) and record_template_change.dart (`RecordTemplateChange.show`, the
// preview-then-apply sheet), both opened from the record detail.

// Wave B, history (014 step 6): record_history_screen.dart, the chronology
// page the router builds for `AppRoutes.recordHistory` and
// `AppRoutes.projectRecordHistory`.

// Wave C (task 014 integration): the Drift implementation main composes, and
// the screens the router and nav shell build.
