import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

void main() {
  testWidgets('the switch is the only writer of the offline flag', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake();
    await _pumpSwitch(tester, store);

    expect(store.read(SettingKeys.offlineByChoice), isFalse);
    expect(find.text(Copy.settingsOfflineEffect), findsOneWidget);

    await tester.tap(find.byType(AppSwitchTile));
    await tester.pumpAndSettle();

    expect(store.read(SettingKeys.offlineByChoice), isTrue);
    expect(
      _flagWritesInLib().single,
      endsWith('features/settings/presentation/offline_switch.dart'),
    );
  });

  testWidgets(
    'a recording boundary sends nothing while the switch is on and drains on release',
    (WidgetTester tester) async {
      final SettingsStore store = SettingsStore.fake();
      final StreamController<NetworkState> radio =
          StreamController<NetworkState>(sync: true);
      addTearDown(radio.close);
      final List<({String path, String body})> sent =
          <({String path, String body})>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            offlineStoreOverride(store),
            _foldedRadio(radio.stream),
          ],
          child: MaterialApp(
            theme: buildTheme(brightness: Brightness.light),
            home: const Scaffold(body: OfflineSwitch()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(OfflineSwitch)),
      );
      final OutboundQueue queue = OutboundQueue(
        network: container.read(connectivityServiceProvider).watch(),
        send: (String path, String body) async {
          sent.add((path: path, body: body));
        },
      );
      addTearDown(queue.dispose);

      radio.add(NetworkState.online);
      await queue.submit(path: '/one', body: 'keep');
      expect(sent, hasLength(1));

      await tester.tap(find.byType(AppSwitchTile));
      await tester.pumpAndSettle();
      expect(store.read(SettingKeys.offlineByChoice), isTrue);

      await queue.submit(path: '/two', body: 'held');
      expect(sent, hasLength(1));
      expect(queue.pending, 1);

      await tester.tap(find.byType(AppSwitchTile));
      await tester.pumpAndSettle();
      expect(store.read(SettingKeys.offlineByChoice), isFalse);
      expect(sent, hasLength(2));
      expect(sent.last.body, 'held');
      expect(queue.pending, 0);
    },
  );

  testWidgets('a stored choice is offline before the switch is touched', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.offlineByChoice.name: true},
    );
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    final List<({String path, String body})> sent =
        <({String path, String body})>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          offlineStoreOverride(store),
          _foldedRadio(radio.stream),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const Scaffold(body: OfflineSwitch()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(OfflineSwitch)),
    );
    final OutboundQueue queue = OutboundQueue(
      network: container.read(connectivityServiceProvider).watch(),
      send: (String path, String body) async {
        sent.add((path: path, body: body));
      },
    );
    addTearDown(queue.dispose);

    radio.add(NetworkState.online);
    await queue.submit(path: '/boot', body: 'held');
    expect(sent, isEmpty);
    expect(queue.pending, 1);
    expect(find.text(Copy.settingsOfflineTitle), findsOneWidget);
  });
}

Future<void> _pumpSwitch(WidgetTester tester, SettingsStore store) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[offlineStoreOverride(store)],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const Scaffold(body: OfflineSwitch()),
      ),
    ),
  );
}

Override _foldedRadio(Stream<NetworkState> radio) {
  return connectivityServiceProvider.overrideWith((Ref ref) {
    final StreamController<bool> override = StreamController<bool>(sync: true);
    final ConnectivityService service = ConnectivityService.fake(
      source: radio,
      offlineOverride: override.stream,
    );
    override.add(ref.read(offlineByChoiceProvider));
    ref.listen<bool>(offlineByChoiceProvider, (bool? _, bool next) {
      if (!override.isClosed) {
        override.add(next);
      }
    });
    ref.onDispose(() {
      unawaited(override.close());
      unawaited(service.dispose());
    });
    return service;
  });
}

List<String> _flagWritesInLib() {
  final List<String> writers = <String>[];
  for (final File file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final String source = file.readAsStringSync();
    if (source.contains('SettingKeys.offlineByChoice') &&
        source.contains('.write(')) {
      writers.add(file.path.replaceAll(r'\', '/').split('frontend/').last);
    }
  }
  writers.sort();
  return writers;
}
