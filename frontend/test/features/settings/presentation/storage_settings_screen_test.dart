import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/cache_cleanup.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';

void main() {
  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, pending: true);
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('an empty tree renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, empty: true);
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.settingsStorageEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, failWith: Exception('Storage could not be read.'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('with a resolvable root, Storage shows the real cache size', (
    WidgetTester tester,
  ) async {
    final Directory temp = Directory.systemTemp.createTempSync('tapture-304-');
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    const int cacheBytes = 48;
    final StorageRoot storageRoot = StorageRoot.fake(documentsDirectory: temp);
    await tester.runAsync(() async {
      final Result<Directory> resolved = await storageRoot.resolve();
      final Directory root = resolved.fold((Failure failure) {
        fail('${failure.message} ${failure.recoveryAction}');
      }, (Directory directory) => directory);
      File(
        '${root.path}/.cache/seed.bin',
      ).writeAsBytesSync(List<int>.filled(cacheBytes, 7));
      File('${root.path}/projects/alpha/photos/shot.jpg')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(24, 1));
    });

    await _pump(
      tester,
      store: SettingsStore.fake(),
      storageRoot: storageRoot,
      storageGuard: StorageGuard.fake(
        storageRoot: storageRoot,
        freeBytes: () => 1 << 30,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsNothing);
    expect(find.byType(AppSkeleton), findsNothing);
    expect(
      find.textContaining(Copy.settingsCacheSize(Copy.fileSize(cacheBytes))),
      findsOneWidget,
    );
    expect(
      find.textContaining(Copy.settingsCacheSize(Copy.fileSize(0))),
      findsNothing,
    );
    expect(find.text('alpha'), findsOneWidget);
  });

  testWidgets('an unwritable root still shows retention', (
    WidgetTester tester,
  ) async {
    final Directory temp = Directory('build/286-storage')
      ..createSync(recursive: true);
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    await _pump(
      tester,
      store: SettingsStore.fake(),
      storageRoot: StorageRoot.fake(documentsDirectory: temp, writable: false),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsNothing);
    expect(find.text(Copy.settingsRetention), findsOneWidget);
  });

  testWidgets(
    'clearing the cache deletes no original file and updates totals',
    (WidgetTester tester) async {
      final Directory temp = Directory('build/079-cache')
        ..createSync(recursive: true);
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final File original = File(
        '${temp.path}/Tapture/projects/alpha/photos/original.jpg',
      );
      final File cached = File('${temp.path}/Tapture/.cache/thumb.bin');
      original.parent.createSync(recursive: true);
      cached.parent.createSync(recursive: true);
      original.writeAsBytesSync(List<int>.filled(100, 1));
      cached.writeAsBytesSync(List<int>.filled(40, 2));

      await _pump(
        tester,
        store: SettingsStore.fake(),
        cacheCleanup: _CacheDelete(cached),
        projects:
            const <
              ({
                String name,
                int photosBytes,
                int documentsBytes,
                int audioBytes,
                int exportsBytes,
              })
            >[
              (
                name: 'alpha',
                photosBytes: 100,
                documentsBytes: 0,
                audioBytes: 0,
                exportsBytes: 0,
              ),
            ],
        cacheBytes: 40,
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('alpha'), findsOneWidget);
      expect(find.textContaining(Copy.fileSize(100)), findsWidgets);
      expect(find.textContaining(Copy.fileSize(40)), findsOneWidget);
      expect(original.existsSync(), isTrue);
      expect(cached.existsSync(), isTrue);

      await tester.tap(find.text(Copy.settingsClearCache));
      await tester.pump();
      await tester.pump();
      expect(find.text(Copy.settingsClearCacheTitle), findsOneWidget);
      await tester.tap(find.text(Copy.settingsClearCache).last);
      await tester.pump();
      await tester.pump();

      expect(original.existsSync(), isTrue);
      expect(cached.existsSync(), isFalse);
      expect(original.readAsBytesSync(), List<int>.filled(100, 1));
      expect(find.textContaining(Copy.fileSize(0)), findsWidgets);
    },
  );
}

class _CacheDelete implements CacheCleanup {
  _CacheDelete(this._cached);

  final File _cached;

  @override
  Future<Result<int>> prune({Duration? maxAge, int? maxBytes}) async {
    if (!_cached.existsSync()) {
      return const Success<int>(0);
    }
    final int size = _cached.statSync().size;
    _cached.deleteSync();
    return Success<int>(size);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  StorageRoot? storageRoot,
  StorageGuard? storageGuard,
  SettingsStore? store,
  CacheCleanup? cacheCleanup,
  Object? failWith,
  bool pending = false,
  bool empty = false,
  List<
    ({
      String name,
      int photosBytes,
      int documentsBytes,
      int audioBytes,
      int exportsBytes,
    })
  >?
  projects,
  int? cacheBytes,
}) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        storageSettingsOverride(
          storageRoot: storageRoot,
          storageGuard: storageGuard,
          store: store,
          cacheCleanup: cacheCleanup,
          failWith: failWith,
          pending: pending,
          empty: empty,
          projects: projects,
          cacheBytes: cacheBytes,
        ),
        if (storageRoot != null)
          storageRootProvider.overrideWith((Ref _) => storageRoot),
        if (storageGuard != null)
          storageGuardProvider.overrideWith((Ref _) => storageGuard),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const StorageSettingsScreen(),
      ),
    ),
  );
}
