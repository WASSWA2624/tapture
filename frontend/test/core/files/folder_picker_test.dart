import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/folder_picker.dart';

void main() {
  test('the fake returns a path, a cancel or a failure', () async {
    expect(
      await const FolderPicker.fake(path: r'D:\evidence').pick(),
      isA<Success<String?>>(),
    );
    expect(
      ((await const FolderPicker.fake(path: r'D:\evidence').pick())
              as Success<String?>)
          .value,
      r'D:\evidence',
    );

    final Result<String?> cancelled = await const FolderPicker.fake(
      cancel: true,
    ).pick();
    expect(cancelled, isA<FailureResult<String?>>());
    expect(
      (cancelled as FailureResult<String?>).failure,
      isA<CancelledFailure>(),
    );

    final Result<String?> failed = await const FolderPicker.fake(
      failure: StorageFailure(message: 'blocked', recoveryAction: 'Retry'),
    ).pick();
    expect(failed, isA<FailureResult<String?>>());
    expect((failed as FailureResult<String?>).failure, isA<StorageFailure>());
  });

  test('a platform that cannot pick fails without a dialog', () async {
    const FolderPicker picker = FolderPicker.fake(canPick: false);
    expect(picker.canPick, isFalse);
    final Result<String?> result = await picker.pick();
    expect(result, isA<FailureResult<String?>>());
  });

  test('the io picker is wired through a conditional import', () {
    final String source = File(
      'lib/core/files/folder_picker.dart',
    ).readAsStringSync();
    expect(
      source.contains("if (dart.library.io) 'folder_picker_io.dart'"),
      isTrue,
    );
    expect(
      source.contains("if (dart.library.js_interop) 'folder_picker_web.dart'"),
      isTrue,
    );
    expect(File('lib/core/files/folder_picker_io.dart').existsSync(), isTrue);
    expect(File('lib/core/files/folder_picker_web.dart').existsSync(), isTrue);
    expect(File('lib/core/files/folder_picker_stub.dart').existsSync(), isTrue);
    expect(FolderPicker().canPick, isTrue);
  });
}
