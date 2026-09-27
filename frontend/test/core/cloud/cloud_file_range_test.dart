import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';

void main() {
  test('openFile reads one slice and not the rest of a large file', () async {
    final Directory root = Directory.systemTemp.createTempSync('tapture-range');
    addTearDown(() => root.deleteSync(recursive: true));
    final File file = File('${root.path}${Platform.pathSeparator}archive.bin');
    await file.writeAsBytes(List<int>.generate(32, (int index) => index));
    final UploadRunner runner = UploadRunner(
      destinationFor: (_) => throw StateError('unused'),
      history: (
        begin: (_) async => throw StateError('unused'),
        finish: (_) async => throw StateError('unused'),
        read: (_) async => throw StateError('unused'),
      ),
      clock: FixedClock(DateTime.utc(2026, 9, 28)),
    );
    final List<int> slice = await runner
        .openFile(file.path, 1 << 20)
        .read(4, 3);
    expect(slice, <int>[4, 5, 6]);
  });
}
