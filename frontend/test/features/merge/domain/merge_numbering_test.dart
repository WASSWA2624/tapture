import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_numbering.dart';

void main() {
  const MergeNumbering numbering = MergeNumbering();

  test('only incoming collisions move, and the arrived number is kept', () {
    final Map<String, RelabelledNumber> full = numbering.relabel(
      incoming: const <IncomingNumber>[
        (id: 'local', number: '1', local: true),
        (id: 'in', number: '1', local: false),
      ],
      takenNumbers: const <String>{'1'},
    );
    expect(full.containsKey('local'), isFalse);
    expect(full['in']!.number, '2');
    expect(full['in']!.arrivedAs, '1');
    expect(
      numbering.relabel(
        incoming: const <IncomingNumber>[(id: 'in', number: '9', local: false)],
        takenNumbers: const <String>{'1'},
      ),
      isEmpty,
    );
  });
}
