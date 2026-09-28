import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/compressed_copy.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'record_bundle.dart';
import 'stage_support.dart';

/// Where a record's original, compressed and prepared photos live.
///
/// Asking for a compressed path writes the compressed copy when it is not
/// there yet; originals are only ever read.
final class PhotoPaths {
  /// Creates the resolver under [storageRoot].
  PhotoPaths({
    required StorageRoot storageRoot,
    FileReader? files,
    FileWriter? writer,
    this.isBrowser = kIsWeb,
  }) : _storageRoot = storageRoot,
       _files = files ?? FileReader(storageRoot: storageRoot),
       _compressed = CompressedCopy(
         storageRoot: storageRoot,
         files: files,
         writer: writer,
       );

  final StorageRoot _storageRoot;
  final FileReader _files;
  final CompressedCopy _compressed;

  /// Browser paths address the project blob store rather than a native file.
  final bool isBrowser;

  /// Original path relative to the storage root on every platform.
  String sourceRelative(RecordBundle bundle, Photo photo) =>
      'projects/${bundle.project.folderName}/${photo.relativePath}';

  /// Reads a relative project or cache path through its platform store.
  Future<Result<Uint8List>> read(String relativePath) =>
      _files.read(relativePath);

  /// Resolves an external-service path, retaining native absolute paths.
  Future<String> servicePath(String relativePath) async {
    if (isBrowser) return relativePath;
    return '${(await root()).path}/$relativePath';
  }

  /// The absolute path of [photo]'s original.
  Future<String> source(RecordBundle bundle, Photo photo) async {
    return servicePath(sourceRelative(bundle, photo));
  }

  /// The compressed copy of [photo], relative to the storage root.
  Future<String> compressedRelative(
    RecordBundle bundle,
    Photo photo, {
    CancellationToken? cancel,
  }) async {
    return StageSupport.unwrap(
      await _compressed.reduceStored(
        sourceRelative(bundle, photo),
        cancel: cancel,
      ),
    ).relativePath;
  }

  /// The storage root on this device.
  Future<Directory> root() async {
    return StageSupport.unwrap(await _storageRoot.resolve());
  }

  /// The absolute path of the copy prepared for reading.
  Future<String> prepared(RecordBundle bundle, Photo photo) async {
    final String written = await compressedRelative(bundle, photo);
    return servicePath('$written.ocr.jpg');
  }

  /// The absolute paths of every compressed copy, in capture order.
  Future<List<String>> compressed(RecordBundle bundle) async {
    return <String>[
      for (final Photo photo in bundle.photos)
        await servicePath(await compressedRelative(bundle, photo)),
    ];
  }
}
