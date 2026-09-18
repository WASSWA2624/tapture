import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';

void main() {
  final List<Uint8List> three = <Uint8List>[
    Uint8List.fromList(<int>[1]),
    Uint8List.fromList(<int>[2]),
    Uint8List.fromList(<int>[3]),
  ];

  test('the fake hands back no more photos than the room left', () async {
    final PhotoPicker picker = PhotoPicker.fake(photos: three);
    final Result<List<Uint8List>> chosen = await picker.choose(
      limit: 2,
      longEdge: 100,
    );
    expect((chosen as Success<List<Uint8List>>).value, three.take(2));
  });

  test('the camera gives one photo', () async {
    final PhotoPicker picker = PhotoPicker.fake(photos: three);
    final Result<List<Uint8List>> taken = await picker.take(longEdge: 100);
    expect((taken as Success<List<Uint8List>>).value, <Uint8List>[three.first]);
  });

  test('a refusal comes back as a failure with catalogue copy', () async {
    const PhotoPicker picker = PhotoPicker.fake(
      failure: PermissionFailure(message: Copy.photoNoAccess),
    );
    final Result<List<Uint8List>> taken = await picker.take(longEdge: 100);
    expect(
      (taken as FailureResult<List<Uint8List>>).failure.message,
      Copy.photoNoAccess,
    );
  });

  test('a device without a camera says so', () {
    expect(const PhotoPicker.fake(canTakePhoto: false).canTakePhoto, isFalse);
  });
}
