import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/pump_app.dart';

const Failure _failed = StorageFailure(
  message: 'The records could not be read.',
  recoveryAction: 'Try again.',
);

const List<DuplicateDifference> _differences = <DuplicateDifference>[
  (label: 'Serial', existing: 'A-1', incoming: 'A-2'),
  (label: 'Condition', existing: 'Good', incoming: 'Faulty'),
];

const ValueKey<String> _override = ValueKey<String>(
  'duplicate-compare-override',
);

void main() {
  testWidgets(
    'the comparison shows both records, their capture details and only the '
    'fields that differ',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        const DuplicateCompareScreen(
          leftTitle: 'Pump 12',
          rightTitle: 'Pump 12 (new)',
          leftDetail: '17 Sep · Ada · North',
          rightDetail: '28 Sep · Ben · North',
          differences: _differences,
        ),
      );
      expect(find.text(Copy.duplicateCompareTitle), findsOneWidget);
      expect(find.text('Pump 12'), findsOneWidget);
      expect(find.text('Pump 12 (new)'), findsOneWidget);
      expect(find.text('17 Sep · Ada · North'), findsOneWidget);
      expect(find.text('28 Sep · Ben · North'), findsOneWidget);
      expect(find.text('Serial'), findsOneWidget);
      expect(find.text('A-1 · A-2'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Good · Faulty'), findsOneWidget);
      expect(find.byType(AppListTile), findsNWidgets(4));
    },
  );

  testWidgets('override is offered from the comparison and fires once', (
    WidgetTester tester,
  ) async {
    var overrides = 0;
    await pumpApp(
      tester,
      DuplicateCompareScreen(
        leftTitle: 'Old',
        rightTitle: 'New',
        differences: _differences,
        onOverride: () => overrides += 1,
      ),
    );
    expect(find.text(Copy.duplicateOverride), findsOneWidget);
    await tester.tap(find.byKey(_override));
    await tester.pump();
    expect(overrides, 1);
  });

  testWidgets('without an override handler the button cannot be pressed', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const DuplicateCompareScreen(
        leftTitle: 'Old',
        rightTitle: 'New',
        differences: _differences,
      ),
    );
    final FilledButton button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(_override),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.enabled, isFalse);
  });

  testWidgets('records that do not differ show the empty state, no override', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      DuplicateCompareScreen(
        leftTitle: 'Old',
        rightTitle: 'New',
        differences: const <DuplicateDifference>[],
        onOverride: () {},
      ),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.duplicateNoDifferenceHeadline), findsOneWidget);
    expect(find.byKey(_override), findsNothing);
    expect(find.byType(AppListTile), findsNothing);
  });

  testWidgets('a failure shows the error state with its message, no override', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      DuplicateCompareScreen(
        leftTitle: 'Old',
        rightTitle: 'New',
        differences: _differences,
        failure: _failed,
        onOverride: () {},
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_failed.message), findsOneWidget);
    expect(find.byKey(_override), findsNothing);
    expect(find.text('A-1 · A-2'), findsNothing);
  });
}
