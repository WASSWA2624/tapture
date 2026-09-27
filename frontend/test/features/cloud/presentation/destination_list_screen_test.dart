import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/cloud/presentation/destination_list_screen.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The destinations could not be read.',
    recoveryAction: 'Try again.',
  );
  const Destination ready = (
    id: 'dest-1',
    kind: DestinationKind.s3,
    label: 'Archive',
    folder: 'inbox',
    credentialRef: 'ref',
    lastCheck: null,
  );
  const Destination refused = (
    id: 'dest-2',
    kind: DestinationKind.webdav,
    label: 'Dav',
    folder: 'files',
    credentialRef: 'ref-2',
    lastCheck: 'The destination refused the sign-in.',
  );

  testWidgets('empty, populated, loading and a failed check', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(const DestinationListScreen(rows: <Destination>[])),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);

    await tester.pumpWidget(
      _app(const DestinationListScreen(rows: <Destination>[ready])),
    );
    expect(find.text('Archive'), findsOneWidget);
    expect(find.textContaining('inbox'), findsOneWidget);

    await tester.pumpWidget(_app(const DestinationListScreen(loading: true)));
    expect(find.byType(AppSkeleton), findsOneWidget);

    await tester.pumpWidget(
      _app(const DestinationListScreen(rows: <Destination>[refused])),
    );
    expect(
      find.textContaining('The destination refused the sign-in.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a failed check cannot be saved, and a success clears the sign-in',
    (WidgetTester tester) async {
      var saved = false;
      final TextEditingController label = TextEditingController();
      final TextEditingController folder = TextEditingController();
      final TextEditingController secret = TextEditingController(
        text: 'secret-value',
      );
      addTearDown(label.dispose);
      addTearDown(folder.dispose);
      addTearDown(secret.dispose);
      await tester.pumpWidget(
        _app(
          DestinationListScreen(
            rows: const <Destination>[],
            editing: true,
            labelController: label,
            folderController: folder,
            secretController: secret,
            onCheck: () async => false,
            onSave: () => saved = true,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('destination-save')));
      await tester.pump();
      expect(saved, isFalse);
      expect(secret.text, 'secret-value');

      await tester.pumpWidget(
        _app(
          DestinationListScreen(
            rows: const <Destination>[],
            editing: true,
            labelController: label,
            folderController: folder,
            secretController: secret,
            onCheck: () async => true,
            onSave: () => saved = true,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('destination-save')));
      await tester.pump();
      expect(saved, isTrue);
      expect(secret.text, isEmpty);
    },
  );

  testWidgets('a load failure is shown', (WidgetTester tester) async {
    await tester.pumpWidget(_app(const DestinationListScreen(failure: failed)));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

Widget _app(Widget home) {
  return ProviderScope(child: MaterialApp(home: home));
}
