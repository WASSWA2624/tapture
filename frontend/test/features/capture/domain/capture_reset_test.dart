import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/capture_reset.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

import '../../../support/fakes/fake_id_service.dart';

/// A session just saved: evidence, captions, values and a record id, with
/// a mutable context so a test can prove nothing is shared.
CaptureSession _saved() {
  return CaptureSession(
    id: 'old',
    projectId: 'p1',
    templateId: 't1',
    contextSnapshot: <String, String>{'site': 'A', 'floor': '2'},
    recordId: 'record-1',
    photos: const <PhotoDraft>[
      PhotoDraft(id: 'ph', projectId: 'p1', relativePath: 'a.jpg', sha256: 'h'),
    ],
    audio: <AudioDraft>[
      AudioDraft(
        id: 'au',
        projectId: 'p1',
        relativePath: 'audio/au.wav',
        mimeType: 'audio/wav',
        fileSize: 10,
        sha256: 'ah',
        durationMs: 500,
      ),
    ],
    captions: const <String, String>{'': 'note', 'ph': 'front'},
    values: const <String, Object?>{'serial': 'A-1'},
    isDirty: true,
  );
}

void main() {
  test('the next session keeps the project, template and context', () {
    final CaptureSession next = CaptureReset.next(
      previous: _saved(),
      ids: FakeIdService(),
    );

    expect(next.projectId, 'p1');
    expect(next.templateId, 't1');
    expect(next.contextSnapshot, <String, String>{'site': 'A', 'floor': '2'});
  });

  test('the next session drops evidence, captions, values, audio, dirt and '
      'the record id, so capturing the next item re-selects nothing', () {
    final CaptureSession next = CaptureReset.next(
      previous: _saved(),
      ids: FakeIdService(),
    );

    expect(next.photos, isEmpty);
    expect(next.audio, isEmpty);
    expect(next.captions, isEmpty);
    expect(next.values, isEmpty);
    expect(next.recordId, isNull);
    expect(next.isDirty, isFalse);
    expect(next.editing, isFalse);
    expect(next.hasEvidence, isFalse);
  });

  test('the next session takes a fresh id from the id service', () {
    final FakeIdService ids = FakeIdService(prefix: 'session');

    final CaptureSession next = CaptureReset.next(previous: _saved(), ids: ids);

    expect(next.id, 'session-1');
    expect(next.id, isNot('old'));
    expect(ids.minted, 1);
  });

  test('the next session shares no mutable state with the saved one', () {
    final CaptureSession previous = _saved();

    final CaptureSession next = CaptureReset.next(
      previous: previous,
      ids: FakeIdService(),
    );
    previous.contextSnapshot['site'] = 'changed';
    next.contextSnapshot['floor'] = '9';

    expect(identical(next.contextSnapshot, previous.contextSnapshot), isFalse);
    expect(next.contextSnapshot['site'], 'A');
    expect(previous.contextSnapshot['floor'], '2');
    expect(identical(next.photos, previous.photos), isFalse);
    expect(identical(next.captions, previous.captions), isFalse);
    expect(identical(next.values, previous.values), isFalse);
  });

  test('the saved session is untouched by the reset', () {
    final CaptureSession previous = _saved();
    final Map<String, Object?> before = previous.toJson();

    CaptureReset.next(previous: previous, ids: FakeIdService());

    expect(previous.toJson(), before);
    expect(previous.photos, hasLength(1));
    expect(previous.recordId, 'record-1');
  });

  test('a reset after an edit starts a plain new capture', () {
    final CaptureSession next = CaptureReset.next(
      previous: _saved().copyWith(editing: true),
      ids: FakeIdService(),
    );

    expect(next.editing, isFalse);
    expect(next.storageKey, 'p1');
  });
}
