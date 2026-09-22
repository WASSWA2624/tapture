import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_hierarchy_screen.dart';
import 'package:tapture/features/context/presentation/context_picker_sheet.dart';
import 'package:tapture/features/context/presentation/context_preset_list.dart';
import 'package:tapture/features/context/presentation/context_preset_save.dart';
import 'package:tapture/features/context/presentation/pinned_fields_sheet.dart';

import '../../../support/fakes/fake_context_repository.dart';

void main() {
  late FakeContextRepository repo;

  setUp(() {
    repo = FakeContextRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: <Override>[
        contextRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('hierarchy empty zero levels and failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(const ContextHierarchyScreen(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.contextHierarchyEmptyHeadline), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        const ContextHierarchyScreen(
          projectId: 'p1',
          failure: StorageFailure(
            message: 'hier-fail',
            recoveryAction: 'retry',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('hier-fail'), findsWidgets);
  });

  testWidgets('hierarchy three levels reorder persists', (
    WidgetTester tester,
  ) async {
    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'a', order: 0, label: 'A'),
      ContextLevel(fieldKey: 'b', order: 1, label: 'B'),
      ContextLevel(fieldKey: 'c', order: 2, label: 'C'),
    ]);
    await tester.pumpWidget(
      wrap(const ContextHierarchyScreen(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('context bar hidden when empty', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Scaffold(body: ContextBar())));
    await tester.pumpAndSettle();
    expect(find.byType(ContextBar), findsOneWidget);
    expect(find.byType(AppChip), findsNothing);
  });

  testWidgets('picker and pinned failure and empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ContextPickerSheet(
          projectId: 'p1',
          level: ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
          currentValue: '',
          failure: StorageFailure(
            message: 'pick-fail',
            recoveryAction: 'retry',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('pick-fail'), findsWidgets);

    await tester.pumpWidget(
      wrap(
        const PinnedFieldsSheet(
          projectId: 'p1',
          failure: StorageFailure(message: 'pin-fail', recoveryAction: 'retry'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('pin-fail'), findsWidgets);
  });

  testWidgets('preset list empty and failure; save duplicate path', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const ContextPresetList(projectId: 'p1')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.contextPresetsEmptyHeadline), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        const ContextPresetList(
          projectId: 'p1',
          failure: StorageFailure(
            message: 'list-fail',
            recoveryAction: 'retry',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('list-fail'), findsWidgets);

    await tester.pumpWidget(
      wrap(const Scaffold(body: ContextPresetSave(projectId: 'p1'))),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.contextPresetSave), findsWidgets);
  });
}
