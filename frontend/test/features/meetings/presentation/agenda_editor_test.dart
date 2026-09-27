import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/agenda_entry.dart';
import 'package:tapture/features/meetings/presentation/agenda_editor.dart';

import '../pump.dart';

void main() {
  testWidgets('add, reorder and remove', (WidgetTester tester) async {
    await pumpMeeting(tester, const _Host());
    await tester.tap(find.text(Copy.meetingAddAgenda));
    await tester.pump();
    await tester.tap(find.text(Copy.meetingAddAgenda));
    await tester.pump();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('agenda-down-1')));
    await tester.pump();
    final _HostState host = tester.state(find.byType(_Host));
    expect(host.entries.map((AgendaEntry entry) => entry.title), <String>[
      'Second',
      'First',
    ]);
    await tester.tap(find.byKey(const ValueKey<String>('agenda-remove-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(AppButton, Copy.meetingRemoveConfirm).last,
    );
    await tester.pumpAndSettle();
    expect(host.entries.single.title, 'Second');
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const AgendaEditor());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(tester, const AgendaEditor(failure: meetingFailed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  List<AgendaEntry> entries = <AgendaEntry>[];
  int _next = 1;

  @override
  Widget build(BuildContext context) {
    return AgendaEditor(
      entries: entries,
      onAdd: () {
        final int id = _next++;
        setState(() {
          entries = <AgendaEntry>[
            ...entries,
            AgendaEntry(id: '$id', title: id == 1 ? 'First' : 'Second'),
          ];
        });
      },
      onChanged: (List<AgendaEntry> next) => setState(() => entries = next),
    );
  }
}
