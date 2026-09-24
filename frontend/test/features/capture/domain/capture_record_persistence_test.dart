import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';

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
}

final class _RecordPersistence implements CaptureRecordPersistence {
  @override
  Future<Result<String>> persist(CaptureSession session) async {
    return Success<String>(session.id);
  }
}
