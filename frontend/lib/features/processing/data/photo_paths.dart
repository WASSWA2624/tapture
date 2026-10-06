import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/compressed_copy.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
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
    this._privacy,
    this._blurFaces,
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
  final PhotoPrivacyService? _privacy;
  final bool Function()? _blurFaces;

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
    final String compressed = StageSupport.unwrap(
      await _compressed.reduceStored(
        sourceRelative(bundle, photo),
        cancel: cancel,
      ),
    ).relativePath;
    final PhotoPrivacyService? privacy = _privacy;
    if (privacy == null) return compressed;
    return StageSupport.unwrap(
      await privacy.prepare(
        photo.id,
        compressed,
        cancel: cancel ?? CancellationToken(),
        blurFaces: _blurFaces?.call() ?? false,
      ),
    ).path;
  }

  /// Privacy-specific cache identity. A policy change cannot reuse text that
  /// was read from the clear original or a prior set of hidden areas.
  Future<String> ocrContentHash(
    RecordBundle bundle,
    Photo photo, {
    CancellationToken? cancel,
  }) async {
    final PhotoPrivacyService? privacy = _privacy;
    if (privacy == null ||
        !StageSupport.unwrap(
          await privacy.requiresProtection(
            photo.id,
            blurFaces: _blurFaces?.call() ?? false,
          ),
        )) {
      return photo.sha256;
    }
    final String path = await compressedRelative(bundle, photo, cancel: cancel);
    return path.startsWith('.cache/privacy/')
        ? path.split('/').last.split('.').first
        : photo.sha256;
  }

  /// Cheap durable policy guard around every provider call, including repair.
  Future<String> privacyRevision(RecordBundle bundle) async => <String>[
    (_blurFaces?.call() ?? false).toString(),
    if (_privacy case final PhotoPrivacyService privacy)
      for (final Photo photo in bundle.photos)
        StageSupport.unwrap(await privacy.revision(photo.id)),
  ].join('|');

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
  Future<List<String>> compressed(
    RecordBundle bundle, {
    CancellationToken? cancel,
  }) async {
    return <String>[
      for (final Photo photo in bundle.photos)
        await servicePath(
          await compressedRelative(bundle, photo, cancel: cancel),
        ),
    ];
  }
}
