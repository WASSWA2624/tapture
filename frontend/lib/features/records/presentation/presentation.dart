/// The records feature's presentation layer: screens, controllers and widgets.
library;

// Wave A3 (task 014 scaffold): providers the records screens share, the
// selection behind bulk actions, and delete to the recycle bin with undo.
//
// Exports stay in one alphabetical run (directives_ordering), so each agent
// adds its lines in place and says what it added in its block below.
export 'record_bulk_actions.dart';
export 'record_bulk_controller.dart';
export 'record_delete_action.dart';
export 'record_delete_controller.dart';
export 'record_detail_controller.dart';
export 'record_detail_screen.dart';
export 'record_edit_controller.dart';
export 'record_edit_screen.dart';
export 'record_field_draft.dart';
export 'record_field_input.dart';
export 'record_field_sheet.dart';
export 'record_history_providers.dart';
export 'record_history_screen.dart';
export 'record_photo_providers.dart';
export 'record_photo_viewer_screen.dart';
export 'record_photos_editor.dart';
export 'record_photos_editor_controller.dart';
export 'record_providers.dart';
export 'record_selection.dart';
export 'record_template_change.dart';
export 'record_template_change_controller.dart';
export 'records_active_filters.dart';
export 'records_filter_sheet.dart';
export 'records_list_controller.dart';
export 'records_list_row.dart';
export 'records_list_screen.dart';
export 'records_list_view.dart';
export 'records_page_providers.dart';
export 'records_sort_menu.dart';
export 'recycle_bin_controller.dart';
export 'recycle_bin_screen.dart';

// Wave B (task 014 screens): each presentation agent appends its exports
// below, one block per agent.

// Wave B, list, filters and sort (014 step 2): records_list_screen.dart and
// records_list_view.dart (the paged list), records_list_controller.dart (the
// per-project filter, sort and search, remembered across restarts),
// records_page_providers.dart (count, page and facet reads),
// records_list_row.dart and records_active_filters.dart (the rows and the
// filter chips), records_filter_sheet.dart and records_sort_menu.dart.

// Wave B, editing values (014 step 5): record_edit_screen.dart (the values
// page), record_field_sheet.dart (the one-value sheet), and the controller,
// draft and input both compose.

// Wave B, photos and template change (014 step 5): record_photos_editor.dart
// and its controller (the photo edit, then the offer to process again), and
// record_template_change.dart and its controller (the preview-then-apply
// template change sheet).

// Wave B, history (014 step 6): record_history_screen.dart (the chronology
// page) and record_history_providers.dart (the history stream and the
// templates it names field labels from).

// Wave B, recycle bin and bulk actions (014 steps 7 and 8):
// recycle_bin_screen.dart and its controller (restore in one press, and
// empty now behind a typed confirm), and record_bulk_actions.dart and its
// controller (approve, archive, delete, export and process again over a
// selection, record by record, with a succeeded and failed summary).

// Wave B, detail (014 step 4): record_detail_screen.dart (the record page)
// and its controller (approve, send to review, archive and unarchive, each
// checked with the lifecycle), and record_photo_viewer_screen.dart with
// record_photo_providers.dart (the read-only full-size viewer, the one
// place a saved photo's original is read).
