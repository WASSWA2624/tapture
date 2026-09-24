import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/photo_derivation.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

void main() {
  test('the newest derived photo replaces its original in the tray', () {
    final List<PhotoDraft> active = _ok(
      PhotoDerivation.select(<PhotoDraft>[
        _photo('original', captured: DateTime.utc(2026, 1, 1)),
        _photo('crop', parent: 'original', captured: DateTime.utc(2026, 1, 2)),
        _photo('draw', parent: 'crop', captured: DateTime.utc(2026, 1, 3)),
      ]),
    );

    expect(active.map((PhotoDraft photo) => photo.id), <String>['draw']);
  });

  test('sibling chains keep the capture order of their originals', () {
    final List<PhotoDraft> active = _ok(
      PhotoDerivation.select(<PhotoDraft>[
        _photo('a', order: 0),
        _photo('b', order: 1),
        _photo('a2', parent: 'a', captured: DateTime.utc(2026, 2, 2)),
      ]),
    );

    expect(active.map((PhotoDraft photo) => photo.id), <String>['a2', 'b']);
  });

  test('a missing ancestor is a typed failure', () {
    final Result<List<PhotoDraft>> result = PhotoDerivation.select(<PhotoDraft>[
      _photo('edit', parent: 'gone'),
    ]);

    expect(result, isA<FailureResult<List<PhotoDraft>>>());
    final Failure failure = (result as FailureResult<List<PhotoDraft>>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.recoveryAction, isNotEmpty);
  });

  test('a cycle is a typed failure', () {
    final Result<List<PhotoDraft>> result = PhotoDerivation.select(<PhotoDraft>[
      _photo('a', parent: 'b'),
      _photo('b', parent: 'a'),
    ]);

    expect(result, isA<FailureResult<List<PhotoDraft>>>());
    expect(
      (result as FailureResult<List<PhotoDraft>>).failure,
      isA<ValidationFailure>(),
    );
  });
}

PhotoDraft _photo(
  String id, {
  String? parent,
  int order = 0,
  DateTime? captured,
}) {
  return PhotoDraft(
    id: id,
    projectId: 'p',
    relativePath: 'photos/$id.jpg',
    sha256: id,
    sortOrder: order,
    derivedFrom: parent,
    capturedAt: captured,
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
