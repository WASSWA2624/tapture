import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('an empty collection names what to do next', (
    WidgetTester tester,
  ) async {
    await expectEmptyState(tester, action: 'Create a project');
  });

  testWidgets('a bare message is not an empty state', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Text('Nothing here'));
    expect(find.byType(AppEmptyState), findsNothing);
  });
}

/// Pumps the shared empty state and requires [action].
Future<void> expectEmptyState(WidgetTester tester, {required String action}) {
  return pumpApp(
    tester,
    AppEmptyState(
      icon: Icons.folder_outlined,
      headline: 'No projects',
      message: action,
    ),
  ).then((_) {
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(action), findsOneWidget);
  });
}
