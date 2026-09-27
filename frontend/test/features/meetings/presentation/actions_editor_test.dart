import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/presentation/actions_editor.dart';

import '../pump.dart';

void main() {
  testWidgets('add, edit, remove and an owner from each source', (
    WidgetTester tester,
  ) async {
    await pumpMeeting(tester, const _Host());
    await tester.tap(find.text(Copy.meetingAddAction));
    await tester.pump();
    expect(find.byType(AppDateField), findsOneWidget);
    expect(find.text('Send the minutes'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey<String>('action-attendee-c1-a1')),
    );
    await tester.pump();
    final _HostState host = tester.state(find.byType(_Host));
    expect(host.actions.single.ownerName, 'Ada');
    await tester.tap(find.byKey(const ValueKey<String>('action-staff-c1-s1')));
    await tester.pump();
    expect(host.actions.single.ownerName, 'Grace');
    expect(host.actions.single.source, 'Send the minutes');
    await tester.enterText(
      find.byKey(const ValueKey<String>('action-text-c1')),
      'Send them',
    );
    await tester.pump();
    expect(host.actions.single.text, 'Send them');
    expect(host.actions.single.source, 'Send the minutes');
    await tester.tap(find.byKey(const ValueKey<String>('action-remove-c1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(AppButton, Copy.meetingRemoveConfirm).last,
    );
    await tester.pumpAndSettle();
    expect(host.actions, isEmpty);
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const ActionsEditor());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(tester, const ActionsEditor(failure: meetingFailed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  List<ActionEntry> actions = <ActionEntry>[];

  @override
  Widget build(BuildContext context) {
    return ActionsEditor(
      actions: actions,
      attendeeOwners: const <({String id, String name})>[
        (id: 'a1', name: 'Ada'),
      ],
      staffOwners: const <({String id, String name})>[
        (id: 's1', name: 'Grace'),
      ],
      onAdd: () => setState(() {
        actions = const <ActionEntry>[
          ActionEntry(
            id: 'c1',
            text: 'Send the minutes',
            source: 'Send the minutes',
          ),
        ];
      }),
      onChanged: (List<ActionEntry> next) => setState(() => actions = next),
    );
  }
}
