import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/presentation/photo_frame.dart';

void main() {
  const Size box = Size(400, 400);

  test('a wide photo fills the width and centres vertically', () {
    final Rect rect = PhotoFrame.fit(box, const Size(4000, 2000), 0);
    expect(rect, const Rect.fromLTWH(0, 100, 400, 200));
  });

  test('a tall photo fills the height and centres horizontally', () {
    final Rect rect = PhotoFrame.fit(box, const Size(1000, 2000), 0);
    expect(rect, const Rect.fromLTWH(100, 0, 200, 400));
  });

  test('a turned photo swaps its sides before it fits', () {
    final Rect once = PhotoFrame.fit(box, const Size(4000, 2000), 1);
    final Rect thrice = PhotoFrame.fit(box, const Size(4000, 2000), 3);
    final Rect twice = PhotoFrame.fit(box, const Size(4000, 2000), 2);
    expect(once, const Rect.fromLTWH(100, 0, 200, 400));
    expect(thrice, once);
    expect(twice, const Rect.fromLTWH(0, 100, 400, 200));
  });

  test('an empty photo or box gives an empty rect', () {
    expect(PhotoFrame.fit(box, Size.zero, 0).isEmpty, isTrue);
    expect(PhotoFrame.fit(Size.zero, const Size(10, 10), 0).isEmpty, isTrue);
  });

  test('quarter turns come from any rotation in degrees', () {
    expect(PhotoFrame.quarterTurns(0), 0);
    expect(PhotoFrame.quarterTurns(90), 1);
    expect(PhotoFrame.quarterTurns(450), 1);
    expect(PhotoFrame.quarterTurns(-90), 3);
  });

  test('moving keeps the frame inside the photo', () {
    const Rect start = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    final Rect pushed = PhotoFrame.move(start, const Offset(0.5, -0.5));
    expect(pushed.topLeft, offsetMoreOrLessEquals(const Offset(0.2, 0)));
    expect(pushed.size, start.size);
    expect(
      PhotoFrame.move(start, const Offset(0.05, 0.05)).topLeft,
      offsetMoreOrLessEquals(const Offset(0.15, 0.15)),
    );
  });

  test('a corner resizes the frame and keeps the opposite corner', () {
    const Rect start = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    final Rect grown = PhotoFrame.resize(
      start,
      Alignment.topLeft,
      const Offset(-0.5, -0.05),
    );
    expect(grown.topLeft, offsetMoreOrLessEquals(const Offset(0, 0.05)));
    expect(grown.bottomRight, offsetMoreOrLessEquals(start.bottomRight));

    final Rect shrunk = PhotoFrame.resize(
      start,
      Alignment.bottomRight,
      const Offset(-2, -0.2),
    );
    expect(shrunk.topLeft, offsetMoreOrLessEquals(start.topLeft));
    expect(shrunk.width, moreOrLessEquals(PhotoFrame.minCropSide));
    expect(shrunk.bottom, moreOrLessEquals(0.7));
  });

  test('a logical drag becomes a fraction of the shown photo', () {
    const Rect photo = Rect.fromLTWH(20, 40, 200, 100);
    expect(
      PhotoFrame.fractionOf(const Offset(20, 10), photo),
      const Offset(0.1, 0.1),
    );
    expect(PhotoFrame.fractionOf(const Offset(5, 5), Rect.zero), Offset.zero);
    expect(
      PhotoFrame.toRect(const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5), photo),
      const Rect.fromLTWH(120, 90, 100, 50),
    );
  });
}
