import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import '../domain/image_preprocess.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'stage_support.dart';

/// The prepare stage: writes a derived copy of each photo ready for reading.
///
/// Originals are only read. The prepared copy sits beside the compressed
/// copy as a new file.
final class PrepareStage {
  /// Creates the stage writing under [storageRoot].
  PrepareStage({
    required StorageRoot storageRoot,
    required this._paths,
    FileWriter? writer,
  }) : _writer = writer ?? FileWriter(storageRoot: storageRoot);

  final FileWriter _writer;
  final PhotoPaths _paths;

  /// Prepares every photo in [bundle] that has no prepared copy yet.
  Future<void> run(RecordBundle bundle, CancellationToken cancel) async {
    for (final Photo photo in bundle.photos) {
      if (cancel.isCancelled) throw const CancelledFailure();
      final String written = await _paths.compressedRelative(
        bundle,
        photo,
        cancel: cancel,
      );
      final String destination = '$written.ocr.jpg';
      if (await _paths.read(destination) is Success<Uint8List>) {
        continue;
      }
      final Uint8List reduced = StageSupport.unwrap(await _paths.read(written));
      final Uint8List prepared = StageSupport.unwrap(
        await ImagePreprocess.prepareOffThread(reduced, cancel: cancel),
      );
      if (prepared.isEmpty) {
        throw const ValidationFailure(
          message: 'That photo could not be prepared for reading.',
          recoveryAction: 'Use another photo or enter the value by hand.',
        );
      }
      StageSupport.unwrap(
        await _writer.write(Stream<List<int>>.value(prepared), destination),
      );
    }
  }
}
