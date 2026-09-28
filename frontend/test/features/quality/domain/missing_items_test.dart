import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('missing items are the register and checklist rows never captured', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>['a', 'b', 'c'],
      capturedRegisterIds: const <String>{'b'},
      checklistIds: const <String>['row-1', 'row-2'],
      capturedChecklistIds: const <String>{'row-1'},
    );
    expect(missing.registerNotFound, <String>['a', 'c']);
    expect(missing.checklistNotCaptured, <String>['row-2']);
  });

  test('a fully captured register and checklist leave nothing missing', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>['a', 'b'],
      capturedRegisterIds: const <String>{'a', 'b'},
      checklistIds: const <String>['row-1'],
      capturedChecklistIds: const <String>{'row-1'},
    );
    expect(missing.registerNotFound, isEmpty);
    expect(missing.checklistNotCaptured, isEmpty);
  });

  test('nothing captured lists every row, in register order', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>['c', 'a', 'b'],
      capturedRegisterIds: const <String>{},
      checklistIds: const <String>['row-2', 'row-1'],
      capturedChecklistIds: const <String>{},
    );
    expect(missing.registerNotFound, <String>['c', 'a', 'b']);
    expect(missing.checklistNotCaptured, <String>['row-2', 'row-1']);
  });

  test('a captured id that is not on the register changes nothing', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>['a'],
      capturedRegisterIds: const <String>{'a', 'stranger'},
      checklistIds: const <String>['row-1'],
      capturedChecklistIds: const <String>{'row-9'},
    );
    expect(missing.registerNotFound, isEmpty);
    expect(missing.checklistNotCaptured, <String>['row-1']);
  });

  test('the register and the checklist are counted apart', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>['shared'],
      capturedRegisterIds: const <String>{},
      checklistIds: const <String>['shared'],
      capturedChecklistIds: const <String>{'shared'},
    );
    expect(missing.registerNotFound, <String>['shared']);
    expect(missing.checklistNotCaptured, isEmpty);
  });

  test('an empty register and checklist have nothing to miss', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>[],
      capturedRegisterIds: const <String>{'a'},
      checklistIds: const <String>[],
      capturedChecklistIds: const <String>{},
    );
    expect(missing.registerNotFound, isEmpty);
    expect(missing.checklistNotCaptured, isEmpty);
  });
}
