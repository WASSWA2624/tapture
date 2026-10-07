import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';

import '../test/support/matchers.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

void main() {
  test('captured evidence survives project recycling and individual recovery offline', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    app.backend.markUnreachable();
    final CaptureRig capture = await CaptureRig.open(app);
    await capture.shoot();
    valueOf(await capture.controller.saveRaw(capture.container.read(captureRecordWriterProvider)!.persist));
    final Photo photo = await app.db.select(app.db.photos).getSingle();
    final String originalHash = sha256.convert(await capture.file(photo.relativePath).readAsBytes()).toString();
    final ProjectRepositoryImpl projects = ProjectRepositoryImpl(db: app.db, clock: app.clock,
      deviceId: 'test', ids: UuidV7Service.sequence(app.clock), storageRoot: capture.storage);
    valueOf(await capture.container.read(photoRepositoryProvider).delete(photo.id, reason: 'independent photo deletion'));
    valueOf(await projects.delete(CaptureRig.projectId));
    expect(capture.file(photo.relativePath).existsSync(), isFalse);
    expect((await projects.watchDeleted().first).single.id, CaptureRig.projectId);
    expect(await capture.container.read(photoRepositoryProvider).watchDeleted().first, isEmpty);
    valueOf(await projects.restore(CaptureRig.projectId));
    expect((await capture.container.read(photoRepositoryProvider).watchDeleted().first).single.id, photo.id);
    expect(sha256.convert(await capture.file(photo.relativePath).readAsBytes()).toString(), originalHash);
    valueOf(await capture.container.read(photoRepositoryProvider).restore(photo.id));
    expect(await capture.container.read(photoRepositoryProvider).watchDeleted().first, isEmpty);
    expect((await app.db.select(app.db.photos).getSingle()).sha256, photo.sha256);
    expect(await app.db.select(app.db.tombstones).get(), isEmpty);
    expect(app.outboundCallCount, 0);
    expect(app.ai.calls, 0);
  });
}
