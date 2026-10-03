import 'dart:async';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'package_files_stub.dart'
    if (dart.library.io) 'package_files_io.dart'
    if (dart.library.js_interop) 'package_files_web.dart'
    as platform;

/// Where an imported package's files land, and how an unfinished import is
/// undone (task 076, W19 and W21). Paths are relative to the storage root.
///
/// On a device the files go under the storage root; in a browser, which has
/// no file system, into the project file store.
abstract interface class PackageFiles {
  /// The files of this platform. Tests pass [writer] to fail a copy part way.
  factory PackageFiles({required StorageRoot storageRoot, FileWriter? writer}) {
    return platform.openPackageFiles(storageRoot: storageRoot, writer: writer);
  }

  /// Files kept in [store], as a browser keeps them and suites do.
  factory PackageFiles.blobs(BlobStore store, {FileWriter? writer}) {
    return _BlobPackageFiles(store, writer ?? BlobFileWriter(store));
  }

  /// Writes [bytes] to [relativePath], completing once they are durable.
  Future<Result<WrittenFile>> write(String relativePath, Uint8List bytes);

  /// Streams a package entry through the same durable atomic writer.
  Future<Result<WrittenFile>> writeStream(
    String relativePath,
    Stream<List<int>> bytes,
  );

  /// Reads a durable merge snapshot through the same platform store.
  Future<Result<Uint8List>> read(String relativePath);

  /// Relocates evidence without deleting it; used by transactional merge undo.
  Future<void> move(String source, String target);

  /// Whether something is stored at [relativePath].
  Future<bool> exists(String relativePath);

  /// Removes [relativePath]. A missing file is left alone.
  Future<void> remove(String relativePath);

  /// Removes the folder [relativePath] with everything in it, where folders
  /// exist. A browser has none; its files are removed one by one.
  Future<void> removeFolder(String relativePath);
}

final class _BlobPackageFiles implements PackageFiles {
  _BlobPackageFiles(this._store, this._writer);

  final BlobStore _store;
  final FileWriter _writer;

  @override
  Future<Result<WrittenFile>> write(String relativePath, Uint8List bytes) {
    return writeStream(relativePath, Stream<List<int>>.value(bytes));
  }

  @override
  Future<Result<WrittenFile>> writeStream(
    String relativePath,
    Stream<List<int>> bytes,
  ) => writePackageFileStream(
    _writer,
    relativePath,
    bytes,
    maxBytes: AppConstants.imports.bundleMaxBytes,
  );

  @override
  Future<Result<Uint8List>> read(String relativePath) async {
    final Result<Uint8List?> result = await _store.read(relativePath);
    return switch (result) {
      Success<Uint8List?>(value: final Uint8List bytes) => Success<Uint8List>(
        bytes,
      ),
      Success<Uint8List?>() => FailureResult<Uint8List>(
        FileReader.unreadable(relativePath),
      ),
      FailureResult<Uint8List?>(:final failure) => FailureResult<Uint8List>(
        failure,
      ),
    };
  }

  @override
  Future<void> move(String source, String target) async {
    final Uint8List bytes = switch (await read(source)) {
      Success<Uint8List>(:final value) => value,
      FailureResult<Uint8List>(failure: final Failure readFailure) =>
        throw readFailure,
    };
    switch (await write(target, bytes)) {
      case FailureResult<WrittenFile>(failure: final Failure writeFailure):
        throw writeFailure;
      case Success<WrittenFile>():
        await remove(source);
    }
  }

  @override
  Future<bool> exists(String relativePath) async {
    final Result<Uint8List?> read = await _store.read(relativePath);
    return switch (read) {
      Success<Uint8List?>(:final Uint8List? value) => value != null,
      FailureResult<Uint8List?>() => false,
    };
  }

  @override
  Future<void> remove(String relativePath) async {
    switch (await _store.remove(relativePath)) {
      case Success<void>():
        return;
      case FailureResult<void>(failure: final Failure removeFailure):
        throw removeFailure;
    }
  }

  @override
  Future<void> removeFolder(String relativePath) async {}
}

/// Forwards package chunks without collecting them, releases an entry even
/// when the writer refuses it before reading, and preserves typed source
/// failures. Browser stores need [maxBytes] because each blob is materialized.
Future<Result<WrittenFile>> writePackageFileStream(
  FileWriter writer,
  String relativePath,
  Stream<List<int>> bytes, {
  int? maxBytes,
}) async {
  final StreamIterator<List<int>> source = StreamIterator<List<int>>(bytes);
  // Subscribe immediately so a writer that refuses before consuming still
  // cancels the opened entry. Only its first source chunk can be pending.
  // Capture a first-read error even when the writer never awaits the stream.
  final Future<(bool, Object?, StackTrace?)> first = source
      .moveNext()
      .then<(bool, Object?, StackTrace?)>(
        (bool more) => (more, null, null),
        onError: (Object error, StackTrace stack) => (false, error, stack),
      );
  Failure? streamFailure;
  var length = 0;
  Stream<List<int>> chunks() async* {
    try {
      final (bool firstMore, Object? error, StackTrace? stack) = await first;
      if (error != null) Error.throwWithStackTrace(error, stack!);
      bool more = firstMore;
      while (more) {
        final List<int> chunk = source.current;
        length += chunk.length;
        if (maxBytes != null && length > maxBytes) {
          throw ValidationFailure(
            localizedMessage: Copy.messages.packageTooLarge(length, maxBytes),
            localizedRecovery: Copy.messages.packageTooLargeRecovery,
          );
        }
        yield chunk;
        more = await source.moveNext();
      }
    } on Failure catch (failure) {
      streamFailure = failure;
      rethrow;
    }
  }

  try {
    final Result<WrittenFile> result = await writer.write(
      chunks(),
      relativePath,
    );
    if (result is FailureResult<WrittenFile> && streamFailure != null) {
      return FailureResult<WrittenFile>(streamFailure!);
    }
    return result;
  } finally {
    await source.cancel();
  }
}
