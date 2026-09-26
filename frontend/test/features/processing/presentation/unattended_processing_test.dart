import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/network/connectivity_service.dart';
import 'package:tapture/features/processing/presentation/unattended_processing.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  testWidgets('with both settings off nothing ever starts', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: SettingsStore.fake());
    await paths.background(tester);
    paths.net(NetworkState.offline);
    paths.net(NetworkState.online);
    paths.plugIn();
    await tester.pump(const Duration(minutes: 10));
    expect(paths.runs, isEmpty);
    await paths.dispose(tester);
  });

  testWidgets('a connection gain in the background processes once', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto());
    paths.net(NetworkState.offline);
    await paths.background(tester);
    paths.net(NetworkState.online);
    await tester.pump();
    expect(paths.runs, <String>['processAll']);
    await paths.dispose(tester);
  });

  testWidgets('nothing runs while the app is in front', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(ocr: true));
    paths.net(NetworkState.offline);
    paths.net(NetworkState.online);
    paths.plugIn();
    await tester.pump(const Duration(minutes: 10));
    expect(paths.runs, isEmpty);
    await paths.dispose(tester);
  });

  testWidgets('Wi-Fi only refuses a metered connection', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto());
    paths.net(NetworkState.offline);
    await paths.background(tester);
    paths.net(NetworkState.metered);
    await tester.pump();
    expect(paths.runs, isEmpty);

    // Moving from metered to Wi-Fi is the gain that may start work.
    paths.net(NetworkState.online);
    await tester.pump();
    expect(paths.runs, <String>['processAll']);
    await paths.dispose(tester);
  });

  testWidgets('a metered connection is used when Wi-Fi only is off', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(wifiOnly: false));
    paths.net(NetworkState.offline);
    await paths.background(tester);
    paths.net(NetworkState.metered);
    await tester.pump();
    expect(paths.runs, <String>['processAll']);
    await paths.dispose(tester);
  });

  testWidgets('the daily cap holds automatic processing back', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(), underCap: false);
    paths.net(NetworkState.offline);
    await paths.background(tester);
    paths.net(NetworkState.online);
    await tester.pump();
    expect(paths.runs, isEmpty);
    await paths.dispose(tester);
  });

  testWidgets('losing the network stops automatic processing', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(), hold: true);
    paths.net(NetworkState.offline);
    await paths.background(tester);
    paths.net(NetworkState.online);
    await tester.pump();
    expect(paths.unattended.running, UnattendedRun.automatic);

    paths.net(NetworkState.offline);
    await tester.pump();
    expect(paths.cancels, 1);
    await paths.dispose(tester);
  });

  testWidgets('on-device reading waits for charging and idle, then runs', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(ocr: true));
    paths.plugIn();
    await paths.background(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(paths.runs, isEmpty, reason: 'not idle yet');

    await tester.pump(const Duration(minutes: 2));
    expect(paths.runs, <String>['readOnDevice']);
    await paths.dispose(tester);
  });

  testWidgets('on-device reading never runs off the charger', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(ocr: true));
    await paths.background(tester);
    await tester.pump(const Duration(minutes: 5));
    expect(paths.runs, isEmpty);
    await paths.dispose(tester);
  });

  testWidgets('a resume stops on-device reading at once', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(ocr: true), hold: true);
    paths.plugIn();
    await paths.background(tester);
    await tester.pump(const Duration(minutes: 3));
    expect(paths.unattended.running, UnattendedRun.onDevice);

    paths.lifecycle.add(AppLifecycleState.resumed);
    await tester.pump();
    expect(paths.cancels, 1);
    await paths.dispose(tester);
  });

  testWidgets('unplugging stops on-device reading', (
    WidgetTester tester,
  ) async {
    final _Paths paths = _Paths(settings: _auto(ocr: true), hold: true);
    paths.plugIn();
    await paths.background(tester);
    await tester.pump(const Duration(minutes: 3));
    paths.charging.add(false);
    await tester.pump();
    expect(paths.cancels, 1);
    await paths.dispose(tester);
  });
}

SettingsStore _auto({bool wifiOnly = true, bool ocr = false}) {
  return SettingsStore.fake(
    stored: <String, Object?>{
      SettingKeys.aiAutoProcess.name: !ocr,
      SettingKeys.aiWifiOnly.name: wifiOnly,
      SettingKeys.aiOpportunisticOcr.name: ocr,
    },
  );
}

/// The paths over hand-driven signals. With [hold], a started run waits
/// until it is cancelled, so a test can see it stopped.
final class _Paths {
  _Paths({
    required SettingsStore settings,
    bool underCap = true,
    bool hold = false,
  }) {
    unattended = UnattendedProcessing(
      network: network.stream,
      lifecycle: lifecycle.stream,
      charging: charging.stream,
      settings: settings,
      underCap: () async => underCap,
      processAll: () => _run('processAll', hold),
      readOnDevice: () => _run('readOnDevice', hold),
      cancel: () {
        cancels++;
        _stopped?.complete();
      },
    )..start();
  }

  final StreamController<NetworkState> network =
      StreamController<NetworkState>.broadcast(sync: true);
  final StreamController<AppLifecycleState> lifecycle =
      StreamController<AppLifecycleState>.broadcast(sync: true);
  final StreamController<bool> charging = StreamController<bool>.broadcast(
    sync: true,
  );
  late final UnattendedProcessing unattended;
  final List<String> runs = <String>[];
  int cancels = 0;
  Completer<void>? _stopped;

  Future<void> _run(String name, bool hold) async {
    runs.add(name);
    if (hold) {
      _stopped = Completer<void>();
      await _stopped!.future;
    }
  }

  void net(NetworkState state) => network.add(state);

  void plugIn() => charging.add(true);

  Future<void> background(WidgetTester tester) async {
    lifecycle.add(AppLifecycleState.paused);
    await tester.pump();
  }

  Future<void> dispose(WidgetTester tester) async {
    unawaited(unattended.dispose());
    await tester.pump();
  }
}
