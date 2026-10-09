import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/owned_capture_persistence.dart';

import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  test(
    'the owned capability preserves durable attribution through its domain port',
    () async {
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final OwnedCapturePersistence persistence = CapturePersistenceImpl(
        photos: photos,
        store: TextStore.memory(),
      );
      const CaptureSession session = CaptureSession(
        id: 'session-1',
        projectId: 'project-1',
        templateId: 'template-1',
        templateVersion: 1,
        contextSnapshot: <String, String>{'district': 'North'},
      );
      const owner = (
        sessionId: 'session-1',
        templateId: 'template-1',
        templateVersion: 1,
      );
      (await persistence.saveSession(session)).getOrThrow();
      (await persistence.saveOwnedSession(
        session.copyWith(
          values: <String, Object?>{'serial': null},
          valueSources: <String, String>{'serial': 'TYPED'},
        ),
        owner: owner,
      )).getOrThrow();
      final CaptureSession saved = (await persistence.loadSession(
        'project-1',
      )).getOrThrow()!;
      expect(saved.id, session.id);
      expect(saved.templateVersion, session.templateVersion);
      expect(saved.contextSnapshot, session.contextSnapshot);
      expect(saved.values.containsKey('serial'), isTrue);
      expect(saved.values['serial'], isNull);
      expect(saved.valueSources['serial'], 'TYPED');
      (await persistence.clearSession('project-1')).getOrThrow();
      expect(
        await persistence.saveOwnedSession(saved, owner: owner),
        isA<FailureResult<void>>(),
      );
      expect((await persistence.loadSession('project-1')).getOrThrow(), isNull);
    },
  );
}
