import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Visible folder name under the documents directory.
const String _rootName = 'Tapture';

/// Disposable home for derived artefacts (rule 1 of the standard).
const String _cacheName = '.cache';

/// Created and removed to prove the root accepts a write.
const String _probeName = '.write-probe';

/// Native channel that reports the shared Documents folder on Android 11+.
const MethodChannel _filesChannel = MethodChannel('com.tapture.app/files');

/// Resolves, creates and hands out the visible `Tapture/` root under the
/// device's documents directory.
///
/// The platform plugin and every absolute path live here. Callers read this
/// through [storageRootProvider] and never compose a root of their own
/// (FE-STR-11, FE-CODE-09).
abstract interface class StorageRoot {
  /// Creates `Tapture/` and `Tapture/.cache` under the documents directory.
  ///
  /// On Android 11+ the preferred home is shared `Documents/Tapture`, so a
  /// file manager can open it and it survives uninstall. App-specific
  /// folders need no runtime permission and are the fallback. [documentsDirectory]
  /// and [publicDocuments] are test seams so a suite can choose the branch
  /// without opening the plugin.
  factory StorageRoot({
    Future<Directory> Function()? documentsDirectory,
    Future<Directory?> Function()? publicDocuments,
    Future<String?> Function()? preferredPath,
  }) {
    return _StorageRoot(
      documentsDirectory: documentsDirectory ?? _platformDocumentsDirectory,
      publicDocuments:
          publicDocuments ??
          (documentsDirectory == null
              ? _platformPublicDocuments
              : () async => null),
      preferredPath: preferredPath,
    );
  }

  /// A stand-in that writes under [documentsDirectory] so tests never touch
  /// the real documents folder (FE-STR-11, FE-TEST-03).
  ///
  /// When [writable] is false, [resolve] returns a [StorageFailure] naming
  /// the path, without creating the tree. [publicDocuments] is the shared
  /// folder a suite offers first, or omitted so only [documentsDirectory]
  /// is tried.
  factory StorageRoot.fake({
    required Directory documentsDirectory,
    Directory? publicDocuments,
    bool writable = true,
    String? preferredPath,
    bool preferredWritable = true,
  }) {
    return _StorageRoot(
      documentsDirectory: () async => documentsDirectory,
      publicDocuments: publicDocuments == null
          ? () async => null
          : () async => publicDocuments,
      preferredPath: preferredPath == null ? null : () async => preferredPath,
      writable: writable,
      preferredWritable: preferredWritable,
    );
  }

  /// The app-private `Tapture/` tree under application support, for derived
  /// application files that are never evidence, such as speech models
  /// (spec §8.1 rule 8). It is never in the visible tree, a bundle or an
  /// export. In a browser, which has no application support folder, [resolve]
  /// returns a [StorageFailure]. [supportDirectory] is the test seam that
  /// replaces the platform's application support folder.
  factory StorageRoot.private({
    @visibleForTesting Future<Directory> Function()? supportDirectory,
  }) {
    return _StorageRoot(
      documentsDirectory: supportDirectory ?? _platformSupportDirectory,
      publicDocuments: () async => null,
    );
  }

  /// The visible `Tapture/` folder. Creates it and `.cache` if they are
  /// absent, memoises a successful result for the process, and returns a
  /// [StorageFailure] naming the path when the location is missing or not
  /// writable. Does not ask for a runtime permission. A persisted preferred
  /// path that still passes the write probe is used first.
  Future<Result<Directory>> resolve();

  /// Probes [path] as the storage root without falling back to Documents.
  Future<Result<Directory>> openAt(String path);

  /// `Tapture/.cache`, the only home for derived artefacts. Disposable: a
  /// missing folder is created again rather than treated as lost data.
  Future<Result<Directory>> cacheDir();

  /// Serializes atomic writes and partial-file recovery in one directory.
  /// Writers sharing this root cannot remove one another's unfinished files.
  Future<T> withWriteLock<T>(String directory, Future<T> Function() write);
}

/// The process-wide [StorageRoot]. Callers never compose an absolute storage
/// path of their own.
final Provider<StorageRoot> storageRootProvider = Provider<StorageRoot>((_) {
  return StorageRoot();
});

/// Shared public Documents on Android 11+. Direct file paths let Files open
/// `Documents/Tapture` and keep the tree after uninstall. Below API 30, or
/// when the channel is missing, this is absent and the app folder is used.
Future<Directory?> _platformPublicDocuments() async {
  if (!Platform.isAndroid) {
    return null;
  }
  try {
    final Object? path = await _filesChannel.invokeMethod<Object>(
      'publicDocumentsPath',
    );
    if (path is String && path.isNotEmpty) {
      return Directory(path);
    }
  } on Object {
    // Unsupported API, missing plugin, or any refuse: use the app folder.
  }
  return null;
}

/// The app-specific documents directory. Used when shared Documents is
/// unavailable or its write probe fails, and on every platform other than
/// Android. No `.nomedia` file is written, so the media scanner is not told
/// to skip the tree.
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

/// The app-private application support directory. A browser has none, so
/// this throws there and [StorageRoot.resolve] reports a [StorageFailure].
Future<Directory> _platformSupportDirectory() {
  if (kIsWeb) {
    return Future<Directory>.error(
      UnsupportedError('No application support folder in a browser'),
    );
  }
  return getApplicationSupportDirectory();
}

final class _StorageRoot implements StorageRoot {
  _StorageRoot({
    required this._documentsDirectory,
    required this._publicDocuments,
    this._preferredPath,
    this._writable = true,
    this._preferredWritable = true,
  });

  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory?> Function() _publicDocuments;
  final Future<String?> Function()? _preferredPath;
  final bool _writable;
  final bool _preferredWritable;

  Directory? _root;
  Future<Result<Directory>>? _inFlight;
  final Map<String, Future<void>> _writes = <String, Future<void>>{};

  @override
  Future<T> withWriteLock<T>(
    String directory,
    Future<T> Function() write,
  ) async {
    final Future<void>? previous = _writes[directory];
    final Completer<void> released = Completer<void>();
    _writes[directory] = released.future;
    try {
      await previous;
      return await write();
    } finally {
      released.complete();
      if (identical(_writes[directory], released.future)) {
        _writes.remove(directory);
      }
    }
  }

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
  Future<Result<Directory>> openAt(String path) {
    return _tryOpenRoot(Directory(path), writable: _preferredWritable);
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

  /// Never throws: a platform with no documents folder (a browser, where
  /// `dart:io` is unsupported) or a plugin error is a [StorageFailure], so
  /// [resolve] completes, forgets the attempt and can be retried.
  Future<Result<Directory>> _open() async {
    try {
      final String? preferred = await _readPreferred();
      if (preferred != null && preferred.isNotEmpty) {
        final Result<Directory> opened = await _tryOpenRoot(
          Directory(preferred),
          writable: _preferredWritable,
        );
        if (opened is Success<Directory>) {
          return opened;
        }
      }
      final Directory? shared = await _resolvePublic();
      if (shared != null) {
        final Result<Directory> opened = await _tryOpen(shared);
        if (opened is Success<Directory>) {
          return opened;
        }
      }
      return _tryOpen(await _documentsDirectory());
    } on Object {
      return FailureResult<Directory>(_noDocumentsFolder);
    }
  }

  Future<String?> _readPreferred() async {
    final Future<String?> Function()? preferredPath = _preferredPath;
    if (preferredPath == null) {
      return null;
    }
    try {
      return await preferredPath();
    } on Object {
      return null;
    }
  }

  Future<Directory?> _resolvePublic() async {
    try {
      return await _publicDocuments();
    } on Object {
      return null;
    }
  }

  Future<Result<Directory>> _tryOpen(Directory documents) {
    return _tryOpenRoot(
      Directory('${documents.path}/$_rootName'),
      writable: _writable,
    );
  }

  Future<Result<Directory>> _tryOpenRoot(
    Directory root, {
    required bool writable,
  }) async {
    final String path = root.path;
    try {
      if (!writable) {
        return FailureResult<Directory>(_unwritable(path));
      }
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

/// The platform gave no documents folder at all.
final StorageFailure _noDocumentsFolder = StorageFailure(
  localizedMessage: Copy.messages.failureThisDeviceHasNoFolderTaptureCan,
  localizedRecovery: Copy.messages.failureUseTaptureOnAPhoneTabletOr,
);

StorageFailure _unwritable(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(
      (path).toString(),
    ),
    localizedRecovery: Copy.messages.failureFreeSpaceOrAllowStorageAccessThen,
  );
}
