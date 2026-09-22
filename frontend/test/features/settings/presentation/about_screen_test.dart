import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/presentation/about_screen.dart';

void main() {
  testWidgets('version, build and licences are shown', (
    WidgetTester tester,
  ) async {
    await _pump(tester, load: () async => (version: '1.0.0', build: '1'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.settingsVersion), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text(Copy.settingsBuild), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text(Copy.settingsLicences), findsOneWidget);
    expect(find.text('The plan'), findsNothing);
    expect(find.text('The specification'), findsNothing);
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
    await _pump(tester, load: () async => (version: '', build: ''));
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.settingsAboutEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, failWith: Exception('The version could not be read.'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Future<({String version, String build})> Function()? load,
  void Function(String url)? openUrl,
  Object? failWith,
  bool pending = false,
}) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        aboutOverride(
          load: load,
          openUrl: openUrl,
          failWith: failWith,
          pending: pending,
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AboutScreen(),
      ),
    ),
  );
}
