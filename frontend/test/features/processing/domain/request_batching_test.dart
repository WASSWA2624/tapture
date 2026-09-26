import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/request_batching.dart';

void main() {
  List<String> photos(int count) {
    return <String>[for (var i = 1; i <= count; i++) 'photo-$i.jpg'];
  }

  test('below the cap every photo goes in one request', () {
    final List<List<String>> batches = RequestBatching.split(photos(5), cap: 6);
    expect(batches, hasLength(1));
    expect(batches.single, photos(5));
  });

  test('at the cap it is still one request', () {
    expect(RequestBatching.split(photos(6), cap: 6), hasLength(1));
  });

  test('above the cap the set splits in capture order', () {
    final List<List<String>> batches = RequestBatching.split(photos(8), cap: 3);
    expect(batches, <List<String>>[
      <String>['photo-1.jpg', 'photo-2.jpg', 'photo-3.jpg'],
      <String>['photo-4.jpg', 'photo-5.jpg', 'photo-6.jpg'],
      <String>['photo-7.jpg', 'photo-8.jpg'],
    ]);
  });

  test('the same record always splits the same way', () {
    expect(
      RequestBatching.split(photos(7), cap: 2),
      RequestBatching.split(photos(7), cap: 2),
    );
  });

  test('a record with no photos is one text-only request', () {
    expect(RequestBatching.split(const <String>[]), <List<String>>[<String>[]]);
  });

  test('a five-photo record is one call under the app cap', () {
    expect(RequestBatching.split(photos(5)), hasLength(1));
  });
}
