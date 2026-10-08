import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/integrity_check.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/orphan_scanner.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../core/db/record_rows.dart';

void main() {
  testWidgets(
    'the retired Check files address opens Storage without diagnostics or evidence mutation',
    (WidgetTester tester) async {
      final AppDatabase db = AppDatabase.memory();
      final Directory files = Directory.systemTemp.createTempSync(
        'tapture-retired-check-',
      );
      addTearDown(() async {
        await db.close();
        if (files.existsSync()) files.deleteSync(recursive: true);
      });
      final File raw = File('${files.path}/raw.bin')
        ..writeAsBytesSync(<int>[1, 3, 5, 7, 9]);
      final String beforeHash = sha256
          .convert(raw.readAsBytesSync())
          .toString();
      final List<Map<String, Object?>> before =
          await tester.runAsync(() async {
            await seedField(
              db,
              'field-with-missing-record',
              recordId: 'missing-record',
              fieldKey: 'serial',
              raw: 'Original evidence',
            );
            await seedPhoto(db, 'missing-photo', recordId: 'missing-record');
            return _snapshot(db);
          }) ??
          <Map<String, Object?>>[];
      expect(before, isNotEmpty);
      int scannerReads = 0;
      int integrityReads = 0;
      await tester.pumpWidget(
        ProviderScope(
          retry: (int _, Object _) => null,
          overrides: <Override>[
            appDatabaseProvider.overrideWithValue(db),
            projectSettingsStoreProvider.overrideWithValue(
              SettingsStore.fake(),
            ),
            storageSettingsOverride(cacheBytes: 0),
            orphanScannerProvider.overrideWith((Ref _) {
              scannerReads++;
              return null;
            }),
            integrityCheckProvider.overrideWith((Ref _) {
              integrityReads++;
              return () async =>
                  const Success<List<IntegrityFinding>>(<IntegrityFinding>[]);
            }),
          ],
          child: const TaptureApp(receiveIncomingBundles: false),
        ),
      );
      await tester.pumpAndSettle();
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(TaptureApp)),
      );
      final GoRouter router = container.read(routerProvider);
      router.go(AppRoutes.settingsStorageCheck);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.settingsStorage);
      expect(find.byType(StorageSettingsScreen), findsOneWidget);
      expect(find.text(Copy.storageCheckTitle), findsNothing);
      expect(scannerReads, 0);
      expect(integrityReads, 0);
      final List<Map<String, Object?>>? after = await tester.runAsync(
        () => _snapshot(db),
      );
      expect(after, before);
      expect(sha256.convert(raw.readAsBytesSync()).toString(), beforeHash);
      expect(raw.existsSync(), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<List<Map<String, Object?>>> _snapshot(
  AppDatabase db,
) async => <Map<String, Object?>>[
  for (final QueryRow row
      in await db.customSelect('SELECT * FROM record_fields ORDER BY id').get())
    row.data,
  for (final QueryRow row
      in await db.customSelect('SELECT * FROM audit_log ORDER BY id').get())
    row.data,
  for (final QueryRow row
      in await db.customSelect('SELECT * FROM photos ORDER BY id').get())
    row.data,
  for (final QueryRow row
      in await db.customSelect('SELECT * FROM tombstones ORDER BY id').get())
    row.data,
];
