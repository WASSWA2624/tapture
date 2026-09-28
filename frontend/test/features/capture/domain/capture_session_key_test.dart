import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';

void main() {
  test('an edit key names its record', () {
    final String key = CaptureSessionKey.edit('r1');

    expect(key, 'edit:r1');
    expect(CaptureSessionKey.isEdit(key), isTrue);
    expect(CaptureSessionKey.recordOf(key), 'r1');
  });

  test('a project id is not an edit key and names no record', () {
    expect(CaptureSessionKey.isEdit('p1'), isFalse);
    expect(CaptureSessionKey.recordOf('p1'), isNull);
  });

  test('a project id that mentions edit later in its name is a project', () {
    expect(CaptureSessionKey.isEdit('site-edit:1'), isFalse);
    expect(CaptureSessionKey.recordOf('site-edit:1'), isNull);
  });

  test('a record id with a colon inside round-trips through its key', () {
    expect(CaptureSessionKey.recordOf(CaptureSessionKey.edit('a:b')), 'a:b');
  });

  test('an empty key is neither an edit nor a record', () {
    expect(CaptureSessionKey.isEdit(''), isFalse);
    expect(CaptureSessionKey.recordOf(''), isNull);
  });

  test('an edit is stored apart from the project\'s unsaved new capture', () {
    const CaptureSession capture = CaptureSession(
      id: 's1',
      projectId: 'p1',
      templateId: 't1',
      contextSnapshot: <String, String>{},
    );
    const CaptureSession edit = CaptureSession(
      id: 's2',
      projectId: 'p1',
      templateId: 't1',
      contextSnapshot: <String, String>{},
      recordId: 'r1',
      editing: true,
    );

    expect(capture.storageKey, 'p1');
    expect(edit.storageKey, CaptureSessionKey.edit('r1'));
    expect(edit.storageKey, isNot(capture.storageKey));
  });

  test('an edit without a record id yet is keyed by its session id', () {
    const CaptureSession edit = CaptureSession(
      id: 's2',
      projectId: 'p1',
      templateId: 't1',
      contextSnapshot: <String, String>{},
      editing: true,
    );

    expect(edit.storageKey, CaptureSessionKey.edit('s2'));
  });
}
