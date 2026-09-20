import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/domain/project_openable_file_lookup.dart';

void main() {
  test('the fake reports a file without a stored path', () async {
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
    String? seenId;
    final ProjectOpenableFileLookup lookup = ProjectOpenableFileLookup.fake(
      file: (fileName: 'book.xlsx', bytes: bytes, mimeType: 'application/pdf'),
      onFind: (String projectId, String _) {
        seenId = projectId;
      },
    );

    expect(
      _ok(await lookup.exists(projectId: 'project-1', folderName: 'alpha')),
      isTrue,
    );
    final ProjectOpenableFile? file = _ok(
      await lookup.find(projectId: 'project-1', folderName: 'alpha'),
    );

    expect(seenId, 'project-1');
    expect(file?.fileName, 'book.xlsx');
    expect(file?.bytes, bytes);
    expect(file?.mimeType, 'application/pdf');
  });

  test('the fake hides a project that has no file', () async {
    final ProjectOpenableFileLookup lookup = ProjectOpenableFileLookup.fake();

    expect(
      _ok(await lookup.exists(projectId: 'project-1', folderName: 'alpha')),
      isFalse,
    );
    expect(
      _ok(await lookup.find(projectId: 'project-1', folderName: 'alpha')),
      isNull,
    );
  });
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}
