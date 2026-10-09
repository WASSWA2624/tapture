import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';

import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  for (final String inconsistency in const <String>[
    'missing project',
    'different project',
    'capture stored as edit',
    'edit stored as capture',
    'different edit record',
    'empty candidate project',
  ]) {
    test('an owned JSON update refuses $inconsistency without changing '
        'the raw store', () async {
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final TextStore store = TextStore.memory();
      final CapturePersistenceImpl persistence = CapturePersistenceImpl(
        photos: photos,
        store: store,
      );
      final bool editing =
          inconsistency == 'edit stored as capture' ||
          inconsistency == 'different edit record' ||
          inconsistency == 'empty candidate project';
      final CaptureSession session = _ownedSession().copyWith(
        editing: editing,
        recordId: 'record-1',
      );
      final CaptureSession sibling = session.copyWith(
        id: 'sibling',
        editing: !editing,
        recordId: 'record-sibling',
      );
      final Map<String, Object?> corrupted = session.toJson();
      switch (inconsistency) {
        case 'missing project':
          corrupted.remove('projectId');
        case 'different project':
          corrupted['projectId'] = 'project-other';
        case 'capture stored as edit':
          corrupted['editing'] = true;
        case 'edit stored as capture':
          corrupted['editing'] = false;
        case 'different edit record':
          corrupted['recordId'] = 'record-other';
        case 'empty candidate project':
          corrupted['projectId'] = '';
      }
      final CaptureSession candidate = session.copyWith(
        projectId: inconsistency == 'empty candidate project'
            ? ''
            : session.projectId,
        values: const <String, Object?>{'inspection': 'OLD'},
      );
      final String before = jsonEncode(<String, Object?>{
        'sessions': <String, Object?>{
          session.storageKey: corrupted,
          sibling.storageKey: sibling.toJson(),
        },
      });
      await store.write(before);
      expect(
        await persistence.saveOwnedSession(candidate, owner: _owner(session)),
        isA<FailureResult<void>>(),
      );
      expect(store.read(), before);
      expect(
        _ok(await persistence.loadSession(sibling.storageKey))?.toJson(),
        sibling.toJson(),
      );
    });
  }

  for (final int? version in <int?>[null, 0, 7]) {
    test(
      'an owned JSON update preserves a draft with version $version',
      () async {
        final FakePhotoRepository photos = FakePhotoRepository();
        addTearDown(photos.dispose);
        final TextStore store = TextStore.memory();
        final CapturePersistenceImpl first = CapturePersistenceImpl(
          photos: photos,
          store: store,
        );
        final CapturePersistenceImpl reopened = CapturePersistenceImpl(
          photos: photos,
          store: store,
        );
        final CaptureSession session = _ownedSession(version: version);
        final CaptureSession edit = session.copyWith(
          id: 'record-1',
          recordId: 'record-1',
          editing: true,
        );
        _ok(await first.saveSession(session));
        _ok(await first.saveSession(edit));
        final CaptureSession updated = session.copyWith(
          values: const <String, Object?>{'inspection': null, 'count': 3},
          valueSources: const <String, String>{'inspection': 'TYPED'},
        );

        _ok(await reopened.saveOwnedSession(updated, owner: _owner(session)));

        expect(
          _ok(await first.loadSession(session.storageKey))?.toJson(),
          updated.toJson(),
        );
        expect(
          _ok(await reopened.loadSession(edit.storageKey))?.toJson(),
          edit.toJson(),
        );
      },
    );
  }

  test('an owned JSON update migrates a matching legacy session', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final TextStore store = TextStore.memory();
    final CaptureSession session = _ownedSession(version: 0);
    final Map<String, Object?> legacy = session.toJson()
      ..remove('templateVersion');
    await store.write(jsonEncode(legacy));
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CaptureSession updated = session.copyWith(
      values: const <String, Object?>{'inspection': 'Confirmed'},
    );

    _ok(await persistence.saveOwnedSession(updated, owner: _owner(session)));

    expect(
      _ok(await persistence.loadSession(session.storageKey))?.toJson(),
      updated.toJson(),
    );
    expect(jsonDecode(store.read()!), contains('sessions'));
  });

  final List<({String reason, String id, String template, int? version})>
  mismatches = <({String reason, String id, String template, int? version})>[
    (
      reason: 'session id',
      id: 'session-other',
      template: 'template-1',
      version: 7,
    ),
    (
      reason: 'template id',
      id: 'session-1',
      template: 'template-other',
      version: 7,
    ),
    (
      reason: 'template version',
      id: 'session-1',
      template: 'template-1',
      version: 8,
    ),
    (
      reason: 'null version',
      id: 'session-1',
      template: 'template-1',
      version: null,
    ),
  ];
  for (final mismatch in mismatches) {
    test('a JSON owner with a different ${mismatch.reason} cannot '
        'change the durable draft', () async {
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final TextStore store = TextStore.memory();
      final CapturePersistenceImpl persistence = CapturePersistenceImpl(
        photos: photos,
        store: store,
      );
      final CaptureSession session = _ownedSession();
      _ok(await persistence.saveSession(session));
      final String? before = store.read();

      expect(
        await persistence.saveOwnedSession(
          session.copyWith(
            values: const <String, Object?>{'inspection': 'Late'},
          ),
          owner: (
            sessionId: mismatch.id,
            templateId: mismatch.template,
            templateVersion: mismatch.version,
          ),
        ),
        isA<FailureResult<void>>(),
      );

      expect(store.read(), before);
      expect(
        _ok(await persistence.loadSession(session.storageKey))?.toJson(),
        session.toJson(),
      );
    });

    test('a JSON candidate with a different ${mismatch.reason} cannot '
        'change the durable draft', () async {
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final TextStore store = TextStore.memory();
      final CapturePersistenceImpl persistence = CapturePersistenceImpl(
        photos: photos,
        store: store,
      );
      final CaptureSession session = _ownedSession();
      _ok(await persistence.saveSession(session));
      final String? before = store.read();
      final CaptureSession candidate = _ownedSession(
        id: mismatch.id,
        template: mismatch.template,
        version: mismatch.version,
      );

      expect(
        await persistence.saveOwnedSession(candidate, owner: _owner(session)),
        isA<FailureResult<void>>(),
      );

      expect(store.read(), before);
    });
  }

  for (final int? storedVersion in <int?>[null, 0]) {
    test('JSON keeps unselected and legacy version ownership distinct '
        'for $storedVersion', () async {
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final TextStore store = TextStore.memory();
      final CapturePersistenceImpl persistence = CapturePersistenceImpl(
        photos: photos,
        store: store,
      );
      final CaptureSession session = _ownedSession(version: storedVersion);
      final int? differentVersion = storedVersion == null ? 0 : null;
      _ok(await persistence.saveSession(session));
      final String? before = store.read();

      expect(
        await persistence.saveOwnedSession(
          session,
          owner: (
            sessionId: session.id,
            templateId: session.templateId,
            templateVersion: differentVersion,
          ),
        ),
        isA<FailureResult<void>>(),
      );
      expect(store.read(), before);
      expect(
        await persistence.saveOwnedSession(
          _ownedSession(version: differentVersion),
          owner: _owner(session),
        ),
        isA<FailureResult<void>>(),
      );
      expect(store.read(), before);
    });
  }

  test('a missing JSON owner cannot recreate a cleared draft', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final TextStore store = TextStore.memory();
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CaptureSession session = _ownedSession();
    final CaptureSession edit = session.copyWith(
      id: 'record-1',
      recordId: 'record-1',
      editing: true,
    );
    _ok(await persistence.saveSession(session));
    _ok(await persistence.saveSession(edit));
    _ok(await persistence.clearSession(session.storageKey));
    final String? before = store.read();

    expect(
      await persistence.saveOwnedSession(session, owner: _owner(session)),
      isA<FailureResult<void>>(),
    );

    expect(store.read(), before);
    expect(_ok(await persistence.loadSession(session.storageKey)), isNull);
    expect(
      _ok(await persistence.loadSession(edit.storageKey))?.toJson(),
      edit.toJson(),
    );
  });

  for (final String corruption in <String>[
    'not JSON',
    '{"sessions":{"project-1":[]}}',
    '{"sessions":{"project-1":{"id":"session-1","templateId":"template-1",'
        '"templateVersion":"7"}}}',
  ]) {
    test('a corrupt JSON owner refuses an update and preserves '
        '$corruption', () async {
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final TextStore store = TextStore.memory();
      await store.write(corruption);
      final CapturePersistenceImpl persistence = CapturePersistenceImpl(
        photos: photos,
        store: store,
      );
      final CaptureSession session = _ownedSession();

      expect(
        await persistence.saveOwnedSession(session, owner: _owner(session)),
        isA<FailureResult<void>>(),
      );

      expect(store.read(), corruption);
    });
  }

  test('JSON reset and confirmation are ordered across instances of the '
      'same store', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final _ControlledTextStore store = _ControlledTextStore();
    final CapturePersistenceImpl oldForm = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CapturePersistenceImpl newForm = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CaptureSession session = _ownedSession();
    _ok(await oldForm.saveSession(session));
    final String? original = store.read();
    store.holdNextWrite();
    final Future<Result<void>> earlyWrite = oldForm.saveOwnedSession(
      session.copyWith(values: const <String, Object?>{'inspection': 'Early'}),
      owner: _owner(session),
    );
    await store.writeStarted;

    final Future<Result<void>> reset = newForm.clearSession(session.storageKey);
    final Future<Result<void>> lateWrite = oldForm.saveOwnedSession(
      session.copyWith(values: const <String, Object?>{'inspection': 'Stale'}),
      owner: _owner(session),
    );
    final CaptureSession confirmed = _ownedSession(
      id: 'session-confirmed',
      template: 'template-confirmed',
      version: 2,
    ).copyWith(values: const <String, Object?>{'inspection': 'Confirmed'});
    final Future<Result<void>> confirmation = newForm.saveSession(confirmed);
    expect(store.read(), original);
    expect(store.writeCount, 2);

    store.releaseWrite();
    _ok(await earlyWrite);
    _ok(await reset);
    expect(await lateWrite, isA<FailureResult<void>>());
    _ok(await confirmation);

    expect(store.writeCount, 4);
    expect(
      _ok(await oldForm.loadSession(session.storageKey))?.toJson(),
      confirmed.toJson(),
    );
    final String? durable = store.read();
    expect(
      await oldForm.saveOwnedSession(session, owner: _owner(session)),
      isA<FailureResult<void>>(),
    );
    expect(store.read(), durable);
  });

  test('delayed JSON writes preserve independent session keys across '
      'instances of the same store', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final _ControlledTextStore store = _ControlledTextStore();
    final CapturePersistenceImpl first = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CapturePersistenceImpl second = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CaptureSession session = _ownedSession();
    _ok(await first.saveSession(session));
    final CaptureSession updated = session.copyWith(
      values: const <String, Object?>{'inspection': 'Updated'},
    );
    final CaptureSession other = _ownedSession(
      id: 'session-other',
      project: 'project-other',
    );
    store.holdNextWrite();
    final Future<Result<void>> delayed = first.saveOwnedSession(
      updated,
      owner: _owner(session),
    );
    await store.writeStarted;
    final Future<Result<void>> independent = second.saveSession(other);
    expect(store.writeCount, 2);

    store.releaseWrite();
    _ok(await delayed);
    _ok(await independent);

    expect(
      _ok(await second.loadSession(session.storageKey))?.toJson(),
      updated.toJson(),
    );
    expect(
      _ok(await first.loadSession(other.storageKey))?.toJson(),
      other.toJson(),
    );
  });

  test('a failed owned JSON write preserves evidence and leaves the shared '
      'queue usable for clear and replacement', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final _ControlledTextStore store = _ControlledTextStore();
    final CapturePersistenceImpl first = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CapturePersistenceImpl second = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CaptureSession session = _ownedSession();
    _ok(await first.saveSession(session));
    final String? before = store.read();
    store.refuseNextWrite();

    expect(
      await first.saveOwnedSession(
        session.copyWith(
          values: const <String, Object?>{'inspection': 'Failed'},
        ),
        owner: _owner(session),
      ),
      isA<FailureResult<void>>(),
    );
    expect(store.read(), before);

    _ok(await second.clearSession(session.storageKey));
    expect(_ok(await first.loadSession(session.storageKey)), isNull);
    final CaptureSession replacement = _ownedSession(id: 'session-replacement');
    _ok(await second.saveSession(replacement));
    _ok(
      await first.saveOwnedSession(
        replacement.copyWith(
          values: const <String, Object?>{'inspection': 'Kept'},
        ),
        owner: _owner(replacement),
      ),
    );
    expect(
      _ok(await second.loadSession(session.storageKey))?.values['inspection'],
      'Kept',
    );
  });

  test('a failed JSON clear preserves evidence and leaves the shared queue '
      'usable for an owned update', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final _ControlledTextStore store = _ControlledTextStore();
    final CapturePersistenceImpl first = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CapturePersistenceImpl second = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );
    final CaptureSession session = _ownedSession();
    _ok(await first.saveSession(session));
    final String? before = store.read();
    store.refuseNextWrite();

    expect(
      await second.clearSession(session.storageKey),
      isA<FailureResult<void>>(),
    );
    expect(store.read(), before);

    final CaptureSession updated = session.copyWith(
      values: const <String, Object?>{'inspection': 'Kept'},
    );
    _ok(await first.saveOwnedSession(updated, owner: _owner(session)));
    expect(
      _ok(await second.loadSession(session.storageKey))?.toJson(),
      updated.toJson(),
    );
  });

  test('memory recovery session round-trips and clears', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: TextStore.memory(),
    );
    const CaptureSession session = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{'country': 'Uganda'},
      isDirty: true,
    );

    _ok(await persistence.saveSession(session));
    expect(
      _ok(await persistence.loadSession(session.projectId))?.toJson(),
      session.toJson(),
    );

    _ok(await persistence.clearSession(session.projectId));
    expect(_ok(await persistence.loadSession(session.projectId)), isNull);
  });

  test('a record edit is stored beside the project new capture', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: TextStore.memory(),
    );
    const CaptureSession fresh = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
      captions: <String, String>{'': 'New capture'},
    );
    const CaptureSession edit = CaptureSession(
      id: 'record-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
      recordId: 'record-1',
      editing: true,
      captions: <String, String>{'': 'Edited'},
    );

    _ok(await persistence.saveSession(fresh));
    _ok(await persistence.saveSession(edit));
    expect(
      _ok(await persistence.loadSession('project-1'))?.recordCaption,
      'New capture',
    );
    expect(
      _ok(await persistence.loadSession('edit:record-1'))?.recordCaption,
      'Edited',
    );

    _ok(await persistence.clearSession('edit:record-1'));
    expect(_ok(await persistence.loadSession('edit:record-1')), isNull);
    expect(
      _ok(await persistence.loadSession('project-1'))?.recordCaption,
      'New capture',
    );
  });

  test('a session stored before keys is read under its project', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final TextStore store = TextStore.memory();
    const CaptureSession legacy = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
      captions: <String, String>{'': 'Kept'},
    );
    await store.write(jsonEncode(legacy.toJson()));
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );

    expect(
      _ok(await persistence.loadSession('project-1'))?.recordCaption,
      'Kept',
    );
    expect(_ok(await persistence.loadSession('project-2')), isNull);
  });
}

CaptureSession _ownedSession({
  String id = 'session-1',
  String project = 'project-1',
  String template = 'template-1',
  int? version = 7,
}) => CaptureSession(
  id: id,
  projectId: project,
  templateId: template,
  templateVersion: version,
  contextSnapshot: const <String, String>{'country': 'Uganda'},
  captions: const <String, String>{'': 'Original evidence'},
  values: const <String, Object?>{'inspection': 'Before'},
  valueSources: const <String, String>{'inspection': 'TYPED'},
  isDirty: true,
);

({String sessionId, String templateId, int? templateVersion}) _owner(
  CaptureSession session,
) => (
  sessionId: session.id,
  templateId: session.templateId,
  templateVersion: session.templateVersion,
);

final class _ControlledTextStore implements TextStore {
  String? _contents;
  int _writeCount = 0;
  bool _refusesNextWrite = false;
  Completer<void>? _started;
  Completer<void>? _release;

  int get writeCount => _writeCount;

  Future<void> get writeStarted => _started!.future;

  void holdNextWrite() {
    _started = Completer<void>();
    _release = Completer<void>();
  }

  void releaseWrite() => _release!.complete();

  void refuseNextWrite() => _refusesNextWrite = true;

  @override
  String? read() => _contents;

  @override
  Future<void> write(String contents) async {
    _writeCount++;
    if (_release case final Completer<void> release) {
      _started!.complete();
      await release.future;
      _started = null;
      _release = null;
    }
    if (_refusesNextWrite) {
      _refusesNextWrite = false;
      throw StateError('Session write refused');
    }
    _contents = contents;
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
