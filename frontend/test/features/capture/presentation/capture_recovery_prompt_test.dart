import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/context/context.dart'
    show contextRepositoryProvider;
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_capture_photo_repository.dart';
import '../../../support/fakes/fake_context_repository.dart';

void main() {
  testWidgets('the prompt names the interrupted photo count exactly', (
    WidgetTester tester,
  ) async {
    await _Recovery.open(tester);

    expect(find.text(Copy.captureRecoveryTitle), findsOneWidget);
    expect(find.text(Copy.captureRecoveryMessage(3)), findsOneWidget);
    expect(find.text(Copy.captureResume), findsOneWidget);
    expect(find.text(Copy.captureDiscard), findsOneWidget);
    expect(find.text(Copy.cancel), findsNothing);
  });

  testWidgets('a stray tap or Back never closes the prompt, and the '
      'interrupted session keeps its photos meanwhile', (
    WidgetTester tester,
  ) async {
    final _Recovery recovery = await _Recovery.open(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AppDialog), findsOneWidget);
    // Nothing on the page wrote over the stored copy while it waited.
    final CaptureSession? stored = await recovery.stored();
    expect(stored?.photos, hasLength(3));
    expect(stored?.recordCaption, 'Record note');
    expect(stored?.templateId, isEmpty);
  });

  testWidgets('resume restores the photos, the record and photo captions and '
      'the typed values', (WidgetTester tester) async {
    final _Recovery recovery = await _Recovery.open(tester);

    await tester.tap(find.text(Copy.captureResume));
    await tester.pumpAndSettle();

    final CaptureSession session = recovery.session;
    expect(session.photos.map((PhotoDraft photo) => photo.id), <String>[
      'a',
      'b',
      'c',
    ]);
    expect(session.recordCaption, 'Record note');
    expect(session.captions['a'], 'Photo note');
    expect(session.values['serial'], 'SN-7');
    expect(session.audio.single.id, 'clip-1');
    expect(_textOf(tester, _captionInput), 'Record note');
    final AppPage page = tester.widget<AppPage>(find.byType(AppPage));
    page.overflow
        .singleWhere(
          (AppOverflowAction action) =>
              action.key == const ValueKey<String>('capture-manual-form'),
        )
        .onTap();
    await tester.pumpAndSettle();
    expect(_textOf(tester, _serialInput), 'SN-7');
  });

  testWidgets("resume shows each photo's cached thumbnail", (
    WidgetTester tester,
  ) async {
    final _Recovery recovery = await _Recovery.open(tester);

    await tester.tap(find.text(Copy.captureResume));
    await tester.pumpAndSettle();

    for (final String id in <String>['a', 'b', 'c']) {
      final AppPhotoThumb thumb = tester.widget<AppPhotoThumb>(
        find.byKey(ValueKey<String>('photo-thumb-$id')),
      );
      expect(thumb.photo.thumbPath, recovery.photos.thumbPathFor(id));
    }
  });

  testWidgets('discard asks nothing more, tombstones the photos, keeps their '
      'files and offers undo', (WidgetTester tester) async {
    final _Recovery recovery = await _Recovery.open(tester);

    await tester.tap(find.text(Copy.captureDiscard));
    await tester.pumpAndSettle();

    // One dialog, no second confirmation.
    expect(find.byType(AppDialog), findsNothing);
    expect(recovery.photos.tombstoned, <String>{'a', 'b', 'c'});
    expect(recovery.photos.bytes.keys, containsAll(<String>['a', 'b', 'c']));
    expect(recovery.session.photos, isEmpty);
    final CaptureSession? stored = await recovery.stored();
    expect(stored?.photos, isEmpty);
    expect(find.text(Copy.captureSessionDiscarded), findsOneWidget);

    await tester.tap(find.text(Copy.undo));
    await tester.pumpAndSettle();

    expect(recovery.photos.tombstoned, isEmpty);
    expect(recovery.session.photos, hasLength(3));
    expect(recovery.session.recordCaption, 'Record note');
    expect((await recovery.stored())?.photos, hasLength(3));
  });

  testWidgets('resume while template and context writes are slow keeps every '
      'photo, caption and audio clip, in the tray and in the stored session', (
    WidgetTester tester,
  ) async {
    final FakeContextRepository contexts = FakeContextRepository();
    addTearDown(contexts.dispose);
    await contexts.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
    ]);
    await contexts.setLevelValue(
      projectId: 'p1',
      fieldKey: 'site',
      value: 'Yard',
    );
    final _Recovery recovery = await _Recovery.open(
      tester,
      saveDelay: const Duration(milliseconds: 300),
      overrides: <Override>[
        contextRepositoryProvider.overrideWith((Ref _) => contexts),
      ],
    );

    await tester.tap(find.text(Copy.captureResume));
    // Resume lands while the template and context writes that follow it
    // are still slow.
    // Every slow write, and any retry onto a newer session, lands in turn.
    for (int step = 0; step < 12; step++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    final CaptureSession session = recovery.session;
    expect(session.photos, hasLength(3));
    expect(session.captions['a'], 'Photo note');
    expect(session.audio, hasLength(1));
    expect(session.templateId, 't1');
    expect(session.contextSnapshot['site'], 'Yard');
    for (final String id in <String>['a', 'b', 'c']) {
      expect(find.byKey(ValueKey<String>('photo-thumb-$id')), findsOneWidget);
    }
    final CaptureSession? stored = await recovery.stored();
    expect(stored?.photos, hasLength(3));
    expect(stored?.recordCaption, 'Record note');
    expect(stored?.audio, hasLength(1));
    expect(stored?.templateId, 't1');
    expect(stored?.contextSnapshot['site'], 'Yard');
    // Leaving the page saves once more; let that slow save land.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}

String _textOf(WidgetTester tester, Finder field) {
  return tester.widget<TextField>(field).controller?.text ?? '';
}

final Finder _captionInput = find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextField &&
      widget.decoration?.labelText == Copy.captureRecordCaption,
);

final Finder _serialInput = find.descendant(
  of: find.byKey(const ValueKey<String>('field-editor-text-serial')),
  matching: find.byType(TextField),
);

/// A capture page opened over an interrupted session of three photos.
final class _Recovery {
  _Recovery._(this._tester, this.photos);

  final WidgetTester _tester;

  /// Photo rows, bytes, tombstones and thumbnails.
  final FakeCapturePhotoRepository photos;

  static Future<_Recovery> open(
    WidgetTester tester, {
    Duration saveDelay = Duration.zero,
    List<Override> overrides = const <Override>[],
  }) async {
    final Directory thumbs = Directory.systemTemp.createTempSync(
      'tapture-recovery-thumbs-',
    );
    addTearDown(() => thumbs.deleteSync(recursive: true));
    final FakeCapturePhotoRepository photos = FakeCapturePhotoRepository(
      thumbs: thumbs,
    );
    final CapturePersistence stored = CapturePersistenceImpl(
      photos: photos,
      store: TextStore.memory(),
    );
    for (final PhotoDraft photo in _interrupted.photos) {
      await stored.savePhoto(photo, bytes: Uint8List.fromList(<int>[1, 2]));
    }
    await stored.saveSession(_interrupted);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          fieldEditorBindingsProvider.overrideWithValue(
            templateFieldEditorBindings,
          ),
          captureProjectTemplatesProvider.overrideWith(
            (Ref _, String _) => Stream<List<TemplateDef>>.value(<TemplateDef>[
              aTemplate(
                id: 't1',
                projectId: 'p1',
                fields: const <FieldDef>[
                  FieldDef(
                    fieldKey: 'serial',
                    label: 'Serial',
                    type: FieldType.text,
                    requiredness: Requiredness.required,
                  ),
                ],
              ),
            ]),
          ),
          currentProjectDetailsProvider.overrideWith(
            (Ref _) => aProject(id: 'p1'),
          ),
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref _) => _Slow(stored, saveDelay),
          ),
          ...overrides,
        ],
        child: const MaterialApp(
          home: Scaffold(body: CaptureScreen(projectId: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _Recovery._(tester, photos);
  }

  ProviderContainer get _container =>
      ProviderScope.containerOf(_tester.element(find.byType(CaptureScreen)));

  /// The live session.
  CaptureSession get session =>
      _container.read(captureControllerProvider('p1'));

  /// The session as stored now.
  Future<CaptureSession?> stored() async {
    final Result<CaptureSession?> loaded = await _container
        .read(capturePersistenceProvider)
        .loadSession('p1');
    return loaded.getOrElse(() => null);
  }
}

/// What was being captured when the app stopped.
final CaptureSession _interrupted = CaptureSession(
  id: 'interrupted',
  projectId: 'p1',
  templateId: '',
  contextSnapshot: const <String, String>{},
  photos: <PhotoDraft>[
    for (int index = 0; index < 3; index++)
      PhotoDraft(
        id: <String>['a', 'b', 'c'][index],
        projectId: 'p1',
        relativePath: 'photos/_unfiled/${<String>['a', 'b', 'c'][index]}.jpg',
        sha256: 'sha-$index',
        sortOrder: index,
      ),
  ],
  audio: <AudioDraft>[
    AudioDraft(
      id: 'clip-1',
      projectId: 'p1',
      relativePath: 'audio/clip-1.wav',
      mimeType: 'audio/wav',
      fileSize: 44,
      sha256: 'clip-sha',
      durationMs: 1000,
      photoIds: <String>['a'],
    ),
  ],
  captions: const <String, String>{'': 'Record note', 'a': 'Photo note'},
  values: const <String, Object?>{'serial': 'SN-7'},
  isDirty: true,
);

/// Session saves that finish [_delay] later, as a slow database write does.
final class _Slow implements CapturePersistence {
  _Slow(this._inner, this._delay);

  final CapturePersistence _inner;
  final Duration _delay;

  @override
  PhotoRepository get photos => _inner.photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo, {Uint8List? bytes}) =>
      _inner.savePhoto(photo, bytes: bytes);

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) =>
      _inner.deletePhoto(photoId, reason: reason);

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    if (_delay > Duration.zero) {
      await Future<void>.delayed(_delay);
    }
    return _inner.saveSession(session);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) =>
      _inner.loadSession(key);

  @override
  Future<Result<void>> clearSession(String key) => _inner.clearSession(key);
}
