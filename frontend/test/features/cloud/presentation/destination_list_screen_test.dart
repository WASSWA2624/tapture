import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/cloud/domain/destination_check.dart';
import 'package:tapture/features/cloud/presentation/destination_list_controller.dart';
import 'package:tapture/features/cloud/presentation/destination_list_screen.dart';

import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The destinations could not be read.',
    recoveryAction: 'Try again.',
  );
  final Destination refused = (
    id: 'dest-2',
    kind: DestinationKind.webdav,
    label: 'Dav',
    folder: 'files',
    credentialRef: 'ref-2',
    lastCheck: DestinationCheck(
      at: DateTime.utc(2026, 9, 28),
      reason: 'The destination refused the sign-in.',
    ).encode(),
  );

  testWidgets('an empty list explains that', (WidgetTester tester) async {
    await _pump(tester, const <Destination>[]);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('a destination names its folder', (WidgetTester tester) async {
    await _pump(tester, <Destination>[
      (
        id: 'dest-1',
        kind: DestinationKind.s3,
        label: 'Archive',
        folder: 'inbox',
        credentialRef: 'ref',
        lastCheck: null,
      ),
    ]);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.textContaining('inbox'), findsOneWidget);
  });

  testWidgets('a loading list shows a skeleton', (WidgetTester tester) async {
    await _pump(tester, const <Destination>[], loading: true);
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('a failed check is named on the row', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <Destination>[refused]);
    expect(
      find.textContaining('The destination refused the sign-in.'),
      findsOneWidget,
    );
  });

  testWidgets('a load failure is shown', (WidgetTester tester) async {
    await _pump(tester, const <Destination>[], error: failed);
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'compact destination exposes complete failure and row actions ${cell.description}',
      (WidgetTester tester) async {
        await _pump(tester, <Destination>[refused], cell: cell);
        expect(
          tester.widget<AppPage>(find.byType(AppPage)).layout,
          AppPageLayout.compact,
        );
        expect(
          tester.widget<AppListTile>(find.byType(AppListTile)).wrapText,
          isTrue,
        );
        expect(
          find.textContaining('The destination refused the sign-in.'),
          findsOneWidget,
        );
        final Finder actions = find.byKey(
          const ValueKey<String>('destination-actions-dest-2'),
        );
        await tester.ensureVisible(actions);
        await tester.pumpAndSettle();
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[actions],
          ),
          isEmpty,
        );
        await tester.tap(actions);
        await tester.pumpAndSettle();
        for (final String action in <String>['edit', 'test', 'remove']) {
          expect(
            find.byKey(ValueKey<String>('destination-$action-dest-2')),
            findsOneWidget,
          );
        }
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  List<Destination> rows, {
  bool loading = false,
  Failure? error,
  ScreenMatrix? cell,
}) async {
  if (cell != null) {
    tester.view.physicalSize = cell.size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final StreamController<List<Destination>> pending =
      StreamController<List<Destination>>.broadcast();
  addTearDown(pending.close);
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      destinationListProvider.overrideWith(
        (Ref _) => error != null
            ? Stream<List<Destination>>.error(error)
            : loading
            ? pending.stream
            : Stream<List<Destination>>.value(rows),
      ),
      destinationKindsProvider.overrideWith(
        (Ref _) async => const <DestinationKind>[],
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(
          brightness: cell?.brightness ?? Brightness.light,
          outdoor: cell?.outdoor ?? false,
        ),
        home: const DestinationListScreen(),
      ),
    ),
  );
  await tester.pump();
}
