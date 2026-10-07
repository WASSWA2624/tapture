import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/features/projects/projects.dart';

void main() {
  testWidgets('obsolete filter links redirect without restoring hidden facets', (
    WidgetTester tester,
  ) async {
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
    final GoRouter router = container.read(routerProvider);
    router.go(
      '${RoutePaths.projectFilters}?status=archived&pin=pinned&organisation=stale',
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), RoutePaths.projects);
    expect(container.read(projectListCriteriaProvider).query, isEmpty);
    expect(container.read(projectListCriteriaProvider).showArchived, isFalse);
    expect(
      find.byKey(const ValueKey<String>('route-project-filters')),
      findsNothing,
    );
  });
}
