/// The storage layout and the file operations built on it.
///
/// `storage_root.dart`, `project_folders.dart`, `file_writer.dart` and
/// `file_relocation.dart` are imported directly: they use `dart:io`, and
/// this barrel is reached from the web shell through TextStore.
library;

export 'path_sanitizer.dart';
export 'photo_path_builder.dart';
export 'text_store.dart';
