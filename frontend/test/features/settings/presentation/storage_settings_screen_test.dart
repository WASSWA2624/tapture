import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/cache_cleanup.dart';
import 'package:tapture/core/files/folder_picker.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/volume_stats.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
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

  testWidgets(
    'Storage shows total, used and available beside the headroom words',
    (WidgetTester tester) async {
      const int total = 4 * 1024 * 1024 * 1024;
      const int used = 3 * 1024 * 1024 * 1024;
      const int free = 1 * 1024 * 1024 * 1024;
      const VolumeStats volume = VolumeStats(
        totalBytes: total,
        usedBytes: used,
        freeBytes: free,
      );
      for (final ({ThemeData theme, Size size}) shot
          in <({ThemeData theme, Size size})>[
            (
              theme: buildTheme(brightness: Brightness.light),
              size: const Size(400, 800),
            ),
            (
              theme: buildTheme(brightness: Brightness.dark),
              size: const Size(1200, 800),
            ),
            (
              theme: buildOutdoorTheme(Brightness.light),
              size: const Size(1200, 800),
            ),
          ]) {
        await _pump(
          tester,
          size: shot.size,
          theme: shot.theme,
          textScale: 2,
          store: SettingsStore.fake(),
          volume: volume,
          rootPath: r'D:\Tapture',
        );
        await tester.pump();

        expect(find.text(Copy.settingsVolumeTotal), findsOneWidget);
        expect(find.text(Copy.settingsVolumeUsed), findsOneWidget);
        expect(find.text(Copy.settingsVolumeAvailable), findsOneWidget);
        expect(find.text(Copy.fileSize(total)), findsOneWidget);
        expect(find.text(Copy.fileSize(used)), findsOneWidget);
        expect(find.text(Copy.fileSize(free)), findsOneWidget);
        expect(find.text(Copy.settingsHeadroomAmple), findsOneWidget);
        expect(find.text(Copy.settingsClearCache), findsOneWidget);
        expect(find.text(Copy.settingsRetention), findsOneWidget);
      }
    },
  );

  testWidgets('low and critical volumes keep their words beside the numbers', (
    WidgetTester tester,
  ) async {
    for (final ({int free, String label, HeadroomState headroom}) shot
        in <({int free, String label, HeadroomState headroom})>[
          (
            free: AppConstants.storage.lowBytes - 1,
            label: Copy.settingsHeadroomLow,
            headroom: HeadroomState.low,
          ),
          (
            free: AppConstants.storage.criticalBytes - 1,
            label: Copy.settingsHeadroomCritical,
            headroom: HeadroomState.critical,
          ),
        ]) {
      await _pump(
        tester,
        store: SettingsStore.fake(),
        headroom: shot.headroom,
        volume: VolumeStats(
          totalBytes: shot.free + (2 * 1024 * 1024 * 1024),
          usedBytes: 2 * 1024 * 1024 * 1024,
          freeBytes: shot.free,
        ),
      );
      await tester.pump();
      expect(find.text(shot.label), findsOneWidget);
      expect(find.text(Copy.fileSize(shot.free)), findsOneWidget);
      expect(find.text(Copy.settingsHeadroomAmple), findsNothing);
    }
  });

  testWidgets('a failed volume probe shows the error state with retry', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      store: SettingsStore.fake(),
      failWith: const StorageFailure(
        message: 'Tapture could not read free space on this device.',
        recoveryAction: 'Free up space or export a project, then try again.',
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.tryAgain), findsOneWidget);
    expect(find.textContaining('could not read free space'), findsOneWidget);
    expect(find.text(Copy.settingsHeadroomAmple), findsNothing);
    expect(find.text(Copy.settingsVolumeTotal), findsNothing);
  });

  testWidgets('Storage shows the active root path', (
    WidgetTester tester,
  ) async {
    final Directory temp = Directory.systemTemp.createTempSync(
      'tapture-root-row-',
    );
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    await _pump(
      tester,
      store: SettingsStore.fake(),
      rootPath: '${temp.path}${Platform.pathSeparator}Tapture',
    );
    await tester.pump();
    expect(find.text(Copy.settingsStorageRoot), findsOneWidget);
    expect(find.textContaining('Tapture'), findsWidgets);
  });

  testWidgets('web does not offer a folder picker', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      store: SettingsStore.fake(),
      rootPath: r'D:\Tapture',
      folderPicker: const FolderPicker.fake(canPick: false),
    );
    await tester.pump();
    final AppListTile tile = tester.widget<AppListTile>(
      find.widgetWithText(AppListTile, Copy.settingsStorageRoot),
    );
    expect(tile.onTap, isNull);
  });
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
  FolderPicker? folderPicker,
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
  VolumeStats? volume,
  String? rootPath,
  HeadroomState? headroom,
  Size size = const Size(400, 800),
  ThemeData? theme,
  double textScale = 1,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  return tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        storageSettingsOverride(
          storageRoot: storageRoot,
          storageGuard: storageGuard,
          store: store,
          cacheCleanup: cacheCleanup,
          folderPicker: folderPicker,
          failWith: failWith,
          pending: pending,
          empty: empty,
          projects: projects,
          cacheBytes: cacheBytes,
          volume: volume,
          rootPath: rootPath,
          headroom: headroom,
        ),
        if (storageRoot != null)
          storageRootProvider.overrideWith((Ref _) => storageRoot),
        if (storageGuard != null)
          storageGuardProvider.overrideWith((Ref _) => storageGuard),
        if (folderPicker != null)
          folderPickerProvider.overrideWith((Ref _) => folderPicker),
      ],
      child: MaterialApp(
        theme: theme ?? buildTheme(brightness: Brightness.light),
        home: const StorageSettingsScreen(),
      ),
    ),
  );
}
