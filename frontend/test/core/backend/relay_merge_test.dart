import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/merge/data/package_import_repository_impl.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../../support/bundle_fixture.dart';
import '../../support/fakes/fake_id_service.dart';
import '../../support/fakes/fake_relay_server.dart';

const String _key = 'shared relay key 0123';

/// Two local databases exchange a project package through the relay: the
/// sender's package writer, its encrypted outbox and a push whose response
/// is lost and replayed; the receiver's decryption, then the same merge a
/// hand-carried bundle takes, then the acknowledgement (task 024 step 25).
void main() {
  late BundleFixture source;
  late sqlite.AppDatabase target;
  late Directory targetDocuments;
  late StorageRoot targetRoot;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 28, 10));

  setUp(() async {
    source = await seedProjectForBundle();
    target = sqlite.AppDatabase.memory();
    targetDocuments = Directory.systemTemp.createTempSync('tapture-relay-');
    targetRoot = StorageRoot.fake(documentsDirectory: targetDocuments);
  });

  tearDown(() async {
    await source.db.close();
    await target.close();
    for (final Directory folder in <Directory>[
      source.root.parent,
      targetDocuments,
    ]) {
      if (folder.existsSync()) {
        folder.deleteSync(recursive: true);
      }
    }
  });

  // One id sequence per receiving device, as the app's shared id service
  // gives: a fresh sequence per call would mint colliding ids.
  late IdService receiverIds;
  setUp(() => receiverIds = UuidV7Service.sequence(clock));

  PackageImportRepositoryImpl receiving() {
    return PackageImportRepositoryImpl(
      db: target,
      files: PackageFiles(storageRoot: targetRoot),
      clock: clock,
      deviceId: 'device-b',
      ids: receiverIds,
    );
  }

  test('a relayed package merges into the receiving database, a replayed push '
      'is stored once, and it is acknowledged only after the merge', () async {
    // Both devices hold the project: the receiver took it by hand once.
    _ok(await receiving().importAsNew(await _inspect(await _export(source))));
    final int before = await _count(target, 'records');
    await insertRow(source.db, 'records', <String, Object?>{
      'id': 'record-relayed',
      'project_id': source.projectId,
      'template_id':
          (await source.db
                      .customSelect('SELECT template_id FROM records LIMIT 1')
                      .getSingle())
                  .data['template_id']!
              as String,
      'status': 'captured',
      'context_json': '{}',
      'captured_at': 1790000400,
    });

    final FakeRelayServer server = FakeRelayServer(
      projectId: source.projectId,
      relayEnabled: true,
    );
    final RelayQueue sender = _device(server, 'device-a');
    final RelayQueue receiver = _device(server, 'device-b');
    _ok(await sender.saveKey(source.projectId, _key));
    _ok(await receiver.saveKey(source.projectId, _key));
    final Uint8List package = await _export(source);
    _ok(await sender.enqueue(source.projectId, package));

    server.dropNextUploadResponse = true;
    expect(await sender.sync(source.projectId), isA<FailureResult<void>>());
    _ok(await sender.sync(source.projectId));
    expect(server.uploads, 2);
    expect(server.uploadKeys.toSet(), hasLength(1));
    expect(server.packages, hasLength(1));
    expect(server.packages.values.single, isNot(package));

    _ok(await receiver.sync(source.projectId));
    final String packageId = server.packages.keys.single;
    expect(_ok(await receiver.snapshot(source.projectId)).incoming, <String>[
      packageId,
    ]);
    final Uint8List opened = _ok(
      await receiver.receive(source.projectId, packageId),
    );
    expect(opened, package);
    expect(server.acks[packageId], isNot(contains('device-b')));

    final InspectedBundle bundle = await _inspect(opened);
    final MergePlan plan = await _plan(receiving(), bundle, source.projectId);
    expect(plan.counts.newRecords, 1);
    _ok(
      await receiving().merge(
        bundle: bundle,
        projectId: source.projectId,
        plan: plan,
        choices: const <String, ConflictChoice>{},
        duplicates: const <PossibleDuplicate>[],
        skipped: const <String>{},
        chooser: 'Ben',
      ),
    );
    _ok(await receiver.applied(source.projectId, packageId));

    expect(await _count(target, 'records'), before + 1);
    expect(
      await target
          .customSelect("SELECT id FROM records WHERE id = 'record-relayed'")
          .get(),
      hasLength(1),
    );
    expect(server.acks[packageId], contains('device-b'));
    expect(server.packages, isEmpty);
    final RelaySnapshot received = _ok(
      await receiver.snapshot(source.projectId),
    );
    expect(received.incoming, isEmpty);
    _ok(await sender.sync(source.projectId));
    final RelaySnapshot sent = _ok(await sender.snapshot(source.projectId));
    expect(sent.queued, 0);
    expect(sent.sent, 1);
    expect(sent.purged, 1);
  });
}

/// A device's relay queue over its own stores.
RelayQueue _device(FakeRelayServer server, String device) {
  return RelayQueue(
    store: BlobStore.memory(),
    secrets: SecureStorage.fake(backing: <SecretKey, String>{}),
    ids: FakeIdService(prefix: device.substring(device.length - 1)),
    send: server.sendFor(device),
    deviceId: device,
  );
}

int _exports = 0;

/// [fixture]'s project package, written by the export the relay reuses.
Future<Uint8List> _export(BundleFixture fixture) async {
  _exports += 1;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 27, 9, _exports));
  final ExportedPackage exported = _ok(
    await ExportRepositoryImpl(
      db: fixture.db,
      storageRoot: fixture.storageRoot,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
      templates: TemplateRepositoryImpl(
        db: fixture.db,
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      ),
    ).exportProject(fixture.projectId, cancel: CancellationToken()),
  );
  final StoredBundle stored = exported.package as StoredBundle;
  return File('${fixture.root.path}/${stored.relativePath}').readAsBytesSync();
}

/// [bytes] opened and checked as the import preview opens a package.
Future<InspectedBundle> _inspect(Uint8List bytes) async {
  final InspectedBundle bundle = _ok(
    await BundleReader.inspect(PickedBytes(bytes, 'relay.tapture')),
  );
  addTearDown(bundle.close);
  return bundle;
}

/// The merge preview's plan for [bundle] into [projectId].
Future<MergePlan> _plan(
  PackageImportRepository repository,
  InspectedBundle bundle,
  String projectId,
) async {
  final MergeGround ground = _ok(
    await repository.groundFor(projectId: projectId, incoming: bundle.tables),
  );
  final CompatibilityReport report = TemplateCompatibility.check(
    incoming: bundle.tables,
    local: ground.local,
    sameProject: true,
  );
  expect(report.canMerge, isTrue);
  return MergePlanner.plan(
    incoming: bundle.tables,
    local: ground.local,
    templateMapping: report.mapping,
    targetProjectId: projectId,
    incomingProjectId: bundle.manifest.projectId,
    elsewhere: ground.elsewhere,
    decided: ground.decided,
  );
}

Future<int> _count(sqlite.AppDatabase db, String table) async {
  final List<QueryRow> rows = await db
      .customSelect('SELECT id FROM $table')
      .get();
  return rows.length;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
