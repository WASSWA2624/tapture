import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/save_raw.dart';

import '../../../support/matchers.dart';

const CaptureSession _empty = CaptureSession(
  id: 's',
  templateId: 't',
  contextSnapshot: <String, String>{},
);

const PhotoDraft _photo = PhotoDraft(
  id: 'p',
  projectId: 'proj',
  relativePath: 'a.jpg',
  sha256: 'h',
);

/// Counts every call that leaves the domain: persistence is the only one
/// a raw save may make.
final class _Outbound {
  int persists = 0;
  CaptureSession? persisted;

  Future<Result<String>> persist(CaptureSession session) async {
    persists += 1;
    persisted = session;
    return const Success<String>('rec');
  }
}

void main() {
  test('a raw save persists the session once and makes no other call', () async {
    final _Outbound outbound = _Outbound();
    final CaptureSession session = _empty.copyWith(
      captions: const <String, String>{'': 'note'},
    );

    final Result<String> result = await SaveRaw.run(
      session: session,
      persist: outbound.persist,
    );

    expect(valueOf(result), 'rec');
    expect(outbound.persists, 1);
    expect(identical(outbound.persisted, session), isTrue);
  });

  test('a raw save writes the captured status and starts nothing', () {
    expect(SaveRaw.capturedStatus, RecordStatus.captured);
  });

  test('a session with neither evidence nor a caption is refused before '
      'persistence', () async {
    final _Outbound outbound = _Outbound();

    final Result<String> result = await SaveRaw.run(
      session: _empty,
      persist: outbound.persist,
    );

    expect(result, isFailure<String, ValidationFailure>());
    expect(outbound.persists, 0);
  });

  test('a whitespace caption does not count as evidence', () async {
    final _Outbound outbound = _Outbound();

    final Result<String> result = await SaveRaw.run(
      session: _empty.copyWith(captions: const <String, String>{'': '   '}),
      persist: outbound.persist,
    );

    expect(result, isFailure<String, ValidationFailure>());
    expect(outbound.persists, 0);
  });

  test('the refusal names what to do next', () async {
    final Result<String> result = await SaveRaw.run(
      session: _empty,
      persist: _Outbound().persist,
    );

    final Failure failure = switch (result) {
      FailureResult<String>(:final Failure failure) => failure,
      Success<String>() => throw TestFailure('The save was not refused.'),
    };
    expect(failure.message, isNotEmpty);
    expect(failure.recoveryAction, isNotEmpty);
  });

  test('one photo is enough to save', () async {
    final _Outbound outbound = _Outbound();

    final Result<String> result = await SaveRaw.run(
      session: _empty.copyWith(photos: const <PhotoDraft>[_photo]),
      persist: outbound.persist,
    );

    expect(valueOf(result), 'rec');
    expect(outbound.persists, 1);
  });

  test('an audio clip alone is enough to save', () async {
    final _Outbound outbound = _Outbound();

    final Result<String> result = await SaveRaw.run(
      session: _empty.copyWith(
        audio: <AudioDraft>[
          AudioDraft(
            id: 'au',
            projectId: 'proj',
            relativePath: 'audio/au.wav',
            mimeType: 'audio/wav',
            fileSize: 10,
            sha256: 'ah',
            durationMs: 500,
          ),
        ],
      ),
      persist: outbound.persist,
    );

    expect(valueOf(result), 'rec');
    expect(outbound.persists, 1);
  });

  test('a caption under the record key is enough to save', () async {
    final _Outbound outbound = _Outbound();

    final Result<String> result = await SaveRaw.run(
      session: _empty.copyWith(
        captions: const <String, String>{'record': 'typed only'},
      ),
      persist: outbound.persist,
    );

    expect(valueOf(result), 'rec');
    expect(outbound.persists, 1);
  });

  test('a persistence failure is returned as it is', () async {
    const StorageFailure full = StorageFailure(
      message: 'No space left.',
      recoveryAction: 'Export a project.',
    );

    final Result<String> result = await SaveRaw.run(
      session: _empty.copyWith(photos: const <PhotoDraft>[_photo]),
      persist: (CaptureSession _) async => const FailureResult<String>(full),
    );

    expect(result, isFailure<String, StorageFailure>());
    expect((result as FailureResult<String>).failure, same(full));
  });
}
