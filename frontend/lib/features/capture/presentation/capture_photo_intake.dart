import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/image_metadata.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/features/capture/domain/capture_photo_path.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_headroom.dart';
import 'package:tapture/features/capture/presentation/capture_target_fields.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

/// How new photo bytes enter a capture session, shared by the capture page
/// and rapid mode so both file evidence the same way.
///
/// Each photo is written into the folder its capture-time context names
/// (spec section 8.1), durably, before the session shows it. The file
/// writer hashes the bytes as they land, so nothing is hashed on the UI
/// isolate (FE-PERF-02). A new capture starts only while the device is not
/// known to be full, and a write already under way completes even if it
/// has just filled up (task 012 step 21).
abstract final class CapturePhotoIntake {
  /// Whether a new capture may start. A failure names the full device and
  /// the way out; null means admitted.
  static Future<Result<HeadroomState>?> admit(WidgetRef ref) {
    return ref.read(captureHeadroomProvider.notifier).admit();
  }

  /// Writes [bytes] as a new photo of the session under [sessionKey], filed
  /// under [projectId].
  static Future<Result<PhotoDraft>> store(
    WidgetRef ref, {
    required String sessionKey,
    required String projectId,
    required Uint8List bytes,
    String? derivedFrom,
  }) async {
    final Result<ImageMetadata> inspected = await ImageMetadata.inspect(bytes);
    if (inspected case FailureResult<ImageMetadata>(:final Failure failure)) {
      return FailureResult<PhotoDraft>(failure);
    }
    if (!ref.context.mounted) {
      return const FailureResult<PhotoDraft>(CancelledFailure());
    }
    final ImageMetadata metadata = (inspected as Success<ImageMetadata>).value;
    final CaptureSession session = ref.read(
      captureControllerProvider(sessionKey),
    );
    final String id = ref.read(captureIdsProvider).newId();
    // After the last position in use, so a photo added after a removal
    // never shares a place with one still in the tray.
    int sortOrder = 0;
    for (final PhotoDraft photo in session.photos) {
      if (photo.sortOrder >= sortOrder) {
        sortOrder = photo.sortOrder + 1;
      }
    }
    final DateTime capturedAt = ref.read(captureClockProvider).nowUtc();
    final String fileName = '$id.${metadata.extension}';
    final PhotoDraft draft = PhotoDraft(
      id: id,
      projectId: projectId,
      captureSessionId: session.id,
      originalFilename: fileName,
      storedFilename: fileName,
      relativePath: _path(ref, projectId, session, fileName, capturedAt),
      sha256: '',
      fileSize: bytes.length,
      mimeType: metadata.mimeType,
      width: metadata.width,
      height: metadata.height,
      capturedAt: capturedAt,
      derivedFrom: derivedFrom,
      sortOrder: sortOrder,
      gpsLat: session.location?.latitude,
      gpsLon: session.location?.longitude,
    );
    final CaptureController controller = ref.read(
      captureControllerProvider(sessionKey).notifier,
    );
    final Result<void> saved = await ref
        .read(captureHeadroomProvider.notifier)
        .complete(() => controller.addPhoto(draft, bytes: bytes));
    return saved.map(
      (_) => ref.context.mounted ? _stored(ref, sessionKey, draft) : draft,
    );
  }

  /// Writes [bytes] as [derived], an edited copy of [source], beside the
  /// source's file, and carries the source's caption onto it. The original
  /// stays as it is (task 012 step 8).
  static Future<Result<PhotoDraft>> storeDerived(
    WidgetRef ref, {
    required String sessionKey,
    required String projectId,
    required PhotoDraft source,
    required PhotoDraft derived,
    required Uint8List bytes,
  }) async {
    final Result<ImageMetadata> inspected = await ImageMetadata.inspect(bytes);
    if (inspected case FailureResult<ImageMetadata>(:final Failure failure)) {
      return FailureResult<PhotoDraft>(failure);
    }
    if (!ref.context.mounted) {
      return const FailureResult<PhotoDraft>(CancelledFailure());
    }
    final ImageMetadata metadata = (inspected as Success<ImageMetadata>).value;
    final String derivedName = derived.relativePath.substring(
      derived.relativePath.lastIndexOf('/') + 1,
    );
    final int extensionAt = derivedName.lastIndexOf('.');
    final String stem = extensionAt < 0
        ? derivedName
        : derivedName.substring(0, extensionAt);
    final PhotoDraft beside = derived.copyWith(
      projectId: projectId,
      relativePath: _beside(source.relativePath, '$stem.${metadata.extension}'),
      storedFilename: '$stem.${metadata.extension}',
      mimeType: metadata.mimeType,
      width: metadata.width,
      height: metadata.height,
      sha256: '',
      fileSize: bytes.length,
    );
    final CaptureController controller = ref.read(
      captureControllerProvider(sessionKey).notifier,
    );
    final Result<void> saved = await ref
        .read(captureHeadroomProvider.notifier)
        .complete(() => controller.updatePhoto(beside, bytes: bytes));
    if (saved case FailureResult<void>(:final failure)) {
      return FailureResult<PhotoDraft>(failure);
    }
    if (!ref.context.mounted) return Success<PhotoDraft>(beside);
    final String? caption = ref
        .read(captureControllerProvider(sessionKey))
        .captions[source.id];
    if (caption != null && caption.isNotEmpty) {
      await controller.setCaption(beside.id, caption);
    }
    return Success<PhotoDraft>(
      ref.context.mounted ? _stored(ref, sessionKey, beside) : beside,
    );
  }

  /// [written] as the session holds it after the write, with the hash and
  /// size the writer measured.
  static PhotoDraft _stored(
    WidgetRef ref,
    String sessionKey,
    PhotoDraft written,
  ) {
    for (final PhotoDraft photo
        in ref.read(captureControllerProvider(sessionKey)).photos) {
      if (photo.id == written.id) {
        return photo;
      }
    }
    return written;
  }

  static String _path(
    WidgetRef ref,
    String projectId,
    CaptureSession session,
    String fileName,
    DateTime capturedAt,
  ) {
    final Project? project = ref.read(currentProjectDetailsProvider);
    final ContextState? context = projectId.isEmpty
        ? null
        : ref.read(projectContextProvider(projectId)).asData?.value;
    final List<ContextLevel> levels = <ContextLevel>[...?context?.levels]
      ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
    String? templateName;
    for (final TemplateDef template
        in ref.read(captureProjectTemplatesProvider(projectId)).asData?.value ??
            const <TemplateDef>[]) {
      if (template.id == session.templateId) {
        templateName = template.name;
      }
    }
    return CapturePhotoPath.of(
      fileName: fileName,
      strategy: project?.id == projectId
          ? project?.settings.folderStrategy
          : null,
      levelKeys: <String>[
        for (final ContextLevel level in levels) level.fieldKey,
      ],
      context: session.contextSnapshot,
      capturedAt: capturedAt,
      templateName: templateName,
    );
  }

  /// [derivedPath]'s file name in [sourcePath]'s folder.
  static String _beside(String sourcePath, String derivedPath) {
    final int folderEnd = sourcePath.lastIndexOf('/');
    final String name = derivedPath.substring(derivedPath.lastIndexOf('/') + 1);
    return folderEnd < 0 ? name : '${sourcePath.substring(0, folderEnd)}/$name';
  }
}
