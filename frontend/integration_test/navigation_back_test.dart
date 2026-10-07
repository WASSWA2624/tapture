import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_back_navigation.dart';
import 'package:tapture/app/widgets/status_line.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android Back returns through project home and Projects before exit',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [networkOnlineOverride()],
          child: const TaptureApp(receiveIncomingBundles: false),
        ),
      );
      await tester.pumpAndSettle();
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(TaptureApp)),
      );
      container.read(openProjectIdProvider.notifier).open('p1');
      final GoRouter router = container.read(routerProvider);
      router.go(RoutePaths.projectDetails('p1'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, RoutePaths.project('p1'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, RoutePaths.projects);
      // Check that the policy yields to native exit without closing the runner.
      expect(
        await ShellBackNavigation.back(tester.element(find.byType(StatusLine))),
        isFalse,
      );
      for (final String root in <String>[
        RoutePaths.captureRoot,
        RoutePaths.records,
        RoutePaths.more,
      ]) {
        router.go(root);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.state.uri.path, RoutePaths.projects);
      }
    },
    skip: kIsWeb || defaultTargetPlatform != TargetPlatform.android,
  );
}
