import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/presentation/decisions_editor.dart';

import '../pump.dart';

void main() {
  testWidgets('add, edit and remove leave the source', (
    WidgetTester tester,
  ) async {
    await pumpMeeting(tester, const _Host());
    await tester.tap(find.text(Copy.meetingAddDecision));
    await tester.pump();
    expect(find.text('Adopt the plan'), findsWidgets);
    expect(find.text('Adopt the plan'), findsWidgets);
    await tester.enterText(find.byType(EditableText), 'Adopt it');
    await tester.pump();
    final _HostState host = tester.state(find.byType(_Host));
    expect(host.decisions.single.text, 'Adopt it');
    expect(host.decisions.single.source, 'Adopt the plan');
    await tester.tap(find.byKey(const ValueKey<String>('decision-remove-d1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(AppButton, Copy.meetingRemoveConfirm).last,
    );
    await tester.pumpAndSettle();
    expect(host.decisions, isEmpty);
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const DecisionsEditor());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(tester, const DecisionsEditor(failure: meetingFailed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  List<Decision> decisions = <Decision>[];

  @override
  Widget build(BuildContext context) {
    return DecisionsEditor(
      decisions: decisions,
      onAdd: () => setState(() {
        decisions = const <Decision>[
          Decision(id: 'd1', text: 'Adopt the plan', source: 'Adopt the plan'),
        ];
      }),
      onChanged: (List<Decision> next) => setState(() => decisions = next),
    );
  }
}
