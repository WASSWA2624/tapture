import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_photo.dart';

void main() {
  const RecordPhoto photo = RecordPhoto(
    id: 'photo-1',
    sha256: 'abc',
    storagePath: 'photos/record-1/img.jpg',
  );

  test('a photo starts upright, uncaptioned and first', () {
    expect(photo.quarterTurns, 0);
    expect(photo.caption, isEmpty);
    expect(photo.hasCaption, isFalse);
    expect(photo.sortOrder, 0);
    expect(photo.photoType, isEmpty);
  });

  test('photos with the same fields are equal', () {
    const RecordPhoto same = RecordPhoto(
      id: 'photo-1',
      sha256: 'abc',
      storagePath: 'photos/record-1/img.jpg',
    );
    expect(photo, same);
    expect(photo.hashCode, same.hashCode);
    expect(photo, isNot(photo.copyWith(quarterTurns: 1)));
  });

  test('copyWith replaces only what it is given', () {
    final RecordPhoto turned = photo.copyWith(
      quarterTurns: 3,
      caption: 'Rating plate',
      sortOrder: 2,
      photoType: 'plate',
    );
    expect(turned.id, 'photo-1');
    expect(turned.sha256, 'abc');
    expect(turned.quarterTurns, 3);
    expect(turned.hasCaption, isTrue);
    expect(turned.sortOrder, 2);
    expect(turned.photoType, 'plate');
    expect(photo.copyWith(), photo);
  });

  test('toString names the photo and never its caption', () {
    expect(
      photo.copyWith(caption: 'secret words').toString(),
      'RecordPhoto(photo-1)',
    );
  });
}
