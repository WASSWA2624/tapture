import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/rapid_run.dart';

import '../test/support/matchers.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

void main() {
  test('a four-item rapid run saves four raw records with their photos, '
      'queues nothing, and reopening the last edits only it', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    final CaptureRig capture = await CaptureRig.open(app);
    valueOf(await capture.controller.setTemplate(CaptureRig.templateId));
    final RapidRun run = capture.container.read(
      rapidRunProvider(CaptureRig.projectId).notifier,
    );
    // Keep the run alive between taps, as the open screen does.
    capture.container.listen<List<RapidCapture>>(
      rapidRunProvider(CaptureRig.projectId),
      (List<RapidCapture>? _, List<RapidCapture> _) {},
    );

    const List<int> photosPerItem = <int>[2, 1, 3, 2];
    for (final int count in photosPerItem) {
      for (int shot = 0; shot < count; shot++) {
        await capture.shoot();
      }
      // One tap: saved raw, and the next item begins.
      valueOf(await run.next());
      app.clock.advance(const Duration(seconds: 10));
    }

    final List<RapidCapture> items = capture.container.read(
      rapidRunProvider(CaptureRig.projectId),
    );
    expect(items.map((RapidCapture item) => item.photos), photosPerItem);
    expect(await app.db.select(app.db.records).get(), hasLength(4));
    for (int index = 0; index < items.length; index++) {
      expect(
        await _photoCount(app, items[index].recordId),
        photosPerItem[index],
      );
    }
    expect(await app.db.select(app.db.processing).get(), isEmpty);
    expect(app.outboundCallCount, 0);

    // Reopen the last item for correction and add a photo to it.
    final String last = items.last.recordId;
    final Map<String, RecordRow> before = <String, RecordRow>{
      for (final RecordRow row in await app.db.select(app.db.records).get())
        row.id: row,
    };
    final String editKey = CaptureSessionKey.edit(last);
    final CaptureController edit = capture.container.read(
      captureControllerProvider(editKey).notifier,
    );
    valueOf(await edit.loadRecord(last));
    await capture.shoot(key: editKey);
    valueOf(await edit.saveEdits());

    expect(await _photoCount(app, last), photosPerItem.last + 1);
    for (final RapidCapture item in items.take(3)) {
      expect(await _photoCount(app, item.recordId), item.photos);
      final RecordRow after =
          await (app.db.select(app.db.records)
                ..where(($RecordsTable row) => row.id.equals(item.recordId)))
              .getSingle();
      expect(after.rev, before[item.recordId]!.rev);
      expect(after.updatedAt, before[item.recordId]!.updatedAt);
    }
    expect(await app.db.select(app.db.records).get(), hasLength(4));
    expect(await app.db.select(app.db.processing).get(), isEmpty);
  });
}

/// Live photos filed on [recordId].
Future<int> _photoCount(TestApp app, String recordId) async {
  final List<Photo> photos = await (app.db.select(
    app.db.photos,
  )..where(($PhotosTable row) => row.recordId.equals(recordId))).get();
  final Set<String> tombstoned = <String>{
    for (final Tombstone row in await app.db.select(app.db.tombstones).get())
      if (row.entityType == 'photos') row.entityId,
  };
  return photos.where((Photo photo) => !tombstoned.contains(photo.id)).length;
}
