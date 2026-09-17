import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';

import 'token_harness.dart';

void main() {
  test('the space scale is the four-point grid from 2 to 48', () {
    expect(Space.x0, 2);
    expect(Space.x1, 4);
    expect(Space.x2, 8);
    expect(Space.x3, 12);
    expect(Space.x4, 16);
    expect(Space.x5, 20);
    expect(Space.x6, 24);
    expect(Space.x7, 28);
    expect(Space.x8, 32);
    expect(Space.x9, 36);
    expect(Space.x10, 40);
    expect(Space.x11, 44);
    expect(Space.x12, 48);
  });

  test('radii and control sizes are the contract values', () {
    expect(Radii.sm, 8);
    expect(Radii.md, 12);
    expect(Radii.lg, 16);
    expect(Radii.pill, greaterThan(Radii.lg));
    expect(Sizes.minTapTarget, 48);
    expect(Sizes.controlHeight, 52);
    expect(Sizes.listPane, 280);
    expect(Sizes.controlHeight, greaterThanOrEqualTo(Sizes.minTapTarget));
  });

  test('dimension tokens do not vary by mode', () {
    // Geometry is a single set; outdoor must not invent a second scale
    // (FE-THEME-03). The same names resolve in every palette.
    expect(tokenModes, hasLength(3));
    expect(Space.x1, Space.x1);
    expect(Radii.md, Radii.md);
    expect(Sizes.minTapTarget, Sizes.minTapTarget);
  });
}
