import 'dart:async';
import 'dart:js_interop';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'blob_file_writer.dart';
import 'file_writer.dart';

/// The browser's project files: one IndexedDB store, so a reload keeps them
/// and clearing the site's data removes them. The writer and the reader
/// share it.
BlobStore projectFileStore() => _projectFiles;

final BlobStore _projectFiles = BlobStore.platform(
  AppConstants.projectFiles.storeName,
);

/// A browser has no file system: every writer keeps its files in
/// [projectFileStore]. [storageRoot] and the failure seams are device
/// concerns and are not read here.
FileWriter openFileWriter({
  required StorageRoot storageRoot,
  int? failAfterBytes,
  bool fullDisk = false,
  bool permissionDenied = false,
  bool vanishedParent = false,
}) {
  return BlobFileWriter(projectFileStore(), onFirstWrite: _askToPersist);
}

var _askedToPersist = false;

/// Asks the browser once per visit to keep the project files when it runs
/// short of space. Not awaited: a prompt must never hold up a save, and a
/// refusal leaves the write to go ahead as best-effort storage.
void _askToPersist() {
  if (_askedToPersist) {
    return;
  }
  _askedToPersist = true;
  try {
    final _NavigatorStorage? storage = _navigator.storage;
    if (storage == null) {
      return;
    }
    unawaited(
      storage.persist().toDart.then<void>(
        (JSBoolean _) {},
        onError: (Object _) {},
      ),
    );
  } on Object {
    // A browser without the Storage API keeps its files best-effort.
  }
}

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external _NavigatorStorage? get storage;
}

extension type _NavigatorStorage._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> persist();
}
