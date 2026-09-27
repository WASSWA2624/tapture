/// The merge feature: bringing project packages from other devices in, as
/// new projects or merged into ones already here.
library;

export 'data/package_files.dart';
export 'data/package_import_repository_impl.dart';
export 'domain/package_import_repository.dart';
export 'domain/package_presence.dart';
export 'presentation/conflict_screen.dart';
export 'presentation/merge_preview_screen.dart';
export 'presentation/package_import_flow.dart' show startPackageImport;
