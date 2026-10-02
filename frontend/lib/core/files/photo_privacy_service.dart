import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/face_blur.dart';
import 'package:tapture/core/export/face_detector.dart';
import 'package:tapture/core/export/image_redaction.dart';
import 'package:tapture/core/time/clock.dart';

import 'file_reader.dart';
import 'file_writer.dart';

/// Durable photo policy shared by capture, analysis and export.
final Provider<PhotoPrivacyService?> photoPrivacyServiceProvider =
    Provider<PhotoPrivacyService?>((Ref _) => null);

/// Applies the latest saved marks every time evidence leaves the device.
/// Originals remain untouched; only disposable derivatives are written.
final class PhotoPrivacyService {
  /// Creates the service over the existing audit trail and file store.
  PhotoPrivacyService({
    required this._db,
    required this._files,
    required this._writer,
    required this._clock,
    required this._deviceId,
    this._operatorName,
    FaceDetector? detector,
  }) : _detector = detector ?? const FaceDetector();

  final AppDatabase _db;
  final FileReader _files;
  final FileWriter _writer;
  final Clock _clock;
  final String _deviceId;
  final String Function()? _operatorName;
  final FaceDetector _detector;

  /// Stable mask revision used to reject an in-flight send after an edit.
  Future<Result<String>> revision(String photoId) async {
    try {
      final Map<String, Object?> policy = await _policy(photoId);
      _marks(policy);
      if (policy.isEmpty) await _checkAncestors(photoId);
      return Success<String>(_maskSignature(policy));
    } on Object catch (error) {
      return FailureResult<String>(Failure.from(error));
    }
  }

  /// Checks policy without decoding a photo, preserving ordinary OCR cache hits.
  Future<Result<bool>> requiresProtection(
    String photoId, {
    bool blurFaces = false,
    bool stripLocation = false,
  }) async {
    try {
      final Map<String, Object?> policy = await _policy(photoId);
      final List<ImageRect> marks = _marks(policy);
      if (policy.isEmpty) await _checkAncestors(photoId);
      return Success<bool>(marks.isNotEmpty || blurFaces || stripLocation);
    } on Object catch (error) {
      return FailureResult<bool>(Failure.from(error));
    }
  }

  /// The current saved marks for the photo editor.
  Future<Result<List<ImageRect>>> marks(String photoId) async {
    try {
      return Success<List<ImageRect>>(_marks(await _policy(photoId)));
    } on Object catch (error) {
      return FailureResult<List<ImageRect>>(Failure.from(error));
    }
  }

  /// Writes one append-only policy event before the editor confirms success.
  Future<Result<void>> setMarks(String photoId, List<ImageRect> marks) async {
    try {
      if (marks.any((ImageRect mark) => !_valid(mark))) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.failureAHiddenAreaIsInvalid,
        );
      }
      final Photo? photo = await (_db.select(
        _db.photos,
      )..where(($PhotosTable row) => row.id.equals(photoId))).getSingleOrNull();
      if (photo == null) {
        throw StorageFailure(
          localizedMessage: Copy.messages.failureThatPhotoIsNoLongerAvailable,
        );
      }
      await _writePolicy(photoId, <String, Object?>{
        'marks': <Map<String, double>>[
          for (final ImageRect mark in marks)
            <String, double>{
              'x': mark.x,
              'y': mark.y,
              'width': mark.width,
              'height': mark.height,
            },
        ],
      }, reason: 'operator-redaction');
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    }
  }

  /// Burns saved masks, optionally discovers/blurs faces and removes metadata.
  /// Any required protection failure stops egress, including a failed write.
  Future<Result<PhotoPrivacyCopy>> prepare(
    String photoId,
    String sourcePath, {
    required CancellationToken cancel,
    bool blurFaces = false,
    bool stripLocation = false,
  }) async {
    try {
      _check(cancel);
      final Map<String, Object?> policy = await _policy(photoId);
      final String revision = _maskSignature(policy);
      final List<ImageRect> marks = _marks(policy);
      if (policy.isEmpty) await _checkAncestors(photoId);
      if (marks.isEmpty && !blurFaces && !stripLocation) {
        return Success<PhotoPrivacyCopy>((
          path: sourcePath,
          faceCount: null,
          redacted: false,
          sha256: null,
          byteLength: null,
        ));
      }
      final Uint8List original = _unwrap(await _files.read(sourcePath));
      final String fingerprint = _unwrap(
        await runIsolate<({Uint8List bytes, String policy}), String>(
          _fingerprint,
          (
            bytes: original,
            policy: jsonEncode(<Object?>[
              marks
                  .map(
                    (ImageRect mark) => <double>[
                      mark.x,
                      mark.y,
                      mark.width,
                      mark.height,
                    ],
                  )
                  .toList(),
              blurFaces,
              stripLocation,
            ]),
          ),
          cancel: cancel,
        ),
      );
      final String path = '.cache/privacy/$fingerprint.png';
      final Result<int?> cached = await _files.length(path);
      if (cached is Success<int?> &&
          cached.value != null &&
          (!blurFaces || policy['checkedFaces'] == true)) {
        final Uint8List bytes = _unwrap(await _files.read(path));
        final String hash = _unwrap(
          await runIsolate<Uint8List, String>(
            _hashBytes,
            bytes,
            cancel: cancel,
          ),
        );
        await _requireRevision(photoId, revision);
        return Success<PhotoPrivacyCopy>((
          path: path,
          faceCount: blurFaces ? policy['faceCount'] as int? : null,
          redacted: marks.isNotEmpty,
          sha256: hash,
          byteLength: bytes.length,
        ));
      }
      // This pass also bakes EXIF orientation and removes metadata, so masks
      // and the detector share the same upright pixel coordinate space.
      Uint8List copy = _unwrap(
        await ImageRedaction.burn(original, marks, cancel: cancel),
      );
      int? faceCount;
      if (blurFaces) {
        final List<FaceRect> faces = _unwrap(
          await _detector.detect(copy, cancel: cancel),
        );
        final FaceBlurCopy blurred = _unwrap(
          await FaceBlur.apply(copy, faces, cancel: cancel),
        );
        copy = blurred.bytes;
        faceCount = blurred.faceCount;
      }
      _check(cancel);
      await _requireRevision(photoId, revision);
      final WrittenFile written = _unwrap(
        await _writer.write(Stream<List<int>>.value(copy), path),
      );
      _check(cancel);
      await _requireRevision(photoId, revision);
      if (blurFaces &&
          (policy['checkedFaces'] != true ||
              policy['faceCount'] != faceCount)) {
        await _writePolicy(
          photoId,
          <String, Object?>{
            ...policy,
            'marks': <Map<String, double>>[
              for (final ImageRect mark in marks)
                <String, double>{
                  'x': mark.x,
                  'y': mark.y,
                  'width': mark.width,
                  'height': mark.height,
                },
            ],
            'checkedFaces': true,
            'faceCount': faceCount,
          },
          reason: 'faces-checked',
          expectedRevision: revision,
        );
      }
      return Success<PhotoPrivacyCopy>((
        path: path,
        faceCount: faceCount,
        redacted: marks.isNotEmpty,
        sha256: written.sha256,
        byteLength: written.byteLength,
      ));
    } on Object catch (error) {
      return FailureResult<PhotoPrivacyCopy>(Failure.from(error));
    }
  }

  Future<Map<String, Object?>> _policy(String photoId) async {
    final AuditLogData? latest =
        await (_db.select(_db.auditLog)
              ..where(
                ($AuditLogTable row) =>
                    row.entityType.equals('photos') &
                    row.entityId.equals(photoId) &
                    row.fieldKey.equals('privacy'),
              )
              ..orderBy(<OrderClauseGenerator<$AuditLogTable>>[
                ($AuditLogTable row) => OrderingTerm.desc(row.at),
                ($AuditLogTable row) => OrderingTerm.desc(row.rowId),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (latest == null) return const <String, Object?>{};
    if (latest.newValue == null) {
      throw const FormatException('Missing photo privacy policy.');
    }
    final Object? decoded = jsonDecode(latest.newValue!);
    if (decoded is! Map) {
      throw const FormatException('Invalid photo privacy policy.');
    }
    return Map<String, Object?>.from(decoded);
  }

  Future<void> _writePolicy(
    String photoId,
    Map<String, Object?> policy, {
    required String reason,
    String? expectedRevision,
  }) {
    return _db.transaction(() async {
      final Map<String, Object?> previous = await _policy(photoId);
      if (expectedRevision != null &&
          _maskSignature(previous) != expectedRevision) {
        throw ValidationFailure(
          localizedMessage:
              Copy.messages.failureHiddenAreasChangedTrySendingAgain,
        );
      }
      await appendAudit(
        _db,
        entityType: 'photos',
        entityId: photoId,
        action: AuditAction.updated,
        fieldKey: 'privacy',
        previousValue: jsonEncode(previous),
        newValue: jsonEncode(policy),
        reason: reason,
        clock: _clock,
        device: _deviceId,
        operator: _operatorName?.call() ?? _deviceId,
      );
    });
  }

  Future<void> _requireRevision(String photoId, String revision) async {
    if (_maskSignature(await _policy(photoId)) != revision) {
      throw ValidationFailure(
        localizedMessage:
            Copy.messages.failureHiddenAreasChangedTrySendingAgain,
      );
    }
  }

  Future<void> _checkAncestors(String photoId) async {
    final Set<String> visited = <String>{};
    String? current = photoId;
    while (current != null && visited.add(current)) {
      final Photo? photo =
          await (_db.select(_db.photos)
                ..where(($PhotosTable row) => row.id.equals(current!)))
              .getSingleOrNull();
      current = photo?.derivedFrom;
      if (current != null && _marks(await _policy(current)).isNotEmpty) {
        throw ValidationFailure(
          localizedMessage:
              Copy.messages.failureCheckTheHiddenAreasOnThisEdited,
          localizedRecovery:
              Copy.messages.failureOpenHidePartsBeforeSendingAndSave,
        );
      }
    }
    if (current != null) throw const FormatException('Cyclic photo ancestry.');
  }
}

/// A protected copy under the storage root, and its visible face result.
typedef PhotoPrivacyCopy = ({
  String path,
  int? faceCount,
  bool redacted,
  String? sha256,
  int? byteLength,
});

T _unwrap<T>(Result<T> result) =>
    result.fold((Failure failure) => throw failure, (T value) => value);

void _check(CancellationToken cancel) {
  if (cancel.isCancelled) throw const CancelledFailure();
}

String _fingerprint(({Uint8List bytes, String policy}) job) => sha256.convert(
  <int>[...sha256.convert(job.bytes).bytes, ...utf8.encode(job.policy)],
).toString();

String _hashBytes(Uint8List bytes) => sha256.convert(bytes).toString();

String _maskSignature(Map<String, Object?> policy) =>
    jsonEncode(policy['marks']);

List<ImageRect> _marks(Map<String, Object?> policy) {
  final Object? raw = policy['marks'];
  if (raw == null && policy.isEmpty) return const <ImageRect>[];
  if (raw is! List) throw const FormatException('Invalid hidden areas.');
  final List<ImageRect> marks = <ImageRect>[];
  for (final Object? row in raw) {
    if (row is! Map ||
        row['x'] is! num ||
        row['y'] is! num ||
        row['width'] is! num ||
        row['height'] is! num) {
      throw const FormatException('Invalid hidden area.');
    }
    final ImageRect mark = (
      x: (row['x'] as num).toDouble(),
      y: (row['y'] as num).toDouble(),
      width: (row['width'] as num).toDouble(),
      height: (row['height'] as num).toDouble(),
    );
    if (!_valid(mark)) {
      throw const FormatException('Invalid hidden area bounds.');
    }
    marks.add(mark);
  }
  return List<ImageRect>.unmodifiable(marks);
}

bool _valid(ImageRect mark) =>
    mark.x.isFinite &&
    mark.y.isFinite &&
    mark.width.isFinite &&
    mark.height.isFinite &&
    mark.x >= 0 &&
    mark.y >= 0 &&
    mark.width > 0 &&
    mark.height > 0 &&
    mark.x + mark.width <= 1 &&
    mark.y + mark.height <= 1;
