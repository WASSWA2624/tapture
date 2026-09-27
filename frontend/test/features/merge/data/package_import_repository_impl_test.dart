import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/merge/data/package_import_repository_impl.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;

import '../../../support/bundle_fixture.dart';

void main() {
  late BundleFixture source;
  late sqlite.AppDatabase target;
  late Directory targetDocuments;
  late StorageRoot targetRoot;

  setUp(() async {
    source = await seedProjectForBundle();
    target = sqlite.AppDatabase.memory();
    targetDocuments = Directory.systemTemp.createTempSync('tapture-import-');
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

  PackageImportRepositoryImpl repository({FileWriter? writer}) {
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 28, 10));
    return PackageImportRepositoryImpl(
      db: target,
      files: PackageFiles(storageRoot: targetRoot, writer: writer),
      clock: clock,
      deviceId: 'device-b',
      ids: UuidV7Service.sequence(clock),
    );
  }

  File targetFile(String folder, String path) =>
      File('${targetDocuments.path}/Tapture/projects/$folder/$path');

  test('a package imports as the same project, row for row and file for '
      'file', () async {
    final InspectedBundle bundle = await _package(source);
    final ImportedProject imported = _ok(
      await repository().importAsNew(bundle),
    );
    expect(imported.projectId, source.projectId);
    expect(imported.records, 2);
    for (final String table in BundleFormat.insertOrder) {
      final List<Map<String, Object?>> expected = _sorted(bundle.rowsOf(table));
      // The import adds its own history rows beside the travelled ones.
      final String here = table == 'audit_log'
          ? "SELECT * FROM audit_log WHERE field_key IS NOT 'merge'"
          : 'SELECT * FROM $table';
      final List<Map<String, Object?>> actual = _sorted(<Map<String, Object?>>[
        for (final QueryRow row in await target.customSelect(here).get())
          row.data,
      ]);
      expect(actual, expected, reason: table);
    }
    final List<QueryRow> merged = await target
        .customSelect(
          'SELECT entity_type, entity_id, action, new_value, reason, device '
          "FROM audit_log WHERE field_key = 'merge' ORDER BY entity_id",
        )
        .get();
    expect(
      <Object?>[for (final QueryRow row in merged) row.data['entity_id']],
      <Object?>[
        for (final Map<String, Object?> row in _sorted(
          bundle.rowsOf('records'),
        ))
          row['id'],
      ],
    );
    for (final QueryRow row in merged) {
      expect(row.data['entity_type'], 'records');
      expect(row.data['action'], 'created');
      expect(row.data['new_value'], 'inserted');
      expect(row.data['reason'], 'site.zip');
      expect(row.data['device'], 'device-b');
    }
    // The search index was rebuilt inside the import's transaction.
    expect(
      (await target
              .customSelect('SELECT record_id FROM record_search_docs')
              .get())
          .length,
      2,
    );
    expect(
      await target.customSelect('SELECT 1 FROM record_search_pending').get(),
      isEmpty,
    );
    for (final MapEntry<String, Uint8List> file in source.files.entries) {
      expect(
        targetFile(source.folderName, file.key).readAsBytesSync(),
        file.value,
        reason: file.key,
      );
    }
    final QueryRow session = await target
        .customSelect('SELECT status, source_device FROM merge_sessions')
        .getSingle();
    expect(session.data['status'], 'imported');
    expect(session.data['source_device'], 'device-test');
    expect(
      _ok(await repository().presenceOf(source.projectId)),
      PackagePresence.live,
    );
  });

  test('a failure while copying leaves no rows and no folder', () async {
    final InspectedBundle bundle = await _package(source);
    final Result<ImportedProject> result = await repository(
      writer: _FailOnWrite(FileWriter(storageRoot: targetRoot), failOn: 2),
    ).importAsNew(bundle);
    expect(result, isA<FailureResult<ImportedProject>>());
    for (final String table in <String>[
      ...BundleFormat.insertOrder,
      'merge_sessions',
    ]) {
      expect(
        await target.customSelect('SELECT id FROM $table').get(),
        isEmpty,
        reason: table,
      );
    }
    expect(
      Directory(
        '${targetDocuments.path}/Tapture/projects/${source.folderName}',
      ).existsSync(),
      isFalse,
    );
  });

  test('a project deleted here is refused', () async {
    await insertRow(target, 'tombstones', <String, Object?>{
      'id': 'tomb-project',
      'entity_type': 'projects',
      'entity_id': source.projectId,
      'deleted_at': 1790000000,
      'deleted_by_device': 'device-b',
      'reason': 'deleted',
    });
    final InspectedBundle bundle = await _package(source);
    expect(
      _ok(await repository().presenceOf(source.projectId)),
      PackagePresence.deleted,
    );
    final Failure failure = _failure(await repository().importAsNew(bundle));
    expect(failure.message, Copy.importProjectDeletedHere);
    expect(await target.customSelect('SELECT id FROM records').get(), isEmpty);
  });

  test('a folder name already taken gets a suffix', () async {
    await insertRow(target, 'projects', <String, Object?>{
      'id': 'project-here',
      'name': 'Here',
      'status': 'active',
      'folder_name': source.folderName,
      'settings': '{}',
    });
    final InspectedBundle bundle = await _package(source);
    _ok(await repository().importAsNew(bundle));
    final String folder = '${source.folderName}-2';
    final QueryRow project = await target
        .customSelect(
          'SELECT folder_name, settings FROM projects WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(source.projectId)],
        )
        .getSingle();
    expect(project.data['folder_name'], folder);
    expect(
      project.data['settings'] as String,
      contains('projects/$folder/cover/cover-1.jpg'),
    );
    expect(targetFile(folder, 'cover/cover-1.jpg').existsSync(), isTrue);
  });

  group('merging', () {
    setUp(() async {
      _ok(await repository().importAsNew(await _package(source)));
    });

    test('brings new records and settled values, and a second merge of the '
        'same package changes nothing', () async {
      final Uint8List photo = Uint8List.fromList(
        List<int>.generate(3000, (int i) => (i * 13) % 256),
      );
      await _addRecordWithPhoto(source, photo);
      await source.db.customStatement(
        "UPDATE record_fields SET value_final = 'SN-0-fixed', verified = 1, "
        "rev = 2, updated_at = 1790000500 WHERE id = 'value-0'",
      );
      final InspectedBundle bundle = await _package(source);

      final MergePlan plan = await _plan(repository(), bundle, source);
      expect(plan.counts.newRecords, 1);
      expect(plan.counts.newPhotos, 1);
      expect(plan.settled.single.rule, SettlementRule.verifiedBeatsUnverified);
      expect(plan.conflicts, isEmpty);

      final MergeOutcome outcome = _ok(
        await repository().merge(
          bundle: bundle,
          projectId: source.projectId,
          plan: plan,
          choices: const <String, ConflictChoice>{},
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ben',
        ),
      );
      expect(outcome.records, 1);
      final QueryRow value = await target
          .customSelect(
            "SELECT value_raw, value_final FROM record_fields "
            "WHERE id = 'value-0'",
          )
          .getSingle();
      expect(value.data['value_raw'], 'SN-0');
      expect(value.data['value_final'], 'SN-0-fixed');
      expect(
        targetFile(source.folderName, 'photos/new.jpg').readAsBytesSync(),
        photo,
      );

      final List<QueryRow> history = await target
          .customSelect(
            'SELECT entity_id, action, new_value, reason, operator '
            "FROM audit_log WHERE field_key = 'merge' AND operator = 'Ben' "
            'ORDER BY entity_id',
          )
          .get();
      final String settledRecord =
          (await target
                      .customSelect(
                        "SELECT record_id FROM record_fields WHERE id = 'value-0'",
                      )
                      .getSingle())
                  .data['record_id']!
              as String;
      expect(
        <String, Object?>{
          for (final QueryRow row in history)
            row.data['entity_id']! as String: row.data['new_value'],
        },
        <String, Object?>{'record-new': 'inserted', settledRecord: 'updated'},
      );
      for (final QueryRow row in history) {
        expect(row.data['reason'], 'site.zip');
        expect(row.data['operator'], 'Ben');
      }

      final MergePlan again = await _plan(repository(), bundle, source);
      expect(again.isEmpty, isTrue);
    });

    test('a conflict settled by a person writes one audit entry and keeps '
        'the captured value', () async {
      await source.db.customStatement(
        "UPDATE record_fields SET value_final = 'SN-A', rev = 3, "
        "updated_at = 1790000500 WHERE id = 'value-0'",
      );
      await target.customStatement(
        "UPDATE record_fields SET value_final = 'SN-B', rev = 3, "
        "updated_at = 1790000600 WHERE id = 'value-0'",
      );
      final InspectedBundle bundle = await _package(source);
      final MergePlan plan = await _plan(repository(), bundle, source);
      final FieldConflict conflict = plan.conflicts.single;
      expect(conflict.kind, ConflictKind.value);
      expect(conflict.mine, 'SN-B');
      expect(conflict.theirs, 'SN-A');
      final int auditBefore = await _count(target, 'audit_log');

      _ok(
        await repository().merge(
          bundle: bundle,
          projectId: source.projectId,
          plan: plan,
          choices: <String, ConflictChoice>{conflict.id: ConflictChoice.theirs},
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ben',
        ),
      );
      // One entry for the settled conflict, one for the changed record.
      expect(await _count(target, 'audit_log'), auditBefore + 2);
      final QueryRow membership = await target
          .customSelect(
            'SELECT entity_id, new_value FROM audit_log '
            "WHERE field_key = 'merge' AND new_value = 'updated'",
          )
          .getSingle();
      expect(membership.data['entity_id'], conflict.recordId);
      final QueryRow value = await target
          .customSelect(
            "SELECT value_raw, value_final, verified FROM record_fields "
            "WHERE id = 'value-0'",
          )
          .getSingle();
      expect(value.data['value_raw'], 'SN-0');
      expect(value.data['value_final'], 'SN-A');
      expect(value.data['verified'], 1);
      final QueryRow stored = await target
          .customSelect('SELECT resolution, resolved_by FROM merge_conflicts')
          .getSingle();
      expect(stored.data['resolution'], 'theirs');
      expect(stored.data['resolved_by'], 'Ben');
      expect((await _plan(repository(), bundle, source)).conflicts, isEmpty);
    });

    test(
      'keeping this device\'s value is remembered for the same package',
      () async {
        await source.db.customStatement(
          "UPDATE record_fields SET value_final = 'SN-A', rev = 3 "
          "WHERE id = 'value-0'",
        );
        await target.customStatement(
          "UPDATE record_fields SET value_final = 'SN-B', rev = 3 "
          "WHERE id = 'value-0'",
        );
        final InspectedBundle bundle = await _package(source);
        final MergePlan plan = await _plan(repository(), bundle, source);
        _ok(
          await repository().merge(
            bundle: bundle,
            projectId: source.projectId,
            plan: plan,
            choices: <String, ConflictChoice>{
              plan.conflicts.single.id: ConflictChoice.mine,
            },
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
        );
        final MergePlan again = await _plan(repository(), bundle, source);
        expect(again.conflicts, isEmpty);
        expect(again.isEmpty, isTrue);
      },
    );

    test(
      'a merge that fails part way leaves rows and files unchanged',
      () async {
        await _addRecordWithPhoto(
          source,
          Uint8List.fromList(List<int>.filled(2000, 7)),
        );
        final InspectedBundle bundle = await _package(source);
        final MergePlan plan = await _plan(repository(), bundle, source);
        final Map<String, int> before = <String, int>{
          for (final String table in <String>[
            ...BundleFormat.insertOrder,
            'merge_sessions',
          ])
            table: await _count(target, table),
        };
        final Result<MergeOutcome> result =
            await repository(
              writer: _FailOnWrite(
                FileWriter(storageRoot: targetRoot),
                failOn: 1,
              ),
            ).merge(
              bundle: bundle,
              projectId: source.projectId,
              plan: plan,
              choices: const <String, ConflictChoice>{},
              duplicates: const <PossibleDuplicate>[],
              skipped: const <String>{},
              chooser: 'Ben',
            );
        expect(result, isA<FailureResult<MergeOutcome>>());
        for (final MapEntry<String, int> table in before.entries) {
          expect(
            await _count(target, table.key),
            table.value,
            reason: table.key,
          );
        }
        expect(
          targetFile(source.folderName, 'photos/new.jpg').existsSync(),
          isFalse,
        );
      },
    );

    test('a possible duplicate is stored, and a skipped record is not '
        'imported', () async {
      await _addRecordWithPhoto(
        source,
        Uint8List.fromList(List<int>.filled(1500, 3)),
      );
      final InspectedBundle bundle = await _package(source);
      final MergeGround ground = _ok(
        await repository().groundFor(
          projectId: source.projectId,
          incoming: bundle.tables,
        ),
      );
      final String localRecord =
          ground.local['records']!.first['id']! as String;
      const Set<String> skipped = <String>{'record-new'};
      final MergePlan plan = MergePlanner.plan(
        incoming: bundle.tables,
        local: ground.local,
        templateMapping: TemplateCompatibility.check(
          incoming: bundle.tables,
          local: ground.local,
          sameProject: true,
        ).mapping,
        targetProjectId: source.projectId,
        incomingProjectId: source.projectId,
        elsewhere: ground.elsewhere,
        skipRecords: skipped,
        decided: ground.decided,
      );
      expect(plan.counts.newRecords, 0);
      _ok(
        await repository().merge(
          bundle: bundle,
          projectId: source.projectId,
          plan: plan,
          choices: const <String, ConflictChoice>{},
          duplicates: <PossibleDuplicate>[
            PossibleDuplicate(
              incomingId: 'record-new',
              localId: localRecord,
              signal: DuplicateSignal.caption,
              score: 0.95,
            ),
          ],
          skipped: skipped,
          chooser: 'Ben',
        ),
      );
      final QueryRow pair = await target
          .customSelect('SELECT status, resolution FROM duplicates')
          .getSingle();
      expect(pair.data['status'], 'resolved');
      expect(pair.data['resolution'], 'discard_new');
      expect(
        await target
            .customSelect("SELECT id FROM records WHERE id = 'record-new'")
            .get(),
        isEmpty,
      );
    });
  });
}

/// Packages written so far, so each gets its own id and file.
int _packages = 0;

/// Writes [fixture]'s project as a package and opens it, as a second
/// device would.
Future<InspectedBundle> _package(BundleFixture fixture) async {
  _packages += 1;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 27, 9, _packages));
  final BundleWriter writer = BundleWriter(
    db: fixture.db,
    storageRoot: fixture.storageRoot,
    files: FileReader(storageRoot: fixture.storageRoot),
    clock: clock,
    ids: UuidV7Service.sequence(clock),
    deviceId: 'device-test',
    device: () async => const DeviceDescriptor.fake(),
    inBrowser: false,
  );
  final Result<BundleOutput> written = await writer.write(
    projectId: fixture.projectId,
    cancel: CancellationToken(),
  );
  final StoredBundle stored = _ok(written) as StoredBundle;
  final File file = File('${fixture.root.path}/${stored.relativePath}');
  final InspectedBundle bundle = _ok(
    await BundleReader.inspect(PickedFile(file, 'site.zip', file.lengthSync())),
  );
  addTearDown(bundle.close);
  return bundle;
}

Future<MergePlan> _plan(
  PackageImportRepository repository,
  InspectedBundle bundle,
  BundleFixture source,
) async {
  final MergeGround ground = _ok(
    await repository.groundFor(
      projectId: source.projectId,
      incoming: bundle.tables,
    ),
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
    targetProjectId: source.projectId,
    incomingProjectId: bundle.manifest.projectId,
    elsewhere: ground.elsewhere,
    decided: ground.decided,
  );
}

/// Adds `record-new` to [fixture]'s project with one field value, a
/// caption and a photo holding [photo].
Future<void> _addRecordWithPhoto(BundleFixture fixture, Uint8List photo) async {
  final String templateId =
      (await fixture.db
                  .customSelect('SELECT template_id FROM records LIMIT 1')
                  .getSingle())
              .data['template_id']!
          as String;
  await insertRow(fixture.db, 'records', <String, Object?>{
    'id': 'record-new',
    'project_id': fixture.projectId,
    'template_id': templateId,
    'status': 'captured',
    'context_json': '{}',
    'captured_at': 1790000400,
  });
  await insertRow(fixture.db, 'record_fields', <String, Object?>{
    'id': 'value-new',
    'record_id': 'record-new',
    'field_key': 'serial_number',
    'value_raw': 'SN-NEW',
    'source': 'TYPED',
  });
  await insertRow(fixture.db, 'captions', <String, Object?>{
    'id': 'caption-new',
    'owner_type': 'record',
    'owner_id': 'record-new',
    'text_raw': 'New pump',
    'input_mode': 'typed',
  });
  await insertRow(fixture.db, 'photos', <String, Object?>{
    'id': 'photo-new',
    'project_id': fixture.projectId,
    'record_id': 'record-new',
    'relative_path': 'photos/new.jpg',
    'mime_type': 'image/jpeg',
    'file_size': photo.length,
    'sha256': crypto.sha256.convert(photo).toString(),
    'captured_at': 1790000400,
  });
  File('${fixture.root.path}/projects/${fixture.folderName}/photos/new.jpg')
    ..createSync(recursive: true)
    ..writeAsBytesSync(photo);
}

Future<int> _count(sqlite.AppDatabase db, String table) async {
  return (await db.customSelect('SELECT id FROM $table').get()).length;
}

List<Map<String, Object?>> _sorted(List<Map<String, Object?>> rows) {
  return List<Map<String, Object?>>.of(rows)..sort(
    (Map<String, Object?> a, Map<String, Object?> b) =>
        '${a['id']}'.compareTo('${b['id']}'),
  );
}

/// Fails the [failOn]th write, as a full or vanished disk would.
final class _FailOnWrite implements FileWriter {
  _FailOnWrite(this._inner, {required this.failOn});

  final FileWriter _inner;
  final int failOn;
  int _writes = 0;

  @override
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    _writes += 1;
    if (_writes == failOn) {
      return const FailureResult<WrittenFile>(
        StorageFailure(message: 'disk full', recoveryAction: 'free space'),
      );
    }
    return _inner.write(bytes, relativePath);
  }

  @override
  Future<Result<WrittenFile>> copyIn(File source, String relativePath) {
    return _inner.copyIn(source, relativePath);
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

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('expected a failure'),
  };
}
