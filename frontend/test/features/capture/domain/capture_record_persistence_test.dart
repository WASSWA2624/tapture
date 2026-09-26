import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';

void main() {
  test('the record persistence boundary returns the committed id', () async {
    final CaptureRecordPersistence persistence = _RecordPersistence();
    const CaptureSession session = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
    );

    final Result<String> result = await persistence.persist(session);

    expect((result as Success<String>).value, 'session-1');
  });

  test('an edit session is stored apart from the new capture', () async {
    final CaptureRecordPersistence persistence = _RecordPersistence();
    final CaptureSession edit =
        (await persistence.load('record-1') as Success<CaptureSession>).value;

    expect(edit.editing, isTrue);
    expect(edit.recordId, 'record-1');
    expect(edit.storageKey, CaptureSessionKey.edit('record-1'));
    expect(CaptureSessionKey.isEdit(edit.storageKey), isTrue);
    expect(CaptureSessionKey.recordOf(edit.storageKey), 'record-1');
    expect(CaptureSessionKey.recordOf('project-1'), isNull);
    expect(await persistence.update(edit), isA<Success<void>>());

    final CaptureSession restored = CaptureSession.fromJson(edit.toJson());
    expect(restored.editing, isTrue);
    expect(restored.storageKey, edit.storageKey);
  });
}

final class _RecordPersistence implements CaptureRecordPersistence {
  @override
  Future<Result<String>> persist(CaptureSession session) async {
    return Success<String>(session.id);
  }

  @override
  Future<Result<CaptureSession>> load(String recordId) async {
    return Success<CaptureSession>(
      CaptureSession(
        id: recordId,
        projectId: 'project-1',
        templateId: 'template-1',
        contextSnapshot: const <String, String>{},
        recordId: recordId,
        editing: true,
      ),
    );
  }

  @override
  Future<Result<void>> update(CaptureSession edited) async {
    return const Success<void>(null);
  }
}
