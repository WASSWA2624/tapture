import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/image_resize.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'evidence_purge_stub.dart'
    if (dart.library.io) 'evidence_purge_io.dart'
    if (dart.library.js_interop) 'evidence_purge_web.dart'
    as platform;

/// Removes evidence files for good: the only place a stored photo or
/// attachment file is ever deleted (FE-SEC-08).
///
/// Deletion everywhere else is a tombstone and the file stays, so a restore
/// is always complete. Only the retention purge calls this, once a record's
/// window has passed, and it decides beforehand which files another row
/// still holds: this service removes exactly what it is told to and never
/// reaches outside a project folder or the per-photo caches.
///
/// On device each file is under the storage root; a browser keeps them in
/// the project-file store, keyed by the same path. Callers never reach
/// either directly (FE-STR-11). A file that is already gone counts as
/// removed, so a purge interrupted half way can simply run again.
abstract interface class EvidencePurge {
  /// The purge for this platform: under [storageRoot] on device, and over
  /// the browser's project-file store on web.
  factory EvidencePurge({required StorageRoot storageRoot}) {
    return platform.openEvidencePurge(storageRoot: storageRoot);
  }

  /// A purge over [files], a store keyed by path under the storage root: how
  /// a browser keeps its evidence, and how a suite runs without a disk.
  ///
  /// A store cannot be listed, so only the cached copies the app writes at
  /// its own sizes ([AppConstants.images]) are removed, and only the stored
  /// files are counted.
  factory EvidencePurge.store(BlobStore files) = _StoreEvidencePurge;

  /// Removes the stored file of each of [photos], unless
  /// [PurgePhoto.keepFile] says another row still holds it, and every cached
  /// copy made from it:
  /// thumbnails and upload copies keyed by its content hash (unless
  /// [PurgePhoto.keepCache] says another photo shares that hash), and the
  /// thumbnails and capture copy keyed by its id.
  ///
  /// Returns how many files went; a stored file that is already missing
  /// counts. Stops at the first file that cannot be removed, leaving the
  /// rest for the next run.
  Future<Result<int>> removePhotos(List<PurgePhoto> photos);

  /// Removes each stored file in [storagePaths], such as a record's
  /// documents and audio. Returns how many went; a missing file counts.
  Future<Result<int>> removeFiles(List<String> storagePaths);

  /// [storagePath] as the purge accepts it: relative to the storage root,
  /// with forward slashes, and inside a project folder
  /// (`projects/<folder>/…`). Anything else throws [ValidationFailure], so
  /// a malformed row can never make the purge delete outside the evidence.
  static String evidencePath(String storagePath) {
    final String relative = safeRelativePath(storagePath);
    final List<String> parts = relative.split('/');
    if (parts.length < 3 || parts.first != projectsFolder) {
      throw _outsideProjects;
    }
    return relative;
  }

  /// [key] checked as the name a per-photo cache entry starts with: a
  /// content hash or a photo id, with no separator or parent step. Throws
  /// [ValidationFailure] otherwise.
  static String cacheKey(String key) {
    if (key.isEmpty ||
        key.contains('/') ||
        key.contains(r'\') ||
        key.contains('..')) {
      throw _badCacheKey;
    }
    return key;
  }

  /// The key whose copy [name], a file in a per-photo cache folder, is:
  /// Legacy `<key>_<edge>` and versioned `<key>_<edge>_<quality>_v<version>`
  /// give `<key>`, including a `.part` left from writing either copy.
  /// Null for any other name, which the purge never removes.
  static String? copyOwner(String name) {
    final String whole = name.endsWith(partSuffix)
        ? name.substring(0, name.length - partSuffix.length)
        : name;
    final RegExpMatch? versioned = _versionedCopy.firstMatch(whole);
    if (versioned != null) {
      return versioned.group(1);
    }
    final int split = whole.lastIndexOf('_');
    if (split <= 0 || !_edge.hasMatch(whole.substring(split + 1))) {
      return null;
    }
    return whole.substring(0, split);
  }

  /// Folder under the storage root that holds every project folder.
  static const String projectsFolder = 'projects';

  /// Cache folder of thumbnails, keyed `<sha256>_<edge>` or `<photoId>_<edge>`.
  static const String thumbsFolder = '.cache/thumbs';

  /// Cache folder of reduced upload copies, keyed by source, size and encoding.
  static const String uploadFolder = '.cache/upload';

  /// Cache folder of capture-time copies, one file per photo id.
  static const String captureCopyFolder = '.cache/capture-src';

  /// Suffix of a write still in flight, swept with the file it was for.
  static const String partSuffix = '.part';
}

/// The process-wide [EvidencePurge], over the process storage root, for a
/// purge built inside the provider scope. `main` builds the launch purge
/// over the same root before the scope exists.
final Provider<EvidencePurge> evidencePurgeProvider = Provider<EvidencePurge>((
  Ref ref,
) {
  return EvidencePurge(storageRoot: ref.watch(storageRootProvider));
});

/// One photo the purge removes: its id, content hash and stored file (path
/// under the storage root), and what must stay because another surviving
/// photo row still uses it. [keepFile] keeps the stored file; [keepCache]
/// keeps the copies keyed by the content hash. Copies keyed by the photo's
/// own id always go.
typedef PurgePhoto = ({
  String photoId,
  String sha256,
  String storagePath,
  bool keepFile,
  bool keepCache,
});

/// The edge a cached copy's name ends in: digits only.
final RegExp _edge = RegExp(r'^[0-9]+$');
final RegExp _versionedCopy = RegExp(r'^(.+)_[0-9]+_[0-9]+_v[0-9]+$');

final ValidationFailure _outsideProjects = ValidationFailure(
  localizedMessage: Copy.messages.failureOnlyFilesInsideAProjectFolderCan,
  localizedRecovery: Copy.messages.failureLeaveTheFileInPlaceThePurge,
);

final ValidationFailure _badCacheKey = ValidationFailure(
  localizedMessage: Copy.messages.failureThatPhotoHasNoUsableNameFor,
  localizedRecovery: Copy.messages.failureLeaveThePhotoInPlaceThePurge,
);

/// The purge over a keyed store. Each path is one key; a key that is not
/// there removes as a success.
final class _StoreEvidencePurge implements EvidencePurge {
  _StoreEvidencePurge(this._files);

  final BlobStore _files;

  @override
  Future<Result<int>> removePhotos(List<PurgePhoto> photos) async {
    try {
      // Every path is checked before anything is removed.
      final List<String> stored = <String>[
        for (final PurgePhoto photo in photos)
          if (!photo.keepFile) EvidencePurge.evidencePath(photo.storagePath),
      ];
      final List<String> copies = <String>[
        for (final PurgePhoto photo in photos) ..._copiesOf(photo),
      ];
      for (final String path in stored) {
        await _remove(path);
      }
      for (final String copy in copies) {
        await _remove(copy);
      }
      return Success<int>(stored.length);
    } on Failure catch (failure) {
      return FailureResult<int>(failure);
    }
  }

  @override
  Future<Result<int>> removeFiles(List<String> storagePaths) async {
    try {
      final List<String> paths = <String>[
        for (final String path in storagePaths)
          EvidencePurge.evidencePath(path),
      ];
      for (final String path in paths) {
        await _remove(path);
      }
      return Success<int>(paths.length);
    } on Failure catch (failure) {
      return FailureResult<int>(failure);
    }
  }

  /// The keys of every cached copy the app writes for [photo], at the sizes
  /// it writes them.
  List<String> _copiesOf(PurgePhoto photo) {
    final List<int> thumbEdges = <int>[
      AppConstants.images.thumbnailEdge,
      AppConstants.images.previewEdge,
    ];
    final List<String> keys = <String>[];
    if (photo.photoId.isNotEmpty) {
      final String id = EvidencePurge.cacheKey(photo.photoId);
      keys.add('${EvidencePurge.captureCopyFolder}/$id');
      for (final int edge in thumbEdges) {
        keys.add('${EvidencePurge.thumbsFolder}/${id}_$edge');
      }
    }
    if (!photo.keepCache && photo.sha256.isNotEmpty) {
      final String sha = EvidencePurge.cacheKey(photo.sha256);
      for (final int edge in thumbEdges) {
        keys.add('${EvidencePurge.thumbsFolder}/${sha}_$edge');
      }
      keys.add(
        '${EvidencePurge.uploadFolder}/${sha}_${AppConstants.images.longEdge}',
      );
      keys.add(
        '${EvidencePurge.uploadFolder}/${ImageResize.uploadCacheKey(sha)}',
      );
    }
    return keys;
  }

  Future<void> _remove(String key) async {
    final Result<void> removed = await _files.remove(key);
    if (removed case FailureResult<void>(
      failure: final Failure removeFailure,
    )) {
      throw removeFailure;
    }
  }
}
