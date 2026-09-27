import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_history_event.dart';

void main() {
  final RecordHistoryEvent edit = RecordHistoryEvent(
    id: 'audit-1',
    at: DateTime.utc(2026, 9, 17, 8),
    kind: RecordHistoryKind.valueChanged,
    operator: 'Ada',
    device: 'device-1',
    fieldKey: 'serial',
    previous: 'SN-1',
    next: 'SN-2',
    reason: 'Operator correction',
  );

  test('a line keeps who, when, what, from what and to what', () {
    expect(edit.at, DateTime.utc(2026, 9, 17, 8));
    expect(edit.kind, RecordHistoryKind.valueChanged);
    expect(edit.operator, 'Ada');
    expect(edit.device, 'device-1');
    expect(edit.fieldKey, 'serial');
    expect(edit.previous, 'SN-1');
    expect(edit.next, 'SN-2');
    expect(edit.reason, 'Operator correction');
  });

  test('the history kind is reachable through this file', () {
    expect(RecordHistoryKind.values, contains(RecordHistoryKind.merged));
  });

  test('a line without a field or values leaves them null', () {
    final RecordHistoryEvent created = RecordHistoryEvent(
      id: 'audit-0',
      at: DateTime.utc(2026, 9, 17, 7),
      kind: RecordHistoryKind.created,
      operator: '',
      device: 'device-1',
    );
    expect(created.fieldKey, isNull);
    expect(created.previous, isNull);
    expect(created.next, isNull);
    expect(created.reason, isNull);
  });

  test('lines with the same fields are equal', () {
    final RecordHistoryEvent same = edit.copyWith();
    expect(same, edit);
    expect(same.hashCode, edit.hashCode);
    expect(edit.copyWith(next: 'SN-3'), isNot(edit));
    expect(
      edit.copyWith(kind: RecordHistoryKind.other).kind,
      RecordHistoryKind.other,
    );
  });

  test('toString names the row and its kind, never the values', () {
    expect(edit.toString(), 'RecordHistoryEvent(audit-1, valueChanged)');
    expect(edit.toString(), isNot(contains('SN-')));
  });
}
