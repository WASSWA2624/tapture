import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'blob_store_stub.dart'
    if (dart.library.io) 'blob_store_io.dart'
    if (dart.library.js_interop) 'blob_store_web.dart'
    as platform;

/// A small keyed store of bytes the app itself owns, such as the operator's
/// feedback. Never project evidence: photos and records live in the project
/// folders [FileWriter] writes, where deletion is a tombstone (FE-SEC-08).
///
/// On device each key is a file under the application support folder; in a
/// browser it is a row in IndexedDB, so it survives a reload. Callers never
/// reach either directly (FE-STR-11).
abstract interface class BlobStore {
  /// The durable store named [name] on this platform.
  factory BlobStore.platform(String name) => platform.openBlobStore(name);

  /// A hand-written stand-in over [backing], so a restart is a new instance
  /// over the same map (FE-TEST-03). [failWrites] makes every write and
  /// removal fail, for the failure-path tests (FE-TEST-10).
  factory BlobStore.memory({
    Map<String, Uint8List>? backing,
    bool failWrites = false,
  }) {
    return _MemoryBlobStore(
      backing ?? <String, Uint8List>{},
      failWrites: failWrites,
    );
  }

  /// The bytes stored under [key], or null when nothing is.
  Future<Result<Uint8List?>> read(String key);

  /// Replaces what is stored under [key]. Completes after the write is
  /// durable, so a caller may confirm it (FE-STATE-07).
  Future<Result<void>> write(String key, Uint8List bytes);

  /// Removes [key]. Removing a key that is not there succeeds.
  Future<Result<void>> remove(String key);

  /// Whether [key] is a relative name this store accepts: letters, digits,
  /// `.`, `_`, `-` and `/`, with no empty, `.` or `..` segment.
  static bool isValidKey(String key) {
    if (key.isEmpty || !_keyShape.hasMatch(key)) {
      return false;
    }
    return key
        .split('/')
        .every((String part) => part.isNotEmpty && part != '.' && part != '..');
  }
}

final RegExp _keyShape = RegExp(r'^[A-Za-z0-9._/-]+$');

/// The in-memory [BlobStore]. Values are copied in and out so a caller cannot
/// change what is stored by holding on to a list.
final class _MemoryBlobStore implements BlobStore {
  _MemoryBlobStore(this._backing, {this._failWrites = false});

  final Map<String, Uint8List> _backing;
  final bool _failWrites;

  @override
  Future<Result<Uint8List?>> read(String key) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<Uint8List?>(invalid);
    }
    final Uint8List? stored = _backing[key];
    return Success<Uint8List?>(
      stored == null ? null : Uint8List.fromList(stored),
    );
  }

  @override
  Future<Result<void>> write(String key, Uint8List bytes) async {
    final Failure? invalid = keyFailure(key) ?? _writeFailure;
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    _backing[key] = Uint8List.fromList(bytes);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> remove(String key) async {
    final Failure? invalid = keyFailure(key) ?? _writeFailure;
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    _backing.remove(key);
    return const Success<void>(null);
  }

  Failure? get _writeFailure => _failWrites ? storeFailure() : null;
}

/// The failure every backend returns for a key [BlobStore.isValidKey]
/// rejects.
Failure? keyFailure(String key) {
  if (BlobStore.isValidKey(key)) {
    return null;
  }
  return const ValidationFailure(
    message: 'Tapture could not name that stored file.',
    recoveryAction: 'Try again. If it keeps happening, export the log.',
  );
}

/// The failure a backend returns when the platform refuses a read or write.
Failure storeFailure() {
  return const StorageFailure(
    message: 'Tapture could not save that on this device.',
    recoveryAction: 'Free some space, then try again.',
  );
}
