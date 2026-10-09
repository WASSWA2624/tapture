import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/context/domain/context_state.dart';

import '../test/support/matchers.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

void main() {
  test(
    'committed context survives restart and later captures preserve saved evidence',
    () async {
      final TestApp app = await bootTestApp();
      addTearDown(app.dispose);
      app.backend.markUnreachable();
      final CaptureRig capture = await CaptureRig.open(app);
      valueOf(
        await app.context
            .saveHierarchy(CaptureRig.projectId, const <ContextLevel>[
              ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
              ContextLevel(fieldKey: 'site', order: 1, label: 'Site'),
            ]),
      );
      valueOf(
        await app.context.setLevelValue(
          projectId: CaptureRig.projectId,
          fieldKey: 'district',
          value: 'North',
        ),
      );
      valueOf(
        await app.context.setLevelValue(
          projectId: CaptureRig.projectId,
          fieldKey: 'site',
          value: 'Clinic',
        ),
      );
      ContextState committed = valueOf(
        await app.context.savePinned(
          CaptureRig.projectId,
          const <String, String>{'operator': 'Field team'},
        ),
      );
      valueOf(await capture.controller.setTemplate(CaptureRig.templateId));
      valueOf(
        await capture.controller.setContext(<String, String>{
          ...committed.values,
          ...committed.pinned,
        }),
      );
      await capture.shoot();
      final CaptureSession draft = capture.session;
      capture.container.invalidate(
        captureControllerProvider(CaptureRig.projectId),
      );
      await capture.container.pump();
      final CaptureSession recovered = (await capture.controller
          .interrupted())!;
      expect(recovered.contextSnapshot, draft.contextSnapshot);
      expect(recovered.photos.single.sha256, draft.photos.single.sha256);
      valueOf(await capture.controller.replaceSession(recovered));
      final String firstId = valueOf(
        await capture.controller.saveRaw(
          capture.container.read(captureRecordWriterProvider)!.persist,
        ),
      );
      final RecordRow first = await app.db.select(app.db.records).getSingle();
      final Photo photo = await app.db.select(app.db.photos).getSingle();
      final bytes = capture.file(photo.relativePath).readAsBytesSync();
      final audit = await app.db.select(app.db.auditLog).get();
      expect(jsonDecode(first.contextJson), draft.contextSnapshot);
      expect(photo.relativePath, contains('North'));
      expect(photo.relativePath, contains('Clinic'));

      valueOf(
        await app.context.setLevelValue(
          projectId: CaptureRig.projectId,
          fieldKey: 'district',
          value: 'South',
        ),
      );
      valueOf(
        await app.context.savePinned(
          CaptureRig.projectId,
          const <String, String>{},
        ),
      );
      final ContextRepositoryImpl restarted = ContextRepositoryImpl(
        db: app.db,
        clock: app.clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(app.clock),
      );
      committed = valueOf(await restarted.load(CaptureRig.projectId));
      expect(committed.values, <String, String>{'district': 'South'});
      expect(committed.pinned, isEmpty);
      expect(
        valueOf(
          await restarted.recentValues(
            projectId: CaptureRig.projectId,
            fieldKey: 'district',
          ),
        ),
        containsAll(<String>['North', 'South']),
      );
      valueOf(
        await capture.controller.setContext(<String, String>{
          ...committed.values,
          ...committed.pinned,
        }),
      );
      await capture.shoot();
      final String secondId = valueOf(
        await capture.controller.saveRaw(
          capture.container.read(captureRecordWriterProvider)!.persist,
        ),
      );
      final List<RecordRow> records = await app.db.select(app.db.records).get();
      expect(records.singleWhere((row) => row.id == firstId), first);
      expect(
        jsonDecode(
          records.singleWhere((row) => row.id == secondId).contextJson,
        ),
        <String, String>{'district': 'South'},
      );
      final Photo preserved = (await app.db.select(app.db.photos).get())
          .singleWhere((row) => row.id == photo.id);
      expect(preserved, photo);
      expect(capture.file(photo.relativePath).readAsBytesSync(), bytes);
      final history = await app.db.select(app.db.auditLog).get();
      expect(history, containsAll(audit));
      expect(await app.db.select(app.db.processing).get(), isEmpty);
      expect(app.ai.calls, 0);
      expect(app.outboundCallCount, 0);
    },
  );

  test(
    'durable manual values survive controller restart and save raw offline',
    () async {
      final TestApp app = await bootTestApp();
      addTearDown(app.dispose);
      app.backend.markUnreachable();
      final CaptureRig capture = await CaptureRig.open(app);
      valueOf(await capture.controller.setTemplate(CaptureRig.templateId));
      valueOf(await capture.controller.setValue('serial', 'SN-recovered'));
      valueOf(
        await capture.controller.setCaption(null, 'Caption after recovery'),
      );
      await capture.shoot();
      final CaptureSession before = capture.session;
      capture.container.invalidate(
        captureControllerProvider(CaptureRig.projectId),
      );
      await capture.container.pump();
      final CaptureSession recovered = (await capture.controller
          .interrupted())!;
      expect(recovered.id, before.id);
      expect(recovered.values['serial'], 'SN-recovered');
      expect(recovered.photos.single.sha256, before.photos.single.sha256);
      valueOf(await capture.controller.replaceSession(recovered));
      final String id = valueOf(
        await capture.controller.saveRaw(
          capture.container.read(captureRecordWriterProvider)!.persist,
        ),
      );
      final RecordField field =
          await (app.db.select(app.db.recordFields)..where(
                ($RecordFieldsTable row) =>
                    row.recordId.equals(id) & row.fieldKey.equals('serial'),
              ))
              .getSingle();
      expect(field.valueRaw, 'SN-recovered');
      final Photo photo = await app.db.select(app.db.photos).getSingle();
      expect(photo.sha256, before.photos.single.sha256);
      expect(capture.file(photo.relativePath).existsSync(), isTrue);
      expect(await app.db.select(app.db.processing).get(), isEmpty);
      expect(app.ai.calls, 0);
      expect(app.outboundCallCount, 0);
    },
  );

  test('a project without templates saves evidence offline', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    await app.db.delete(app.db.templateFields).go();
    await app.db.delete(app.db.templates).go();
    app.backend.markUnreachable();
    final CaptureRig capture = await CaptureRig.open(app);
    expect(capture.session.templateId, isEmpty);
    await capture.shoot();
    valueOf(await capture.controller.setCaption(null, 'Evidence before setup'));

    final String id = valueOf(
      await capture.controller.saveRaw(
        capture.container.read(captureRecordWriterProvider)!.persist,
      ),
    );

    final RecordRow record = await app.db.select(app.db.records).getSingle();
    final Photo photo = await app.db.select(app.db.photos).getSingle();
    expect(record.id, id);
    expect(record.templateId, isEmpty);
    expect(record.status, RecordStatus.captured.stored);
    expect(photo.recordId, id);
    expect(capture.file(photo.relativePath).existsSync(), isTrue);
    expect(await app.db.select(app.db.templates).get(), isEmpty);
    expect(await app.db.select(app.db.processing).get(), isEmpty);
    expect(app.ai.calls, 0);
    expect(app.outboundCallCount, 0);
  });

  test('forty records captured offline in sequence are saved raw with their '
      'photos, and nothing is processed or sent', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    app.backend.markUnreachable();
    final CaptureRig capture = await CaptureRig.open(app);
    valueOf(await capture.controller.setTemplate(CaptureRig.templateId));

    final List<String> saved = <String>[];
    for (int item = 0; item < 40; item++) {
      await capture.shoot();
      valueOf(await capture.controller.setCaption(null, 'Item $item'));
      saved.add(
        valueOf(
          await capture.controller.saveRaw(
            capture.container.read(captureRecordWriterProvider)!.persist,
          ),
        ),
      );
      app.clock.advance(const Duration(seconds: 5));
    }

    final List<RecordRow> records = await app.db.select(app.db.records).get();
    expect(records, hasLength(40));
    expect(records.map((RecordRow row) => row.id).toSet(), saved.toSet());
    expect(
      records.every(
        (RecordRow row) => row.status == RecordStatus.captured.stored,
      ),
      isTrue,
    );
    final List<Photo> photos = await app.db.select(app.db.photos).get();
    expect(photos, hasLength(40));
    expect(photos.map((Photo photo) => photo.recordId).toSet(), saved.toSet());
    for (final Photo photo in photos) {
      expect(capture.file(photo.relativePath).existsSync(), isTrue);
    }
    expect(await app.db.select(app.db.processing).get(), isEmpty);
    expect(app.ai.calls, 0);
    expect(app.outboundCallCount, 0);
    // The session after the last save is empty and ready for the next item.
    expect(capture.session.photos, isEmpty);
    expect(capture.session.templateId, CaptureRig.templateId);
  });
}
