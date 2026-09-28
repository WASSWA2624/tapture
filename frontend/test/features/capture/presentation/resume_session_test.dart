import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';

void main() {
  test('a late template write keeps photos from a resume that finished first', () async {
    final _Gate gate = _Gate();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        capturePersistenceProvider.overrideWith((Ref ref) => gate),
      ],
    );
    addTearDown(container.dispose);
    final CaptureController controller = container.read(
      captureControllerProvider('project-1').notifier,
    );
    final Future<Result<void>> template = controller.setTemplate('meters');
    await gate.started.future;
    const PhotoDraft photo = PhotoDraft(
      id: 'photo-1',
      projectId: 'project-1',
      relativePath: 'a.jpg',
      sha256: 'abc',
    );
    final CaptureSession resumed = controller.state.copyWith(
      photos: const <PhotoDraft>[photo],
      templateId: '',
    );
    await controller.replaceSession(resumed);
    gate.release();
    await template;
    expect(controller.state.photos, hasLength(1));
    expect(controller.state.photos.single.id, 'photo-1');
    expect(controller.state.templateId, 'meters');
  });
}

final class _Gate implements CapturePersistence {
  final Completer<void> started = Completer<void>();
  Completer<void>? _hold;

  void release() {
    _hold?.complete();
  }

  @override
  PhotoRepository get photos => throw UnimplementedError();

  @override
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo, {Uint8List? bytes}) {
    return Future<Result<PhotoDraft>>.value(Success<PhotoDraft>(photo));
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) {
    return Future<Result<void>>.value(const Success<void>(null));
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    if (!started.isCompleted) {
      _hold = Completer<void>();
      started.complete();
      await _hold!.future;
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) async =>
      const Success<CaptureSession?>(null);

  @override
  Future<Result<void>> clearSession(String key) async =>
      const Success<void>(null);
}
