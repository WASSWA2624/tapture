import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/widgets/app_action_dock.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/reference/presentation/dataset_key_screen.dart';
import 'package:tapture/features/reference/presentation/dataset_row_edit_screen.dart';
import 'package:tapture/features/reference/reference.dart';

import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';
import '../reference_fixtures.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final Size size in <Size>[const Size(390, 844), const Size(390, 300)]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets(
        'import picker stays reachable at $size x$scale and cancellation keeps import open',
        (WidgetTester tester) async {
          final FakeReferenceRepository store = FakeReferenceRepository();
          addTearDown(store.dispose);
          await _pump(
            tester,
            const DatasetKeyScreen(projectId: 'project'),
            store,
            size: size,
            scale: scale,
          );
          final Finder pick = _primary(Copy.datasetsPickFile);
          await tester.ensureVisible(pick);
          await tester.pump();
          expect(pick.hitTestable(), findsOneWidget);
          final Rect dock = tester.getRect(find.byType(AppActionDock));
          final Rect visible = tester.getRect(pick).intersect(dock);
          expect(dock.bottom, lessThanOrEqualTo(size.height));
          expect(visible.height, greaterThanOrEqualTo(Sizes.minTapTarget));
          expect(visible.bottom, greaterThan(size.height / 2));
          final Rect label = tester.getRect(find.text(Copy.datasetsPickFile));
          expect(label.intersect(dock), label);
          expect(
            tester.getSize(pick).height,
            greaterThanOrEqualTo(Sizes.primaryActionHeight),
          );
          await tester.tap(pick);
          await tester.pumpAndSettle();
          expect(find.text(Copy.datasetsPickHeadline), findsOneWidget);
          expect(pick.hitTestable(), findsOneWidget);
          expect(store.savedRows, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'grouped dataset correction preserves cells after failure and writes prior values on retry',
    (WidgetTester tester) async {
      final FakeReferenceRepository store = (await _seededStore())
        ..saveRowFailure = const StorageFailure(message: 'The device is full.');
      await _pump(
        tester,
        const DatasetRowEditScreen(datasetId: 'dataset', rowId: 'row'),
        store,
        scale: 2,
      );
      final Finder location = find.byKey(
        const ValueKey<String>('dataset-row-field-Location'),
      );
      await tester.enterText(location, 'Room 2');
      await tester.tap(_primary(Copy.datasetsSaveRow));
      await tester.pumpAndSettle();
      expect(tester.widget<AppTextField>(location).controller.text, 'Room 2');
      expect(
        (await store.rowById('row')).getOrThrow()?.values['Location'],
        'Room 1',
      );
      expect(find.text('The device is full.'), findsWidgets);
      store.saveRowFailure = null;
      await tester.tap(_primary(Copy.datasetsSaveRow));
      await tester.pumpAndSettle();
      expect(
        (await store.rowById('row')).getOrThrow()?.values['Location'],
        'Room 2',
      );
      expect(store.savedRows.last.previousValues?['Location'], 'Room 1');
      expect((await store.rowById('row')).getOrThrow()?.key, 'A-1');
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _primary(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppPrimaryAction && widget.label == label,
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  FakeReferenceRepository store, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpApp(
    tester,
    screen,
    overrides: <Override>[
      referenceRepositoryProvider.overrideWithValue(store),
      documentPickerProvider.overrideWithValue(const DocumentPicker.fake()),
    ],
  );
  await tester.pumpAndSettle();
}

Future<FakeReferenceRepository> _seededStore() async {
  final FakeReferenceRepository store = FakeReferenceRepository();
  addTearDown(store.dispose);
  await store.importDataset(
    dataset: aDataset(
      id: 'dataset',
      name: 'Equipment register',
      keyColumn: 'Serial number',
      columns: const <String>['Serial number', 'Location'],
      projectId: 'project',
    ),
    rows: <ReferenceRow>[
      aReferenceRow(
        id: 'row',
        datasetId: 'dataset',
        key: 'A-1',
        values: const <String, String>{
          'Serial number': 'A-1',
          'Location': 'Room 1',
        },
      ),
    ],
  );
  return store;
}
