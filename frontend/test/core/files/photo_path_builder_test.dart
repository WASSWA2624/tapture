import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/photo_path_builder.dart';

void main() {
  test('the default strategy is byContext', () {
    expect(PhotoPathBuilder.defaultStrategy, PhotoFolderStrategy.byContext);
  });

  test('a fully set context matches the specification path', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.byContext,
        contextValues: <String>['Kampala', 'Kasubi-HC-IV', 'Theatre'],
      ),
      'photos/Kampala/Kasubi-HC-IV/Theatre',
    );
  });

  test('spaces in a context value become hyphens', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.byContext,
        contextValues: <String>['Kampala', 'Kasubi HC IV', 'Theatre'],
      ),
      'photos/Kampala/Kasubi-HC-IV/Theatre',
    );
  });

  group('partial context', () {
    test('no levels land under _unfiled', () {
      expect(
        buildPhotoPath(
          strategy: PhotoFolderStrategy.byContext,
          contextValues: const <String>[],
        ),
        'photos/_unfiled',
      );
    });

    test('one set level pads the rest with _unfiled', () {
      expect(
        buildPhotoPath(
          strategy: PhotoFolderStrategy.byContext,
          contextValues: <String>['Kampala'],
        ),
        'photos/Kampala/_unfiled/_unfiled',
      );
    });

    test('two set levels pad the last with _unfiled', () {
      expect(
        buildPhotoPath(
          strategy: PhotoFolderStrategy.byContext,
          contextValues: <String>['Kampala', 'Kasubi-HC-IV'],
        ),
        'photos/Kampala/Kasubi-HC-IV/_unfiled',
      );
    });

    test('a blank middle level is _unfiled', () {
      expect(
        buildPhotoPath(
          strategy: PhotoFolderStrategy.byContext,
          contextValues: <String>['Kampala', '', 'Theatre'],
        ),
        'photos/Kampala/_unfiled/Theatre',
      );
    });
  });

  test('byTemplate uses the sanitised template name', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.byTemplate,
        contextValues: const <String>[],
        templateName: 'Medical Equipment',
      ),
      'photos/Medical-Equipment',
    );
  });

  test('byTemplate with no name is _unfiled', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.byTemplate,
        contextValues: const <String>[],
      ),
      'photos/_unfiled',
    );
  });

  test('byCaptureDate uses year/month/day', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.byCaptureDate,
        contextValues: const <String>[],
        capturedAt: DateTime.utc(2026, 9, 17),
      ),
      'photos/2026/09/17',
    );
  });

  test('byCaptureDate with no date is _unfiled', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.byCaptureDate,
        contextValues: const <String>[],
      ),
      'photos/_unfiled',
    );
  });

  test('flat is photos with no extra folders', () {
    expect(
      buildPhotoPath(
        strategy: PhotoFolderStrategy.flat,
        contextValues: <String>['Kampala', 'Kasubi-HC-IV', 'Theatre'],
      ),
      'photos',
    );
  });

  test('a traversal context value is refused', () {
    expect(
      () => buildPhotoPath(
        strategy: PhotoFolderStrategy.byContext,
        contextValues: <String>['..'],
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
