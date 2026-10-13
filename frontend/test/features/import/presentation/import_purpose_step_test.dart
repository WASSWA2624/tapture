import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/presentation/import_controller.dart';
import 'package:tapture/features/import/presentation/import_purpose_step.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The sheet could not be read.',
    recoveryAction: 'Choose another file.',
  );

  testWidgets('no sheet is the empty state', (WidgetTester tester) async {
    await _pump(tester, (busy: false, failure: null, document: null));
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('a refused sheet stays on the page', (WidgetTester tester) async {
    await _pump(tester, (busy: false, failure: failed, document: null));
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('records and a register are offered for a held sheet', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (
      busy: false,
      failure: null,
      document: PickedBytes(Uint8List(0), 'rows.csv'),
    ));
    expect(
      find.byKey(const ValueKey<String>('import-purpose-records')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('import-purpose-register')),
      findsOneWidget,
    );
    expect(
      tester.widget<AppPage>(find.byType(AppPage)).layout,
      AppPageLayout.compact,
    );
    expect(
      tester
          .widgetList<AppListTile>(find.byType(AppListTile))
          .every((AppListTile row) => row.wrapText),
      isTrue,
    );
  });
}

Future<void> _pump(WidgetTester tester, ImportView view) async {
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const ImportPurposeStep(),
      ),
    ),
  );
  await tester.pump();
  container.read(importControllerProvider.notifier).present(view);
  await tester.pump();
}
