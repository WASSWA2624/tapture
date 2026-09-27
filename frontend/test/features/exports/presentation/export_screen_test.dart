import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/exports/presentation/export_options_section.dart';
import 'package:tapture/features/exports/presentation/export_progress.dart';
import 'package:tapture/features/exports/presentation/export_scope_section.dart';
import 'package:tapture/features/exports/presentation/export_screen.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'Export could not be read.',
    recoveryAction: 'Try again.',
  );
  const ExportColumns remembered = (
    raw: false,
    refined: true,
    confidence: false,
    evidence: false,
  );

  testWidgets('each scope updates the count and refined starts on', (
    WidgetTester tester,
  ) async {
    ExportScopeKind scope = ExportScopeKind.approved;
    int count = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScopeSection(
          selected: scope,
          count: count,
          onSelect: (ExportScopeKind next) {
            scope = next;
            count = 5;
          },
        ),
      ),
    );
    expect(find.text(Copy.exportCount(2)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('export-scope-all')));
    await tester.pump();
    expect(scope, ExportScopeKind.all);
    expect(count, 5);
    await tester.pumpWidget(
      const MaterialApp(home: ExportOptionsSection(columns: remembered)),
    );
    expect(
      find.byKey(const ValueKey<String>('export-refined')),
      findsOneWidget,
    );
  });

  testWidgets('scope and options empty and failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExportScopeSection()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportScopeSection(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: ExportOptionsSection(columns: remembered, empty: true),
      ),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: ExportOptionsSection(columns: remembered, failure: failed),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('a default export is one tap and cancel is offered', (
    WidgetTester tester,
  ) async {
    var started = false;
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(
          scope: ExportScopeKind.approved,
          count: 3,
          columns: remembered,
          onExport: () => started = true,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('export-run')));
    await tester.pump();
    expect(started, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: ExportProgress(
          stages: const <ExportStage>[
            (label: 'Records', state: StepState.running),
          ],
          onCancel: () => cancelled = true,
        ),
      ),
    );
    expect(find.byType(AppProgressSteps), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('export-cancel')));
    await tester.pump();
    expect(cancelled, isTrue);
  });

  testWidgets('the export screen empty and failure states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExportScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportScreen(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportProgress(empty: true)),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportProgress(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
