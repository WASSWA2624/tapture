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
export 'presentation/record_providers.dart';
export 'presentation/record_selection.dart';

// Wave B (task 014 data and screens): append one block per agent below,
// exporting only what main, the router or another feature needs.

// Wave B, editing values (014 step 5): record_edit_screen.dart, the values
// page the router builds for `AppRoutes.recordValuesEdit`, and
// record_field_sheet.dart, the one-value sheet the record detail opens when
// a value is tapped.

// Wave C (task 014 integration): the Drift implementation main composes, and
// the screens the router and nav shell build.
