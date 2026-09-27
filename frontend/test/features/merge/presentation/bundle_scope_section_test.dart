import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/merge/presentation/bundle_scope_section.dart';
import 'package:tapture/features/merge/presentation/bundle_share_actions.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The bundle could not be prepared.',
    recoveryAction: 'Try again.',
  );

  testWidgets('each scope shows its size', (WidgetTester tester) async {
    BundleScopeKind? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: BundleScopeSection(
          selected: BundleScopeKind.withoutPhotos,
          sizeLabel: '2 MB',
          onSelect: (BundleScopeKind kind) => chosen = kind,
        ),
      ),
    );
    expect(find.text(Copy.bundleSize('2 MB')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('bundle-scope-full')));
    await tester.pump();
    expect(chosen, BundleScopeKind.full);
  });

  testWidgets('scope empty and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BundleScopeSection()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: BundleScopeSection(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('share and open go through the callbacks', (
    WidgetTester tester,
  ) async {
    String? shared;
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BundleShareActions(
          path: 'project.tapture',
          onShare: (String path) => shared = path,
          onOpen: () => opened = true,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('bundle-share')));
    await tester.tap(find.byKey(const ValueKey<String>('bundle-open')));
    await tester.pump();
    expect(shared, 'project.tapture');
    expect(opened, isTrue);
    await tester.pumpWidget(
      const MaterialApp(home: BundleShareActions(empty: true)),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: BundleShareActions(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
