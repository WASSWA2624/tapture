/// The storage layout and the file operations built on it.
///
/// `storage_root.dart`, `project_folders.dart`, `file_writer.dart`,
/// `file_relocation.dart`, `thumbnail_cache.dart`, `compressed_copy.dart`,
/// `cache_cleanup.dart`, `storage_guard.dart` and `orphan_scanner.dart` are
/// imported directly: they use `dart:io`, and this barrel is reached from
/// the web shell through TextStore.
library;

export 'path_sanitizer.dart';
export 'photo_path_builder.dart';
export 'text_store.dart';
