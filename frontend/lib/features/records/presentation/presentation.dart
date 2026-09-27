/// The records feature's presentation layer: screens, controllers and widgets.
library;

// Wave A3 (task 014 scaffold): providers the records screens share, the
// selection behind bulk actions, and delete to the recycle bin with undo.
//
// Exports stay in one alphabetical run (directives_ordering), so each agent
// adds its lines in place and says what it added in its block below.
export 'record_delete_action.dart';
export 'record_delete_controller.dart';
export 'record_edit_controller.dart';
export 'record_edit_screen.dart';
export 'record_field_draft.dart';
export 'record_field_input.dart';
export 'record_field_sheet.dart';
export 'record_providers.dart';
export 'record_selection.dart';

// Wave B (task 014 screens): each presentation agent appends its exports
// below, one block per agent.

// Wave B, editing values (014 step 5): record_edit_screen.dart (the values
// page), record_field_sheet.dart (the one-value sheet), and the controller,
// draft and input both compose.
