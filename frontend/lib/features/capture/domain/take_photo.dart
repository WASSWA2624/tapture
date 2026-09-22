import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/ids/uuid_service.dart';

import 'photo_draft.dart';

/// Writes shutter bytes through [FileWriter], hashes them, and builds a
/// [PhotoDraft]. Preview stays live — callers run this off the UI thread.
abstract final class TakePhoto {
  /// Persists [bytes] at [relativePath] and returns a draft.
  static Future<Result<PhotoDraft>> write({
    required Uint8List bytes,
    required String relativePath,
    required String projectId,
    required String sessionId,
    required FileWriter writer,
    required IdService ids,
    String photoType = 'other',
    int sortOrder = 0,
    String originalFilename = '',
  }) async {
    final Result<WrittenFile> written = await writer.write(
      Stream<List<int>>.value(bytes),
      relativePath,
    );
    return written.fold(FailureResult<PhotoDraft>.new, (WrittenFile file) {
      final String hash = sha256.convert(bytes).toString();
      return Success<PhotoDraft>(
        PhotoDraft(
          id: ids.newId(),
          projectId: projectId,
          relativePath: file.relativePath,
          sha256: hash,
          photoType: photoType,
          sortOrder: sortOrder,
          originalFilename: originalFilename.isEmpty
              ? relativePath.split('/').last
              : originalFilename,
          fileSize: bytes.length,
          mimeType: 'image/jpeg',
        ),
      );
    });
  }
}
