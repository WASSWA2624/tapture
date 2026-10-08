import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show QueryRow, Table, TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../../../support/processing_fixture.dart';

/// The provider key reaches secure storage and nothing else: not a table,
/// not a stored request summary, not a file under the storage root and not
/// an entry inside an exported project package or its workbook.
void main() {
  const String secret = 'sk-live-7Qe9-custody-probe';

  test('a saved key never reaches the database or an export', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'GRUNDFOS 240V',
    );
    await fixture.addField('serial', required: true);

    // What the key screen does on save: the key to secure storage, the
    // provider choice to the settings the database holds.
    final Map<SecretKey, String> vault = <SecretKey, String>{};
    final SecureStorage storage = SecureStorage.fake(backing: vault);
    final SettingsStore settings = await SettingsStore.open(
      db: fixture.db,
      deviceId: 'device-a',
      clock: fixture.clock,
    );
    _ok(await storage.putSecret(SecretKey.providerCredential, secret));
    _ok(await settings.write(SettingKeys.aiProvider, 'backend'));

    final ProcessingJob job = await fixture.job();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[
      '{"fields":{"serial":{"value":"SN458923","confidence":0.9,'
          '"evidence":["SN458923"]}}}',
    ]);
    final ProcessingStageWorker worker = fixture.worker(
      provider: provider,
      settings: settings,
    );
    for (final JobStage stage in JobStage.values) {
      await worker.perform(stage, job);
    }
    expect(provider.requests, hasLength(1), reason: 'the record went online');

    final ExportedPackage exported = _ok(
      await ExportRepositoryImpl(
        db: fixture.db,
        storageRoot: fixture.storageRoot,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
        templates: TemplateRepositoryImpl(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
        ),
      ).exportProject(fixture.project.id, cancel: CancellationToken()),
    );

    expect(vault[SecretKey.providerCredential], secret);
    for (final TableInfo<Table, Object?> table in fixture.db.allTables) {
      final List<QueryRow> rows = await fixture.db
          .customSelect('SELECT * FROM ${table.actualTableName}')
          .get();
      for (final QueryRow row in rows) {
        expect(
          row.data.values.join('\u0000'),
          isNot(contains(secret)),
          reason: table.actualTableName,
        );
      }
    }
    final Directory root = _ok(await fixture.storageRoot.resolve());
    final StoredBundle stored = exported.package as StoredBundle;
    final List<int> package = File(
      '${root.path}/${stored.relativePath}',
    ).readAsBytesSync();
    expect(_text(package), isNot(contains(secret)));
    void expectNoSecretIn(List<int> zip) {
      for (final ArchiveFile entry in ZipDecoder().decodeBytes(zip)) {
        if (!entry.isFile) {
          continue;
        }
        final List<int> content = entry.content;
        expect(_text(content), isNot(contains(secret)), reason: entry.name);
        if (entry.name.endsWith('.xlsx')) {
          expectNoSecretIn(content);
        }
      }
    }

    expectNoSecretIn(package);
    for (final File file
        in fixture.documents.listSync(recursive: true).whereType<File>()) {
      expect(
        _text(file.readAsBytesSync()),
        isNot(contains(secret)),
        reason: file.path,
      );
    }
  });
}

String _text(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}
