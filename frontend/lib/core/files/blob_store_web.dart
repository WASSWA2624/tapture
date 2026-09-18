import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'blob_store.dart';

/// An IndexedDB database named for [name], so values survive a reload.
BlobStore openBlobStore(String name) => _IndexedDbBlobStore('tapture-$name');

/// The one object store inside each database.
const String _objectStore = 'blobs';

/// Schema version of the database; bump with an upgrade step, never edit.
const int _dbVersion = 1;

final class _IndexedDbBlobStore implements BlobStore {
  _IndexedDbBlobStore(this._name);

  final String _name;
  Future<_IdbDatabase>? _open;

  @override
  Future<Result<Uint8List?>> read(String key) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<Uint8List?>(invalid);
    }
    try {
      final _IdbDatabase db = await _database();
      final _IdbTransaction tx = db.transaction(_objectStore.toJS, 'readonly');
      final JSAny? value = await _request(
        tx.objectStore(_objectStore).get(key.toJS),
      );
      if (value == null || !value.isA<JSUint8Array>()) {
        return const Success<Uint8List?>(null);
      }
      return Success<Uint8List?>((value as JSUint8Array).toDart);
    } on Object {
      return FailureResult<Uint8List?>(storeFailure());
    }
  }

  @override
  Future<Result<void>> write(String key, Uint8List bytes) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    return _change((_IdbObjectStore store) {
      store.put(Uint8List.fromList(bytes).toJS, key.toJS);
    });
  }

  @override
  Future<Result<void>> remove(String key) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    return _change((_IdbObjectStore store) {
      store.delete(key.toJS);
    });
  }

  /// Runs [body] in a read-write transaction and completes once the browser
  /// reports the transaction durable (FE-STATE-07).
  Future<Result<void>> _change(void Function(_IdbObjectStore) body) async {
    try {
      final _IdbDatabase db = await _database();
      final _IdbTransaction tx = db.transaction(_objectStore.toJS, 'readwrite');
      final Completer<void> done = Completer<void>();
      tx
        ..oncomplete = ((JSAny _) => done.complete()).toJS
        ..onerror = ((JSAny _) => _fail(done)).toJS
        ..onabort = ((JSAny _) => _fail(done)).toJS;
      body(tx.objectStore(_objectStore));
      await done.future;
      return const Success<void>(null);
    } on Object {
      return FailureResult<void>(storeFailure());
    }
  }

  Future<_IdbDatabase> _database() {
    return _open ??= _openDatabase().then(
      (_IdbDatabase db) => db,
      onError: (Object error) {
        _open = null;
        throw storeFailure();
      },
    );
  }

  Future<_IdbDatabase> _openDatabase() {
    final _IdbOpenRequest request = _indexedDb.open(_name, _dbVersion);
    request.onupgradeneeded = ((JSAny _) {
      final _IdbDatabase db = request.result! as _IdbDatabase;
      if (!db.objectStoreNames.contains(_objectStore)) {
        db.createObjectStore(_objectStore);
      }
    }).toJS;
    return _request(request).then((JSAny? db) => db! as _IdbDatabase);
  }
}

void _fail(Completer<void> done) {
  if (!done.isCompleted) {
    done.completeError(storeFailure());
  }
}

/// Completes with [request]'s result when it succeeds.
Future<JSAny?> _request(_IdbRequest request) {
  final Completer<JSAny?> done = Completer<JSAny?>();
  request
    ..onsuccess = ((JSAny _) => done.complete(request.result)).toJS
    ..onerror = ((JSAny _) {
      if (!done.isCompleted) {
        done.completeError(storeFailure());
      }
    }).toJS;
  return done.future;
}

@JS('indexedDB')
external _IdbFactory get _indexedDb;

extension type _IdbFactory._(JSObject _) implements JSObject {
  external _IdbOpenRequest open(String name, int version);
}

extension type _IdbRequest._(JSObject _) implements JSObject {
  external JSAny? get result;
  external set onsuccess(JSFunction? handler);
  external set onerror(JSFunction? handler);
}

extension type _IdbOpenRequest._(JSObject _) implements _IdbRequest {
  external set onupgradeneeded(JSFunction? handler);
}

extension type _IdbDatabase._(JSObject _) implements JSObject {
  external _IdbObjectStore createObjectStore(String name);
  external _IdbTransaction transaction(JSString storeNames, String mode);
  external _DomStringList get objectStoreNames;
}

extension type _DomStringList._(JSObject _) implements JSObject {
  external bool contains(String name);
}

extension type _IdbTransaction._(JSObject _) implements JSObject {
  external _IdbObjectStore objectStore(String name);
  external set oncomplete(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external set onabort(JSFunction? handler);
}

extension type _IdbObjectStore._(JSObject _) implements JSObject {
  external _IdbRequest get(JSString key);
  external _IdbRequest put(JSAny value, JSString key);
  external _IdbRequest delete(JSString key);
}
