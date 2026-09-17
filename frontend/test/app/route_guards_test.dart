import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';

void main() {
  testWidgets(
    'a capture link with no project asks which project, then continues',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: TaptureApp()));
      await tester.pump();

      final BuildContext context = tester.element(find.byType(TaptureApp));
      final ProviderContainer container = ProviderScope.containerOf(context);
      final GoRouter router = container.read(routerProvider);

      router.go(AppRoutes.capture('p1'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('route-projects')),
        findsOneWidget,
      );
      expect(router.state.uri.path, AppRoutes.projects);
      expect(
        router.state.uri.queryParameters[AppRoutes.fromQuery],
        AppRoutes.capture('p1'),
      );

      container.read(openProjectIdProvider.notifier).open('p1');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('route-capture')),
        findsOneWidget,
      );
      expect(router.state.uri.path, AppRoutes.capture('p1'));
    },
  );

  test('guards divert a project-scoped location without a widget', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final GoRouter router = container.read(routerProvider);
    final GoRouterState state = GoRouterState(
      router.configuration,
      uri: Uri.parse(AppRoutes.capture('p1')),
      matchedLocation: AppRoutes.capture('p1'),
      fullPath: AppRoutes.capture('p1'),
      pathParameters: const <String, String>{'projectId': 'p1'},
      pageKey: const ValueKey<String>('capture'),
      metadata: const <String, dynamic>{'projectScoped': true},
    );

    String? to;
    for (final RouteGuard guard in appGuards()) {
      to = guard(state, _ref(container));
      if (to != null) {
        break;
      }
    }

    final Uri diverted = Uri.parse(to!);
    expect(diverted.path, AppRoutes.projects);
    expect(
      diverted.queryParameters[AppRoutes.fromQuery],
      AppRoutes.capture('p1'),
    );
  });

  test('guards resume once a project is open, without a widget', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(openProjectIdProvider.notifier).open('p1');
    final GoRouter router = container.read(routerProvider);
    final Uri intended = Uri(
      path: AppRoutes.projects,
      queryParameters: <String, String>{
        AppRoutes.fromQuery: AppRoutes.capture('p1'),
      },
    );
    final GoRouterState state = GoRouterState(
      router.configuration,
      uri: intended,
      matchedLocation: AppRoutes.projects,
      fullPath: AppRoutes.projects,
      pathParameters: const <String, String>{},
      pageKey: const ValueKey<String>('projects'),
    );

    String? to;
    for (final RouteGuard guard in appGuards()) {
      to = guard(state, _ref(container));
      if (to != null) {
        break;
      }
    }

    expect(to, AppRoutes.capture('p1'));
  });
}

Ref _ref(ProviderContainer container) {
  late Ref captured;
  container.read(
    Provider<int>((Ref ref) {
      captured = ref;
      return 0;
    }),
  );
  return captured;
}
