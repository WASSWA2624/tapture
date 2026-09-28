import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/record_number.dart';

/// The per-project watermark behind one transaction at a time, as the
/// record insert holds it: a read, the allocation, then the write, with no
/// other insert between them.
final class _SerialisedAllocator {
  int _last = 0;
  Future<void> _turn = Future<void>.value();

  /// Allocates inside the project's transaction, after every earlier one.
  Future<int> allocate() {
    final Future<int> mine = _turn.then((_) async {
      final int read = _last;
      // Yield, as a database round trip would, before the write lands.
      await Future<void>.value();
      final int number = RecordNumber.next(read);
      _last = number;
      return number;
    });
    _turn = mine.then((_) {});
    return mine;
  }
}

void main() {
  test('the first record in a project is number one', () {
    expect(RecordNumber.next(0), 1);
  });

  test('a negative watermark restarts at one rather than below it', () {
    expect(RecordNumber.next(-3), 1);
  });

  test('each number follows the last allocated', () {
    expect(RecordNumber.next(41), 42);
  });

  test('a range is consecutive from the number after the watermark', () {
    expect(RecordNumber.allocateRange(5, 4), <int>[6, 7, 8, 9]);
  });

  test('a zero-length range allocates nothing', () {
    expect(RecordNumber.allocateRange(5, 0), isEmpty);
  });

  test(
    'twenty rapid captures get twenty consecutive numbers with no gap or '
    'duplicate',
    () {
      final List<int> numbers = RecordNumber.allocateRange(0, 20);

      expect(numbers, <int>[for (var n = 1; n <= 20; n++) n]);
      expect(numbers.toSet(), hasLength(20));
    },
  );

  test(
    'twenty parallel inserts allocating inside one transaction each never '
    'collide',
    () async {
      final _SerialisedAllocator allocator = _SerialisedAllocator();

      final List<int> numbers = await Future.wait(<Future<int>>[
        for (var i = 0; i < 20; i++) allocator.allocate(),
      ]);

      expect(numbers.toSet(), hasLength(20));
      expect(numbers..sort(), <int>[for (var n = 1; n <= 20; n++) n]);
    },
  );
}
