import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/features/merge/presentation/package_import_controller.dart';

import 'support/harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run on the owned Android emulator. Once DocumentsUI opens, the host saves
  // `adb -s emulator-5554 shell dumpsys activity activities` to verify the real
  // ACTION_OPEN_DOCUMENT, CATEGORY_OPENABLE and application/zip intent, then
  // cancels with `adb -s emulator-5554 shell input keyevent KEYCODE_BACK`.
  testWidgets(
    'cancelling the native Android package picker preserves import and storage',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        final TestApp app = await bootTestApp();
        addTearDown(app.dispose);
        final ProviderContainer container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(app.db)],
        );
        addTearDown(container.dispose);
        final PackageImportController flow = container.read(
          packageImportControllerProvider.notifier,
        );
        expect(container.read(documentPickerProvider).canPick, isTrue);
        final PackageImportView before = container.read(
          packageImportControllerProvider,
        );
        final Map<String, List<Map<String, Object?>>> rows =
            await _databaseRows(app.db);
        final Directory imports = Directory(
          '${(await getTemporaryDirectory()).path}/imports',
        );
        final bool importsExisted = await imports.exists();
        if (!importsExisted) await imports.create(recursive: true);
        final Directory owned = await imports.createTemp('native-picker-');
        addTearDown(() async {
          await owned.delete(recursive: true);
          if (!importsExisted &&
              await imports.exists() &&
              await imports.list().isEmpty) {
            await imports.delete();
          }
        });
        await File(
          '${owned.path}/evidence.zip',
        ).writeAsBytes(const <int>[0x50, 0x4b, 0x03, 0x04, 1, 2, 3, 4]);
        final Map<String, _CacheEntry> files = await _cacheEntries(imports);

        // The production controller supplies BundleFormat's ZIP extension/MIME
        // to the real DocumentPicker; no platform channel is replaced here.
        final Result<PickedDocument> result = await flow.pick();

        expect(result, isA<FailureResult<PickedDocument>>());
        expect(
          (result as FailureResult<PickedDocument>).failure,
          isA<CancelledFailure>(),
        );
        expect(container.read(packageImportControllerProvider), before);
        expect(await _databaseRows(app.db), rows);
        expect(await imports.exists(), isTrue);
        expect(await _cacheEntries(imports), files);
        expect(app.outboundCallCount, 0);
      });
    },
    skip: kIsWeb || defaultTargetPlatform != TargetPlatform.android,
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

Future<Map<String, List<Map<String, Object?>>>> _databaseRows(
  AppDatabase db,
) async {
  final Map<String, List<Map<String, Object?>>> rows =
      <String, List<Map<String, Object?>>>{};
  for (final TableInfo<Table, Object?> table in db.allTables) {
    rows[table.actualTableName] = <Map<String, Object?>>[
      for (final QueryRow row
          in await db
              .customSelect('SELECT * FROM "${table.actualTableName}"')
              .get())
        row.data,
    ];
  }
  return rows;
}

typedef _CacheEntry = ({
  FileSystemEntityType type,
  int bytes,
  DateTime modified,
  String? digest,
});

Future<Map<String, _CacheEntry>> _cacheEntries(Directory imports) async {
  final Map<String, _CacheEntry> entries = <String, _CacheEntry>{};
  if (!await imports.exists()) return entries;
  await for (final FileSystemEntity entry in imports.list(
    recursive: true,
    followLinks: false,
  )) {
    final FileStat stat = await entry.stat();
    entries[entry.path] = (
      type: stat.type,
      bytes: stat.size,
      modified: stat.modified,
      digest: entry is File
          ? (await sha256.bind(entry.openRead()).first).toString()
          : null,
    );
  }
  return entries;
}
