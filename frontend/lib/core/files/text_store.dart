import 'package:tapture/core/constants/app_constants.dart';

import 'text_store_stub.dart' if (dart.library.io) 'text_store_io.dart' as io;

/// A small string store with an in-memory fake, so callers never touch a
/// plugin or `dart:io` (FE-STR-11).
abstract interface class TextStore {
  /// A hand-written stand-in driven by [backing], so a restart is a new
  /// instance over the same map.
  factory TextStore.memory([Map<String, String>? backing]) = _MemoryTextStore;

  /// Reads and writes a single file. [path] is the durable location a
  /// restart reads; omitted, it is a temp-dir file named for the theme-mode
  /// preference key.
  factory TextStore.file({String? path}) = _FileTextStore;

  /// The stored contents, or null when nothing has been written.
  String? read();

  /// Replaces the stored contents. Completes before a caller treats the
  /// write as done (FE-STATE-07).
  Future<void> write(String contents);
}

final class _MemoryTextStore implements TextStore {
  _MemoryTextStore([Map<String, String>? backing])
    : _backing = backing ?? <String, String>{};

  final Map<String, String> _backing;

  @override
  String? read() => _backing[AppConstants.preferences.themeMode];

  @override
  Future<void> write(String contents) async {
    _backing[AppConstants.preferences.themeMode] = contents;
  }
}

final class _FileTextStore implements TextStore {
  _FileTextStore({String? path}) : _path = path ?? io.defaultPreferencesPath();

  final String _path;

  @override
  String? read() => io.readTextFile(_path);

  @override
  Future<void> write(String contents) async {
    io.writeTextFile(_path, contents);
  }
}
