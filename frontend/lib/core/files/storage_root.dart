import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Visible folder name under the documents directory.
const String _rootName = 'Tapture';

/// Disposable home for derived artefacts (rule 1 of the standard).
const String _cacheName = '.cache';

/// Created and removed to prove the root accepts a write.
const String _probeName = '.write-probe';

/// Resolves, creates and hands out the visible `Tapture/` root under the
/// device's documents directory.
///
/// The platform plugin and every absolute path live here. Callers read this
/// through [storageRootProvider] and never compose a root of their own
/// (FE-STR-11, FE-CODE-09).
abstract interface class StorageRoot {
  /// Creates `Tapture/` and `Tapture/.cache` under the documents directory.
  ///
  /// App-specific folders need no runtime permission. [documentsDirectory]
  /// is the test seam so a suite can resolve into a temporary folder without
  /// opening the plugin. Omitted, the documents directory comes from the
  /// platform.
  factory StorageRoot({Future<Directory> Function()? documentsDirectory}) {
    return _StorageRoot(
      documentsDirectory: documentsDirectory ?? _platformDocumentsDirectory,
    );
  }

  /// A stand-in that writes under [documentsDirectory] so tests never touch
  /// the real documents folder (FE-STR-11, FE-TEST-03).
  ///
  /// When [writable] is false, [resolve] returns a [StorageFailure] naming
  /// the path, without creating the tree.
  factory StorageRoot.fake({
    required Directory documentsDirectory,
    bool writable = true,
  }) {
    return _StorageRoot(
      documentsDirectory: () async => documentsDirectory,
      writable: writable,
    );
  }

  /// The visible `Tapture/` folder. Creates it and `.cache` if they are
  /// absent, memoises a successful result for the process, and returns a
  /// [StorageFailure] naming the path when the location is missing or not
  /// writable. Does not ask for a runtime permission.
  Future<Result<Directory>> resolve();

  /// `Tapture/.cache`, the only home for derived artefacts. Disposable: a
  /// missing folder is created again rather than treated as lost data.
  Future<Result<Directory>> cacheDir();
}

/// The process-wide [StorageRoot]. Callers never compose an absolute storage
/// path of their own.
final Provider<StorageRoot> storageRootProvider = Provider<StorageRoot>((_) {
  return StorageRoot();
});

/// The user-visible documents directory. On Android this is the app-specific
/// external Documents folder so the tree is reachable over a cable; elsewhere
/// it is the platform documents directory. No `.nomedia` file is written, so
/// the media scanner is not told to skip the tree.
Future<Directory> _platformDocumentsDirectory() async {
  if (Platform.isAndroid) {
    final List<Directory>? external = await getExternalStorageDirectories(
      type: StorageDirectory.documents,
    );
    if (external != null && external.isNotEmpty) {
      return external.first;
    }
  }
  return getApplicationDocumentsDirectory();
}

final class _StorageRoot implements StorageRoot {
  _StorageRoot({required this._documentsDirectory, this._writable = true});

  final Future<Directory> Function() _documentsDirectory;
  final bool _writable;

  Directory? _root;
  Future<Result<Directory>>? _inFlight;

  @override
  Future<Result<Directory>> resolve() {
    final Directory? root = _root;
    if (root != null) {
      return Future<Result<Directory>>.value(Success<Directory>(root));
    }
    return _inFlight ??= _open().then((Result<Directory> result) {
      switch (result) {
        case Success<Directory>(:final value):
          _root = value;
        case FailureResult<Directory>():
          _inFlight = null;
      }
      return result;
    });
  }

  @override
  Future<Result<Directory>> cacheDir() async {
    final Result<Directory> resolved = await resolve();
    switch (resolved) {
      case FailureResult<Directory>(:final failure):
        return FailureResult<Directory>(failure);
      case Success<Directory>(:final value):
        return _ensureCache(value);
    }
  }

  Future<Result<Directory>> _open() async {
    String path = _rootName;
    try {
      final Directory documents = await _documentsDirectory();
      path = '${documents.path}/$_rootName';
      if (!_writable) {
        return FailureResult<Directory>(_unwritable(path));
      }
      final Directory root = Directory(path);
      await root.create(recursive: true);
      final Result<Directory> cache = await _ensureCache(root);
      if (cache is FailureResult<Directory>) {
        return cache;
      }
      await _probeWritable(root);
      return Success<Directory>(root);
    } on Object {
      return FailureResult<Directory>(_unwritable(path));
    }
  }

  Future<Result<Directory>> _ensureCache(Directory root) async {
    final Directory cache = Directory('${root.path}/$_cacheName');
    try {
      await cache.create(recursive: true);
      return Success<Directory>(cache);
    } on Object {
      return FailureResult<Directory>(_unwritable(cache.path));
    }
  }

  Future<void> _probeWritable(Directory root) async {
    final File marker = File('${root.path}/$_probeName');
    await marker.writeAsString('ok', flush: true);
    try {
      await marker.delete();
    } on Object {
      // A leftover probe is not user data; write success is the signal.
    }
  }
}

StorageFailure _unwritable(String path) {
  return StorageFailure(
    message: 'Tapture could not write to $path.',
    recoveryAction: 'Free space or allow storage access, then try again.',
  );
}
