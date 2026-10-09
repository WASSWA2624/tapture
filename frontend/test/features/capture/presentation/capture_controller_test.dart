import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/data/capture_device_sources.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/data/drift_capture_persistence.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_device_source.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/domain/owned_capture_persistence.dart';
import 'package:tapture/features/capture/domain/pending_audio_draft.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_device_providers.dart';
import 'package:tapture/features/capture/presentation/capture_template_providers.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/projects/presentation/project_template_selection.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_capture_record_persistence.dart';
import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  for (final (int header, bool hasContent, int reads) scenario
      in <(int, bool, int)>[(2, true, 0), (2, false, 1), (1, true, 1)]) {
    test(
      'null-version recovery header${scenario.$1} content${scenario.$2} follows first-save source eligibility',
      () async {
        final CaptureSession recovered = CaptureSession(
          id: 'legacy-owner',
          projectId: 'p1',
          templateId: 'address',
          contextSnapshot: const <String, String>{},
          values: scenario.$2
              ? const <String, Object?>{'business': 'Retained original'}
              : const <String, Object?>{},
          valueSources: scenario.$2
              ? const <String, String>{'business': 'TYPED'}
              : const <String, String>{},
        );
        final _DeviceCaptureRig rig = await _DeviceCaptureRig.open(
          headerVersion: scenario.$1,
          initial: recovered,
        );
        addTearDown(rig.dispose);
        expect(rig.controller.state.templateVersion, isNull);
        expect(rig.reads.length, scenario.$3);
        expect(
          (await rig.persistence.loadSession('p1')).getOrThrow()?.toJson(),
          recovered.toJson(),
        );
        if (scenario.$3 == 0) {
          await rig.lifecycle.handle(AppLifecycleState.resumed);
          await rig.container.pump();
          expect(
            rig.reads,
            isEmpty,
            reason: 'Resume cannot opt into an unknown captured shape.',
          );
          expect(rig.source.snapshot(recovered), isNull);
        } else {
          await rig.complete(0, '10.0.0.2');
          expect(rig.source.snapshot(recovered), '10.0.0.2');
          expect(rig.reads.length, 1);
        }
      },
    );
  }

  test(
    'same-owner recovery refreshes only after durability and rejects a late previous read',
    () async {
      final _DeviceCaptureRig rig = await _DeviceCaptureRig.open();
      addTearDown(rig.dispose);
      final CaptureSession initial = rig.controller.state;
      expect(rig.reads.length, 1);
      rig.persistence.fail = true;
      expect(
        await rig.controller.replaceSession(
          initial.copyWith(
            values: const <String, Object?>{'business': 'Failed'},
          ),
        ),
        isA<FailureResult<void>>(),
      );
      expect(rig.reads.length, 1);
      expect(rig.controller.state.toJson(), initial.toJson());
      await rig.complete(0, '10.0.0.1');
      expect(rig.source.snapshot(initial), '10.0.0.1');
      expect(
        (await rig.persistence.loadSession('p1')).getOrThrow()?.toJson(),
        initial.toJson(),
      );
      rig.persistence.fail = false;
      final CaptureSession recovered = initial.copyWith(
        values: const <String, Object?>{'business': 'Recovered'},
      );
      _ok(await rig.controller.replaceSession(recovered));
      expect(rig.reads.length, 2);
      expect(
        rig.reads[1].isCompleted,
        isFalse,
        reason: 'Recovery commits without waiting for enumeration.',
      );
      expect(rig.source.snapshot(recovered), isNull);
      expect(
        (await rig.persistence.loadSession('p1')).getOrThrow()?.toJson(),
        recovered.toJson(),
      );
      _ok(await rig.controller.replaceSession(recovered));
      expect(
        rig.reads.length,
        3,
        reason: 'Each same-owner recovery starts exactly one new reading.',
      );
      rig.reads[1].complete(
        const PlatformFacts.fake(addresses: <String>['10.0.0.2']),
      );
      await rig.reads[1].future;
      expect(rig.source.snapshot(recovered), isNull);
      await rig.complete(2, '10.0.0.3');
      expect(rig.source.snapshot(recovered), '10.0.0.3');
      expect(rig.controller.state.toJson(), recovered.toJson());
    },
  );

  test(
    'lifecycle resume refreshes the eligible owner once and leaves excluded owners unread',
    () async {
      final _DeviceCaptureRig rig = await _DeviceCaptureRig.open();
      addTearDown(rig.dispose);
      final CaptureSession initial = rig.controller.state;
      final Map<String, Object?> durable = initial.toJson();
      await rig.lifecycle.handle(AppLifecycleState.inactive);
      await rig.lifecycle.handle(AppLifecycleState.paused);
      expect(rig.reads.length, 1);
      await rig.lifecycle.handle(AppLifecycleState.resumed);
      await rig.container.pump();
      expect(rig.reads.length, 2);
      expect(rig.reads[1].isCompleted, isFalse);
      expect(rig.source.snapshot(initial), isNull);
      expect(
        (await rig.persistence.loadSession('p1')).getOrThrow()?.toJson(),
        durable,
        reason: 'A source refresh has no session write.',
      );
      rig.reads[0].complete(
        const PlatformFacts.fake(addresses: <String>['10.0.0.1']),
      );
      await rig.reads[0].future;
      expect(rig.source.snapshot(initial), isNull);
      await rig.complete(1, '10.0.0.2');
      expect(rig.source.snapshot(initial), '10.0.0.2');
      for (final (String templateId, int version) target in <(String, int)>[
        ('no-source', 1),
        ('malformed-source', 1),
        ('address', 0),
        ('missing', 1),
      ]) {
        _ok(await rig.controller.setTemplate(target.$1, version: target.$2));
        await rig.lifecycle.handle(AppLifecycleState.resumed);
        await rig.container.pump();
        expect(rig.reads.length, 2, reason: target.toString());
        expect(rig.source.snapshot(rig.controller.state), isNull);
      }
      _ok(
        await rig.controller.replaceSession(
          initial.copyWith(recordId: 'committed'),
        ),
      );
      await rig.lifecycle.handle(AppLifecycleState.resumed);
      await rig.container.pump();
      expect(rig.reads.length, 2);
      expect(rig.source.snapshot(rig.controller.state), isNull);
      _ok(
        await rig.controller.replaceSession(
          initial.copyWith(recordId: 'committed', editing: true),
        ),
      );
      await rig.lifecycle.handle(AppLifecycleState.resumed);
      await rig.container.pump();
      expect(rig.reads.length, 2);
      rig.disposeContainer();
      await rig.lifecycle.handle(AppLifecycleState.resumed);
      expect(
        rig.reads.length,
        2,
        reason: 'Disposal cancels the owned lifecycle subscription.',
      );
    },
  );

  test(
    'lifecycle and same-owner recovery preserve the default unavailable device port',
    () async {
      final _DeviceCaptureRig rig = await _DeviceCaptureRig.open(native: false);
      addTearDown(rig.dispose);
      final CaptureSession initial = rig.controller.state;
      _ok(await rig.controller.replaceSession(initial));
      await rig.lifecycle.handle(AppLifecycleState.resumed);
      await rig.container.pump();
      expect(rig.reads, isEmpty);
      expect(rig.source.snapshot(initial), isNull);
      expect(
        (await rig.persistence.loadSession('p1')).getOrThrow()?.toJson(),
        initial.toJson(),
      );
    },
  );

  test(
    'device reads follow loaded pinned shape and invalidate late reset and history-zero results',
    () async {
      final StreamController<List<TemplateDef>> templates =
          StreamController<List<TemplateDef>>();
      final List<Completer<PlatformFacts>> reads = <Completer<PlatformFacts>>[];
      final FakePhotoRepository photos = FakePhotoRepository();
      CaptureDeviceSources? source;
      final ProviderContainer scoped = ProviderContainer(
        overrides: <Override>[
          photoRepositoryProvider.overrideWithValue(photos),
          capturePersistenceProvider.overrideWith(
            (Ref _) => CapturePersistenceImpl(
              photos: photos,
              store: TextStore.memory(),
            ),
          ),
          captureProjectTemplatesProvider.overrideWith(
            (Ref _, String key) => templates.stream,
          ),
          captureDeviceSourceProvider.overrideWith((Ref ref, String key) {
            source = CaptureDeviceSources(
              clock: FixedClock(DateTime.utc(2026, 10, 9)),
              readFacts: () {
                final Completer<PlatformFacts> pending =
                    Completer<PlatformFacts>();
                reads.add(pending);
                return pending.future;
              },
            );
            ref.onDispose(source!.dispose);
            return source!;
          }),
        ],
      );
      addTearDown(() async {
        scoped.dispose();
        photos.dispose();
        await templates.close();
      });
      // Match Capture's Consumer lifetime: Riverpod pauses dependency streams
      // for a controller that is only read imperatively and has no listener.
      final ProviderSubscription<CaptureSession> capture = scoped.listen(
        captureControllerProvider('p1'),
        (_, _) {},
      );
      addTearDown(capture.close);
      final CaptureController controller = scoped.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.setTemplate('t1', version: 1));
      expect(reads, isEmpty, reason: 'Loading is not an opted-in shape.');
      final TemplateDef old = aTemplate(
        id: 't1',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'business',
            label: 'Business',
            type: FieldType.text,
          ),
        ],
      );
      final TemplateDef current = TemplateVersioning.remember(
        from: old,
        to: old.copyWith(
          version: 2,
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'network_address',
              label: 'Local address',
              type: FieldType.text,
              autoFill: AutoFill.localAddress,
            ),
          ],
        ),
      );
      templates.add(<TemplateDef>[current]);
      expect(
        await scoped.read(captureProjectTemplatesProvider('p1').future),
        <TemplateDef>[current],
      );
      await scoped.pump();
      expect(
        reads,
        isEmpty,
        reason:
            'The current header cannot override a pinned source-less shape.',
      );
      _ok(await controller.setTemplate('t1', version: 2));
      expect(reads.length, 1);
      final CaptureSession previous = controller.state;
      _ok(await controller.discardSession());
      expect(controller.state.id, isNot(previous.id));
      expect(reads.length, 2);
      reads.first.complete(
        const PlatformFacts.fake(addresses: <String>['10.0.0.1']),
      );
      await reads.first.future;
      expect(source!.snapshot(previous), isNull);
      expect(source!.snapshot(controller.state), isNull);
      final Future<void> completed = source!.changes.firstWhere(
        (_) => source!.snapshot(controller.state) != null,
      );
      reads[1].complete(
        const PlatformFacts.fake(addresses: <String>['10.0.0.2']),
      );
      await completed;
      expect(source!.snapshot(controller.state), '10.0.0.2');
      _ok(await controller.setTemplate('t1', version: 0));
      expect(reads.length, 2);
      expect(source!.snapshot(controller.state), isNull);
      _ok(await controller.setTemplate('missing', version: 1));
      expect(reads.length, 2);
      _ok(await controller.setTemplate('t1', version: 1));
      expect(reads.length, 2);
      _ok(await controller.setTemplate('t1', version: 2));
      expect(reads.length, 3);
      final CaptureSession resumed = controller.state.copyWith(id: 'resumed');
      _ok(await controller.replaceSession(resumed));
      expect(reads.length, 4);
      reads[2].complete(
        const PlatformFacts.fake(addresses: <String>['10.0.0.3']),
      );
      await reads[2].future;
      expect(source!.snapshot(resumed), isNull);
      final Future<void> refreshed = source!.changes.firstWhere(
        (_) => source!.snapshot(resumed) != null,
      );
      reads[3].complete(
        const PlatformFacts.fake(addresses: <String>['10.0.0.4']),
      );
      await refreshed;
      expect(source!.snapshot(resumed), '10.0.0.4');
    },
  );

  late FakePhotoRepository photos;
  late ProviderContainer container;

  setUp(() {
    photos = FakePhotoRepository();
    container = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWith((Ref _) => photos),
        capturePersistenceProvider.overrideWith(
          (Ref ref) =>
              CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
        ),
      ],
    );
  });

  tearDown(() {
    photos.dispose();
    container.dispose();
  });

  test(
    'default owned persistence refuses inconsistent edit projects',
    () async {
      for (final (String storedProject, String candidateProject) projects
          in const <(String, String)>[('', 'p1'), ('p2', 'p1'), ('', '')]) {
        final ProviderContainer scoped = ProviderContainer(
          overrides: <Override>[
            photoRepositoryProvider.overrideWith((Ref _) => photos),
          ],
        );
        try {
          final OwnedCapturePersistence persistence =
              scoped.read(capturePersistenceProvider)
                  as OwnedCapturePersistence;
          final CaptureSession stored = CaptureSession(
            id: 'session-1',
            projectId: projects.$1,
            recordId: 'record-1',
            editing: true,
            templateId: 'template-1',
            templateVersion: 7,
            contextSnapshot: const <String, String>{},
            values: const <String, Object?>{'serial': 'CURRENT'},
          );
          (await persistence.saveSession(stored)).getOrThrow();
          expect(
            await persistence.saveOwnedSession(
              stored.copyWith(
                projectId: projects.$2,
                values: const <String, Object?>{'serial': 'OLD'},
              ),
              owner: (
                sessionId: stored.id,
                templateId: stored.templateId,
                templateVersion: stored.templateVersion,
              ),
            ),
            isA<FailureResult<void>>(),
          );
          expect(
            (await persistence.loadSession(
              stored.storageKey,
            )).getOrThrow()?.toJson(),
            stored.toJson(),
          );
        } finally {
          scoped.dispose();
        }
      }
    },
  );

  test('addPhoto persists before next state', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    final Result<void> result = await controller.addPhoto(
      const PhotoDraft(
        id: 'ph1',
        projectId: 'p1',
        relativePath: 'photos/a.jpg',
        sha256: 'hash1',
      ),
    );
    expect(result, isA<Success<void>>());
    expect(controller.state.photos, hasLength(1));
    final loaded = await photos.byId('ph1');
    expect(loaded.getOrElse(() => null)?.sha256, 'hash1');
  });

  test('failed write leaves emitted state unchanged', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    final CaptureSession before = controller.state;
    final Result<void> result = await controller.addPhoto(
      const PhotoDraft(id: 'bad', projectId: '', relativePath: '', sha256: 'x'),
    );
    expect(result, isA<FailureResult<void>>());
    expect(controller.state.photos, before.photos);
  });

  test(
    'undo restores the photo in its original position with its caption',
    () async {
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      for (int index = 0; index < 3; index++) {
        await controller.addPhoto(
          PhotoDraft(
            id: 'photo-$index',
            projectId: 'p1',
            relativePath: 'photos/$index.jpg',
            sha256: 'hash-$index',
            sortOrder: index,
            photoType: 'nameplate',
          ),
        );
      }
      await controller.setCaption('photo-1', 'The original label');
      final Result<PhotoDraft?> removed = await controller.removePhoto(
        'photo-1',
      );
      expect(
        controller.state.photos.map((PhotoDraft photo) => photo.id),
        <String>['photo-0', 'photo-2'],
      );
      expect(
        await controller.undoRemove((removed as Success<PhotoDraft?>).value!),
        isA<Success<void>>(),
      );
      expect(
        controller.state.photos.map((PhotoDraft photo) => photo.id),
        <String>['photo-0', 'photo-1', 'photo-2'],
      );
      expect(controller.state.captions['photo-1'], 'The original label');
      expect(controller.state.photos[1].photoType, 'nameplate');
    },
  );

  test('incomplete reorder cannot drop photos', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    await controller.addPhoto(
      const PhotoDraft(
        id: 'photo',
        projectId: 'p1',
        relativePath: 'photos/photo.jpg',
        sha256: 'hash',
      ),
    );
    expect(
      await controller.reorderPhotos(const <String>[]),
      isA<FailureResult<void>>(),
    );
    expect(controller.state.photos.single.id, 'photo');
  });

  test('discard failure retains the interrupted recovery session', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    final CaptureSession interrupted = controller.state.copyWith(
      photos: const <PhotoDraft>[
        PhotoDraft(
          id: 'missing-row',
          projectId: 'p1',
          relativePath: 'photos/photo.jpg',
          sha256: 'hash',
        ),
      ],
      captions: const <String, String>{'': 'Preserved draft'},
    );
    await controller.replaceSession(interrupted);
    expect(await controller.discardSession(), isA<FailureResult<void>>());
    expect(controller.state, same(interrupted));
    final CaptureSession? recovery =
        (await container.read(capturePersistenceProvider).loadSession('p1')
                as Success<CaptureSession?>)
            .value;
    expect(recovery?.recordCaption, 'Preserved draft');
  });

  test(
    'enqueue retry reuses the committed record without another raw write',
    () async {
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      await controller.addPhoto(
        const PhotoDraft(
          id: 'ph1',
          projectId: 'p1',
          relativePath: 'photos/a.jpg',
          sha256: 'hash1',
        ),
      );
      var persistCalls = 0;
      var enqueueCalls = 0;

      Future<Result<String>> persist(CaptureSession _) async {
        persistCalls += 1;
        return const Success<String>('record-1');
      }

      Future<Result<ProcessingJob>> enqueue(String recordId) async {
        enqueueCalls += 1;
        if (enqueueCalls == 1) {
          return const FailureResult<ProcessingJob>(
            NetworkFailure(message: 'Offline.', recoveryAction: 'Retry.'),
          );
        }
        return Success<ProcessingJob>(
          ProcessingJob(id: 'job-1', recordId: recordId),
        );
      }

      final first = await controller.saveAndAnalyse(
        persist: persist,
        enqueue: enqueue,
      );
      expect(
        (first as Success<SaveAndAnalyseResult>).value.enqueueFailed,
        isTrue,
      );
      expect(controller.state.recordId, 'record-1');
      expect(controller.state.photos, hasLength(1));

      final second = await controller.saveAndAnalyse(
        persist: persist,
        enqueue: enqueue,
      );
      expect(
        (second as Success<SaveAndAnalyseResult>).value.enqueueFailed,
        isFalse,
      );
      expect(persistCalls, 1);
      expect(enqueueCalls, 2);
      expect(controller.state.photos, isEmpty);
      expect(controller.state.recordId, isNull);
    },
  );

  group('each mutation is stored before it is shown', () {
    Future<void> expectStored(CaptureController controller) async {
      final CaptureSession? stored = _ok(
        await container.read(capturePersistenceProvider).loadSession('p1'),
      );
      expect(stored?.toJson(), controller.state.toJson());
    }

    CaptureController open() {
      return container.read(captureControllerProvider('p1').notifier);
    }

    test('setValue', () async {
      final CaptureController controller = open();
      _ok(await controller.setValue('serial', 'SN-1'));
      expect(controller.state.values['serial'], 'SN-1');
      await expectStored(controller);
    });

    test('applyLookup', () async {
      final CaptureController controller = open();
      _ok(
        await controller.applyLookup(const <String, String>{
          'site': 'Yard',
        }, 'row-1'),
      );
      expect(controller.state.values['site'], 'Yard');
      expect(controller.state.lookupRows['site'], 'row-1');
      await expectStored(controller);
    });

    test('applyCaptions', () async {
      final CaptureController controller = open();
      _ok(await controller.addPhoto(_photo('ph1')));
      _ok(
        await controller.applyCaptions(const <CaptionWrite>[
          CaptionWrite(photoId: 'ph1', text: 'Rating plate'),
        ]),
      );
      expect(controller.state.captions['ph1'], 'Rating plate');
      await expectStored(controller);
    });

    test('setTemplate', () async {
      final CaptureController controller = open();
      _ok(await controller.setTemplate('t1'));
      expect(controller.state.templateId, 't1');
      await expectStored(controller);
    });

    test('setContext', () async {
      final CaptureController controller = open();
      _ok(await controller.setContext(const <String, String>{'site': 'A'}));
      expect(controller.state.contextSnapshot, <String, String>{'site': 'A'});
      await expectStored(controller);
    });

    test('setLocation', () async {
      final CaptureController controller = open();
      _ok(await controller.setLocation(_fix, sessionId: controller.state.id));
      expect(controller.state.location?.latitude, _fix.latitude);
      await expectStored(controller);
    });

    test('addAudio', () async {
      final CaptureController controller = open();
      _ok(await controller.addAudio(_clip));
      expect(controller.state.audio.single.id, 'clip-1');
      await expectStored(controller);
    });

    test('a complete reorder', () async {
      final CaptureController controller = open();
      _ok(await controller.addPhoto(_photo('ph1')));
      _ok(await controller.addPhoto(_photo('ph2', sortOrder: 1)));
      _ok(await controller.reorderPhotos(const <String>['ph2', 'ph1']));
      expect(
        controller.state.photos.map((PhotoDraft photo) => photo.id),
        <String>['ph2', 'ph1'],
      );
      await expectStored(controller);
    });
  });

  for (final bool reset in <bool>[true, false]) {
    test(
      'owned field write finishing after ${reset ? 'reset' : 'template change'} preserves the current durable owner',
      () async {
        final _DelayedFieldWrite persistence = _DelayedFieldWrite();
        final ProviderContainer scoped = ProviderContainer(
          overrides: <Override>[
            capturePersistenceProvider.overrideWithValue(persistence),
          ],
        );
        addTearDown(scoped.dispose);
        final CaptureController controller = scoped.read(
          captureControllerProvider('p1').notifier,
        );
        _ok(await controller.setTemplate('t1', version: 1));
        final CaptureSession original = controller.state;
        final Future<Result<void>> stale = controller.setValue(
          'serial',
          'OLD',
          owner: (
            sessionId: original.id,
            templateId: original.templateId,
            templateVersion: original.templateVersion,
          ),
        );
        if (reset) {
          _ok(await controller.discardSession());
        } else {
          _ok(await controller.setTemplate('t2', version: 2));
        }
        final CaptureSession current = controller.state;
        persistence.release.complete();
        expect(await stale, isA<FailureResult<void>>());
        expect(controller.state.toJson(), current.toJson());
        expect(persistence.stored?.toJson(), current.toJson());
        expect(controller.state.values.containsKey('serial'), isFalse);
      },
    );
  }

  test('an already stale origin never starts a field write', () async {
    final _DelayedFieldWrite persistence = _DelayedFieldWrite();
    final ProviderContainer scoped = ProviderContainer(
      overrides: <Override>[
        capturePersistenceProvider.overrideWithValue(persistence),
      ],
    );
    addTearDown(scoped.dispose);
    final CaptureController controller = scoped.read(
      captureControllerProvider('p1').notifier,
    );
    final CaptureSession original = controller.state;
    _ok(await controller.setTemplate('t2', version: 2));
    final int before = persistence.writes;
    expect(
      await controller.setValue(
        'serial',
        'OLD',
        owner: (
          sessionId: original.id,
          templateId: original.templateId,
          templateVersion: original.templateVersion,
        ),
      ),
      isA<FailureResult<void>>(),
    );
    expect(persistence.writes, before);
    expect(controller.state.values, isEmpty);
  });

  test(
    'failed late owned write preserves the confirmed durable reset without repair',
    () async {
      final _DelayedFieldWrite persistence = _DelayedFieldWrite();
      final ProviderContainer scoped = ProviderContainer(
        overrides: <Override>[
          capturePersistenceProvider.overrideWithValue(persistence),
        ],
      );
      addTearDown(scoped.dispose);
      final CaptureController controller = scoped.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.setTemplate('t1', version: 1));
      final CaptureSession original = controller.state;
      final Future<Result<void>> stale = controller.setValue(
        'serial',
        'OLD',
        owner: (
          sessionId: original.id,
          templateId: original.templateId,
          templateVersion: original.templateVersion,
        ),
      );
      _ok(await controller.discardSession());
      final CaptureSession current = controller.state;
      persistence.failOwned = true;
      persistence.release.complete();
      final FailureResult<void> failed = await stale as FailureResult<void>;
      expect(failed.failure.message, 'Owned write refused');
      expect(controller.state.toJson(), current.toJson());
      expect(persistence.stored?.toJson(), current.toJson());
      expect(controller.state.values.containsKey('serial'), isFalse);
    },
  );

  test(
    'owned writes fail closed on a legacy persistence while omitted origins still work',
    () async {
      final CapturePersistence persistence = _FailingSaves(
        CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
      );
      final ProviderContainer scoped = ProviderContainer(
        overrides: <Override>[
          capturePersistenceProvider.overrideWithValue(persistence),
        ],
      );
      addTearDown(scoped.dispose);
      final CaptureController controller = scoped.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.setTemplate('t1', version: 1));
      final CaptureSession original = controller.state;
      expect(
        await controller.setValue(
          'serial',
          'REFUSED',
          owner: (
            sessionId: original.id,
            templateId: original.templateId,
            templateVersion: original.templateVersion,
          ),
        ),
        isA<FailureResult<void>>(),
      );
      expect(controller.state.toJson(), original.toJson());
      expect(
        _ok(await persistence.loadSession('p1'))?.toJson(),
        original.toJson(),
      );
      _ok(await controller.setValue('serial', 'Legacy caller'));
      expect(controller.state.values['serial'], 'Legacy caller');
      expect(
        _ok(await persistence.loadSession('p1'))?.values['serial'],
        'Legacy caller',
      );
    },
  );

  group('an interrupted session', () {
    CapturePersistence store() => container.read(capturePersistenceProvider);

    test('with work in it is offered back and nothing overwrites it', () async {
      final CaptureSession work = CaptureSession(
        id: 'interrupted',
        projectId: 'p1',
        templateId: 't1',
        contextSnapshot: const <String, String>{},
        photos: <PhotoDraft>[_photo('ph1')],
        captions: const <String, String>{'': 'Pump room'},
      );
      _ok(await store().saveSession(work));
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );

      final CaptureSession? offered = await controller.interrupted();

      expect(offered?.toJson(), work.toJson());
      expect(controller.state.photos, isEmpty);
      expect(_ok(await store().loadSession('p1'))?.toJson(), work.toJson());
    });

    test('with nothing in it is not offered but hands on its pinned '
        'template', () async {
      _ok(
        await store().saveSession(
          const CaptureSession(
            id: 'after-save',
            projectId: 'p1',
            templateId: 't2',
            contextSnapshot: <String, String>{},
          ),
        ),
      );
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );

      expect(await controller.interrupted(), isNull);
      expect(controller.state.templateId, 't2');
    });

    test('an edit is offered only while it holds a change', () async {
      final CaptureController controller = container.read(
        captureControllerProvider(CaptureSessionKey.edit('r1')).notifier,
      );
      const CaptureSession untouched = CaptureSession(
        id: 'r1',
        projectId: 'p1',
        templateId: 't1',
        contextSnapshot: <String, String>{},
        recordId: 'r1',
        editing: true,
      );
      _ok(await store().saveSession(untouched));
      expect(await controller.interrupted(), isNull);

      _ok(await store().saveSession(untouched.copyWith(isDirty: true)));
      expect((await controller.interrupted())?.recordId, 'r1');
    });

    test(
      'checkpoint stores a session with work and skips an empty one',
      () async {
        final CaptureController controller = container.read(
          captureControllerProvider('p1').notifier,
        );
        _ok(await controller.checkpoint());
        expect(_ok(await store().loadSession('p1')), isNull);

        _ok(await controller.addPhoto(_photo('ph1')));
        _ok(await store().clearSession('p1'));
        _ok(await controller.checkpoint());
        expect(_ok(await store().loadSession('p1'))?.photos, hasLength(1));
      },
    );
  });

  test('caption, value, template and context writes that finish out of '
      'order all land, in memory and in the stored session', () async {
    final _OutOfOrder sessions = _OutOfOrder();
    final ProviderContainer racing = ProviderContainer(
      overrides: <Override>[
        capturePersistenceProvider.overrideWith((Ref _) => sessions),
      ],
    );
    addTearDown(racing.dispose);
    final CaptureController controller = racing.read(
      captureControllerProvider('p1').notifier,
    );

    final List<Future<Result<void>>> writes = <Future<Result<void>>>[
      controller.setCaption(null, 'Pump room'),
      controller.setValue('serial', 'SN-4'),
      controller.setTemplate('t1'),
      controller.setContext(const <String, String>{'site': 'Yard'}),
    ];
    // The last write started lands first, the first lands last.
    sessions.releaseInReverse();
    for (final Future<Result<void>> write in writes) {
      _ok(await write);
    }

    for (final CaptureSession session in <CaptureSession>[
      controller.state,
      sessions.stored!,
    ]) {
      expect(session.recordCaption, 'Pump room');
      expect(session.values['serial'], 'SN-4');
      expect(session.templateId, 't1');
      expect(session.contextSnapshot, <String, String>{'site': 'Yard'});
    }
    expect(sessions.stored!.toJson(), controller.state.toJson());
  });

  test(
    'saving keeps the context, the pinned template and the camera '
    'settings, starts afresh and leaves the saved record untouched',
    () async {
      final FakeCaptureRecordPersistence records =
          FakeCaptureRecordPersistence();
      final CameraService camera = CameraService.fake();
      await camera.setFlash(CameraFlashMode.on);
      final SettingsStore settings = SettingsStore.fake();
      _ok(await settings.write(SettingKeys.grid, true));
      final ProviderContainer saving = ProviderContainer(
        overrides: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref _) => CapturePersistenceImpl(
              photos: photos,
              store: TextStore.memory(),
            ),
          ),
          captureRecordWriterProvider.overrideWith((Ref _) => records),
          cameraServiceProvider.overrideWith((Ref _) => camera),
          offlineStoreProvider.overrideWith((Ref _) => settings),
        ],
      );
      addTearDown(saving.dispose);
      saving.read(projectTemplateSelectionProvider.notifier).select('t2');
      final CaptureController controller = saving.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.setContext(const <String, String>{'site': 'Yard'}));
      _ok(await controller.setTemplate('t2'));
      _ok(await controller.addPhoto(_photo('ph1')));
      _ok(await controller.setCaption(null, 'Pump room'));
      _ok(await controller.setCaption('ph1', 'Rating plate'));
      _ok(await controller.setValue('serial', 'SN-4'));
      final CaptureSession before = controller.state;

      _ok(await controller.saveRaw(records.persist));

      final CaptureSession next = controller.state;
      expect(next.id, isNot(before.id));
      expect(next.templateId, 't2');
      expect(next.contextSnapshot, <String, String>{'site': 'Yard'});
      expect(next.photos, isEmpty);
      expect(next.captions, isEmpty);
      expect(next.values, isEmpty);
      expect(saving.read(projectTemplateSelectionProvider), 't2');
      expect(saving.read(cameraServiceProvider).flashMode, CameraFlashMode.on);
      expect(saving.read(offlineStoreProvider).read(SettingKeys.grid), isTrue);
      // The pin is stored with the fresh session, so it outlives a restart.
      final CaptureSession? stored = _ok(
        await saving.read(capturePersistenceProvider).loadSession('p1'),
      );
      expect(stored?.templateId, 't2');
      expect(stored?.photos, isEmpty);
      // What was saved is exactly what was captured, reset or not.
      final CaptureSession saved = records.persisted.single;
      expect(saved.photos.single.id, 'ph1');
      expect(saved.recordCaption, 'Pump room');
      expect(saved.captions['ph1'], 'Rating plate');
      expect(saved.values['serial'], 'SN-4');
      expect(saved.templateId, 't2');
    },
  );

  test('addPhoto writes the bytes to disk and a photos row before the state '
      'shows it', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final Directory root = Directory.systemTemp.createTempSync(
      'tapture-capture-controller-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: root);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 29, 8));
    final Project project = await db.select(db.projects).getSingle();
    final DriftPhotoRepository drafts = DriftPhotoRepository(
      db: db,
      writer: FileWriter(storageRoot: storage),
      reader: FileReader(storageRoot: storage),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
      storageRoot: storage,
    );
    final List<String> events = <String>[];
    final ProviderContainer durable = ProviderContainer(
      overrides: <Override>[
        capturePersistenceProvider.overrideWith(
          (Ref _) => _Recording(
            DriftCapturePersistence(
              db: db,
              photos: drafts,
              clock: clock,
              deviceId: 'device-a',
              ids: UuidV7Service.sequence(clock),
            ),
            db,
            events,
          ),
        ),
      ],
    );
    addTearDown(durable.dispose);
    final Directory resolved = _ok(await storage.resolve());
    final File file = File(
      '${resolved.path}/projects/${project.folderName}/photos/_unfiled/ph1.jpg',
    );
    durable.listen<CaptureSession>(captureControllerProvider(project.id), (
      CaptureSession? _,
      CaptureSession next,
    ) {
      if (next.photos.isNotEmpty) {
        events.add('shown, file on disk: ${file.existsSync()}');
      }
    });

    final Result<void> added = await durable
        .read(captureControllerProvider(project.id).notifier)
        .addPhoto(
          PhotoDraft(
            id: 'ph1',
            projectId: project.id,
            captureSessionId: 's1',
            relativePath: 'photos/_unfiled/ph1.jpg',
            sha256: '',
          ),
          bytes: Uint8List.fromList(<int>[9, 8, 7]),
        );

    _ok(added);
    expect(events, <String>[
      'photo row written: true',
      'session stored',
      'shown, file on disk: true',
    ]);
    expect(file.readAsBytesSync(), <int>[9, 8, 7]);
  });

  test('a failed enqueue leaves a complete captured record, and the retry '
      'queues exactly one job', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 29, 8));
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final Project project = await db.select(db.projects).getSingle();
    final Template template = await db.select(db.templates).getSingle();
    final CaptureRecordWriter writer = CaptureRecordWriter(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    );
    final ProcessingRepositoryImpl processing = ProcessingRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      settings: SettingsStore.fake(),
    );
    final ProviderContainer offline = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWith((Ref _) => photos),
        capturePersistenceProvider.overrideWith(
          (Ref _) =>
              CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
        ),
      ],
    );
    addTearDown(offline.dispose);
    final CaptureController controller = offline.read(
      captureControllerProvider(project.id).notifier,
    );
    _ok(await controller.setTemplate(template.id));
    _ok(
      await controller.addPhoto(
        _photo('ph1', projectId: project.id).copyWith(
          captureSessionId: controller.state.id,
          originalFilename: 'ph1.jpg',
          storedFilename: 'ph1.jpg',
        ),
      ),
    );
    _ok(await controller.setCaption(null, 'Pump room'));
    _ok(await controller.setCaption('ph1', 'Rating plate'));
    _ok(await controller.setValue('serial', 'SN-4'));
    int enqueued = 0;

    Future<Result<ProcessingJob>> enqueue(String recordId) async {
      enqueued += 1;
      if (enqueued == 1) {
        return const FailureResult<ProcessingJob>(
          NetworkFailure(message: 'Offline.', recoveryAction: 'Retry.'),
        );
      }
      final Result<String> job = await processing.enqueue(recordId);
      return job.map(
        (String id) => SaveAndAnalyse.jobFor(jobId: id, recordId: recordId),
      );
    }

    final SaveAndAnalyseResult first = _ok(
      await controller.saveAndAnalyse(
        persist: writer.persist,
        enqueue: enqueue,
      ),
    );
    expect(first.enqueueFailed, isTrue);
    final RecordRow record = await db.select(db.records).getSingle();
    expect(record.id, first.recordId);
    expect(record.status, RecordStatus.captured.stored);
    final Photo photo = await db.select(db.photos).getSingle();
    expect(photo.recordId, record.id);
    expect(
      (await db.select(db.captions).get()).map((Caption row) => row.textRaw),
      unorderedEquals(<String>['Pump room', 'Rating plate']),
    );
    final RecordField serial = (await db.select(db.recordFields).get())
        .singleWhere((RecordField row) => row.fieldKey == 'serial');
    expect(serial.valueRaw, 'SN-4');
    expect(serial.source, 'TYPED');
    expect(await db.select(db.processing).get(), isEmpty);

    final SaveAndAnalyseResult retried = _ok(
      await controller.saveAndAnalyse(
        persist: writer.persist,
        enqueue: enqueue,
      ),
    );
    expect(retried.enqueueFailed, isFalse);
    expect(retried.recordId, record.id);
    expect(await db.select(db.records).get(), hasLength(1));
    final List<ProcessingJobRow> jobs = await db.select(db.processing).get();
    expect(jobs, hasLength(1));
    expect(jobs.single.recordId, record.id);
  });

  group('dropAudio (task 125)', () {
    PendingAudioDraft take(String id) => PendingAudioDraft(
      id: id,
      projectId: 'p1',
      relativePath: 'audio/$id.wav',
      storageRelativePath: 'projects/alpha/audio/$id.wav',
    );

    test('forgets only the named pending take, stored before it is shown, '
        'and leaves clips alone', () async {
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.addAudio(_clip));
      _ok(await controller.stageAudio(take('take-1')));
      _ok(await controller.stageAudio(take('take-2')));

      _ok(await controller.dropAudio('take-1'));

      expect(
        controller.state.pendingAudio.map((PendingAudioDraft p) => p.id),
        <String>['take-2'],
      );
      expect(controller.state.audio.single.id, _clip.id);
      final CaptureSession? stored = _ok(
        await container.read(capturePersistenceProvider).loadSession('p1'),
      );
      expect(stored?.pendingAudio.map((PendingAudioDraft p) => p.id), <String>[
        'take-2',
      ]);
    });

    test('a take that is not pending is a no-op', () async {
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.stageAudio(take('take-1')));
      _ok(await controller.dropAudio('missing'));
      expect(controller.state.pendingAudio.single.id, 'take-1');
    });

    test('a failed write keeps the pending take', () async {
      final ProviderContainer failing = ProviderContainer(
        overrides: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref _) => _FailingSaves(
              CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
            ),
          ),
        ],
      );
      addTearDown(failing.dispose);
      final CaptureController controller = failing.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await controller.stageAudio(take('take-1')));
      (failing.read(capturePersistenceProvider) as _FailingSaves).fail = true;

      expect(await controller.dropAudio('take-1'), isA<FailureResult<void>>());
      expect(controller.state.pendingAudio.single.id, 'take-1');
    });
  });

  test('without a live transcript take, finishing it does nothing and the '
      'saves run as before', () async {
    final FakeCaptureRecordPersistence records = FakeCaptureRecordPersistence();
    final ProviderContainer saving = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWith((Ref _) => photos),
        capturePersistenceProvider.overrideWith(
          (Ref _) =>
              CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
        ),
        captureRecordWriterProvider.overrideWith((Ref _) => records),
      ],
    );
    addTearDown(saving.dispose);
    final CaptureController controller = saving.read(
      captureControllerProvider('p1').notifier,
    );
    expect(await controller.finishCaptureIfActive(), isA<Success<void>>());
    _ok(await controller.addAudio(_clip));
    _ok(await controller.saveRaw(records.persist));
    expect(records.persisted.single.audio.single.id, _clip.id);
  });
}

/// Owned controller, durable store and pending device reads for resume tests.
final class _DeviceCaptureRig {
  _DeviceCaptureRig({
    required this.container,
    required this.controller,
    required this.source,
    required this.persistence,
    required this.lifecycle,
    required this.reads,
    required this._photos,
    required this._subscription,
  });

  final ProviderContainer container;
  final CaptureController controller;
  final CaptureDeviceSource source;
  final _FailingSaves persistence;
  final LifecycleObserver lifecycle;
  final List<Completer<PlatformFacts>> reads;
  final FakePhotoRepository _photos;
  final ProviderSubscription<CaptureSession> _subscription;
  bool _disposed = false;

  static Future<_DeviceCaptureRig> open({
    bool native = true,
    int headerVersion = 1,
    CaptureSession? initial,
  }) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    final _FailingSaves persistence = _FailingSaves(
      CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
    );
    final LifecycleObserver lifecycle = LifecycleObserver.fake();
    final List<Completer<PlatformFacts>> reads = <Completer<PlatformFacts>>[];
    final List<TemplateDef> templates = <TemplateDef>[
      aTemplate(
        id: 'address',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'network_address',
            label: 'Address',
            type: FieldType.text,
            autoFill: AutoFill.localAddress,
          ),
        ],
      ).copyWith(version: headerVersion),
      aTemplate(
        id: 'no-source',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'business',
            label: 'Business',
            type: FieldType.text,
          ),
        ],
      ),
      aTemplate(
        id: 'malformed-source',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'network_address',
            label: 'Address',
            type: FieldType.number,
            autoFill: AutoFill.localAddress,
          ),
        ],
      ),
    ];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWithValue(photos),
        capturePersistenceProvider.overrideWithValue(persistence),
        lifecycleObserverProvider.overrideWithValue(lifecycle),
        captureProjectTemplatesProvider.overrideWith(
          (Ref _, String key) => Stream<List<TemplateDef>>.value(templates),
        ),
        if (native)
          captureDeviceSourceProvider.overrideWith((Ref ref, String key) {
            final CaptureDeviceSources source = CaptureDeviceSources(
              clock: FixedClock(DateTime.utc(2026, 10, 9)),
              readFacts: () {
                final Completer<PlatformFacts> pending =
                    Completer<PlatformFacts>();
                reads.add(pending);
                return pending.future;
              },
            );
            ref.onDispose(source.dispose);
            return source;
          }),
      ],
    );
    final ProviderSubscription<CaptureSession> subscription = container.listen(
      captureControllerProvider('p1'),
      (_, _) {},
    );
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    if (initial == null) {
      _ok(await controller.setTemplate('address', version: 1));
    } else {
      _ok(await controller.replaceSession(initial));
    }
    expect(
      await container.read(captureProjectTemplatesProvider('p1').future),
      templates,
    );
    await container.pump();
    return _DeviceCaptureRig(
      container: container,
      controller: controller,
      source: container.read(captureDeviceSourceProvider('p1')),
      persistence: persistence,
      lifecycle: lifecycle,
      reads: reads,
      photos: photos,
      subscription: subscription,
    );
  }

  Future<void> complete(int index, String address) async {
    final Future<void> ready = source.changes.firstWhere(
      (_) => source.snapshot(controller.state) == address,
    );
    reads[index].complete(PlatformFacts.fake(addresses: <String>[address]));
    await ready;
  }

  void disposeContainer() {
    if (_disposed) return;
    _disposed = true;
    _subscription.close();
    container.dispose();
  }

  void dispose() {
    disposeContainer();
    _photos.dispose();
    lifecycle.dispose();
  }
}

/// Session storage whose saves fail while [fail] is set.
final class _FailingSaves implements CapturePersistence {
  _FailingSaves(this._inner);

  final CapturePersistence _inner;

  /// Whether the next saves fail.
  bool fail = false;

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
    if (fail) {
      return const FailureResult<void>(StorageFailure());
    }
    return _inner.saveSession(session);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) =>
      _inner.loadSession(key);

  @override
  Future<Result<void>> clearSession(String key) => _inner.clearSession(key);
}

PhotoDraft _photo(String id, {String projectId = 'p1', int sortOrder = 0}) {
  return PhotoDraft(
    id: id,
    projectId: projectId,
    relativePath: 'photos/_unfiled/$id.jpg',
    sha256: 'sha-$id',
    sortOrder: sortOrder,
  );
}

final GeoFix _fix = GeoFix(
  latitude: 0.3476,
  longitude: 32.5825,
  accuracyMetres: 6,
  capturedAt: DateTime.utc(2026, 9, 29, 8),
);

final AudioDraft _clip = AudioDraft(
  id: 'clip-1',
  projectId: 'p1',
  relativePath: 'audio/clip-1.wav',
  mimeType: 'audio/wav',
  fileSize: 44,
  sha256: 'clip-sha',
  durationMs: 1000,
  photoIds: const <String>[],
);

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

/// Delays the originating form before checking its current durable owner.
final class _DelayedFieldWrite implements OwnedCapturePersistence {
  final Completer<void> release = Completer<void>();
  CaptureSession? stored;
  bool failOwned = false;
  int writes = 0;

  @override
  PhotoRepository get photos => throw UnimplementedError();
  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    writes += 1;
    stored = session;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveOwnedSession(
    CaptureSession session, {
    required ({String sessionId, String templateId, int? templateVersion})
    owner,
  }) async {
    writes += 1;
    await release.future;
    if (failOwned) {
      return const FailureResult<void>(
        StorageFailure(message: 'Owned write refused'),
      );
    }
    final CaptureSession? current = stored;
    if (current == null ||
        current.id != owner.sessionId ||
        current.templateId != owner.templateId ||
        current.templateVersion != owner.templateVersion ||
        session.id != owner.sessionId ||
        session.templateId != owner.templateId ||
        session.templateVersion != owner.templateVersion) {
      return const FailureResult<void>(
        StorageFailure(message: 'Owner changed'),
      );
    }
    stored = session;
    return const Success<void>(null);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) async =>
      Success<CaptureSession?>(stored);
  @override
  Future<Result<void>> clearSession(String key) async {
    stored = null;
    return const Success<void>(null);
  }

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async => Success<PhotoDraft>(photo);
  @override
  Future<Result<void>> deletePhoto(
    String photoId, {
    required String reason,
  }) async => const Success<void>(null);
}

/// Holds writes and releases them last-started first to exercise rebasing.
final class _OutOfOrder implements CapturePersistence {
  final List<({CaptureSession session, Completer<void> done})> _held =
      <({CaptureSession session, Completer<void> done})>[];
  bool _holding = true;

  /// The session as stored now.
  CaptureSession? stored;

  /// Lands every held write, newest first, and stops holding.
  void releaseInReverse() {
    _holding = false;
    for (final ({CaptureSession session, Completer<void> done}) write
        in _held.reversed) {
      stored = write.session;
      write.done.complete();
    }
    _held.clear();
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
    if (_holding) {
      final Completer<void> done = Completer<void>();
      _held.add((session: session, done: done));
      await done.future;
      return const Success<void>(null);
    }
    stored = session;
    return const Success<void>(null);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) async =>
      Success<CaptureSession?>(stored);

  @override
  Future<Result<void>> clearSession(String key) async {
    stored = null;
    return const Success<void>(null);
  }
}

/// Records, around a real store, when a photo row is readable and when the
/// session is stored, so a test can order them against what the page shows.
final class _Recording implements CapturePersistence {
  _Recording(this._inner, this._db, this._events);

  final CapturePersistence _inner;
  final AppDatabase _db;
  final List<String> _events;

  @override
  PhotoRepository get photos => _inner.photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    final Result<PhotoDraft> saved = await _inner.savePhoto(
      photo,
      bytes: bytes,
    );
    final Photo? row =
        await (_db.select(_db.photos)
              ..where(($PhotosTable table) => table.id.equals(photo.id)))
            .getSingleOrNull();
    _events.add('photo row written: ${row != null}');
    return saved;
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) =>
      _inner.deletePhoto(photoId, reason: reason);

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    final Result<void> saved = await _inner.saveSession(session);
    _events.add('session stored');
    return saved;
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) =>
      _inner.loadSession(key);

  @override
  Future<Result<void>> clearSession(String key) => _inner.clearSession(key);
}
