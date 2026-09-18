import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';

void main() {
  testWidgets('rows read the store and state the folder-strategy rule', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake();
    await _pump(tester, store: store);
    await tester.pumpAndSettle();

    expect(find.text(Copy.settingsCamera), findsOneWidget);
    expect(find.text(Copy.settingsAutoFillDates), findsOneWidget);
    expect(find.text(Copy.settingsGps), findsOneWidget);
    expect(find.text(Copy.settingsGpsWhyOff), findsOneWidget);
    expect(find.text(Copy.settingsPhotoQuality), findsOneWidget);
    expect(find.text(Copy.settingsFolderStrategy), findsOneWidget);
    expect(
      find.textContaining(Copy.settingsFolderStrategyNewFilesOnly),
      findsOneWidget,
    );
    expect(find.text(Copy.settingsNamingPattern), findsOneWidget);
    expect(store.read(SettingKeys.gpsEnabled), isFalse);

    await tester.tap(find.text(Copy.settingsGps));
    await tester.pumpAndSettle();
    expect(store.read(SettingKeys.gpsEnabled), isTrue);

    await tester.tap(find.text(Copy.settingsFolderStrategy));
    await tester.pumpAndSettle();
    expect(store.read(SettingKeys.folderStrategy), 'byTemplate');
    expect(
      find.textContaining(Copy.settingsFolderStrategyNewFilesOnly),
      findsOneWidget,
    );
  });

  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, pending: true);
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('an empty snapshot renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, store: SettingsStore.fake(), missing: true);
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.settingsCaptureEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      failWith: Exception('Capture defaults could not be read.'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  SettingsStore? store,
  bool missing = false,
  Object? failWith,
  bool pending = false,
}) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        captureSettingsOverride(
          store: store,
          missing: missing,
          failWith: failWith,
          pending: pending,
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const CaptureSettingsScreen(),
      ),
    ),
  );
}
