/// The merge feature: bringing project packages from other devices in, as
/// new projects or merged into ones already here.
library;

export 'data/merge_repository_impl.dart' show mergeRepositoryProvider;
export 'data/package_files.dart';
export 'data/package_import_repository_impl.dart';
export 'domain/package_import_repository.dart';
export 'domain/package_presence.dart';
export 'presentation/bundle_scope_section.dart';
export 'presentation/conflict_screen.dart';
export 'presentation/merge_preview_screen.dart';
export 'presentation/package_import_flow.dart' show startPackageImport;
export 'presentation/project_merge_history_screen.dart';
