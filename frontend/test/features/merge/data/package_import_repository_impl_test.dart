import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
import 'package:tapture/features/review/review.dart' show ReviewRepositoryImpl;
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, FieldType, TemplateDef, TemplateJson;

import '../../../support/bundle_fixture.dart';

void main() {
  late BundleFixture source;
  late sqlite.AppDatabase target;
  late Directory targetDocuments;
  late StorageRoot targetRoot;
  late IdService targetIds;

  setUp(() async {
    source = await seedProjectForBundle();
    target = sqlite.AppDatabase.memory();
    targetDocuments = Directory.systemTemp.createTempSync('tapture-import-');
    targetRoot = StorageRoot.fake(documentsDirectory: targetDocuments);
    targetIds = UuidV7Service.sequence(
      FixedClock(DateTime.utc(2026, 9, 28, 10)),
    );
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
      ids: targetIds,
    );
  }

  File targetFile(String folder, String path) =>
      File('${targetDocuments.path}/Tapture/projects/$folder/$path');

  for (final Object declaration in <Object>[
    'FUTURE_SOURCE',
    false,
    42,
    <String, Object?>{'provider': 'future'},
    'LOCAL_ADDRESS',
  ]) {
    test(
      'an imported SQL source $declaration is refused before files or database rows change',
      () async {
        final InspectedBundle checked = await _package(source);
        final InspectedBundle invalid = _sourceVariant(checked, declaration);
        final before = await _storageRows(target);
        final files = _storedFiles(targetDocuments);
        expect(
          await repository().importAsNew(invalid),
          isA<FailureResult<ImportedProject>>(),
        );
        expect(await _storageRows(target), before);
        expect(_storedFiles(targetDocuments), files);
      },
    );
  }
  for (final bool nested in <bool>[false, true]) {
    test(
      'an unsupported ${nested ? 'nested' : 'top-level'} history source cannot import or merge',
      () async {
        final InspectedBundle checked = await _package(source);
        final InspectedBundle invalid = _sourceVariant(
          checked,
          'FUTURE_SOURCE',
          history: true,
          nested: nested,
        );
        expect(
          await repository().importAsNew(invalid),
          isA<FailureResult<ImportedProject>>(),
        );
        expect(await target.select(target.projects).get(), isEmpty);
        expect(_storedFiles(targetDocuments), isEmpty);
        _ok(await repository().importAsNew(checked));
        final MergePlan plan = await _plan(repository(), checked, source);
        final before = await _storageRows(target);
        final files = _storedFiles(targetDocuments);
        expect(
          await repository().merge(
            bundle: invalid,
            projectId: source.projectId,
            plan: plan,
            choices: const <String, ConflictChoice>{},
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
          isA<FailureResult<MergeOutcome>>(),
        );
        expect(await _storageRows(target), before);
        expect(_storedFiles(targetDocuments), files);
      },
    );
  }
  for (final bool primary in <bool>[false, true]) {
    test(
      'an unsupported SQL companion with ${primary ? 'known primary' : 'no primary'} cannot pass package preflight',
      () async {
        final InspectedBundle checked = await _package(source);
        final InspectedBundle invalid = _sourceVariant(checked, 'NOW');
        invalid.rowsOf('template_fields').first['validation'] = jsonEncode(
          <String, Object?>{
            '_tapture': <String, Object?>{
              if (primary) 'autoFill': 'NOW',
              'autoFillTop': <Object?>['future', null],
            },
          },
        );
        expect(
          await repository().importAsNew(invalid),
          isA<FailureResult<ImportedProject>>(),
        );
        expect(await target.select(target.projects).get(), isEmpty);
        expect(_storedFiles(targetDocuments), isEmpty);
        _ok(await repository().importAsNew(checked));
        final MergePlan plan = await _plan(repository(), checked, source);
        final before = await _storageRows(target);
        final files = _storedFiles(targetDocuments);
        expect(
          await repository().merge(
            bundle: invalid,
            projectId: source.projectId,
            plan: plan,
            choices: const <String, ConflictChoice>{},
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
          isA<FailureResult<MergeOutcome>>(),
        );
        expect(await _storageRows(target), before);
        expect(_storedFiles(targetDocuments), files);
      },
    );
  }
  for (final bool update in <bool>[false, true]) {
    test(
      'direct merge ${update ? 'updates' : 'inserts'} cannot bypass source validation or copy files',
      () async {
        final InspectedBundle checked = await _package(source);
        _ok(await repository().importAsNew(checked));
        final MergePlan empty = await _plan(repository(), checked, source);
        final Map<String, Object?> field = checked
            .rowsOf('template_fields')
            .first;
        final Map<String, Object?> invalid = <String, Object?>{
          if (!update) ...field,
          'id': update ? field['id'] : 'field-invalid',
          'validation': '{"_tapture":{"autoFill":"FUTURE_SOURCE"}}',
        };
        final BundleEntry file = checked.manifest.entries.firstWhere(
          (entry) => entry.path.startsWith('photos/'),
        );
        final MergePlan plan = MergePlan(
          inserts: update
              ? const <String, List<Map<String, Object?>>>{}
              : <String, List<Map<String, Object?>>>{
                  'template_fields': <Map<String, Object?>>[invalid],
                },
          updates: update
              ? <String, List<Map<String, Object?>>>{
                  'template_fields': <Map<String, Object?>>[invalid],
                }
              : const <String, List<Map<String, Object?>>>{},
          files: <({String entry, String target})>[
            (entry: file.path, target: 'photos/should-not-copy.jpg'),
          ],
          settled: empty.settled,
          conflicts: empty.conflicts,
          counts: empty.counts,
          insertedRecords: empty.insertedRecords,
        );
        final before = await _storageRows(target);
        final files = _storedFiles(targetDocuments);
        expect(
          await repository().merge(
            bundle: checked,
            projectId: source.projectId,
            plan: plan,
            choices: const <String, ConflictChoice>{},
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
          isA<FailureResult<MergeOutcome>>(),
        );
        expect(await _storageRows(target), before);
        expect(_storedFiles(targetDocuments), files);
      },
    );
  }

  for (final bool history in <bool>[false, true]) {
    test(
      'a partial merge ${history ? 'history' : 'raw flag'} update is checked before file writes',
      () async {
        final InspectedBundle checked = await _package(source);
        _ok(await repository().importAsNew(checked));
        final MergePlan empty = await _plan(repository(), checked, source);
        final InspectedBundle invalid = _sourceVariant(
          checked,
          'FUTURE_SOURCE',
          history: history,
        );
        final String table = history ? 'templates' : 'template_fields';
        final Map<String, Object?> row = checked.rowsOf(table).first;
        final Map<String, Object?> update = <String, Object?>{
          'id': row['id'],
          if (history)
            'detection': invalid.rowsOf(table).first['detection']
          else
            'auto_fill': 'FUTURE_SOURCE',
        };
        final BundleEntry file = checked.manifest.entries.firstWhere(
          (entry) => entry.path.startsWith('photos/'),
        );
        final MergePlan plan = MergePlan(
          inserts: const {},
          updates: <String, List<Map<String, Object?>>>{
            table: <Map<String, Object?>>[update],
          },
          files: <({String entry, String target})>[
            (entry: file.path, target: 'photos/should-not-copy.jpg'),
          ],
          settled: empty.settled,
          conflicts: empty.conflicts,
          counts: empty.counts,
          insertedRecords: empty.insertedRecords,
        );
        final before = await _storageRows(target);
        final files = _storedFiles(targetDocuments);
        expect(
          await repository().merge(
            bundle: checked,
            projectId: source.projectId,
            plan: plan,
            choices: const <String, ConflictChoice>{},
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
          isA<FailureResult<MergeOutcome>>(),
        );
        expect(await _storageRows(target), before);
        expect(_storedFiles(targetDocuments), files);
      },
    );
  }

  for (final int flag in <int>[0, 1]) {
    test(
      'legacy boolean source flag $flag and validation arrays remain valid package data',
      () async {
        await source.db.customStatement(
          'UPDATE template_fields SET auto_fill = ?, validation = ?',
          <Object?>[flag, '["legacy-rule"]'],
        );
        final InspectedBundle checked = await _package(source);
        _ok(await repository().importAsNew(checked));
        final List<QueryRow> fields = await target
            .customSelect('SELECT auto_fill, validation FROM template_fields')
            .get();
        expect(fields, isNotEmpty);
        for (final QueryRow row in fields) {
          expect(row.data['auto_fill'], flag);
          expect(row.data['validation'], '["legacy-rule"]');
        }
      },
    );
  }

  test(
    'a partial merge type update cannot make an existing local address non-text',
    () async {
      final InspectedBundle checked = await _package(source);
      _ok(await repository().importAsNew(checked));
      final MergePlan empty = await _plan(repository(), checked, source);
      await target.customStatement(
        "UPDATE template_fields SET auto_fill = 1, validation = ? WHERE id = 'field-serial'",
        <Object?>['{"_tapture":{"autoFill":"LOCAL_ADDRESS"}}'],
      );
      final MergePlan plan = MergePlan(
        inserts: const {},
        files: empty.files,
        settled: empty.settled,
        conflicts: const [],
        counts: empty.counts,
        insertedRecords: const [],
        updates: const <String, List<Map<String, Object?>>>{
          'template_fields': <Map<String, Object?>>[
            <String, Object?>{'id': 'field-serial', 'type': 'number'},
          ],
        },
      );
      final before = await _storageRows(target);
      final files = _storedFiles(targetDocuments);
      expect(
        await repository().merge(
          bundle: checked,
          projectId: source.projectId,
          plan: plan,
          choices: const <String, ConflictChoice>{},
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ben',
        ),
        isA<FailureResult<MergeOutcome>>(),
      );
      expect(await _storageRows(target), before);
      expect(_storedFiles(targetDocuments), files);
    },
  );

  test(
    'import copies entries through the stream boundary without reading whole originals',
    () async {
      final InspectedBundle checked = await _package(source);
      final List<String> streamed = <String>[];
      final InspectedBundle bundle = InspectedBundle(
        manifest: checked.manifest,
        tables: checked.tables,
        name: checked.name,
        readEntry: (_) async =>
            throw StateError('full entry read is forbidden'),
        openEntry: (String path) async {
          streamed.add(path);
          return checked.openEntry(path);
        },
        close: checked.close,
      );
      final ImportedProject imported = _ok(
        await repository().importAsNew(bundle),
      );
      expect(imported.records, 2);
      expect(streamed, isNotEmpty);
      final sqlite.Project project =
          await (target.select(target.projects)..where(
                (sqlite.$ProjectsTable row) =>
                    row.id.equals(imported.projectId),
              ))
              .getSingle();
      for (final String entry in streamed) {
        final BundleEntry expected = checked.manifest.entries.singleWhere(
          (BundleEntry e) => e.path == entry,
        );
        final File file = targetFile(project.folderName, entry);
        expect(await file.exists(), isTrue);
        expect(
          crypto.sha256.convert(await file.readAsBytes()).toString(),
          expected.sha256,
        );
      }
    },
  );

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

  test(
    'production vectors and full lineage survive import, causal merge and reexport',
    () async {
      final InspectedBundle original = await _package(source);
      final PackageImportRepositoryImpl repo = repository();
      _ok(await repo.importAsNew(original));
      final BundleTables imported = (await BundleTables.read(
        target,
        source.projectId,
      ))!;
      for (final table in original.manifest.versionVectors.entries) {
        for (final entity in table.value.entries) {
          expect(imported.versionVectors[table.key]?[entity.key], entity.value);
        }
      }
      await source.db.customStatement(
        "UPDATE record_fields SET value_final = 'causally newer', rev = rev + 1, "
        "updated_by_device = 'device-test', updated_at = updated_at + 1 WHERE id = 'value-0'",
      );
      final InspectedBundle peer = await _package(source);
      final MergeGround ground = _ok(
        await repo.groundFor(
          projectId: source.projectId,
          incoming: peer.tables,
        ),
      );
      final MergePlan plan = MergePlanner.plan(
        incoming: peer.mergeRows,
        local: ground.local,
        templateMapping: TemplateCompatibility.check(
          incoming: peer.tables,
          local: ground.local,
          sameProject: true,
        ).mapping,
        targetProjectId: source.projectId,
        incomingProjectId: source.projectId,
      );
      expect(plan.conflicts, isEmpty);
      expect(plan.settled.single.rule, SettlementRule.causalFastForward);
      _ok(
        await repo.merge(
          bundle: peer,
          projectId: source.projectId,
          plan: plan,
          choices: const <String, ConflictChoice>{},
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ben',
        ),
      );
      final QueryRow field = await target
          .customSelect(
            "SELECT value_raw, value_final FROM record_fields WHERE id = 'value-0'",
          )
          .getSingle();
      expect(field.data['value_raw'], 'SN-0');
      expect(field.data['value_final'], 'causally newer');
      final BundleTables after = (await BundleTables.read(
        target,
        source.projectId,
      ))!;
      expect(
        after.versionVectors['record_fields']!['value-0']!['device-test'],
        peer
            .manifest
            .versionVectors['record_fields']!['value-0']!['device-test'],
      );
      expect(
        after.versionVectors['record_fields']!['value-0']!['device-b'],
        greaterThan(0),
      );
      final MergePlan repeated = MergePlanner.plan(
        incoming: peer.mergeRows,
        local: after.mergeRows,
        templateMapping: plan.inserts.isEmpty
            ? TemplateCompatibility.check(
                incoming: peer.tables,
                local: after.rows,
                sameProject: true,
              ).mapping
            : const <String, String>{},
        targetProjectId: source.projectId,
        incomingProjectId: source.projectId,
      );
      expect(repeated.isEmpty, isTrue);
      final QueryRow session = await target
          .customSelect(
            "SELECT counts FROM merge_sessions WHERE status = 'applied'",
          )
          .getSingle();
      expect(
        (jsonDecode(session.read<String>('counts'))
            as Map<String, Object?>)['lineage'],
        peer.manifest.toJson()['lineage'],
      );
      final FixedClock exportClock = FixedClock(DateTime.utc(2026, 9, 29));
      final StoredBundle outgoing =
          _ok(
                await BundleWriter(
                  db: target,
                  storageRoot: targetRoot,
                  files: FileReader(storageRoot: targetRoot),
                  clock: exportClock,
                  ids: targetIds,
                  deviceId: 'device-b',
                  device: () async => const DeviceDescriptor.fake(),
                  inBrowser: false,
                ).write(
                  projectId: source.projectId,
                  cancel: CancellationToken(),
                ),
              )
              as StoredBundle;
      final File file = File(
        '${targetDocuments.path}/Tapture/${outgoing.relativePath}',
      );
      final InspectedBundle exported = _ok(
        await BundleReader.inspect(
          PickedFile(file, 'return.zip', file.lengthSync()),
        ),
      );
      addTearDown(exported.close);
      expect(
        exported.manifest.versionVectors['record_fields']!['value-0'],
        after.versionVectors['record_fields']!['value-0'],
      );
      expect(
        exported.manifest.lineage.map((step) => step.device),
        containsAll(<String>['device-test', 'device-b']),
      );
    },
  );

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

  test('records from a package without template versions take their '
      'template\'s version', () async {
    await source.db.customStatement('UPDATE templates SET version = 3');
    final InspectedBundle bundle = await _package(source);
    for (final Map<String, Object?> row in bundle.rowsOf('records')) {
      row.remove('template_version');
    }

    _ok(await repository().importAsNew(bundle));

    final List<QueryRow> records = await target
        .customSelect('SELECT template_version FROM records')
        .get();
    expect(records, hasLength(bundle.rowsOf('records').length));
    expect(<Object?>[
      for (final QueryRow row in records) row.data['template_version'],
    ], everyElement(3));
  });

  test('a package whose reference key repeats brings every row', () async {
    await insertRow(source.db, 'reference_rows', <String, Object?>{
      'id': 'row-ds-global-2',
      'dataset_id': 'ds-global',
      'key_value': 'K1',
      'key_normalised': 'k1',
      'values': '{"site":"B"}',
    });
    final InspectedBundle bundle = await _package(source);

    _ok(await repository().importAsNew(bundle));

    expect(await _referenceRowIds(target, 'ds-global'), <String>[
      'row-ds-global',
      'row-ds-global-2',
    ]);
  });

  test('a reference key this device already repeats keeps its rows and '
      'only new keys are added', () async {
    await insertRow(source.db, 'reference_rows', <String, Object?>{
      'id': 'row-k2',
      'dataset_id': 'ds-global',
      'key_value': 'K2',
      'key_normalised': 'k2',
      'values': '{}',
    });
    await insertRow(target, 'reference_datasets', <String, Object?>{
      'id': 'ds-global',
      'name': 'ds-global',
      'key_column': 'code',
      'columns': '[]',
    });
    for (final String id in <String>['row-here-1', 'row-here-2']) {
      await insertRow(target, 'reference_rows', <String, Object?>{
        'id': id,
        'dataset_id': 'ds-global',
        'key_value': 'K1',
        'key_normalised': 'k1',
        'values': '{"here":"$id"}',
      });
    }
    final InspectedBundle bundle = await _package(source);

    _ok(await repository().importAsNew(bundle));

    expect(await _referenceRowIds(target, 'ds-global'), <String>[
      'row-here-1',
      'row-here-2',
      'row-k2',
    ]);
  });

  group('merging', () {
    setUp(() async {
      _ok(await repository().importAsNew(await _package(source)));
    });

    Future<({InspectedBundle bundle, MergePlan plan})> conflicting() async {
      await source.db.customStatement(
        "UPDATE record_fields SET value_final = 'SN-A', rev = 3 WHERE id = 'value-0'",
      );
      await target.customStatement(
        "UPDATE record_fields SET value_final = 'SN-B', rev = 3 WHERE id = 'value-0'",
      );
      final InspectedBundle bundle = await _package(source);
      return (bundle: bundle, plan: await _plan(repository(), bundle, source));
    }

    test(
      'an entered replacement is validated and stored beside raw evidence',
      () async {
        final opened = await conflicting();
        final FieldConflict conflict = opened.plan.conflicts.single;
        _ok(
          await repository().merge(
            bundle: opened.bundle,
            projectId: source.projectId,
            plan: opened.plan,
            choices: <String, ConflictChoice>{
              conflict.id: ConflictChoice.typed,
            },
            typedValues: <String, String>{conflict.id: 'SN-C'},
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
        );
        final QueryRow value = await target
            .customSelect(
              "SELECT value_raw, value_final, verified_by FROM record_fields WHERE id = 'value-0'",
            )
            .getSingle();
        expect(value.data['value_raw'], 'SN-0');
        expect(value.data['value_final'], 'SN-C');
        expect(value.data['verified_by'], 'Ben');
        expect(
          (await target
                  .customSelect('SELECT resolution FROM merge_conflicts')
                  .getSingle())
              .data['resolution'],
          'typed',
        );
        final List<QueryRow> audit = await target
            .customSelect(
              "SELECT new_value FROM audit_log WHERE reason = 'merge conflict: typed a replacement'",
            )
            .get();
        expect(audit.single.data['new_value'], 'SN-C');
      },
    );

    test(
      'an invalid replacement fails before copying or writing any merge rows',
      () async {
        final opened = await conflicting();
        final FieldConflict conflict = opened.plan.conflicts.single;
        await target.customStatement(
          "UPDATE template_fields SET type = 'number' WHERE field_key = ?",
          <Object?>[conflict.fieldKey],
        );
        final int before = await _count(target, 'merge_sessions');
        final Result<MergeOutcome> result = await repository().merge(
          bundle: opened.bundle,
          projectId: source.projectId,
          plan: opened.plan,
          choices: <String, ConflictChoice>{conflict.id: ConflictChoice.typed},
          typedValues: <String, String>{conflict.id: 'not a number'},
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ben',
        );
        expect(result, isA<FailureResult<MergeOutcome>>());
        expect(
          (result as FailureResult<MergeOutcome>).failure,
          isA<ValidationFailure>(),
        );
        expect(await _count(target, 'merge_sessions'), before);
        expect(await _count(target, 'merge_conflicts'), 0);
      },
    );

    test(
      'deciding later persists an unresolved conflict and blocks approval facts',
      () async {
        final opened = await conflicting();
        final FieldConflict conflict = opened.plan.conflicts.single;
        _ok(
          await repository().merge(
            bundle: opened.bundle,
            projectId: source.projectId,
            plan: opened.plan,
            choices: <String, ConflictChoice>{
              conflict.id: ConflictChoice.later,
            },
            duplicates: const <PossibleDuplicate>[],
            skipped: const <String>{},
            chooser: 'Ben',
          ),
        );
        final QueryRow row = await target
            .customSelect('SELECT resolution, resolved_by FROM merge_conflicts')
            .getSingle();
        expect(row.data['resolution'], isNull);
        expect(row.data['resolved_by'], isNull);
        final facts = _ok(
          await ReviewRepositoryImpl(db: target).facts(conflict.recordId),
        );
        expect(facts.conflicts, contains(conflict.fieldKey));
        expect(
          (await target
                  .customSelect(
                    "SELECT value_final FROM record_fields WHERE id = 'value-0'",
                  )
                  .getSingle())
              .data['value_final'],
          'SN-B',
        );
      },
    );

    test(
      'a persisted snapshot restores database values and recycles only incoming evidence',
      () async {
        final BundleTables before = (await BundleTables.read(
          target,
          source.projectId,
        ))!;
        final Uint8List photo = Uint8List.fromList(
          List<int>.generate(3000, (int i) => i % 256),
        );
        await _addRecordWithPhoto(source, photo);
        await source.db.customStatement(
          "UPDATE record_fields SET value_final = 'fixed', verified = 1, rev = 2 WHERE id = 'value-0'",
        );
        final InspectedBundle bundle = await _package(source);
        final MergePlan plan = await _plan(repository(), bundle, source);
        final MergeOutcome applied = _ok(
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
        final history = await repository().historyRepository
            .watchHistory(source.projectId)
            .first;
        expect(history.first.bundleId, bundle.manifest.bundleId);
        expect(history.first.sourceDevice, bundle.manifest.sourceDeviceId);
        expect(history.first.counts['records'], 1);
        expect(history.first.undoUntil, isNotNull);
        _ok(await repository().historyRepository.undo(applied.sessionId));
        final BundleTables restored = (await BundleTables.read(
          target,
          source.projectId,
        ))!;
        for (final String table in BundleFormat.insertOrder.where(
          (String table) => table != 'audit_log',
        )) {
          List<Map<String, Object?>> payload(List<Map<String, Object?>> rows) =>
              rows
                  .map(
                    (Map<String, Object?> row) => Map<String, Object?>.of(row)
                      ..remove('rev')
                      ..remove('updated_at')
                      ..remove('updated_by_device'),
                  )
                  .toList();
          expect(
            _sorted(payload(restored.rows[table]!)),
            _sorted(payload(before.rows[table]!)),
            reason: table,
          );
        }
        for (final table in before.versionVectors.entries) {
          for (final entity in table.value.entries) {
            for (final counter in entity.value.entries) {
              expect(
                restored.versionVectors[table.key]?[entity.key]?[counter.key],
                greaterThanOrEqualTo(counter.value),
              );
            }
          }
        }
        expect(
          targetFile(source.folderName, 'photos/new.jpg').existsSync(),
          isFalse,
        );
        expect(
          File(
            '${targetDocuments.path}/Tapture/.recycle/merge-${applied.sessionId}/projects/${source.folderName}/photos/new.jpg',
          ).readAsBytesSync(),
          photo,
        );
        expect(
          File(
            '${targetDocuments.path}/Tapture/.recycle/merge-${applied.sessionId}/snapshot.json',
          ).existsSync(),
          isTrue,
        );
        expect(
          (await repository().historyRepository
                  .watchHistory(source.projectId)
                  .first)
              .first
              .undoUntil,
          isNull,
        );
        expect(
          (await target
                  .customSelect(
                    "SELECT COUNT(*) AS n FROM audit_log WHERE field_key = 'merge_undo'",
                  )
                  .getSingle())
              .data['n'],
          1,
        );
        for (final MapEntry<String, Uint8List> entry in source.files.entries) {
          expect(
            targetFile(source.folderName, entry.key).readAsBytesSync(),
            entry.value,
          );
        }
      },
    );

    test('undo refuses to overwrite an edit made after the merge', () async {
      final opened = await conflicting();
      final FieldConflict conflict = opened.plan.conflicts.single;
      final MergeOutcome applied = _ok(
        await repository().merge(
          bundle: opened.bundle,
          projectId: source.projectId,
          plan: opened.plan,
          choices: <String, ConflictChoice>{conflict.id: ConflictChoice.theirs},
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ben',
        ),
      );
      await target.customStatement(
        "UPDATE record_fields SET value_final = 'later edit', rev = rev + 1 WHERE id = 'value-0'",
      );
      expect(
        await repository().historyRepository.undo(applied.sessionId),
        isA<FailureResult<void>>(),
      );
      expect(
        (await target
                .customSelect(
                  "SELECT value_final FROM record_fields WHERE id = 'value-0'",
                )
                .getSingle())
            .data['value_final'],
        'later edit',
      );
      expect(
        (await target
                .customSelect(
                  'SELECT status FROM merge_sessions WHERE id = ?',
                  variables: <Variable<Object>>[
                    Variable<String>(applied.sessionId),
                  ],
                )
                .getSingle())
            .data['status'],
        'applied',
      );
    });

    test(
      'bootstrap recovers an interrupted undo before exposing project evidence',
      () async {
        final Uint8List photo = Uint8List.fromList(
          List<int>.generate(3000, (int i) => (i * 13) % 256),
        );
        await _addRecordWithPhoto(source, photo);
        final InspectedBundle bundle = await _package(source);
        final MergePlan plan = await _plan(repository(), bundle, source);
        final MergeOutcome applied = _ok(
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
        final sqlite.MergeSession session =
            await (target.select(target.merge)..where(
                  (sqlite.$MergeTable row) => row.id.equals(applied.sessionId),
                ))
                .getSingle();
        final PackageFiles files = PackageFiles(storageRoot: targetRoot);
        final String original = 'projects/${source.folderName}/photos/new.jpg';
        final String recycled = '.recycle/merge-${applied.sessionId}/$original';
        final String retained =
            '.recycle/merge-${applied.sessionId}/snapshot.json';
        await target.customStatement(
          "UPDATE merge_sessions SET counts = json_set(counts, '\$.undo_journal', ?) WHERE id = ?",
          <Object?>['${session.undoSnapshotPath}.undo', applied.sessionId],
        );
        _ok(
          await files.write('${session.undoSnapshotPath}.undo', Uint8List(0)),
        );
        await files.move(original, recycled);
        await files.move(session.undoSnapshotPath, retained);
        expect(
          targetFile(source.folderName, 'photos/new.jpg').existsSync(),
          isFalse,
        );
        _ok(await repository().historyRepository.recoverInterruptedUndo());
        _ok(await repository().historyRepository.recoverInterruptedUndo());
        expect(
          targetFile(source.folderName, 'photos/new.jpg').readAsBytesSync(),
          photo,
        );
        expect(await files.exists(session.undoSnapshotPath), isTrue);
        expect(await files.exists('${session.undoSnapshotPath}.undo'), isFalse);
        expect(
          (await target.select(target.merge).get())
              .where((sqlite.MergeSession row) => row.id == applied.sessionId)
              .single
              .status,
          'applied',
        );
        _ok(await repository().historyRepository.undo(applied.sessionId));
        await target.customStatement(
          "UPDATE merge_sessions SET counts = json_set(counts, '\$.undo_journal', ?) WHERE id = ?",
          <Object?>['${session.undoSnapshotPath}.undo', applied.sessionId],
        );
        _ok(
          await files.write('${session.undoSnapshotPath}.undo', Uint8List(0)),
        );
        _ok(await repository().historyRepository.recoverInterruptedUndo());
        expect(
          targetFile(source.folderName, 'photos/new.jpg').existsSync(),
          isFalse,
        );
        expect(await files.exists(retained), isTrue);
        expect(await files.exists('${session.undoSnapshotPath}.undo'), isFalse);
      },
    );

    test(
      'a failed undo rolls back database changes and moves incoming evidence back',
      () async {
        final Uint8List photo = Uint8List.fromList(
          List<int>.generate(3000, (int i) => (i * 13) % 256),
        );
        await _addRecordWithPhoto(source, photo);
        final InspectedBundle bundle = await _package(source);
        final MergePlan plan = await _plan(repository(), bundle, source);
        final MergeOutcome applied = _ok(
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
        await target.customStatement(
          "CREATE TRIGGER deny_undo BEFORE DELETE ON records WHEN OLD.id = 'record-new' "
          "BEGIN SELECT RAISE(ABORT, 'fixture refusal'); END",
        );
        expect(
          await repository().historyRepository.undo(applied.sessionId),
          isA<FailureResult<void>>(),
        );
        expect(
          targetFile(source.folderName, 'photos/new.jpg').readAsBytesSync(),
          photo,
        );
        expect(
          (await target
                  .customSelect(
                    "SELECT COUNT(*) AS n FROM records WHERE id = 'record-new'",
                  )
                  .getSingle())
              .data['n'],
          1,
        );
        expect(
          (await target.select(target.merge).get())
              .where((sqlite.MergeSession row) => row.id == applied.sessionId)
              .single
              .status,
          'applied',
        );
      },
    );

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

    test(
      'a transcript merges once: its segments never double, and edits '
      'made on both devices resolve by when they were written, audited',
      () async {
        Future<void> mergeAll(InspectedBundle bundle, MergePlan plan) async {
          _ok(
            await repository().merge(
              bundle: bundle,
              projectId: source.projectId,
              plan: plan,
              choices: const <String, ConflictChoice>{},
              typedValues: const <String, String>{},
              duplicates: const <PossibleDuplicate>[],
              skipped: const <String>{},
              chooser: 'Ben',
            ),
          );
        }

        await _addTranscript(source);
        final InspectedBundle first = await _package(source);
        await mergeAll(first, await _plan(repository(), first, source));
        expect(await _count(target, 'transcripts'), 1);
        expect(await _segmentTexts(target), <String>['the pump', 'is loud']);

        // Both devices edit the transcript; this one first.
        await target.customStatement(
          "UPDATE transcripts SET text_edited = 'Target edit', "
          "edited_at = 1790000500, rev = rev + 1, updated_by_device = 'device-b' "
          "WHERE id = 't-merge'",
        );
        await source.db.customStatement(
          "UPDATE transcripts SET text_edited = 'Source edit', "
          "edited_at = 1790000600, rev = rev + 1 WHERE id = 't-merge'",
        );
        final InspectedBundle second = await _package(source);
        final MergePlan plan = await _plan(repository(), second, source);
        expect(plan.conflicts, isEmpty);
        expect(plan.inserts['transcript_segments'], isNull);
        await mergeAll(second, plan);

        final QueryRow merged = await target
            .customSelect(
              "SELECT text_edited, edited_at FROM transcripts WHERE id = 't-merge'",
            )
            .getSingle();
        expect(merged.data['text_edited'], 'Source edit');
        expect(merged.data['edited_at'], 1790000600);
        expect(await _segmentTexts(target), <String>['the pump', 'is loud']);
        final List<QueryRow> audit = await target
            .customSelect(
              'SELECT previous_value, new_value FROM audit_log '
              "WHERE entity_type = 'transcripts' AND entity_id = 't-merge' "
              "AND field_key = 'text_edited'",
            )
            .get();
        expect(audit.single.data['previous_value'], 'Target edit');
        expect(audit.single.data['new_value'], 'Source edit');

        // The same package again changes nothing.
        final MergePlan again = await _plan(repository(), second, source);
        expect(again.inserts['transcripts'], isNull);
        expect(again.inserts['transcript_segments'], isNull);
        expect(again.updates['transcripts'], isNull);
      },
    );
  });
}

/// Adds finished standalone transcript `t-merge` to [fixture]'s project
/// with two raw segments.
Future<void> _addTranscript(BundleFixture fixture) async {
  await insertRow(fixture.db, 'transcripts', <String, Object?>{
    'id': 't-merge',
    'project_id': fixture.projectId,
    'owner_kind': 'standalone',
    'audio_path': 'projects/${fixture.folderName}/audio/t-merge.wav',
    'language_tag': 'en',
    'model_id': 'tiny-q5_1',
    'status': 'complete',
    'started_at': 1790000400,
    'covered_ms': 2000,
  });
  for (final (int seq, String text) in <(int, String)>[
    (1, 'the pump'),
    (2, 'is loud'),
  ]) {
    await insertRow(fixture.db, 'transcript_segments', <String, Object?>{
      'id': 't-merge-$seq',
      'transcript_id': 't-merge',
      'seq': seq,
      'start_ms': (seq - 1) * 1000,
      'end_ms': seq * 1000,
      'text_raw': text,
    });
  }
}

/// The raw segment texts [db] holds, in reading order.
Future<List<String>> _segmentTexts(sqlite.AppDatabase db) async {
  return <String>[
    for (final QueryRow row
        in await db
            .customSelect(
              'SELECT text_raw FROM transcript_segments ORDER BY start_ms, seq',
            )
            .get())
      row.data['text_raw']! as String,
  ];
}

InspectedBundle _sourceVariant(
  InspectedBundle bundle,
  Object declaration, {
  bool history = false,
  bool nested = false,
}) {
  final Map<String, List<Map<String, Object?>>> tables =
      <String, List<Map<String, Object?>>>{
        for (final table in bundle.tables.entries)
          table.key: <Map<String, Object?>>[
            for (final row in table.value) Map<String, Object?>.of(row),
          ],
      };
  if (history) {
    final Map<String, Object?> snapshot = TemplateJson.encode(
      const TemplateDef(
        id: '',
        templateKey: 'history',
        name: 'History',
        version: 1,
        fields: <FieldDef>[
          FieldDef(
            fieldKey: 'serial_number',
            label: 'Serial',
            type: FieldType.text,
          ),
        ],
        identityFieldKeys: <String>[],
        rows: [],
      ),
    );
    final Map<String, Object?> field =
        (snapshot['fields']! as List).first as Map<String, Object?>;
    if (nested) {
      field['auto_fill'] = 'NOW';
      field['validation'] = <String, Object?>{
        '_tapture': <String, Object?>{'autoFill': declaration},
      };
    } else {
      field['auto_fill'] = declaration;
    }
    tables['templates']!.first['detection'] = jsonEncode(<String, Object?>{
      '_tapture_versions': <String, Object?>{'1': snapshot},
    });
  } else {
    tables['template_fields']!.first.addAll(<String, Object?>{
      'type': declaration == 'LOCAL_ADDRESS' ? 'number' : 'text',
      'auto_fill': 1,
      'validation': jsonEncode(<String, Object?>{
        '_tapture': <String, Object?>{'autoFill': declaration},
      }),
    });
  }
  return InspectedBundle(
    manifest: bundle.manifest,
    tables: tables,
    name: bundle.name,
    readEntry: bundle.readEntry,
    openEntry: bundle.openEntry,
    close: bundle.close,
  );
}

Future<Map<String, List<Map<String, Object?>>>> _storageRows(
  sqlite.AppDatabase db,
) async {
  final Map<String, List<Map<String, Object?>>> rows =
      <String, List<Map<String, Object?>>>{};
  for (final String table in <String>{
    ...BundleFormat.insertOrder,
    'merge_sessions',
    'merge_conflicts',
    'version_vectors',
  }) {
    rows[table] = <Map<String, Object?>>[
      for (final QueryRow row
          in await db.customSelect('SELECT * FROM $table ORDER BY id').get())
        row.data,
    ];
  }
  return rows;
}

Map<String, String> _storedFiles(Directory root) => <String, String>{
  for (final File file in root.listSync(recursive: true).whereType<File>())
    file.path.substring(root.path.length): crypto.sha256
        .convert(file.readAsBytesSync())
        .toString(),
};

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

Future<List<String>> _referenceRowIds(
  sqlite.AppDatabase db,
  String datasetId,
) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT id FROM reference_rows WHERE dataset_id = ? ORDER BY id',
        variables: <Variable<Object>>[Variable<String>(datasetId)],
      )
      .get();
  return <String>[for (final QueryRow row in rows) row.data['id']! as String];
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

  @override
  Future<Result<WrittenFile>> adoptStaged(File staging, String relativePath) {
    return _inner.adoptStaged(staging, relativePath);
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
