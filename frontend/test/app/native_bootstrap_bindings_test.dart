import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/audio/audio_capture_plugin.dart';
import 'package:tapture/core/audio/audio_capture_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/files/blob_store_io.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/speech/live_transcription_service.dart';
import 'package:tapture/core/speech/routed_stt_service.dart';
import 'package:tapture/core/speech/speech_preferences.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/data/deliverable_repository_impl.dart';
import 'package:tapture/features/exports/domain/deliverable_repository.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/presentation/language_settings_screen.dart'
    show voiceLanguageProvider;
import 'package:tapture/features/templates/templates.dart';
import 'package:tapture/main.dart' as app;

import '../support/pump_external_work.dart';

void main() {
  testWidgets(
    'the production root reads, renders and prepares its real SQLite record',
    (WidgetTester tester) async {
      // This host engine has no radio plugin. Keep the actual app adapter
      // offline through its native boundary, without replacing its providers.
      const MethodChannel radio = MethodChannel(
        'dev.fluttercommunity.plus/connectivity',
      );
      const MethodChannel changes = MethodChannel(
        'dev.fluttercommunity.plus/connectivity_status',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(radio, (_) async => <String>['none']);
      messenger.setMockMethodCallHandler(changes, (_) async => null);
      addTearDown(() {
        messenger.setMockMethodCallHandler(radio, null);
        messenger.setMockMethodCallHandler(changes, null);
      });
      // Real I/O awaited outside runAsync never completes under the fake
      // clock, so the scratch folder is made synchronously.
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-bootstrap-bindings-',
      );
      // A genuine native disk database; this host regression makes no claim
      // about device encryption or SDK timings. The physical target uses SDK keys.
      final sqlite.AppDatabase db = sqlite.AppDatabase.open(
        directoryPath: '${directory.path}/database',
      );
      final SecureStorage secrets = SecureStorage.fake(
        backing: <SecretKey, String>{},
      );
      final StorageRoot root = StorageRoot(
        documentsDirectory: () async =>
            Directory('${directory.path}/documents'),
      );
      AsyncCallback? shutdown;
      try {
        shutdown = await tester.runAsync(
          () => app.runDeviceMetricsApp(
            database: db,
            secrets: secrets,
            storageRoot: root,
            logger: Logger(
              persist: true,
              directoryPath: '${directory.path}/logs',
            ),
            relayStore: folderBlobStore(
              () async => Directory('${directory.path}/relay'),
            ),
            feedbackStore: folderBlobStore(
              () async => Directory('${directory.path}/feedback'),
            ),
          ),
        );
        await pumpExternalWork(
          tester,
          () => find
              .byKey(const ValueKey<String>('route-projects'))
              .evaluate()
              .isNotEmpty,
        );
        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byKey(const ValueKey<String>('route-projects'))),
        );
        expect(
          container.read(recordRepositoryProvider),
          isA<RecordRepositoryImpl>(),
        );
        expect(container.read(providerKeyStorageProvider), same(secrets));
        // Live transcription is bound to the real streaming capture and the
        // on-device speech host, not the unavailable defaults (task 118).
        expect(
          container.read(audioCaptureServiceProvider),
          isA<AudioCapturePlugin>(),
        );
        expect(
          container
              .read(liveTranscriptionServiceProvider)
              .runtimeType
              .toString(),
          '_LiveTranscriptionService',
        );
        // Every text field's microphone goes through the routed on-device
        // dictation, in the voice language (task 120).
        expect(container.read(sttServiceProvider), isA<RoutedSttService>());
        expect(
          container.read(speechLanguageProvider),
          container.read(voiceLanguageProvider),
        );
        // Windows and Linux bind no platform recogniser: none can stay on
        // the device there, so only Whisper dictates.
        expect(container.read(platformRecogniserProvider), isNotNull);
        try {
          for (final TargetPlatform platform in <TargetPlatform>[
            TargetPlatform.windows,
            TargetPlatform.linux,
          ]) {
            debugDefaultTargetPlatformOverride = platform;
            container.invalidate(platformRecogniserProvider);
            expect(
              container.read(platformRecogniserProvider),
              isNull,
              reason: '$platform',
            );
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
          container.invalidate(platformRecogniserProvider);
        }
        expect(container.read(platformRecogniserProvider), isNotNull);
        final RecordEntry record = (await tester.runAsync(() async {
          final Project project =
              (await container
                      .read(projectRepositoryProvider)
                      .createReady(name: 'Owned bootstrap project'))
                  .getOrThrow();
          final TemplateDef template =
              (await container
                      .read(templateRepositoryProvider)
                      .save(
                        TemplateDef(
                          id: '',
                          templateKey: 'bootstrap_record',
                          name: 'Bootstrap record',
                          version: 1,
                          projectId: project.id,
                          fields: const <FieldDef>[
                            FieldDef(
                              fieldKey: 'serial',
                              label: 'Serial',
                              type: FieldType.text,
                              identity: true,
                            ),
                          ],
                          identityFieldKeys: const <String>['serial'],
                          rows: const <TemplateRow>[],
                        ),
                      ))
                  .getOrThrow();
          return (await container.read(recordRepositoryProvider).save((
            projectId: project.id,
            templateId: template.id,
            fields: <String, String>{'serial': 'bootstrap-real-value'},
            context: <String, String>{},
          ))).getOrThrow();
        }))!;
        final sqlite.RecordRow persisted = (await tester.runAsync(
          () => (db.select(
            db.records,
          )..where((r) => r.id.equals(record.id))).getSingle(),
        ))!;
        expect(persisted.id, record.id);
        expect(record.status, RecordStatus.draft);
        await tester.runAsync(() async {
          final RecordRepository records = container.read(
            recordRepositoryProvider,
          );
          (await records.transition(
            record.id,
            RecordStatus.needsReview,
          )).getOrThrow();
          expect(
            (await records.byId(record.id)).getOrThrow()?.status,
            RecordStatus.needsReview,
          );
          (await records.transition(
            record.id,
            RecordStatus.approved,
          )).getOrThrow();
          expect(
            (await records.byId(record.id)).getOrThrow()?.status,
            RecordStatus.approved,
          );
          expect(await db.select(db.processing).get(), isEmpty);
        });
        container
            .read(routerProvider)
            .go(RoutePaths.projectRecord(record.projectId, record.id));
        await pumpExternalWork(
          tester,
          () =>
              container
                      .read(recordEntryProvider(record.id))
                      .asData
                      ?.value
                      ?.id ==
                  record.id &&
              find.byType(RecordDetailScreen).evaluate().isNotEmpty &&
              // The field rows wait for the template, read after the record.
              find
                  .byKey(const ValueKey<String>('record-source-serial'))
                  .evaluate()
                  .isNotEmpty,
        );
        // The identity value heads the record, after its number.
        expect(
          find.textContaining('bootstrap-real-value'),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('record-source-serial')),
            matching: find.text(Copy.recordSourceTyped),
          ),
          findsOneWidget,
        );
        final DeliverableRepository deliverables = container.read(
          deliverableRepositoryProvider,
        )!;
        expect(deliverables, isA<DeliverableRepositoryImpl>());
        final PreparedDeliverable prepared = (await tester.runAsync(() async {
          final ExportRequest options = (await deliverables.options(
            record.projectId,
          )).getOrThrow();
          return (await deliverables.prepare(
            options.copyWith(
              scope: (
                kind: ExportScopeKind.all,
                context: null,
                from: null,
                to: null,
                filter: null,
              ),
            ),
            cancel: CancellationToken(),
          )).getOrThrow();
        }))!;
        expect(prepared.request.records.map((r) => r.id), <String>[record.id]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        // Closing waits on stream work started under the fake clock, so both
        // clocks must advance; runAsync alone deadlocks here.
        var closed = false;
        unawaited(
          () async {
            await shutdown?.call();
            await db.close();
          }().whenComplete(() => closed = true),
        );
        for (int step = 0; !closed && step < 600; step++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(closed, isTrue, reason: 'the database did not close');
        await tester.runAsync(() async {
          if (await directory.exists()) await directory.delete(recursive: true);
        });
      }
    },
  );
}
