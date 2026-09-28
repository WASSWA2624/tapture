import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/core/widgets/forms/validation_display.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/settings/settings.dart';

const Failure _failed = StorageFailure(
  message: 'Quality could not be read.',
  recoveryAction: 'Try again.',
);

void main() {
  testWidgets('the validation summary names the count and jumps to the error', (
    WidgetTester tester,
  ) async {
    var jumped = false;
    await _pump(
      tester,
      ValidationDisplay.summary(
        issues: const <ValidationIssue>[
          ValidationIssue('serial', Severity.error, 'Serial is required.'),
          ValidationIssue('note', Severity.warning, 'Note is required.'),
        ],
        onJumpToError: () => jumped = true,
      ),
    );
    expect(find.text(Copy.validationIssueCount(1, 1)), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('validation-first-error')),
    );
    expect(jumped, isTrue);
  });

  testWidgets('validation display renders none, warnings, errors and mixed', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const ValidationDisplay.inline(
        fieldKey: 'serial',
        issues: <ValidationIssue>[],
      ),
    );
    expect(find.textContaining(Copy.validationErrorLabel), findsNothing);

    await _pump(
      tester,
      const ValidationDisplay.inline(
        fieldKey: 'note',
        issues: <ValidationIssue>[
          ValidationIssue('note', Severity.warning, 'Note is required.'),
        ],
      ),
    );
    expect(find.textContaining(Copy.validationWarningLabel), findsOneWidget);

    await _pump(
      tester,
      const ValidationDisplay.inline(
        fieldKey: 'serial',
        issues: <ValidationIssue>[
          ValidationIssue('serial', Severity.error, 'Serial is required.'),
        ],
      ),
    );
    expect(find.textContaining(Copy.validationErrorLabel), findsOneWidget);
  });

  testWidgets(
    'the duplicate prompt offers four choices and dismisses to nothing',
    (WidgetTester tester) async {
      DuplicateChoice? choice;
      await _pump(
        tester,
        DuplicatePrompt(
          differences: const <DuplicateDifference>[
            (label: 'Serial', incoming: 'A-2', existing: 'A-1'),
          ],
          onChoose: (DuplicateChoice next) => choice = next,
        ),
      );
      expect(find.text('A-1 → A-2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('duplicate-keep')));
      expect(choice, DuplicateChoice.keepBoth);
    },
  );

  testWidgets('the duplicate prompt renders empty and failure', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const DuplicatePrompt(differences: <DuplicateDifference>[]),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(
      tester,
      const DuplicatePrompt(
        differences: <DuplicateDifference>[],
        failure: _failed,
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('the merge sheet renders empty and failure', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const DuplicateMergeSheet(fields: <MergeField>[]));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(
      tester,
      const DuplicateMergeSheet(fields: <MergeField>[], failure: _failed),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('a conflict row picks a candidate or a typed value', (
    WidgetTester tester,
  ) async {
    String? picked;
    String? typed;
    await _pump(
      tester,
      ConflictResolutionRow(
        choices: const <ConflictChoice>[
          (
            id: 'ocr',
            sourceLabel: 'Read from photo',
            value: 'A-1',
            evidence: 'photo-1',
          ),
          (id: 'bar', sourceLabel: 'Barcode', value: 'A-2', evidence: null),
        ],
        onPick: (String id, String _) => picked = id,
        onTyped: (String value, String _) => typed = value,
      ),
    );
    await tester.tap(find.text('A-1'));
    expect(picked, 'ocr');
    await tester.enterText(
      find.byKey(const ValueKey<String>('conflict-typed')),
      'A-3',
    );
    await tester.tap(find.byKey(const ValueKey<String>('conflict-use-typed')));
    expect(typed, 'A-3');
  });

  testWidgets('the conflict row renders empty and failure', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const ConflictResolutionRow(choices: <ConflictChoice>[]),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(
      tester,
      const ConflictResolutionRow(
        choices: <ConflictChoice>[],
        failure: _failed,
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('verification mode toggles on, off and shows a failure', (
    WidgetTester tester,
  ) async {
    bool? next;
    await _pump(
      tester,
      VerificationModeToggle(onChanged: (bool value) => next = value),
    );
    expect(find.text(Copy.verificationModeOff), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('verification-mode')));
    expect(next, isTrue);

    await _pump(tester, const VerificationModeToggle(failure: _failed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
      ),
    ),
  );
}
