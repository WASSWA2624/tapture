import 'dart:io';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/bundled_assets.dart';
import 'package:tapture/core/files/derived_files.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';

import 'speech_engine.dart';
import 'speech_failures.dart';
import 'speech_model_catalogue.dart';
import 'speech_model_entry.dart';
import 'speech_model_source.dart';
import 'speech_model_status.dart';
import 'speech_model_store.dart';
import 'speech_model_verification.dart';

/// Extracted Android copies of bundled models, under the private root.
const String _bundledFolder = 'speech/bundled';

/// Imported models, under the private root.
const String _importedFolder = 'speech/imported';

/// The share of an import's progress spent hashing; copying takes the rest.
const double _hashShare = 0.5;

/// The store on a device, over [privateRoot] and the build's [assets].
SpeechModelStore openSpeechModelStore({
  required StorageRoot privateRoot,
  required BundledAssets assets,
  required List<SpeechModelEntry> catalogue,
  SpeechEngine? webEngine,
}) => _IoSpeechModelStore(
  privateRoot: privateRoot,
  assets: assets,
  catalogue: catalogue,
);

final class _IoSpeechModelStore implements SpeechModelStore {
  _IoSpeechModelStore({
    required this._privateRoot,
    required this._assets,
    required this._catalogue,
  });

  final StorageRoot _privateRoot;
  final BundledAssets _assets;
  final List<SpeechModelEntry> _catalogue;
  final Set<String> _damaged = <String>{};
  Future<Result<Directory>>? _started;

  @override
  bool get canImport => true;

  /// The private root, after stale extracted copies were removed once.
  Future<Result<Directory>> _root() {
    return _started ??= _start().then((Result<Directory> result) {
      if (result is FailureResult<Directory>) {
        _started = null;
      }
      return result;
    });
  }

  Future<Result<Directory>> _start() async {
    final Result<Directory> root = await _privateRoot.resolve();
    if (root case Success<Directory>(:final Directory value)) {
      await _removeStaleCopies(Directory('${value.path}/$_bundledFolder'));
    }
    return root;
  }

  /// Removes every extracted copy whose name is not a current catalogue
  /// model's `<sha12>-<file>`, so a changed model never lingers.
  Future<void> _removeStaleCopies(Directory folder) async {
    if (!await folder.exists()) {
      return;
    }
    final Set<String> current = <String>{
      for (final SpeechModelEntry entry in _catalogue)
        if (entry.asset case final String asset)
          bundledCopyName(key: asset, sha256: entry.sha256),
    };
    final List<FileSystemEntity> found = await folder
        .list(followLinks: false)
        .toList();
    for (final FileSystemEntity entity in found) {
      if (entity is File && !current.contains(_nameOf(entity.path))) {
        await discardDerivedFile(entity, privateRoot: _privateRoot);
      }
    }
  }

  @override
  Future<Result<List<SpeechModelStatus>>> inventory() async {
    final Result<Directory> root = await _root();
    switch (root) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<List<SpeechModelStatus>>(failure);
      case Success<Directory>(:final Directory value):
        return Success<List<SpeechModelStatus>>(<SpeechModelStatus>[
          for (final SpeechModelEntry entry in _catalogue)
            await _statusOf(entry, value),
        ]);
    }
  }

  /// [entry]'s presence from a file lookup and its length: never a hash.
  Future<SpeechModelStatus> _statusOf(
    SpeechModelEntry entry,
    Directory root,
  ) async {
    final Result<String?> found = await _pathOf(entry, root);
    final String? path = found.fold((_) => null, (String? value) => value);
    if (path == null) {
      return SpeechModelStatus(entry: entry, present: false);
    }
    final bool rightSize;
    try {
      rightSize = await File(path).length() == entry.bytes;
    } on FileSystemException {
      return SpeechModelStatus(entry: entry, present: false);
    }
    return SpeechModelStatus(
      entry: entry,
      present: true,
      imported: entry.asset == null,
      damaged: !rightSize || _damaged.contains(entry.id),
    );
  }

  /// Where [entry] is on this device, null when it is absent.
  Future<Result<String?>> _pathOf(
    SpeechModelEntry entry,
    Directory root, {
    CancellationToken? cancel,
  }) async {
    if (entry.asset case final String asset) {
      return _assets.pathOf(
        asset,
        sha256: entry.sha256,
        extractTo: '${root.path}/$_bundledFolder',
        cancel: cancel,
      );
    }
    final File imported = _importedFile(entry, root);
    return Success<String?>(await imported.exists() ? imported.path : null);
  }

  File _importedFile(SpeechModelEntry entry, Directory root) =>
      File('${root.path}/$_importedFolder/${entry.fileName}');

  @override
  Future<Result<SpeechModelSource>> locate(
    SpeechModelEntry entry, {
    CancellationToken? cancel,
  }) async {
    final Result<Directory> root = await _root();
    if (root case FailureResult<Directory>(:final Failure failure)) {
      return FailureResult<SpeechModelSource>(failure);
    }
    final Result<String?> found = await _pathOf(
      entry,
      (root as Success<Directory>).value,
      cancel: cancel,
    );
    switch (found) {
      case FailureResult<String?>(:final Failure failure):
        return FailureResult<SpeechModelSource>(failure);
      case Success<String?>(value: null):
        return FailureResult<SpeechModelSource>(speechModelMissing());
      case Success<String?>(:final String? value):
        return Success<SpeechModelSource>(
          SpeechModelSource(entry: entry, path: value),
        );
    }
  }

  @override
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry) async {
    final Result<SpeechModelSource> located = await locate(entry);
    final Result<Directory> root = await _root();
    if (entry.asset == null ||
        located is! Success<SpeechModelSource> ||
        root is! Success<Directory>) {
      return located;
    }
    final String? path = located.value.path;
    final String folder = '${root.value.path}/$_bundledFolder/';
    if (path == null || !path.startsWith(folder)) {
      return located;
    }
    final Result<void> discarded = await discardDerivedFile(
      File(path),
      privateRoot: _privateRoot,
    );
    if (discarded case FailureResult<void>(:final Failure failure)) {
      return FailureResult<SpeechModelSource>(failure);
    }
    return locate(entry);
  }

  @override
  Future<Result<void>> verify(
    SpeechModelSource source, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    final String? path = source.path;
    if (path == null) {
      return FailureResult<void>(speechModelMissing());
    }
    final Result<void> verified = await verifySpeechModelFile(
      path,
      source.entry,
      cancel: cancel,
      onProgress: onProgress,
    );
    switch (verified) {
      case Success<void>():
        _damaged.remove(source.entry.id);
      case FailureResult<void>(failure: CorruptionFailure()):
        _damaged.add(source.entry.id);
      case FailureResult<void>():
        break;
    }
    return verified;
  }

  @override
  Future<Result<SpeechModelEntry>> import(
    PickedDocument picked, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    try {
      return await _import(picked, cancel, onProgress);
    } finally {
      await discardPickedCopy(picked);
    }
  }

  Future<Result<SpeechModelEntry>> _import(
    PickedDocument picked,
    CancellationToken? cancel,
    void Function(double)? onProgress,
  ) async {
    if (picked is! PickedFile) {
      return FailureResult<SpeechModelEntry>(speechImportUnknown());
    }
    final Result<Directory> root = await _root();
    if (root case FailureResult<Directory>(:final Failure failure)) {
      return FailureResult<SpeechModelEntry>(failure);
    }
    final File source = picked.file;
    final int length;
    try {
      length = await source.length();
    } on FileSystemException {
      return FailureResult<SpeechModelEntry>(speechImportUnknown());
    }
    final Set<String> fitting = <String>{};
    for (final SpeechModelEntry entry in _catalogue) {
      if (entry.asset == null && entry.bytes == length) {
        final Result<void> header = await precheckSpeechModelFile(
          source.path,
          entry,
        );
        if (header is Success<void>) {
          fitting.add(entry.id);
        }
      }
    }
    if (fitting.isEmpty) {
      return FailureResult<SpeechModelEntry>(speechImportUnknown());
    }
    final Result<String> hashed = await HashingService.sha256OfFile(
      source,
      cancel: cancel,
      onProgress: onProgress == null
          ? null
          : (double fraction) => onProgress(fraction * _hashShare),
    );
    final String digest;
    switch (hashed) {
      case FailureResult<String>(failure: final CancelledFailure failure):
        return FailureResult<SpeechModelEntry>(failure);
      case FailureResult<String>():
        return FailureResult<SpeechModelEntry>(speechImportUnknown());
      case Success<String>(:final String value):
        digest = value;
    }
    final SpeechModelEntry? entry = SpeechModelCatalogue.matchImport(
      length,
      digest,
      among: _catalogue,
    );
    if (entry == null || !fitting.contains(entry.id)) {
      return FailureResult<SpeechModelEntry>(speechImportUnknown());
    }
    return _copyIn(
      source,
      entry,
      (root as Success<Directory>).value,
      cancel,
      onProgress,
    );
  }

  /// Copies [source] atomically through a `.part` file and a rename, then
  /// confirms the copy has [entry]'s SHA-256.
  Future<Result<SpeechModelEntry>> _copyIn(
    File source,
    SpeechModelEntry entry,
    Directory root,
    CancellationToken? cancel,
    void Function(double)? onProgress,
  ) async {
    final Result<WrittenFile> written =
        await FileWriter(storageRoot: _privateRoot).write(
          _watchedRead(source, entry.bytes, cancel, onProgress),
          '$_importedFolder/${entry.fileName}',
        );
    switch (written) {
      case FailureResult<WrittenFile>(:final Failure failure):
        return FailureResult<SpeechModelEntry>(
          cancel?.isCancelled ?? false ? const CancelledFailure() : failure,
        );
      case Success<WrittenFile>(:final WrittenFile value):
        if (value.sha256 != entry.sha256) {
          await discardDerivedFile(
            _importedFile(entry, root),
            privateRoot: _privateRoot,
          );
          return FailureResult<SpeechModelEntry>(speechImportUnknown());
        }
    }
    _damaged.remove(entry.id);
    onProgress?.call(1);
    return Success<SpeechModelEntry>(entry);
  }

  @override
  Future<Result<void>> remove(SpeechModelEntry entry) async {
    if (entry.asset != null) {
      return const FailureResult<void>(ValidationFailure());
    }
    final Result<Directory> root = await _root();
    switch (root) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<void>(failure);
      case Success<Directory>(:final Directory value):
        _damaged.remove(entry.id);
        return discardDerivedFile(
          _importedFile(entry, value),
          privateRoot: _privateRoot,
        );
    }
  }

  @override
  void markDamaged(String modelId) {
    _damaged.add(modelId);
  }
}

/// [source]'s bytes for an import copy, reporting the copied share after the
/// hash's and stopping with a [CancelledFailure] once [cancel] fires.
Stream<List<int>> _watchedRead(
  File source,
  int length,
  CancellationToken? cancel,
  void Function(double)? onProgress,
) async* {
  var copied = 0;
  await for (final List<int> chunk in source.openRead()) {
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    yield chunk;
    copied += chunk.length;
    if (onProgress != null && length > 0 && copied < length) {
      onProgress(_hashShare + (1 - _hashShare) * copied / length);
    }
  }
  if (cancel?.isCancelled ?? false) {
    throw const CancelledFailure();
  }
}

String _nameOf(String path) => path.split(RegExp(r'[\\/]')).last;
