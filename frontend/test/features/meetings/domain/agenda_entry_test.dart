import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/agenda_entry.dart';

void main() {
  test('an agenda entry keeps its discussion notes', () {
    const AgendaEntry entry = AgendaEntry(
      id: 'g1',
      title: 'Welcome',
      notes: 'Opened.',
    );
    expect(AgendaEntry.fromJson(entry.toJson()), entry);
  });
}
