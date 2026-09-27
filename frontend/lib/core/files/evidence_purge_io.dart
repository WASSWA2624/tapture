import 'dart:io';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'evidence_purge.dart';

/// The purge over the device's file system, under [storageRoot].
EvidencePurge openEvidencePurge({required StorageRoot storageRoot}) {
  return _DeviceEvidencePurge(storageRoot);
}

/// Deletes under the storage root. Every path is checked before the first
/// file goes, and a file already missing counts as removed.
final class _DeviceEvidencePurge implements EvidencePurge {
  _DeviceEvidencePurge(this._storageRoot);

  final StorageRoot _storageRoot;

  @override
  Future<Result<int>> removePhotos(List<PurgePhoto> photos) async {
    if (photos.isEmpty) {
      return const Success<int>(0);
    }
    try {
      final List<String> stored = <String>[
        for (final PurgePhoto photo in photos)
          if (!photo.keepFile) EvidencePurge.evidencePath(photo.storagePath),
      ];
      final Set<String> thumbKeys = <String>{};
      final Set<String> uploadKeys = <String>{};
      final Set<String> photoIds = <String>{};
      for (final PurgePhoto photo in photos) {
        if (photo.photoId.isNotEmpty) {
          final String id = EvidencePurge.cacheKey(photo.photoId);
          photoIds.add(id);
          thumbKeys.add(id);
        }
        if (!photo.keepCache && photo.sha256.isNotEmpty) {
          final String sha = EvidencePurge.cacheKey(photo.sha256);
          thumbKeys.add(sha);
          uploadKeys.add(sha);
        }
      }
      final Result<Directory> resolved = await _storageRoot.resolve();
      switch (resolved) {
        case FailureResult<Directory>(:final Failure failure):
          return FailureResult<int>(failure);
        case Success<Directory>(value: final Directory root):
          var removed = 0;
          for (final String path in stored) {
            await _removeStored(File('${root.path}/$path'));
            removed += 1;
          }
          removed += await _removeCopies(
            Directory('${root.path}/${EvidencePurge.thumbsFolder}'),
            thumbKeys,
          );
          removed += await _removeCopies(
            Directory('${root.path}/${EvidencePurge.uploadFolder}'),
            uploadKeys,
          );
          final String captureCopies =
              '${root.path}/${EvidencePurge.captureCopyFolder}';
          for (final String id in photoIds) {
            removed += await _removeCopy(File('$captureCopies/$id'));
            removed += await _removeCopy(
              File('$captureCopies/$id${EvidencePurge.partSuffix}'),
            );
          }
          return Success<int>(removed);
      }
    } on Failure catch (failure) {
      return FailureResult<int>(failure);
    } on Object {
      return const FailureResult<int>(_notRemoved);
    }
  }

  @override
  Future<Result<int>> removeFiles(List<String> storagePaths) async {
    if (storagePaths.isEmpty) {
      return const Success<int>(0);
    }
    try {
      final List<String> paths = <String>[
        for (final String path in storagePaths)
          EvidencePurge.evidencePath(path),
      ];
      final Result<Directory> resolved = await _storageRoot.resolve();
      switch (resolved) {
        case FailureResult<Directory>(:final Failure failure):
          return FailureResult<int>(failure);
        case Success<Directory>(value: final Directory root):
          for (final String path in paths) {
            await _removeStored(File('${root.path}/$path'));
          }
          return Success<int>(paths.length);
      }
    } on Failure catch (failure) {
      return FailureResult<int>(failure);
    } on Object {
      return const FailureResult<int>(_notRemoved);
    }
  }
}

/// Deletes a stored evidence file. One that is already gone is left as it
/// is and still counts as removed; any other refusal throws.
Future<void> _removeStored(File file) async {
  try {
    await file.delete();
  } on PathNotFoundException {
    // Already gone: the purge is idempotent.
  }
}

/// Deletes one cached copy. Returns 1 when a file went, 0 when there was
/// none.
Future<int> _removeCopy(File file) async {
  if (!file.existsSync()) {
    return 0;
  }
  try {
    await file.delete();
    return 1;
  } on PathNotFoundException {
    return 0;
  }
}

/// Deletes every file in [folder] that is a copy of one of [keys]
/// (`<key>_<edge>`, see [EvidencePurge.copyOwner]) and returns how many
/// went. The folder is read once, whatever the number of keys.
Future<int> _removeCopies(Directory folder, Set<String> keys) async {
  if (keys.isEmpty || !folder.existsSync()) {
    return 0;
  }
  final List<File> copies = <File>[];
  await for (final FileSystemEntity entity in folder.list(followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final String? owner = EvidencePurge.copyOwner(_nameOf(entity.path));
    if (owner != null && keys.contains(owner)) {
      copies.add(entity);
    }
  }
  var removed = 0;
  for (final File copy in copies) {
    removed += await _removeCopy(copy);
  }
  return removed;
}

String _nameOf(String path) {
  final String slashed = path.replaceAll(r'\', '/');
  return slashed.substring(slashed.lastIndexOf('/') + 1);
}

const StorageFailure _notRemoved = StorageFailure(
  message: 'A deleted record’s files could not be removed from this device.',
  recoveryAction: 'Allow storage access; the purge tries again next launch.',
);
