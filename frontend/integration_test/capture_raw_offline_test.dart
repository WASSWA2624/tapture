import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';

import '../test/support/matchers.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

void main() {
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
