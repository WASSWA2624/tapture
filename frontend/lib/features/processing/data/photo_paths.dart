import 'dart:io';

import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/compressed_copy.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'record_bundle.dart';
import 'stage_support.dart';

/// Where a record's original, compressed and prepared photos live.
///
/// Asking for a compressed path writes the compressed copy when it is not
/// there yet; originals are only ever read.
final class PhotoPaths {
  /// Creates the resolver under [storageRoot].
  PhotoPaths({required StorageRoot storageRoot})
    : _storageRoot = storageRoot,
      _folders = ProjectFolders(storageRoot: storageRoot),
      _compressed = CompressedCopy(storageRoot: storageRoot);

  final StorageRoot _storageRoot;
  final ProjectFolders _folders;
  final CompressedCopy _compressed;

  /// The absolute path of [photo]'s original.
  Future<String> source(RecordBundle bundle, Photo photo) async {
    final Directory directory = StageSupport.unwrap(
      await _folders.resolve(bundle.project),
    );
    return '${directory.path}/${photo.relativePath}';
  }

  /// The compressed copy of [photo], relative to the storage root.
  Future<String> compressedRelative(RecordBundle bundle, Photo photo) async {
    return StageSupport.unwrap(
      await _compressed.reduce(await source(bundle, photo)),
    ).relativePath;
  }

  /// The storage root on this device.
  Future<Directory> root() async {
    return StageSupport.unwrap(await _storageRoot.resolve());
  }

  /// The absolute path of the copy prepared for reading.
  Future<String> prepared(RecordBundle bundle, Photo photo) async {
    final String written = await compressedRelative(bundle, photo);
    final Directory root = await this.root();
    return '${root.path}/$written.ocr.jpg';
  }

  /// The absolute paths of every compressed copy, in capture order.
  Future<List<String>> compressed(RecordBundle bundle) async {
    final Directory root = await this.root();
    return <String>[
      for (final Photo photo in bundle.photos)
        '${root.path}/${await compressedRelative(bundle, photo)}',
    ];
  }
}
