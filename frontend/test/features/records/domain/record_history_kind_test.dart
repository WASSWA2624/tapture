import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_history_kind.dart';

RecordHistoryKind _kind({
  String entityType = 'records',
  String action = 'updated',
  String? fieldKey,
  String? newValue,
  String? reason,
}) {
  return RecordHistoryKind.classify(
    entityType: entityType,
    action: action,
    fieldKey: fieldKey,
    newValue: newValue,
    reason: reason,
  );
}

void main() {
  test('the history tells thirteen kinds of line apart', () {
    expect(RecordHistoryKind.values, hasLength(13));
  });

  test('a record row with no field key and action created is the capture', () {
    expect(_kind(action: 'created'), RecordHistoryKind.created);
    expect(_kind(action: 'created', fieldKey: ''), RecordHistoryKind.created);
  });

  test('the record-level markers of D10 each name their own kind', () {
    expect(_kind(fieldKey: 'status'), RecordHistoryKind.statusChanged);
    expect(_kind(fieldKey: 'templateId'), RecordHistoryKind.templateChanged);
    expect(
      _kind(fieldKey: 'photo', newValue: 'added'),
      RecordHistoryKind.photoAdded,
    );
    expect(
      _kind(fieldKey: 'photo', newValue: 'removed'),
      RecordHistoryKind.photoRemoved,
    );
    expect(
      _kind(fieldKey: 'processing', newValue: 'completed'),
      RecordHistoryKind.processed,
    );
    expect(
      _kind(fieldKey: 'export', newValue: 'v2'),
      RecordHistoryKind.exported,
    );
    expect(_kind(fieldKey: 'merge'), RecordHistoryKind.merged);
  });

  test('a value flag is told apart from a value edit by its reason', () {
    expect(
      _kind(fieldKey: 'serial', reason: 'evidenceRemoved'),
      RecordHistoryKind.evidenceRemoved,
    );
    expect(
      _kind(fieldKey: 'serial', reason: 'retired'),
      RecordHistoryKind.retired,
    );
    expect(
      _kind(fieldKey: 'serial', reason: 'Operator correction'),
      RecordHistoryKind.valueChanged,
    );
  });

  test('any other field key on a record is a value change', () {
    expect(_kind(fieldKey: 'serial'), RecordHistoryKind.valueChanged);
    expect(
      _kind(action: 'created', fieldKey: 'serial'),
      RecordHistoryKind.valueChanged,
    );
  });

  test('caption rows are caption changes whatever they carry', () {
    expect(_kind(entityType: 'captions'), RecordHistoryKind.captionChanged);
    expect(
      _kind(entityType: 'captions', action: 'created', fieldKey: 'text'),
      RecordHistoryKind.captionChanged,
    );
  });

  test('photo rows are added when created and removed when deleted', () {
    expect(
      _kind(entityType: 'photos', action: 'created'),
      RecordHistoryKind.photoAdded,
    );
    expect(
      _kind(entityType: 'photos', action: 'deleted'),
      RecordHistoryKind.photoRemoved,
    );
    expect(
      _kind(entityType: 'photos', fieldKey: 'evidenceMissing'),
      RecordHistoryKind.other,
    );
  });

  test('row matching and unmarked updates fall to other', () {
    expect(_kind(fieldKey: 'templateRowId'), RecordHistoryKind.other);
    expect(_kind(fieldKey: 'evidenceMissing'), RecordHistoryKind.other);
    expect(_kind(), RecordHistoryKind.other);
    expect(_kind(action: 'deleted'), RecordHistoryKind.other);
  });
}
