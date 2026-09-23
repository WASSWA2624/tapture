import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';

void main() {
  test('recovery JSON preserves metadata and snapshots photo owners', () {
    final List<String> owners = <String>['photo-1'];
    final AudioDraft draft = AudioDraft(
      id: 'audio-1',
      projectId: 'project-1',
      relativePath: 'audio/audio-1.wav',
      mimeType: 'audio/wav',
      fileSize: 2048,
      sha256: 'abc123',
      durationMs: 1250,
      photoIds: owners,
    );
    owners.add('photo-2');

    final AudioDraft restored = AudioDraft.fromJson(draft.toJson());

    expect(draft.photoIds, <String>['photo-1']);
    expect(() => draft.photoIds.add('photo-3'), throwsUnsupportedError);
    expect(restored.id, draft.id);
    expect(restored.projectId, draft.projectId);
    expect(restored.relativePath, draft.relativePath);
    expect(restored.mimeType, draft.mimeType);
    expect(restored.fileSize, draft.fileSize);
    expect(restored.sha256, draft.sha256);
    expect(restored.durationMs, draft.durationMs);
    expect(restored.photoIds, draft.photoIds);
  });
}
