import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/domain/import_flow.dart';
import 'package:tapture/features/import/presentation/import_controller.dart';
import 'package:tapture/features/import/presentation/import_screen.dart';

import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'That file could not be read.',
    recoveryAction: 'Choose another file.',
  );

  testWidgets(
    'the idle page has one choose action with collapsed supported files',
    (WidgetTester tester) async {
      await _pump(tester, _idle);
      expect(find.byType(AppEmptyState), findsNothing);
      expect(find.byType(AppPrimaryAction), findsOneWidget);
      expect(find.text(Copy.importBundleLine), findsNothing);
      await tester.tap(find.text(Copy.importSupportedFiles));
      await tester.pumpAndSettle();
      expect(find.text(Copy.importBundleLine), findsOneWidget);
      for (final ImportFlow flow in ImportFlow.values) {
        expect(
          find.byKey(ValueKey<String>('import-kind-${flow.name}')),
          findsOneWidget,
        );
      }
    },
  );

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'compact import and expanded help ${cell.description}',
      (WidgetTester tester) async {
        await _pump(tester, _idle, cell: cell);
        expect(find.byType(AppPrimaryAction), findsOneWidget);
        expect(find.text(Copy.importBundleLine), findsNothing);
        final Finder help = find.text(Copy.importSupportedFiles);
        await tester.ensureVisible(help);
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(find.text(Copy.importBundleLine), findsOneWidget);
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('import-kind-template')),
        );
        await tester.pumpAndSettle();
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  testWidgets('pseudo locale keeps choose action and help reachable', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _idle,
      cell: const ScreenMatrix(Size(393, 320), 2, Brightness.dark, false),
      locale: const Locale('en', 'XA'),
    );
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
  });

  testWidgets('a check in progress stays on the page', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (busy: true, failure: null, document: null));
    expect(
      find.byKey(const ValueKey<String>('import-checking')),
      findsOneWidget,
    );
  });

  testWidgets('a refusal stays on the page', (WidgetTester tester) async {
    await _pump(tester, (busy: false, failure: failed, document: null));
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(failed.message), findsOneWidget);
  });
}

const ImportView _idle = (busy: false, failure: null, document: null);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  ImportView view, {
  ScreenMatrix? cell,
  Locale? locale,
}) async {
  tester.view.physicalSize = cell?.size ?? const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(
          brightness: cell?.brightness ?? Brightness.light,
          outdoor: cell?.outdoor ?? false,
        ),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell?.textScale ?? 1)),
          child: child!,
        ),
        home: const ImportScreen(),
      ),
    ),
  );
  await tester.pump();
  container.read(importControllerProvider.notifier).present(view);
  await tester.pumpAndSettle();
  return container;
}
