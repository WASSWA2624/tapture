import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/feedback/domain/feedback_origin.dart';
import 'package:tapture/features/feedback/presentation/feedback_overlay.dart';

void main() {
  testWidgets('feedback names Appearance with route name settingsAppearance', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);

    router.go(AppRoutes.settingsAppearance);
    await tester.pumpAndSettle();

    final FeedbackOrigin origin = _origin(tester);
    expect(origin.screen, Copy.settingsAppearanceTitle);
    expect(origin.routeName, 'settingsAppearance');
    expect(origin.route, AppRoutes.settingsAppearance);
  });

  testWidgets('every settings page is filed under its own name', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);

    for (final ({String path, String name, String screen}) page
        in <({String path, String name, String screen})>[
          (
            path: AppRoutes.settingsLanguage,
            name: 'settingsLanguage',
            screen: Copy.settingsLanguageTitle,
          ),
          (
            path: AppRoutes.settingsFiles,
            name: 'settingsFiles',
            screen: Copy.settingsFilesTitle,
          ),
          (
            path: AppRoutes.recycleBin,
            name: 'recycleBin',
            screen: Copy.recycleBinTitle,
          ),
        ]) {
      router.go(page.path);
      await tester.pumpAndSettle();

      final FeedbackOrigin origin = _origin(tester);
      expect(origin.routeName, page.name, reason: page.path);
      expect(origin.screen, page.screen, reason: page.path);
    }
  });

  testWidgets('the origin follows the router without a rebuild of the app', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);
    expect(_origin(tester).routeName, 'projects');

    router.go(AppRoutes.more);
    await tester.pumpAndSettle();

    expect(_origin(tester).routeName, 'more');
    expect(_origin(tester).screen, Copy.navMore);
  });
}

FeedbackOrigin _origin(WidgetTester tester) {
  return tester.widget<FeedbackOverlay>(find.byType(FeedbackOverlay)).origin;
}

Future<GoRouter> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[networkOnlineOverride()],
      child: const TaptureApp(),
    ),
  );
  await tester.pumpAndSettle();
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(TaptureApp)),
  );
  return container.read(routerProvider);
}
